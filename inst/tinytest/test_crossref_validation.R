# Tests for validate_codecheck_yml_crossref function

library(tinytest)
source("mocks.R")

# A Crossref API and DOI handle service answering from fixtures instead of the
# network: `records` maps a DOI to its Crossref record, `handles` lists the DOIs
# registered anywhere (Crossref or DataCite).
mock_crossref_GET <- function(records = list(), handles = names(records),
                              urls = list()) {
  function(url, ...) {
    json_response <- function(body) {
      response <- mock_response(url, 200L)
      response$headers <- list(`content-type` = "application/json")
      response$content <- charToRaw(as.character(
        jsonlite::toJSON(body, auto_unbox = TRUE)))
      response
    }
    if (grepl("api.crossref.org/works/", url, fixed = TRUE)) {
      doi <- sub("^.*/works/", "", url)
      if (doi %in% names(records)) {
        return(json_response(list(message = records[[doi]])))
      }
      return(mock_response(url, 404L))
    }
    if (grepl("doi.org/api/handles/", url, fixed = TRUE)) {
      doi <- sub("^.*/handles/", "", url)
      return(mock_response(url, if (doi %in% handles) 200L else 404L))
    }
    mock_response(url, if (url %in% names(urls)) urls[[url]] else 404L)
  }
}

paper_record <- list(
  title = list("The principal components of natural images"),
  author = list(
    list(given = "Peter J. B.", family = "Hancock"),
    list(given = "Roland J.", family = "Baddeley"),
    list(given = "Leslie S.", family = "Smith",
         ORCID = "http://orcid.org/0000-0002-3716-8013")))
crossref_api <- mock_crossref_GET(list("10.1088/0954-898X_3_1_008" = paper_record))

validate_quietly <- function(...) suppressMessages(validate_codecheck_yml_crossref(...))
outcome_of <- function(result, id) result$results$outcome[result$results$id == id]

# Setup - create a temporary directory for testing
test_dir <- tempdir()
test_yml <- file.path(test_dir, "codecheck.yml")

paper_yml <- function(reference, authors = '
    - name: Peter J. B. Hancock
    - name: Roland J. Baddeley
    - name: Leslie S. Smith
      ORCID: 0000-0002-3716-8013', title = "The principal components of natural images") {
  cat("---
paper:
  title: ", title, "
  authors:", authors, "
  reference: ", reference, "
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
", file = test_yml, sep = "")
}

# Test 1: Function fails if file doesn't exist
expect_error(
  validate_codecheck_yml_crossref("nonexistent.yml"),
  pattern = "codecheck.yml file not found"
)

# Test 2: No paper metadata fails CC-CFG-016, a MUST in 2.0, so it stops
cat("---
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
", file = test_yml)

expect_error(validate_quietly(test_yml), pattern = "CC-CFG-016")
result <- validate_quietly(test_yml, stop_on_error = FALSE)
expect_false(result$valid)
expect_true(any(grepl("CC-CFG-016", result$issues)))
expect_equal(outcome_of(result, "CC-MET-004"), "skipped")

# Test 3: No paper reference fails CC-CFG-021
cat("---
paper:
  title: Test Paper
  authors:
    - name: Test Author
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
", file = test_yml)

result <- validate_quietly(test_yml, stop_on_error = FALSE)
expect_false(result$valid)
expect_true(any(grepl("CC-CFG-021", result$issues)))

# Test 4: A placeholder reference is not looked up
paper_yml("https://FIXME")
result <- with_mocked_codecheck(
  list(codecheck_GET = function(url, ...) stop("no request expected")),
  validate_quietly(test_yml))
expect_true(result$valid)
expect_equal(length(result$issues), 0)
expect_equal(outcome_of(result, "CC-MET-004"), "skipped")

# Test 5: Return value structure
expect_true(is.list(result))
expect_true(all(c("valid", "issues", "crossref_metadata", "results") %in% names(result)))
expect_true(is.logical(result$valid))
expect_true(is.character(result$issues))

# Test 6: A matching Crossref record passes every comparison
paper_yml("https://doi.org/10.1088/0954-898X_3_1_008")
result <- with_mocked_codecheck(list(codecheck_GET = crossref_api),
                                validate_quietly(test_yml))
expect_true(result$valid)
expect_equal(result$crossref_metadata$title[[1]], "The principal components of natural images")
for (id in c("CC-MET-004", "CC-MET-005", "CC-MET-006", "CC-MET-007", "CC-MET-008")) {
  expect_equal(outcome_of(result, id), "ok", info = id)
}

# Test 7: Each kind of mismatch is reported by its own rule, as a warning
paper_yml("https://doi.org/10.1088/0954-898X_3_1_008", title = "Principal components")
expect_warning(result <- with_mocked_codecheck(list(codecheck_GET = crossref_api),
                                               validate_quietly(test_yml)),
               pattern = "CC-MET-005")
expect_false(result$valid)
expect_equal(outcome_of(result, "CC-MET-005"), "warning")

paper_yml("https://doi.org/10.1088/0954-898X_3_1_008", authors = '
    - name: Peter J. B. Hancock
    - name: Jane Doe
      ORCID: 0000-0002-3716-8013')
result <- suppressWarnings(with_mocked_codecheck(list(codecheck_GET = crossref_api),
                                                 validate_quietly(test_yml)))
expect_equal(outcome_of(result, "CC-MET-006"), "warning")
expect_equal(outcome_of(result, "CC-MET-007"), "warning")
expect_true(any(grepl("author 2 'Jane Doe' is 'Roland J. Baddeley'", result$issues)))
# Author 2 has an ORCID here but none on Crossref: nothing to compare.
expect_equal(outcome_of(result, "CC-MET-008"), "skipped")

paper_yml("https://doi.org/10.1088/0954-898X_3_1_008", authors = '
    - name: Peter J. B. Hancock
    - name: Roland J. Baddeley
    - name: Leslie S. Smith
      ORCID: 0000-0001-8607-8025')
result <- suppressWarnings(with_mocked_codecheck(list(codecheck_GET = crossref_api),
                                                 validate_quietly(test_yml)))
expect_equal(outcome_of(result, "CC-MET-008"), "warning")

# check_orcids = FALSE leaves CC-MET-008 out
result <- with_mocked_codecheck(list(codecheck_GET = crossref_api),
                                validate_quietly(test_yml, check_orcids = FALSE))
expect_false("CC-MET-008" %in% result$results$id)
expect_true(result$valid)

# Test 8: strict turns a mismatch into an error
paper_yml("https://doi.org/10.1088/0954-898X_3_1_008", title = "Principal components")
expect_error(with_mocked_codecheck(list(codecheck_GET = crossref_api),
                                   validate_quietly(test_yml, strict = TRUE)),
             pattern = "Validation failed")

# Test 9: A DOI registered nowhere fails CC-MET-004
paper_yml("https://doi.org/10.1234/invalid")
expect_warning(result <- with_mocked_codecheck(list(codecheck_GET = crossref_api),
                                               validate_quietly(test_yml)),
               pattern = "CC-MET-004")
expect_false(result$valid)
expect_equal(outcome_of(result, "CC-MET-005"), "skipped")

# Test 10: A DataCite DOI resolves, it just has no Crossref record to compare
paper_yml("https://doi.org/10.5281/zenodo.1234")
result <- with_mocked_codecheck(
  list(codecheck_GET = mock_crossref_GET(handles = "10.5281/zenodo.1234")),
  validate_quietly(test_yml))
expect_true(result$valid)
expect_equal(outcome_of(result, "CC-MET-004"), "ok")
expect_equal(outcome_of(result, "CC-MET-005"), "skipped")

# Test 11: A reference that is not a DOI is checked as a URL
paper_yml("http://papers.invalid/paper.pdf")
expect_warning(result <- with_mocked_codecheck(list(codecheck_GET = crossref_api),
                                               validate_quietly(test_yml)),
               pattern = "CC-MET-004")
expect_false(result$valid)

# Test 12: An unreachable Crossref makes the rules skip, it never fails them
paper_yml("https://doi.org/10.1088/0954-898X_3_1_008")
result <- with_mocked_codecheck(
  list(codecheck_GET = function(url, ...) stop("Could not resolve host")),
  validate_quietly(test_yml, strict = TRUE))
expect_true(result$valid)
expect_equal(length(result$issues), 0)
expect_true(all(result$results$outcome[grepl("^CC-MET", result$results$id)] == "skipped"))

# Test 13: A rate-limited Crossref is not a missing DOI either
result <- with_mocked_codecheck(
  list(codecheck_GET = function(url, ...) mock_response(url, 429L)),
  validate_quietly(test_yml, strict = TRUE))
expect_true(result$valid)
expect_equal(outcome_of(result, "CC-MET-004"), "skipped")

# Test 14: The record is requested once, however many rules read it
requests <- 0
counting_api <- function(url, ...) {
  requests <<- requests + 1
  crossref_api(url, ...)
}
invisible(with_mocked_codecheck(list(codecheck_GET = counting_api),
                                validate_quietly(test_yml)))
expect_equal(requests, 1)

# Clean up
unlink(test_yml)
