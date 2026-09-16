# Tests for ORCID validation functions

library(tinytest)
source("mocks.R")

# An ORCID API answering from a table instead of the network: ORCID -> name,
# or NA for a record that does not exist.
mock_orcid_GET <- function(names) {
  function(url, ...) {
    orcid <- sub("^.*/v3.0/([^/]+)/person$", "\\1", url)
    if (!orcid %in% names(names) || is.na(names[[orcid]])) {
      return(mock_response(url, 404L))
    }
    parts <- strsplit(names[[orcid]], " ")[[1]]
    body <- jsonlite::toJSON(list(name = list(
      `given-names` = list(value = paste(head(parts, -1), collapse = " ")),
      `family-name` = list(value = tail(parts, 1)))), auto_unbox = TRUE)
    response <- mock_response(url, 200L)
    response$headers <- list(`content-type` = "application/json")
    response$content <- charToRaw(as.character(body))
    response
  }
}

# Setup - create a temporary directory for testing
test_dir <- tempdir()
test_yml <- file.path(test_dir, "codecheck_orcid_test.yml")

# Test 1: Function fails if file doesn't exist
expect_error(
  validate_codecheck_yml_orcid("nonexistent.yml"),
  pattern = "codecheck.yml file not found"
)

# Test 2: Validation warns if no codechecker information
cat("---
paper:
  title: Test Paper
  authors:
    - name: Test Author
manifest:
  - file: output.pdf
    comment: Test output
", file = test_yml)

# CC-CFG-008 is a MUST, so it stops without strict
expect_error(suppressMessages(validate_codecheck_yml_orcid(test_yml)),
             pattern = "CC-CFG-008")
result <- suppressMessages(validate_codecheck_yml_orcid(test_yml, stop_on_error = FALSE))
expect_false(result$valid)
expect_true(any(grepl("CC-CFG-008", result$issues)))

# Test 3: Validation passes with valid structure (no ORCIDs to check)
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

result <- suppressMessages(validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE))
expect_true(result$valid)
expect_equal(length(result$issues), 0)

# Test 4: Validation warns on missing codechecker name
cat("---
paper:
  title: Test Paper
  authors:
    - name: Test Author
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - ORCID: 0000-0001-8607-8025
", file = test_yml)

expect_error(with_mocked_codecheck(list(codecheck_GET = mock_orcid_GET(list())),
  suppressMessages(validate_codecheck_yml_orcid(test_yml))),
  pattern = "CC-CFG-009")
result <- with_mocked_codecheck(list(codecheck_GET = mock_orcid_GET(list())),
  suppressMessages(validate_codecheck_yml_orcid(test_yml, stop_on_error = FALSE)))
expect_false(result$valid)
expect_true(any(grepl("CC-CFG-009", result$issues)))

# Test 5: Validation warns on invalid author ORCID format
cat("---
paper:
  title: Test Paper
  authors:
    - name: Test Author
      ORCID: invalid-orcid
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
", file = test_yml)

result <- suppressMessages(validate_codecheck_yml_orcid(test_yml, stop_on_error = FALSE))
expect_false(result$valid)
expect_true(any(grepl("CC-MET-001.*not-valid|CC-MET-001.*invalid-orcid", result$issues)))

# Test 6: Validation warns on invalid codechecker ORCID format
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
    ORCID: not-valid
", file = test_yml)

result <- suppressMessages(validate_codecheck_yml_orcid(test_yml, stop_on_error = FALSE))
expect_false(result$valid)
expect_true(any(grepl("CC-MET-001.*not-valid|CC-MET-001.*invalid-orcid", result$issues)))

# Test 7: validate_authors parameter works
cat("---
paper:
  title: Test Paper
  authors:
    - name: Test Author
      ORCID: invalid-author
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
    ORCID: invalid-checker
", file = test_yml)

# Skip author validation
result_no_authors <- suppressMessages(
  validate_codecheck_yml_orcid(test_yml, validate_authors = FALSE, stop_on_error = FALSE)
)
# Should only find checker ORCID error
expect_false(result_no_authors$valid)
expect_true(any(grepl("invalid-checker", result_no_authors$issues)))
expect_false(any(grepl("invalid-author", result_no_authors$issues)))

# Test 8: validate_codecheckers parameter works
result_no_checkers <- suppressMessages(
  validate_codecheck_yml_orcid(test_yml, validate_codecheckers = FALSE, stop_on_error = FALSE)
)
# Should only find author ORCID error
expect_false(result_no_checkers$valid)
expect_true(any(grepl("invalid-author", result_no_checkers$issues)))
expect_false(any(grepl("invalid-checker", result_no_checkers$issues)))

# Test 9: validate_contents_references function exists and works
cat("---
paper:
  title: Test Paper
  authors:
    - name: Test Author
  reference: https://FIXME
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
", file = test_yml)

# Should work with placeholder DOI (skips CrossRef validation)
result <- suppressMessages(validate_contents_references(test_yml, strict = FALSE, skip_on_auth_error = TRUE))
expect_true(is.list(result))
expect_true("valid" %in% names(result))
expect_true("crossref_result" %in% names(result))
expect_true("orcid_result" %in% names(result))

# Test 10: validate_contents_references with only CrossRef
result_crossref_only <- suppressMessages(
  validate_contents_references(test_yml, strict = FALSE, validate_orcid = FALSE)
)
expect_true(is.list(result_crossref_only))
expect_true(!is.null(result_crossref_only$crossref_result))
expect_true(is.null(result_crossref_only$orcid_result))

# Test 11: validate_contents_references with only ORCID
result_orcid_only <- suppressMessages(
  validate_contents_references(test_yml, strict = FALSE, validate_crossref = FALSE, skip_on_auth_error = TRUE)
)
expect_true(is.list(result_orcid_only))
expect_true(is.null(result_orcid_only$crossref_result))
expect_true(!is.null(result_orcid_only$orcid_result))

# Test 12: Return structure validation (without real ORCID API call)
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

result <- suppressMessages(validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE))
expect_true(is.list(result))
expect_true("valid" %in% names(result))
expect_true("issues" %in% names(result))
expect_true(is.logical(result$valid))
expect_true(is.character(result$issues))

# Test 13: ORCID records answered by a mocked ORCID API
cat("---
paper:
  title: Test Paper
  authors:
    - name: Stephen Eglen
      ORCID: 0000-0001-8607-8025
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
", file = test_yml)

orcid_api <- mock_orcid_GET(list("0000-0001-8607-8025" = "Stephen J. Eglen"))

# Test 14: a matching name passes, tolerating a middle initial
result_match <- with_mocked_codecheck(list(codecheck_GET = orcid_api),
  suppressMessages(validate_codecheck_yml_orcid(test_yml)))
expect_true(result_match$valid)
expect_false(result_match$skipped)
expect_equal(result_match$results$outcome[result_match$results$id == "CC-MET-003"], "ok")

# Test 15: a mismatching name is a warning, and strict makes it an error
writeLines(sub("Stephen Eglen", "John Doe", readLines(test_yml)), test_yml)
expect_warning(result_mismatch <- with_mocked_codecheck(list(codecheck_GET = orcid_api),
  suppressMessages(validate_codecheck_yml_orcid(test_yml))), pattern = "CC-MET-003")
expect_false(result_mismatch$valid)
expect_true(any(grepl("John Doe .* is 'Stephen J. Eglen' on ORCID", result_mismatch$issues)))
expect_error(with_mocked_codecheck(list(codecheck_GET = orcid_api),
  suppressMessages(validate_codecheck_yml_orcid(test_yml, strict = TRUE))),
  pattern = "Validation failed")

# Test 15a: an ORCID with no record fails CC-MET-002
expect_warning(result_missing <- with_mocked_codecheck(
  list(codecheck_GET = mock_orcid_GET(list())),
  suppressMessages(validate_codecheck_yml_orcid(test_yml))), pattern = "CC-MET-002")
expect_false(result_missing$valid)

# Test 15b: an unreachable ORCID API skips, it does not fail
result_offline <- with_mocked_codecheck(
  list(codecheck_GET = function(url, ...) stop("Could not resolve host")),
  suppressMessages(validate_codecheck_yml_orcid(test_yml)))
expect_true(result_offline$valid)
expect_true(result_offline$skipped)
expect_equal(result_offline$results$outcome[result_offline$results$id == "CC-MET-002"], "skipped")

# Test 16: skip_on_auth_error=TRUE parameter - verify skipped field is returned
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

result_skip <- suppressMessages(
  validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE)
)
expect_true(is.list(result_skip))
expect_true("skipped" %in% names(result_skip), info = "Result should include 'skipped' field")
expect_true(is.logical(result_skip$skipped))

# Test 17: validate_contents_references passes skip_on_auth_error parameter
result_combined <- suppressMessages(
  validate_contents_references(
    test_yml,
    strict = FALSE,
    validate_crossref = FALSE,
    skip_on_auth_error = TRUE
  )
)
expect_true(is.list(result_combined))
expect_true(!is.null(result_combined$orcid_result))
expect_true("skipped" %in% names(result_combined$orcid_result),
            info = "ORCID result should include 'skipped' field")

# Test 18: get_orcid_name_public() works against a known public ORCID record
# without any authentication - this is the fallback that makes name checks
# work for co-authors/codecheckers even when the caller has no ORCID token
# (or one scoped only to their own record).
public_name <- codecheck:::get_orcid_name_public("0000-0002-1825-0097")
if (!is.null(public_name)) {
  expect_true(grepl("Carberry", public_name),
              info = "Public ORCID API lookup should return Josiah Carberry's name")
} else {
  expect_true(TRUE, info = "Public ORCID API not reachable in this environment - skipping")
}

# Test 19: get_orcid_name_public() returns NULL for a malformed/nonexistent ORCID
expect_true(is.null(codecheck:::get_orcid_name_public("0000-0000-0000-0000")))

# Clean up
unlink(test_yml)
