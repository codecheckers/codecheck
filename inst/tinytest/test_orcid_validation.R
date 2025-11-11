# Tests for ORCID validation functions

library(tinytest)

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

result <- suppressWarnings(validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE))
expect_false(result$valid)
expect_true(any(grepl("No codechecker information", result$issues)))

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

result <- suppressWarnings(validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE))
expect_false(result$valid)
expect_true(any(grepl("missing a name", result$issues)))

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

result <- suppressWarnings(validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE))
expect_false(result$valid)
expect_true(any(grepl("invalid ORCID format", result$issues)))

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

result <- suppressWarnings(validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE))
expect_false(result$valid)
expect_true(any(grepl("invalid ORCID format", result$issues)))

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
result_no_authors <- suppressWarnings(
  validate_codecheck_yml_orcid(test_yml, strict = FALSE, validate_authors = FALSE, skip_on_auth_error = TRUE)
)
# Should only find checker ORCID error
expect_false(result_no_authors$valid)
expect_true(any(grepl("Codechecker.*invalid ORCID", result_no_authors$issues)))
expect_false(any(grepl("Author.*invalid ORCID", result_no_authors$issues)))

# Test 8: validate_codecheckers parameter works
result_no_checkers <- suppressWarnings(
  validate_codecheck_yml_orcid(test_yml, strict = FALSE, validate_codecheckers = FALSE, skip_on_auth_error = TRUE)
)
# Should only find author ORCID error
expect_false(result_no_checkers$valid)
expect_true(any(grepl("Author.*invalid ORCID", result_no_checkers$issues)))
expect_false(any(grepl("Codechecker.*invalid ORCID", result_no_checkers$issues)))

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

# Test 13: Valid ORCID format is accepted
cat("---
paper:
  title: Test Paper
  authors:
    - name: Test Author
      ORCID: 0000-0000-0000-000X
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
", file = test_yml)

# Should pass format validation (ORCID API call may warn but won't fail validation)
result <- suppressMessages(suppressWarnings(
  validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE)
))
expect_true(is.list(result))
# Note: valid may be TRUE or FALSE depending on ORCID API access,
# but the function should complete without error
expect_true(is.logical(result$valid))

# Test 14: Real ORCID with matching name (Stephen Eglen)
# This test uses a real ORCID from the package authors
# It requires ORCID_TOKEN to be set for full validation
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

# Capture messages to check if ORCID API was accessible
messages_match <- character(0)
result_real_match <- tryCatch({
  withCallingHandlers(
    validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE),
    message = function(m) {
      messages_match <<- c(messages_match, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
}, error = function(e) {
  list(valid = NA, issues = c(paste("Error:", e$message)))
})

# Check result structure always
expect_true(is.list(result_real_match))
expect_true("valid" %in% names(result_real_match))
expect_true(is.logical(result_real_match$valid))

# Only validate actual match if ORCID API was accessible
# Check for both "Could not retrieve" and authentication skip messages
orcid_accessible <- !any(grepl("Could not retrieve ORCID record|ORCID authentication required|validation skipped", messages_match))

if (orcid_accessible) {
  # ORCID API accessible - validation should pass with matching name
  expect_true(result_real_match$valid,
              info = "Stephen Eglen should match ORCID 0000-0001-8607-8025")
  expect_equal(length(result_real_match$issues), 0,
              info = "Should have no validation issues for matching name")
} else {
  # ORCID API not accessible or authentication unavailable - just verify function completed without error
  expect_true(TRUE, info = "ORCID API not accessible or authentication unavailable - skipping name match validation")
}

# Test 15: Real ORCID with mismatching name
# This test uses Stephen Eglen's real ORCID but with wrong name
# It requires ORCID_TOKEN to be set for full validation
cat("---
paper:
  title: Test Paper
  authors:
    - name: John Doe
      ORCID: 0000-0001-8607-8025
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
", file = test_yml)

# Capture messages to check if ORCID API was accessible
messages_mismatch <- character(0)
result_real_mismatch <- tryCatch({
  withCallingHandlers(
    suppressWarnings(validate_codecheck_yml_orcid(test_yml, strict = FALSE, skip_on_auth_error = TRUE)),
    message = function(m) {
      messages_mismatch <<- c(messages_mismatch, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
}, error = function(e) {
  list(valid = NA, issues = c(paste("Error:", e$message)))
})

# Check result structure always
expect_true(is.list(result_real_mismatch))
expect_true("valid" %in% names(result_real_mismatch))
expect_true(is.logical(result_real_mismatch$valid))

# Only validate actual mismatch if ORCID API was accessible
# Check for both "Could not retrieve" and authentication skip messages
orcid_accessible_mismatch <- !any(grepl("Could not retrieve ORCID record|ORCID authentication required|validation skipped", messages_mismatch))

if (orcid_accessible_mismatch) {
  # ORCID API accessible - validation should fail due to name mismatch
  expect_false(result_real_mismatch$valid,
               info = "John Doe should NOT match ORCID 0000-0001-8607-8025 (Stephen Eglen)")
  expect_true(any(grepl("name mismatch", result_real_mismatch$issues)),
              info = "Should report name mismatch issue")
} else {
  # ORCID API not accessible or authentication unavailable - just verify function completed without error
  expect_true(TRUE, info = "ORCID API not accessible or authentication unavailable - skipping name mismatch validation")
}

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

# Clean up
unlink(test_yml)
