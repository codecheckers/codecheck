# Tests for OpenAlex records merged from several copies of a work
# (codecheckers/register#247). Certificate 2025-019 references an arXiv
# preprint, whose record W4415061882 OpenAlex merged into W4411175514, the
# record of its SSRN copy: that record's DOI and primary location are SSRN's,
# and the arXiv copy is one of its locations. The record is a trimmed copy in
# fixtures/openalex/; no test here reaches the network.

library(codecheck)
source("mocks.R")

record_json <- paste(readLines(file.path("fixtures", "openalex", "W4411175514.json"),
                               warn = FALSE), collapse = "\n")
record <- jsonlite::fromJSON(record_json, simplifyVector = FALSE)
arxiv <- "https://doi.org/10.48550/arXiv.2503.21065"
ssrn <- "https://doi.org/10.2139/ssrn.5287999"

openalex_response <- function(url, ...) mock_json_response(url, record_json)

# --- reading the record --------------------------------------------------------

with_mocked_codecheck(list(codecheck_GET_openalex = openalex_response), {
  fields <- codecheck:::get_openalex_work_fields_result("https://openalex.org/W4415061882")$value
})
# The primary location is the SSRN copy's, as OpenAlex has it.
expect_equal(fields$issn, "1556-5068")
expect_equal(fields$venue, "SSRN Electronic Journal")
expect_equal(fields$doi, ssrn)
# The record's own ID, not the one asked for.
expect_equal(fields$id, "https://openalex.org/W4411175514")
# Locations without a DOI (the OAI-PMH harvest of arXiv) are left out.
expect_equal(vapply(fields$locations, function(l) l$doi, character(1)),
             c(ssrn, "https://doi.org/10.48550/arxiv.2503.21065"))
expect_equal(fields$locations[[2]]$issn, "2331-8422")

# --- the publication of the referenced copy -------------------------------------

cached <- function(openalex_id) list(status = "found", value = fields)
with_mocked_codecheck(list(get_openalex_work_fields_cached_result = cached), {
  of_arxiv <- codecheck:::get_openalex_work_fields_for("W4411175514", arxiv)$value
  of_ssrn <- codecheck:::get_openalex_work_fields_for("W4411175514", ssrn)$value
  of_other <- codecheck:::get_openalex_work_fields_for("W4411175514", "https://doi.org/10.1234/other")$value
})
# The arXiv preprint keeps its own server, found by its DOI in any case.
expect_equal(of_arxiv$issn, "2331-8422")
expect_equal(of_arxiv$venue, "arXiv (Cornell University)")
# but not the SSRN copy's date, which the callers look up elsewhere
expect_true(is.na(of_arxiv$publication_date))
# The SSRN copy is the record's own work.
expect_equal(of_ssrn$issn, "1556-5068")
expect_equal(of_ssrn$publication_date, "2025-01-01")
# A work the record lists no copy of gets nothing, as before (2023-011).
expect_true(all(is.na(unlist(of_other[c("issn", "venue", "publication_date")]))))

expect_equal(codecheck:::openalex_location_fields(fields, "https://arxiv.org/abs/2503.21065"),
             list(issn = NA_character_, venue = NA_character_))

# --- reporting the merge --------------------------------------------------------

with_mocked_codecheck(list(get_openalex_work_fields_cached_result = cached), {
  expect_message(
    merged <- codecheck:::report_openalex_merge("2025-019", "https://openalex.org/W4415061882",
                                                "https://openalex.org/W4411175514"),
    "W4415061882 was merged into W4411175514 (primary DOI 10.2139/ssrn.5287999)", fixed = TRUE)
  expect_equal(merged, "merged")
  # an ID that changed without a redirect is reported as a change
  expect_message(
    changed <- codecheck:::report_openalex_merge("2025-019", "https://openalex.org/W1",
                                                 "https://openalex.org/W2"),
    "changed from W1 to W2", fixed = TRUE)
  expect_equal(changed, "changed")
  # nothing to report without a previous ID, or when it is the same
  expect_silent(codecheck:::report_openalex_merge("2025-019", NULL, "https://openalex.org/W4411175514"))
  expect_true(is.na(codecheck:::report_openalex_merge("2025-019", "https://openalex.org/W4411175514",
                                                      "https://openalex.org/W4411175514")))
})

# --- suggesting reference-other entries ------------------------------------------

dois <- codecheck:::openalex_record_dois(fields)
expect_equal(dois, c(ssrn, "https://doi.org/10.48550/arxiv.2503.21065"))
expect_equal(codecheck:::missing_reference_other_dois(dois, arxiv), "https://doi.org/10.2139/ssrn.5287999")
# named already, in any spelling of the DOI
expect_equal(codecheck:::missing_reference_other_dois(dois, arxiv, "https://doi.org/10.2139/SSRN.5287999"),
             character(0))
expect_equal(codecheck:::missing_reference_other_dois(dois, ssrn, "doi:10.48550/arxiv.2503.21065"),
             character(0))
# a trailing version is the same copy
expect_equal(codecheck:::missing_reference_other_dois("https://doi.org/10.1234/x.v2", "https://doi.org/10.1234/x"),
             character(0))
expect_equal(codecheck:::missing_reference_other_dois(character(0), arxiv), character(0))
# and the suggestion is the DOI as OpenAlex has it, version and all (2023-012:
# the Research Square preprint of a Scientific Reports article)
expect_equal(codecheck:::missing_reference_other_dois(
  c("https://doi.org/10.1038/s41598-023-48241-y", "https://doi.org/10.21203/rs.3.rs-2587424/v1"),
  "https://doi.org/10.1038/s41598-023-48241-y"),
  "https://doi.org/10.21203/rs.3.rs-2587424/v1")

expect_message(codecheck:::suggest_reference_other("2025-019", dois, arxiv),
               "reference-other: [https://doi.org/10.2139/ssrn.5287999]", fixed = TRUE)
expect_silent(codecheck:::suggest_reference_other("2025-019", dois, arxiv, ssrn))
expect_silent(codecheck:::suggest_reference_other("2025-019", dois, NA_character_))

# --- rule CC-MET-010 --------------------------------------------------------------

paper_lookup <- function(reference) {
  list(status = "ok", doi = "10.5555/ro-reference",
       record = codecheck:::openalex_paper_record(modifyList(record, list(
         locations = c(record$locations,
                       list(list(doi = "https://doi.org/10.5555/ro-reference")))))))
}
met010 <- function(case, lookup = paper_lookup) {
  with_mocked_codecheck(list(lookup_openalex_paper = lookup), {
    validate_codecheck_yml_rules(file.path("yaml", "reference-other", case, "codecheck.yml"),
                                 rules = "CC-MET-010", stop_on_error = FALSE, quiet = TRUE)
  })
}
absent <- met010("absent")
expect_equal(absent$outcome, "info")
expect_true(grepl("https://doi.org/10.2139/ssrn.5287999", absent$detail, fixed = TRUE))
expect_true(grepl("https://doi.org/10.48550/arxiv.2503.21065", absent$detail, fixed = TRUE))
# a reference-other that is not a sequence is CC-CFG-029's to report
expect_equal(met010("scalar")$outcome, "skipped")
# without an OpenAlex record there is nothing to compare
expect_equal(met010("absent", function(reference) list(status = "unindexed", doi = "10.5555/ro-reference",
                                                      detail = "not in OpenAlex"))$outcome,
             "skipped")
# a record that lists only the reference passes
only_reference <- function(reference) {
  list(status = "ok", doi = "10.5555/ro-reference",
       record = list(title = "x", author = list(), dois = "https://doi.org/10.5555/ro-reference"))
}
expect_equal(met010("absent", only_reference)$outcome, "ok")

# The rule is a 2.0 rule only, like the field.
expect_false("CC-MET-010" %in% codecheck_rules("1.0")$id)
expect_equal(codecheck_rules("2.0")$severity[codecheck_rules("2.0")$id == "CC-MET-010"], "info")
