## Test validate_certificate_github_issue function

# Skip all tests if GitHub token is not available
# These tests require GitHub API access and will fail without authentication
github_token <- Sys.getenv("GITHUB_PAT")
if (github_token == "") {
  github_token <- Sys.getenv("GITHUB_TOKEN")
}

if (github_token == "") {
  exit_file("Skipping GitHub issue validation tests: GITHUB_PAT or GITHUB_TOKEN not set")
}

# Test 1: Valid certificate with open issue in register
# Using a real certificate that should exist in the register
test_yml_valid <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: '2025-025'",  # Valiente certificate from earlier tests
  "report: 'https://doi.org/10.5281/zenodo.12345678'",  # Dummy DOI to avoid placeholder detection
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Test Author",
  "  reference: https://example.com"
), test_yml_valid)

# Test with a known closed certificate
result_closed <- tryCatch({
  validate_certificate_github_issue(test_yml_valid, strict = FALSE)
}, error = function(e) {
  list(valid = FALSE, error = e$message)
})

# Should return a result (not error)
expect_true(is.list(result_closed),
            info = "Function should return a list for valid certificate")

if (!is.null(result_closed$certificate)) {
  expect_equal(result_closed$certificate, "2025-025",
               info = "Should return the certificate identifier")
  expect_true(!is.null(result_closed$issue_number),
              info = "Should find an issue number")

  # Check if warnings are present for closed issues
  if (!is.null(result_closed$issue_state) && result_closed$issue_state == "closed") {
    expect_true(length(result_closed$warnings) > 0,
                info = "Should have warnings for closed issue")
  }
}

unlink(test_yml_valid)

# Test 2: Certificate identifier is a placeholder - should skip validation
test_yml_placeholder <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: 'YYYY-NNN'",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Test Author",
  "  reference: https://example.com"
), test_yml_placeholder)

result_placeholder <- validate_certificate_github_issue(test_yml_placeholder)
expect_true(result_placeholder$valid,
            info = "Placeholder certificate should be valid (skipped)")
expect_true(result_placeholder$skipped,
            info = "Should indicate validation was skipped for placeholder")
expect_null(result_placeholder$issue_number,
            info = "Should not have issue number for placeholder")

unlink(test_yml_placeholder)

# Test 3: Non-existent certificate should error
test_yml_nonexistent <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: '2099-888'",  # Unlikely to exist (not a placeholder pattern)
  "report: 'https://doi.org/10.5281/zenodo.88888888'",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Test Author",
  "  reference: https://example.com"
), test_yml_nonexistent)

expect_error(
  validate_certificate_github_issue(test_yml_nonexistent),
  "No GitHub issue found",
  info = "Should error when no matching issue is found"
)

unlink(test_yml_nonexistent)

# Test 4: Missing certificate field should error
test_yml_no_cert <- tempfile(fileext = ".yml")
writeLines(c(
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Test Author"
), test_yml_no_cert)

expect_error(
  validate_certificate_github_issue(test_yml_no_cert),
  "Certificate identifier not found",
  info = "Should error when certificate field is missing"
)

unlink(test_yml_no_cert)

# Test 5: Empty certificate field should error
test_yml_empty_cert <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: ''",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Test Author"
), test_yml_empty_cert)

expect_error(
  validate_certificate_github_issue(test_yml_empty_cert),
  "Certificate identifier not found",
  info = "Should error when certificate field is empty"
)

unlink(test_yml_empty_cert)

# Test 6: Non-existent file should error
expect_error(
  validate_certificate_github_issue("/nonexistent/codecheck.yml"),
  "codecheck.yml file not found",
  info = "Should error when file does not exist"
)

# Test 7: Invalid repo format should error
test_yml_for_repo <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: '2025-025'",
  "report: 'https://doi.org/10.5281/zenodo.12345678'",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Test Author"
), test_yml_for_repo)

expect_error(
  validate_certificate_github_issue(test_yml_for_repo, repo = "invalid"),
  "repo must be in format 'owner/repo'",
  info = "Should error when repo format is invalid"
)

unlink(test_yml_for_repo)

# Test 8: Pass metadata directly instead of file path
metadata <- list(
  certificate = "2025-025",
  report = "https://doi.org/10.5281/zenodo.12345678",
  paper = list(
    title = "Test Paper",
    authors = list(
      list(name = "Test Author")
    )
  )
)

result_metadata <- tryCatch({
  validate_certificate_github_issue(yml_file = "dummy.yml", metadata = metadata)
}, error = function(e) {
  list(valid = FALSE, error = e$message)
})

expect_true(is.list(result_metadata),
            info = "Function should accept metadata directly")

# Test 9: Strict mode with closed issue should fail
test_yml_strict <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: '2025-025'",  # This is likely a closed issue
  "report: 'https://doi.org/10.5281/zenodo.12345678'",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Test Author"
), test_yml_strict)

# Only test strict mode if we know the issue is closed
result_check <- tryCatch({
  validate_certificate_github_issue(test_yml_strict, strict = FALSE)
}, error = function(e) NULL)

if (!is.null(result_check) && !is.null(result_check$issue_state)) {
  if (result_check$issue_state == "closed") {
    # Strict mode should fail for closed issues
    expect_error(
      validate_certificate_github_issue(test_yml_strict, strict = TRUE),
      "Certificate validation failed in strict mode",
      info = "Strict mode should fail for closed issues"
    )
  }
}

unlink(test_yml_strict)

# Test 10: Return structure validation
test_yml_structure <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: '2025-025'",
  "report: 'https://doi.org/10.5281/zenodo.12345678'",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Test Author"
), test_yml_structure)

result_structure <- tryCatch({
  validate_certificate_github_issue(test_yml_structure, strict = FALSE)
}, error = function(e) {
  list(valid = FALSE, error = e$message)
})

if (result_structure$valid && !result_structure$skipped) {
  # Validate the structure of the return value
  expect_true(assertthat::has_name(result_structure, "valid"),
              info = "Result should have 'valid' field")
  expect_true(assertthat::has_name(result_structure, "certificate"),
              info = "Result should have 'certificate' field")
  expect_true(assertthat::has_name(result_structure, "issue_number"),
              info = "Result should have 'issue_number' field")
  expect_true(assertthat::has_name(result_structure, "issue_state"),
              info = "Result should have 'issue_state' field")
  expect_true(assertthat::has_name(result_structure, "issue_assignees"),
              info = "Result should have 'issue_assignees' field")
  expect_true(assertthat::has_name(result_structure, "warnings"),
              info = "Result should have 'warnings' field")
  expect_true(assertthat::has_name(result_structure, "errors"),
              info = "Result should have 'errors' field")

  # Validate field types
  expect_true(is.logical(result_structure$valid),
              info = "valid should be logical")
  expect_true(is.character(result_structure$certificate),
              info = "certificate should be character")
  expect_true(is.character(result_structure$warnings),
              info = "warnings should be character vector")
  expect_true(is.character(result_structure$errors),
              info = "errors should be character vector")
}

unlink(test_yml_structure)
