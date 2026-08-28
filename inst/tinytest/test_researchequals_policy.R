# Tests for the CODECHECK curation policy checks of certificates published on
# ResearchEquals: researchequals_policy_check() and
# check_register_researchequals_policy(). All tests run offline against
# fixtures and mocks.

library(tinytest)
source("mocks.R")

fixture <- function(name) {
  path <- system.file("tinytest", "fixtures", name, package = "codecheck")
  if (path == "") path <- file.path("fixtures", name)
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

version <- fixture("researchequals_version_2020-007.json")
blocknote_version <- fixture("researchequals_version_2026-014.json")
codecheck_collection <- fixture("researchequals_collection.json")
agile_collection <- fixture("researchequals_collection_agile.json")

fixture_path <- function(name) {
  path <- system.file("tinytest", "fixtures", name, package = "codecheck")
  if (path == "") path <- file.path("fixtures", name)
  path
}

# an httr response carrying a fixture as its body, enough for httr::content()
json_response <- function(url, name, status = 200L) {
  body <- paste(readLines(fixture_path(name), warn = FALSE), collapse = "\n")
  structure(list(url = url,
                 status_code = as.integer(status),
                 headers = list(`content-type` = "application/json"),
                 all_headers = list(),
                 content = charToRaw(body)),
            class = "response")
}

# the collections a certificate must be part of, as get_researchequals_collections()
# returns them
collections <- list("CODECHECK" = codecheck_collection,
                    "Reproducible AGILE" = agile_collection)

# The real record of 2020-007 lists no references - ResearchEquals keeps related
# work in a flat list without relation types, and the link to the checked paper
# lives in the certificate PDF only - and it is in the CODECHECK collection but
# not in the Reproducible AGILE one. The fixture is used as it is for those
# findings, and amended wherever a fully compliant module is needed.
compliant <- version
compliant$refs <- list("https://doi.org/10.5281/zenodo.3818838")

in_both <- collections
in_both[["Reproducible AGILE"]]$submissions <- c(
  agile_collection$submissions,
  list(list(id = "test", status = "accepted",
            link_url = "https://doi.org/10.53962/nsys-9a40",
            link_title = "CODECHECK Certificate 2020-007")))

# the venue the Reproducible AGILE collection is mandatory for
agile_venue <- "AGILEGIS"

status_of <- function(result, check) result$status[result$check == check]
detail_of <- function(result, check) result$detail[result$check == check]

# ------------------------------------------------- report reference detection

expect_true(codecheck:::is_researchequals_report("https://doi.org/10.53962/nsys-9a40"))
expect_true(codecheck:::is_researchequals_report("10.53962/nsys-9a40"))
expect_true(codecheck:::is_researchequals_report(
  "https://researchequals.com/en-US/versions/8d0a10a6-c84b-4505-903a-f55224441a40"))
expect_false(codecheck:::is_researchequals_report("https://doi.org/10.5281/zenodo.3865641"))
expect_false(codecheck:::is_researchequals_report(NA))
expect_false(codecheck:::is_researchequals_report(""))

expect_equal(codecheck:::normalize_doi("doi:10.53962/NSYS-9a40"), "10.53962/nsys-9a40")
expect_equal(codecheck:::normalize_doi("https://doi.org/10.53962/nsys-9a40"), "10.53962/nsys-9a40")
expect_equal(codecheck:::normalize_doi("10.53962/nsys-9a40"), "10.53962/nsys-9a40")

# the required collections are recognised by their issue ID, an unknown one is
# named after the part of its title before the en dash
expect_equal(codecheck:::collection_name(codecheck_collection), "CODECHECK")
expect_equal(codecheck:::collection_name(agile_collection), "Reproducible AGILE")
expect_equal(codecheck:::collection_name(list(id = "other", title = "Some – Collection")),
             "Some")

# ------------------------------------------------------- venue applicability

# the CODECHECK collection is mandatory for every certificate, whatever the venue
expect_true(codecheck:::collection_applies(codecheck_collection, NULL))
expect_true(codecheck:::collection_applies(codecheck_collection, "GigaScience"))

# the Reproducible AGILE collection only for the papers of the AGILE conference
expect_true(codecheck:::collection_applies(agile_collection, agile_venue))
expect_true(codecheck:::collection_applies(agile_collection, "agilegis"))
expect_false(codecheck:::collection_applies(agile_collection, "GigaScience"))
# an unknown venue cannot be judged, so the venue-specific collection is skipped
expect_false(codecheck:::collection_applies(agile_collection, NULL))
expect_false(codecheck:::collection_applies(agile_collection, NA))
expect_false(codecheck:::collection_applies(agile_collection, ""))

# a collection the policy does not know applies to every certificate
expect_true(codecheck:::collection_applies(list(id = "other", title = "Some – Collection"), NULL))

# ------------------------------------------------------ policy check: compliant

result <- researchequals_policy_check(compliant, collections = in_both,
                                     venue = agile_venue)

expect_true(is.data.frame(result))
expect_equal(sum(result$status == "fail"), 0)
expect_equal(status_of(result, "title"), "pass")
expect_equal(status_of(result, "license"), "pass")
expect_equal(status_of(result, "module type"), "pass")
expect_equal(status_of(result, "published"), "pass")
expect_equal(status_of(result, "certificate PDF"), "pass")
expect_equal(status_of(result, "latest version"), "pass")

# membership is checked per collection, the counterpart of the Zenodo community
expect_equal(status_of(result, "collection: CODECHECK"), "pass")
expect_equal(status_of(result, "collection: Reproducible AGILE"), "pass")

# without the collections the membership cannot be judged, so it is not reported
expect_false(any(grepl("^collection", researchequals_policy_check(compliant)$check)))

# a single collection issue is accepted in place of the list of them
single <- researchequals_policy_check(compliant, collections = codecheck_collection)
expect_equal(single$check[grepl("^collection", single$check)], "collection: CODECHECK")

# ---------------------------------------- collection membership: venue-specific

# for a certificate of another venue only the CODECHECK collection is required,
# so 2020-007 missing from Reproducible AGILE is not held against it
other_venue <- researchequals_policy_check(compliant, collections = collections,
                                           venue = "GigaScience")
expect_equal(other_venue$check[grepl("^collection", other_venue$check)],
             "collection: CODECHECK")
expect_equal(sum(other_venue$status == "fail"), 0)

# without a venue the AGILE collection cannot be judged either
expect_equal(
  researchequals_policy_check(compliant, collections = collections)$check[
    grepl("^collection", researchequals_policy_check(compliant, collections = collections)$check)],
  "collection: CODECHECK")

# an AGILEGIS certificate must be in both, and 2020-007 is not in the AGILE one
agile_entry <- researchequals_policy_check(compliant, collections = collections,
                                           venue = agile_venue)
expect_equal(agile_entry$check[agile_entry$status == "fail"],
             "collection: Reproducible AGILE")

# the record as it stands on ResearchEquals, checked as an AGILEGIS entry: it is
# in the CODECHECK collection but not in the Reproducible AGILE one, and lists
# no reference to the paper
as_published <- researchequals_policy_check(version, collections = collections,
                                            venue = agile_venue)
expect_equal(sort(as_published$check[as_published$status == "fail"]),
             sort(c("related work: paper", "collection: Reproducible AGILE")))
expect_equal(status_of(as_published, "collection: CODECHECK"), "pass")

# ------------------------------------------- collection membership: not a member

not_a_member <- compliant
not_a_member$pids <- list("doi:10.53962/some-other")
result_out <- researchequals_policy_check(not_a_member, collections = collections,
                                         venue = agile_venue)
expect_equal(status_of(result_out, "collection: CODECHECK"), "fail")
expect_true(grepl("researchequals.com/collections/720ac28c-07a1-40c3-a098-c77443e5de96",
                  detail_of(result_out, "collection: CODECHECK"), fixed = TRUE))
expect_true(grepl("researchequals.com/collections/aad8e6af-bd94-47f3-b215-c68d31687c74",
                  detail_of(result_out, "collection: Reproducible AGILE"), fixed = TRUE))

# a submission that has not been accepted yet is a warning, not a failure
pending <- collections
pending[["CODECHECK"]]$submissions[[2]]$status <- "pending"
expect_equal(
  status_of(researchequals_policy_check(version, collections = pending),
            "collection: CODECHECK"),
  "warn")

rejected <- collections
rejected[["CODECHECK"]]$submissions[[2]]$status <- "rejected"
result_rej <- researchequals_policy_check(version, collections = rejected)
expect_equal(status_of(result_rej, "collection: CODECHECK"), "fail")
expect_true(grepl("rejected", detail_of(result_rej, "collection: CODECHECK")))

# an empty collection is not a member either
empty_collection <- collections
empty_collection[["CODECHECK"]]$submissions <- list()
expect_equal(
  status_of(researchequals_policy_check(version, collections = empty_collection),
            "collection: CODECHECK"),
  "fail")

# -------------------------------------------------- policy check: non-compliant

broken <- version
broken$title <- "Some report"
broken$description <- ""
broken$license_id <- "Q334661"           # MIT
broken$type_id <- "Q55107540"            # other
broken$language <- ""
broken$published <- FALSE
broken$refs <- list()
broken$contributors[[1]]$orcid <- ""
broken$content_mediatype <- "application/x-blocknote"

result <- researchequals_policy_check(broken, collections = in_both,
                                     venue = agile_venue)
expect_equal(sort(result$check[result$status == "fail"]),
             sort(c("title", "description", "license", "module type", "language",
                    "published", "related work: paper")))
expect_equal(status_of(result, "contributors"), "warn")
expect_equal(status_of(result, "certificate PDF"), "warn")

# the older title convention is a warning, not a failure
older_title <- version
older_title$title <- "Reproducibility review of: A Paper Title"
expect_equal(status_of(researchequals_policy_check(older_title), "title"), "warn")

# a superseded version fails: the report DOI should point at the current one
superseded <- version
superseded$version_history <- list(list(version = 1), list(version = 2))
expect_equal(status_of(researchequals_policy_check(superseded), "latest version"), "fail")

# ------------------------------------------------------------ main file resolution

# a plainly deposited PDF is used as it is, without any further request
plain <- codecheck:::researchequals_main_file(version)
expect_equal(plain$mediatype, "application/pdf")
expect_equal(plain$url,
             "https://researchequals.com/api/files/fbdeef1a-eec8-46bb-9131-939a5e8d4f52")
expect_null(plain$name)

# a version without a deposited file has no main file at all
expect_null(codecheck:::researchequals_main_file(list(content_s3 = NULL)))

# a document written in the ResearchEquals editor may embed the certificate PDF,
# which is what must be downloaded - not the document holding it
with_mocked_codecheck(
  list(codecheck_GET_retry = function(url, ...)
    json_response(url, "researchequals_blocknote_2026-014.json")),
  {
    embedded <- codecheck:::researchequals_main_file(blocknote_version, "2026-014")
  })
expect_equal(embedded$mediatype, "application/pdf")
expect_equal(embedded$url,
             "https://researchequals.com/api/files/a2e7a5bb-64bc-4930-bf2c-562d66f90074")
expect_equal(embedded$name, "agile-2026_reproducibility-review_026.pdf")

# blocks nest, and a certificate named after the policy wins over another PDF
nested <- list(
  list(type = "paragraph", props = list(), children = list(
    list(type = "file", props = list(url = "https://example.com/figure.pdf",
                                     name = "figure.pdf"), children = list()),
    list(type = "pdf", props = list(url = "https://example.com/codecheck.pdf",
                                    name = "codecheck.pdf"), children = list()))))
expect_equal(length(codecheck:::blocknote_pdf_blocks(nested)), 2L)
with_mocked_codecheck(
  list(codecheck_GET_retry = function(url, ...) {
    structure(list(url = url, status_code = 200L,
                   headers = list(`content-type` = "application/json"),
                   all_headers = list(),
                   content = charToRaw(jsonlite::toJSON(nested, auto_unbox = TRUE))),
              class = "response")
  }),
  {
    preferred <- codecheck:::researchequals_main_file(blocknote_version)
  })
expect_equal(preferred$name, "codecheck.pdf")

# a text document without any PDF stays what it is, and so does one that cannot
# be fetched: the caller then sees the unresolved main file, as before
with_mocked_codecheck(
  list(codecheck_GET_retry = function(url, ...) {
    structure(list(url = url, status_code = 200L,
                   headers = list(`content-type` = "application/json"),
                   all_headers = list(), content = charToRaw("[]")),
              class = "response")
  }),
  {
    text_only <- codecheck:::researchequals_main_file(blocknote_version)
  })
expect_equal(text_only$mediatype, "application/x-blocknote")
expect_equal(text_only$url,
             "https://researchequals.com/api/files/949c04ca-90f4-499e-882f-dc17ca9c19d2")

with_mocked_codecheck(
  list(codecheck_GET_retry = function(url, ...) NULL),
  {
    expect_warning(unreachable <- codecheck:::researchequals_main_file(blocknote_version))
  })
expect_equal(unreachable$mediatype, "application/x-blocknote")

# ------------------------------------------- certificate PDF: resolved main file

# with the resolved main file the embedded PDF is what the policy judges
resolved <- blocknote_version
resolved$main_file <- list(url = "https://researchequals.com/api/files/a2e7a5bb",
                           mediatype = "application/pdf",
                           name = "agile-2026_reproducibility-review_026.pdf")
result_pdf <- researchequals_policy_check(resolved)
expect_equal(status_of(result_pdf, "certificate PDF"), "pass")
expect_true(grepl("agile-2026_reproducibility-review_026.pdf",
                  detail_of(result_pdf, "certificate PDF"), fixed = TRUE))

# a text-only certificate is still only a warning
text_certificate <- blocknote_version
text_certificate$main_file <- list(url = "https://researchequals.com/api/files/949c04ca",
                                   mediatype = "application/x-blocknote", name = NULL)
expect_equal(status_of(researchequals_policy_check(text_certificate), "certificate PDF"),
             "warn")

# without a resolved main file the deposited media type is used, as before
expect_equal(status_of(researchequals_policy_check(blocknote_version), "certificate PDF"),
             "warn")
expect_equal(status_of(researchequals_policy_check(version), "certificate PDF"), "pass")

# --------------------------------------------------------- register-wide check

# check_register_researchequals_policy() caches version metadata, so keep this
# test's cache out of the user's real one (restored at the end of the file;
# on.exit() would run immediately, it is not inside a function)
policy_cache_root <- file.path(tempfile("codecheck_re_policy_cache"))
dir.create(policy_cache_root, recursive = TRUE)
policy_old_root <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(policy_cache_root)

register_table <- data.frame(
  Certificate = c("[2020-007](https://codecheck.org.uk/register/certs/2020-007/)", "2026-001"),
  Report = c("https://doi.org/10.53962/nsys-9a40", "https://doi.org/10.5281/zenodo.3865641"),
  Venue = c("AGILEGIS", "GigaScience"),
  stringsAsFactors = FALSE)

# the DOI is resolved to a version ID over the network, so mock that away
with_mocked_codecheck(
  list(get_researchequals_version_id = function(report_link)
    "8d0a10a6-c84b-4505-903a-f55224441a40"),
  {
    result <- check_register_researchequals_policy(
      register_table,
      get_metadata = function(version_id) compliant,
      get_collections = function() in_both)
  })

# the Zenodo-hosted entry is out of scope here
expect_equal(nrow(result), 1L)
expect_equal(result$certificate, "2020-007")
expect_equal(result$status, "compliant")
expect_equal(result$n_fail, 0L)

# the venue comes from the register table: as an AGILEGIS entry the certificate
# must be in the Reproducible AGILE collection, and this one is not
with_mocked_codecheck(
  list(get_researchequals_version_id = function(report_link)
    "8d0a10a6-c84b-4505-903a-f55224441a40"),
  {
    agile_missing <- check_register_researchequals_policy(
      register_table,
      get_metadata = function(version_id) compliant,
      get_collections = function() collections)
  })
expect_equal(agile_missing$status, "non-compliant")
expect_true(grepl("Reproducible AGILE", agile_missing$findings))

# the same certificate at another venue only needs the CODECHECK collection
other_venue_table <- register_table
other_venue_table$Venue <- c("GigaScience", "GigaScience")
with_mocked_codecheck(
  list(get_researchequals_version_id = function(report_link)
    "8d0a10a6-c84b-4505-903a-f55224441a40"),
  {
    other <- check_register_researchequals_policy(
      other_venue_table,
      get_metadata = function(version_id) compliant,
      get_collections = function() collections)
  })
expect_equal(other$status, "compliant")

# a register table without a Venue column is handled: only the collections that
# apply to every certificate are checked
no_venue_table <- register_table[, c("Certificate", "Report")]
with_mocked_codecheck(
  list(get_researchequals_version_id = function(report_link)
    "8d0a10a6-c84b-4505-903a-f55224441a40"),
  {
    no_venue <- check_register_researchequals_policy(
      no_venue_table,
      get_metadata = function(version_id) compliant,
      get_collections = function() collections)
  })
expect_equal(no_venue$status, "compliant")

# an unresolvable report is reported as "unknown", never as an error
with_mocked_codecheck(
  list(get_researchequals_version_id = function(report_link) NULL),
  {
    unknown <- check_register_researchequals_policy(
      register_table,
      get_metadata = function(version_id) stop("must not be called"),
      get_collections = function() in_both)
  })
expect_equal(unknown$status, "unknown")
expect_true(is.na(unknown$version_id))

# a getter that throws must yield "unknown", too. Uses a version id of its own:
# a failed lookup is deliberately not cached, but a successful one from an
# earlier assertion would be served from the cache instead of the getter
with_mocked_codecheck(
  list(get_researchequals_version_id = function(report_link)
    "00000000-0000-0000-0000-000000000000"),
  {
    down <- check_register_researchequals_policy(
      register_table[1, ],
      get_metadata = function(version_id) stop("ResearchEquals is down"),
      get_collections = function() in_both)
  })
expect_equal(down$status, "unknown")
expect_true(is.na(down$n_fail))

# unreachable collections skip the membership checks instead of failing every
# certificate because of them
with_mocked_codecheck(
  list(get_researchequals_version_id = function(report_link)
    "8d0a10a6-c84b-4505-903a-f55224441a40"),
  {
    no_collections <- check_register_researchequals_policy(
      register_table[1, ],
      get_metadata = function(version_id) compliant,
      get_collections = function() stop("ResearchEquals is down"))
  })
expect_equal(no_collections$status, "compliant")
expect_false(grepl("collection", no_collections$findings))

# a register without any ResearchEquals report is not checked at all
expect_equal(nrow(check_register_researchequals_policy(
  register_table[2, ],
  get_metadata = function(version_id) stop("must not be called"),
  get_collections = function() stop("must not be called"))), 0L)

# a table without the expected columns is handled, not an error
expect_equal(nrow(check_register_researchequals_policy(data.frame(a = 1))), 0L)
expect_equal(nrow(check_register_researchequals_policy(NULL)), 0L)

# repeated checks are served from the cache rather than re-fetching
fetches <- 0
counting_getter <- function(version_id) {
  fetches <<- fetches + 1
  compliant
}
with_mocked_codecheck(
  list(get_researchequals_version_id = function(report_link)
    "8d0a10a6-c84b-4505-903a-f55224441a40"),
  {
    invisible(check_register_researchequals_policy(
      register_table, get_metadata = counting_getter,
      get_collections = function() in_both))
    before <- fetches
    invisible(check_register_researchequals_policy(
      register_table, get_metadata = counting_getter,
      get_collections = function() in_both))
  })
expect_equal(fetches, before)

# a corrected module must not keep being reported from the earlier cache
expect_true(clear_researchequals_policy_cache("8d0a10a6-c84b-4505-903a-f55224441a40"))

R.cache::setCacheRootPath(policy_old_root)

# the reporter tolerates an empty result and returns its input invisibly
expect_silent(report_researchequals_policy_findings(
  codecheck:::empty_researchequals_policy_result()))
expect_equal(report_researchequals_policy_findings(result), result)
