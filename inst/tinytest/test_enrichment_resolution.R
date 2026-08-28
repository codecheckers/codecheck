tinytest::using(ttdo)

config_path <- system.file("extdata", "config.R", package = "codecheck")
if (config_path == "" || !file.exists(config_path)) {
  exit_file("Package not installed properly")
}
source(config_path)

# keep this test's certs out of the real docs/certs, restored at the end
old_certs_dir <- CONFIG$CERTS_DIR[["cert"]]
test_certs_dir <- file.path(tempfile("codecheck_enrichment_test"))
dir.create(test_certs_dir, recursive = TRUE)
CONFIG$CERTS_DIR[["cert"]] <- test_certs_dir

write_previous_json <- function(cert_id, paper_fields) {
  cert_dir <- file.path(test_certs_dir, cert_id)
  dir.create(cert_dir, recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    list(paper = paper_fields),
    file.path(cert_dir, "index.json"),
    auto_unbox = TRUE, pretty = TRUE, null = "null"
  )
}

## read_previous_cert_field() ------------------------------------------------

# no index.json at all
expect_true(is.null(codecheck:::read_previous_cert_field("no-such-cert", c("paper", "openalex"))))

write_previous_json("2020-018", list(openalex = "https://openalex.org/W3042993452"))
expect_equal(
  codecheck:::read_previous_cert_field("2020-018", c("paper", "openalex")),
  "https://openalex.org/W3042993452"
)
# key path present in the file but not this field
expect_true(is.null(codecheck:::read_previous_cert_field("2020-018", c("paper", "abstract"))))
# key path with a missing intermediate segment
expect_true(is.null(codecheck:::read_previous_cert_field("2020-018", c("codecheck", "summary"))))

## resolve_external_field() - OpenAlex ID (scalar field) --------------------

new_id <- "https://openalex.org/W111"

# found always wins, previous value or not
expect_equal(
  codecheck:::resolve_external_field("2020-018", c("paper", "openalex"), "found", new_id, empty_value = NA_character_),
  new_id
)

# absent, no prune flag: previous value is kept
expect_equal(
  codecheck:::resolve_external_field("2020-018", c("paper", "openalex"), "absent", NA_character_, empty_value = NA_character_),
  "https://openalex.org/W3042993452"
)

# absent, prune_unavailable = TRUE: previous value is actually removed
expect_true(is.na(
  codecheck:::resolve_external_field("2020-018", c("paper", "openalex"), "absent", NA_character_,
                                     empty_value = NA_character_, prune_unavailable = TRUE)
))

# failed: previous value is kept regardless of prune_unavailable - a
# non-response must never be treated as confirmation of removal
expect_equal(
  codecheck:::resolve_external_field("2020-018", c("paper", "openalex"), "failed", NA_character_, empty_value = NA_character_),
  "https://openalex.org/W3042993452"
)
expect_equal(
  codecheck:::resolve_external_field("2020-018", c("paper", "openalex"), "failed", NA_character_,
                                     empty_value = NA_character_, prune_unavailable = TRUE),
  "https://openalex.org/W3042993452"
)

# no previous value at all: absent/failed both yield the empty value, found still wins
expect_true(is.na(
  codecheck:::resolve_external_field("2020-099", c("paper", "openalex"), "absent", NA_character_, empty_value = NA_character_)
))
expect_true(is.na(
  codecheck:::resolve_external_field("2020-099", c("paper", "openalex"), "failed", NA_character_, empty_value = NA_character_)
))
expect_equal(
  codecheck:::resolve_external_field("2020-099", c("paper", "openalex"), "found", new_id, empty_value = NA_character_),
  new_id
)

## resolve_external_field() - abstract (list-shaped field) ------------------

empty_abstract <- list(source = NULL, text = NULL)
write_previous_json("2020-021", list(abstract = list(text = "Previously known abstract.", source = "CrossRef")))

kept <- codecheck:::resolve_external_field(
  "2020-021", c("paper", "abstract"), "failed", empty_abstract, empty_value = empty_abstract
)
expect_equal(kept$text, "Previously known abstract.")
expect_equal(kept$source, "CrossRef")

pruned <- codecheck:::resolve_external_field(
  "2020-021", c("paper", "abstract"), "absent", empty_abstract, empty_value = empty_abstract, prune_unavailable = TRUE
)
expect_true(is.null(pruned$text))

## cleanup --------------------------------------------------------------

CONFIG$CERTS_DIR[["cert"]] <- old_certs_dir
