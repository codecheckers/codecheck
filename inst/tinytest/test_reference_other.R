# Tests for paper.reference-other (configuration specification 2.0): what the
# validation rules say about each form of the field, how rendering reads it,
# the type of each reference from its DOI registry record, and how the work
# pages of related DOIs are linked. The configurations are fixtures in
# yaml/reference-other/<case>/codecheck.yml, the registry responses trimmed
# copies in fixtures/registry/. No test here reaches the network.

library(codecheck)
source("mocks.R")
# creates the CONFIG environment the render functions read, as register_render() does
source(system.file("extdata", "config.R", package = "codecheck"))

fixture <- function(case) file.path("yaml", "reference-other", case, "codecheck.yml")
config <- function(case) yaml::read_yaml(fixture(case))

# --- reading the field for rendering ------------------------------------------

get_other <- codecheck:::get_reference_other

expect_equal(nrow(get_other(config("absent"))), 0)
expect_equal(nrow(get_other(config("empty"))), 0)

one <- get_other(config("one-doi"))
expect_equal(one$url, "https://doi.org/10.5555/ro-preprint")
expect_equal(one$doi, "10.5555/ro-preprint")

# spellings normalized, the upper-case repeat dropped, the web address kept
mixed <- get_other(config("mixed"))
expect_equal(mixed$doi, c("10.5555/ro-preprint", NA, "10.5555/ro-dataset"))
expect_equal(mixed$url, c("https://doi.org/10.5555/ro-preprint",
                          "https://example.org/preprints/ro",
                          "https://doi.org/10.5555/ro-dataset"))

# the entry that repeats the reference is dropped
expect_equal(get_other(config("repeats-reference"))$doi, "10.5555/ro-preprint")

# a bare URL is used as a one-item list
expect_equal(get_other(config("scalar"))$doi, "10.5555/ro-preprint")

# a map item and free text are left out, with a warning naming the certificate
map_messages <- capture.output(map_other <- get_other(config("map-item"), "2026-901"), type = "message")
expect_equal(map_other$doi, "10.5555/ro-dataset")
expect_true(any(grepl("2026-901", map_messages)))
text_messages <- capture.output(text_other <- get_other(config("free-text"), "2026-901"), type = "message")
expect_equal(text_other$doi, "10.5555/ro-preprint")
expect_true(any(grepl("see the preprint on bioRxiv", text_messages, fixed = TRUE)))
# read again by a page renderer, without the identifier, it says nothing
expect_equal(capture.output(quiet_other <- get_other(config("free-text")), type = "message"), character(0))

# a whole map is not a list of references
map_config <- config("one-doi")
map_config$paper[["reference-other"]] <- list(preprint = "https://doi.org/10.5555/ro-preprint")
expect_equal(nrow(suppressMessages(get_other(map_config))), 0)

# --- the type of a reference, from its registry record -------------------------

registry <- function(name) jsonlite::fromJSON(file.path("fixtures", "registry", name),
                                              simplifyVector = FALSE)
expect_equal(codecheck:::crossref_reference_type(registry("crossref_biorxiv_preprint.json")$message), "Preprint")
expect_equal(codecheck:::crossref_reference_type(registry("crossref_journal_article.json")$message), "Journal article")
expect_equal(codecheck:::crossref_reference_type(list(type = "proceedings-article")), "Conference paper")
# posted content that is not a preprint, and types the register does not show
expect_true(is.na(codecheck:::crossref_reference_type(list(type = "posted-content", subtype = "other"))))
expect_true(is.na(codecheck:::crossref_reference_type(list(type = "peer-review"))))
expect_true(is.na(codecheck:::crossref_reference_type(list())))

# arXiv registers its preprints as Text/Article
expect_equal(codecheck:::datacite_reference_type(registry("datacite_arxiv.json")$data$attributes), "Preprint")
expect_equal(codecheck:::datacite_reference_type(registry("datacite_zenodo_report.json")$data$attributes), "Report")
expect_equal(codecheck:::datacite_reference_type(list(types = list(resourceTypeGeneral = "Preprint"))), "Preprint")
expect_equal(codecheck:::datacite_reference_type(list(types = list(resourceTypeGeneral = "Dataset"))), "Dataset")
# a publisher written as an object, as in newer DataCite records
expect_equal(codecheck:::datacite_reference_type(list(publisher = list(name = "arXiv"))), "Preprint")
expect_true(is.na(codecheck:::datacite_reference_type(list(types = list(resourceTypeGeneral = "Text")))))

# The registry lookup reads type and date from one response.
json_response <- function(url, file) {
  structure(list(url = url, status_code = 200L,
                 headers = list(`content-type` = "application/json"), all_headers = list(),
                 content = readBin(file.path("fixtures", "registry", file), "raw",
                                   file.info(file.path("fixtures", "registry", file))$size)),
            class = "response")
}
registry_GET <- function(url, ...) {
  if (grepl("api.crossref.org/works/10.1101", url, fixed = TRUE)) return(json_response(url, "crossref_biorxiv_preprint.json"))
  if (grepl("api.crossref.org/works/10.1371", url, fixed = TRUE)) return(json_response(url, "crossref_journal_article.json"))
  if (grepl("api.datacite.org/dois/10.48550", url, fixed = TRUE)) return(json_response(url, "datacite_arxiv.json"))
  mock_response(url, 404L)
}
registry_agency <- function(doi) if (startsWith(doi, "10.48550/")) "DataCite" else "Crossref"

with_mocked_codecheck(list(codecheck_GET = registry_GET, lookup_registration_agency = registry_agency), {
  preprint <- codecheck:::get_registry_record_result("https://doi.org/10.1101/2023.07.11.548542")
  expect_equal(preprint$status, "found")
  expect_equal(preprint$value$type, "Preprint")
  expect_equal(preprint$value$agency, "Crossref")
  # the posted date of the preprint, as before the record was shared
  expect_equal(codecheck:::get_registry_publication_date_result("https://doi.org/10.1101/2023.07.11.548542"),
               list(status = "found", value = "2023-07-12"))

  arxiv <- codecheck:::get_registry_record_result("https://doi.org/10.48550/arXiv.2104.00718")
  expect_equal(arxiv$value$type, "Preprint")
  expect_equal(arxiv$value$agency, "DataCite")

  expect_equal(codecheck:::get_registry_record_result("https://doi.org/10.1234/unknown")$status, "absent")
  expect_equal(codecheck:::get_registry_record_result("https://example.org/paper")$status, "absent")
})

# A web address has no type, and a failed lookup none either.
expect_equal(codecheck:::get_reference_type("https://example.org/paper"),
             list(type = NA_character_, agency = NA_character_))
expect_equal(codecheck:::reference_type_html(list(type = NA_character_, agency = NA_character_)), "")
label <- codecheck:::reference_type_html(list(type = "Preprint", agency = "Crossref"))
expect_true(grepl('class="reference-kind"', label, fixed = TRUE))
expect_true(grepl(">Preprint<", label, fixed = TRUE))
expect_true(grepl("Crossref record", label, fixed = TRUE))

# --- the certificate page --------------------------------------------------------

# Types without the registry: a fixed answer per DOI.
fake_type <- function(reference) {
  doi <- codecheck:::normalize_work_key(reference)
  if (is.na(doi)) return(list(type = NA_character_, agency = NA_character_))
  if (grepl("preprint", doi)) list(type = "Preprint", agency = "Crossref")
  else list(type = "Journal article", agency = "Crossref")
}

with_mocked_codecheck(list(get_reference_type = fake_type), {
  html <- codecheck:::paper_reference_other_html(config("mixed"))
  # one paragraph in the style of the authors line, no word on where it came from
  expect_true(grepl("^<p>\n<strong>Other references</strong>:", html))
  expect_false(grepl("reference-other", html, fixed = TRUE))
  # a DOI links to its own work page, its icon to doi.org, with its type
  expect_true(grepl('href="../../works/10.5555/ro-preprint/"', html, fixed = TRUE))
  expect_true(grepl('href="https://doi.org/10.5555/ro-preprint" title="Resolve DOI at doi.org"', html, fixed = TRUE))
  expect_true(grepl(">Preprint</span>", html, fixed = TRUE))
  # a web address links out, its explanation only in the hover text
  expect_true(grepl('<a href="https://example.org/preprints/ro" title="External page, not a DOI: no CODECHECK work page">example.org/preprints/ro</a>',
                    html, fixed = TRUE))
  expect_false(grepl('works/example.org', html, fixed = TRUE))
  # entries separated by commas right after each entry, the last without
  expect_equal(lengths(regmatches(html, gregexpr("(</a>|</span>), <a ", html))), 2)
  expect_false(grepl(" ,", html, fixed = TRUE))
  expect_true(grepl("Journal article</span>\n</p>$", html))

  expect_equal(codecheck:::paper_reference_other_html(config("absent")), "")

  json <- codecheck:::reference_other_json(codecheck:::typed_reference_other(config("mixed")))
  expect_equal(length(json), 3)
  expect_equal(json[[1]], list(url = "https://doi.org/10.5555/ro-preprint",
                               doi = "10.5555/ro-preprint", type = "Preprint"))
  # a web address has neither DOI nor type
  expect_equal(json[[2]], list(url = "https://example.org/preprints/ro"))
  expect_equal(length(codecheck:::reference_other_json(codecheck:::typed_reference_other(config("absent")))), 0)
})

# --- which work pages are one work ----------------------------------------------

certs <- c("A", "B", "C", "D")
keys <- c("10.5555/ro-a", "10.5555/ro-x", "10.5555/ro-solo", NA)
refs <- list(
  get_other(config("chain-a")),                                       # A -> X
  get_other(config("chain-b")),                                       # X -> Y
  data.frame(url = "https://example.org/solo", doi = NA_character_,   # web only
             stringsAsFactors = FALSE),
  get_other(config("reference-not-doi"))                              # no DOI -> preprint
)
relations <- codecheck:::build_work_relations(certs, keys, refs)

# A, X and Y are one work, across the two certificates
expect_equal(sort(relations[["10.5555/ro-a"]]$doi), c("10.5555/ro-x", "10.5555/ro-y"))
expect_equal(sort(relations[["10.5555/ro-y"]]$doi), c("10.5555/ro-a", "10.5555/ro-x"))
# whether each related DOI is some certificate's reference
x_rel <- relations[["10.5555/ro-y"]]
expect_equal(x_rel$is_reference[x_rel$doi == "10.5555/ro-x"], TRUE)
expect_equal(relations[["10.5555/ro-a"]]$is_reference[relations[["10.5555/ro-a"]]$doi == "10.5555/ro-y"], FALSE)
# a web address is shown on the work page of its certificate's DOI
expect_equal(relations[["10.5555/ro-solo"]]$url, "https://example.org/solo")
expect_true(is.na(relations[["10.5555/ro-solo"]]$doi))
# a single DOI without a reference that is a DOI has nothing to link to
expect_null(relations[["10.5555/ro-preprint"]])
expect_equal(length(codecheck:::build_work_relations("A", "10.5555/ro-a", list(get_other(config("absent"))))), 0)

# --- add_work_key() over a register --------------------------------------------------

# Certificates with and without further references, the way the register has
# them: most have none, which must not break the lookup (a zero-row table).
work_register <- data.frame(Certificate = c("A", "B", "N", "W"),
                            Repository = c("a", "b", "n", "w"), stringsAsFactors = FALSE)
work_configs <- list(a = config("chain-a"), b = config("chain-b"), n = config("absent"),
                     w = config("reference-not-doi"))
with_mocked_codecheck(list(
  get_codecheck_yml_or_null = function(repository, ...) work_configs[[repository]],
  get_other_reference_fields = function(url) list(openalex = NA_character_, publication_date = "2025-01-01"),
  get_reference_type = fake_type), {
  work_table <- suppressMessages(codecheck:::add_work_key(work_register[, "Certificate", drop = FALSE],
                                                          work_register))
})
expect_equal(work_table$Work, c("10.5555/ro-a", "10.5555/ro-x", "10.5555/ro-reference", NA))
expect_equal(nrow(work_table$`Work other`[[3]]), 0)
expect_equal(work_table$`Work other`[[1]]$doi, "10.5555/ro-x")
expect_equal(work_table$`Work other`[[1]]$publication_date, "2025-01-01")
# the relations carry each related DOI's type
expect_equal(sort(names(CONFIG$WORK_RELATIONS)), c("10.5555/ro-a", "10.5555/ro-x", "10.5555/ro-y"))
expect_equal(unique(CONFIG$WORK_RELATIONS[["10.5555/ro-y"]]$type), "Journal article")
CONFIG$WORK_RELATIONS <- list()

# A reference-other entry with braces is reported as text, never evaluated
# (cli would read "{...}" in a message template as R code).
braces <- config("one-doi")
braces$paper[["reference-other"]] <- list("see {stop('evaluated')} on bioRxiv")
brace_messages <- capture.output(brace_other <- get_other(braces, "2026-901"), type = "message")
expect_equal(nrow(brace_other), 0)
expect_true(any(grepl("{stop('evaluated')}", brace_messages, fixed = TRUE)))

# --- the works grouping ------------------------------------------------------------

table <- data.frame(Certificate = c("A", "B", "D"), Work = c("10.5555/ro-a", "10.5555/ro-x", NA),
                    OpenAlex = c("https://openalex.org/WA", "https://openalex.org/WX", NA),
                    stringsAsFactors = FALSE)
table$`Work publication date` <- c("2026-01-01", "2026-02-01", NA)
with_ids <- function(r) { r$openalex <- NA_character_; r$publication_date <- NA_character_; r }
others <- lapply(list(refs[[1]], refs[[2]], refs[[4]]), with_ids)
others[[1]]$publication_date <- "2025-12-01"
table$`Work other` <- others

rows <- codecheck:::explode_work_records(table)
expect_equal(paste(rows$Certificate, rows$Work, rows$`Referenced as`),
             c("A 10.5555/ro-a Reference", "A 10.5555/ro-x Other reference",
               "B 10.5555/ro-x Reference", "B 10.5555/ro-y Other reference",
               "D 10.5555/ro-preprint Other reference"))
# a row for a further reference carries that DOI's own identifiers, not the
# certificate's reference's
expect_true(is.na(rows$OpenAlex[2]))
expect_equal(rows$`Work publication date`[2], "2025-12-01")
expect_equal(rows$OpenAlex[1], "https://openalex.org/WA")

# every DOI has a page, also those only named as a further reference
expect_equal(sort(codecheck:::all_work_keys(table)),
             c("10.5555/ro-a", "10.5555/ro-preprint", "10.5555/ro-x", "10.5555/ro-y"))
# the works overview lists only the references (decision on register#150 follow-up)
expect_equal(sort(unique(table$Work[!is.na(table$Work)])), c("10.5555/ro-a", "10.5555/ro-x"))

# The works overview lists the references only, but counts every certificate
# that names the DOI, as the DOI's own page does; also one whose reference is
# no DOI.
table$`Paper Title` <- "[Linked versions](https://doi.org/x)"
overview <- codecheck:::create_all_works_table(table)$works
counts <- stats::setNames(overview[[CONFIG$NON_REG_TABLE_COL_NAMES[["works"]][["no_checks"]]]],
                          overview[[CONFIG$NON_REG_TABLE_COL_NAMES[["works"]][["Work"]]]])
expect_equal(sort(names(counts)), c("10.5555/ro-a", "10.5555/ro-x"))
expect_equal(counts[["10.5555/ro-x"]], 2L)
expect_equal(counts[["10.5555/ro-a"]], 1L)

# --- the work page's metadata panel ----------------------------------------------------

# typed once, as add_work_key() does
CONFIG$WORK_RELATIONS <- with_mocked_codecheck(list(get_reference_type = fake_type),
                                               lapply(relations, codecheck:::add_reference_types))
details_y <- list(name = "10.5555/ro-y", output_dir = "docs/works/10.5555/ro-y/", for_html_file = TRUE)
page_rows <- rows[rows$Work == "10.5555/ro-y", , drop = FALSE]
page_rows$Repository <- NA_character_
with_mocked_codecheck(list(get_reference_type = fake_type,
                           get_codecheck_yml_or_null = function(...) NULL,
                           wikidata_id_for = function(...) NULL), {
  panel <- codecheck:::generate_work_metadata_html(details_y, page_rows)
})
expect_true(grepl("Same work as:", panel, fixed = TRUE))
expect_true(grepl('href="../../../works/10.5555/ro-a/"', panel, fixed = TRUE))
expect_true(grepl('href="../../../works/10.5555/ro-x/"', panel, fixed = TRUE))
# this DOI is only ever a further reference: the note links the references
expect_true(grepl("related-work-note", panel, fixed = TRUE))
expect_true(grepl("This DOI is another reference to the same work as", panel, fixed = TRUE))
# no role badges, and the field's name nowhere on the page
expect_false(grepl("reference of", panel, fixed = TRUE))
expect_false(grepl("reference-other", panel, fixed = TRUE))

# the page of a reference has the row, but not the note
details_x <- list(name = "10.5555/ro-x", output_dir = "docs/works/10.5555/ro-x/", for_html_file = TRUE)
page_x <- rows[rows$Work == "10.5555/ro-x", , drop = FALSE]
page_x$Repository <- NA_character_
with_mocked_codecheck(list(get_reference_type = fake_type,
                           get_codecheck_yml_or_null = function(...) NULL,
                           wikidata_id_for = function(...) NULL), {
  panel_x <- codecheck:::generate_work_metadata_html(details_x, page_x)
  stats_x <- codecheck:::build_work_stats_field("10.5555/ro-x", page_x)
})
expect_true(grepl("Same work as:", panel_x, fixed = TRUE))
expect_false(grepl("related-work-note", panel_x, fixed = TRUE))
# the page's own DOI has its type label too
expect_true(grepl('10.5555/ro-x</a> <span class="reference-kind"', panel_x, fixed = TRUE))
# the related works in the page's index.json, with their types
expect_equal(sort(vapply(stats_x$related, function(r) r$doi, character(1))),
             c("10.5555/ro-a", "10.5555/ro-y"))
expect_equal(unique(vapply(stats_x$related, function(r) r$type, character(1))), "Journal article")
CONFIG$WORK_RELATIONS <- list()

# --- register_check(): linked versions are not near-duplicates -------------------------

titles <- c("Linked versions of a checked work", "Linked versions of a checked work")
# without reference-other, two DOIs with one title are reported
expect_warning(codecheck:::check_near_duplicate_works(c("A", "B"), c("10.5555/ro-a", "10.5555/ro-x"), titles),
               "share a paper title")
# with it, they are one work
expect_silent(codecheck:::check_near_duplicate_works(
  c("A", "B"), c("10.5555/ro-a", "10.5555/ro-x"), titles, list(refs[[1]], refs[[2]])))
# also when one reference is not a DOI, through its further reference
expect_silent(codecheck:::check_near_duplicate_works(
  c("A", "D"), c("10.5555/ro-preprint", NA), titles,
  list(get_other(config("absent")), refs[[4]])))
# but not when they are unrelated
expect_warning(codecheck:::check_near_duplicate_works(
  c("A", "C"), c("10.5555/ro-a", "10.5555/ro-solo"), titles, list(refs[[1]], refs[[3]])),
  "share a paper title")
