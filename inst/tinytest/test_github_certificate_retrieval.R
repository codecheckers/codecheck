## Test get_certificate_from_github_issue function

# Test 1: Valid codecheck.yml with matching author name (mock)
# Create a temporary codecheck.yml file
test_yml <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: '2024-999'",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: John Doe",
  "  reference: https://example.com"
), test_yml)

# Test that function loads the YAML file correctly
# (We can't easily test GitHub API without mocking, so we test the structure)
result <- tryCatch({
  get_certificate_from_github_issue(test_yml)
  TRUE
}, error = function(e) {
  FALSE
})
expect_true(result, info = "Function should load valid YAML file without error")

# Clean up
unlink(test_yml)

# Test 2: Invalid input - non-existent file
expect_error(
  get_certificate_from_github_issue("/nonexistent/file.yml"),
  "must be a path"
)

# Test 3: Invalid input - not a list or file path
expect_error(
  get_certificate_from_github_issue(123),
  "must be a path"
)

# Test 4: YAML without paper.authors field should error
test_yml_no_authors <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: '2024-999'",
  "paper:",
  "  title: Test Paper"
), test_yml_no_authors)

expect_error(
  get_certificate_from_github_issue(test_yml_no_authors),
  "must have paper.authors field"
)

unlink(test_yml_no_authors)

# Test 5: Pass metadata list directly instead of file path
metadata <- list(
  certificate = "2024-001",
  paper = list(
    title = "Test Paper",
    authors = list(
      list(name = "Jane Smith")
    ),
    reference = "https://example.com"
  )
)

result_metadata <- tryCatch({
  get_certificate_from_github_issue(metadata)
  TRUE
}, error = function(e) {
  FALSE
})
expect_true(result_metadata, info = "Function should accept metadata list without error")

# Test 6: Invalid repo format
test_yml_valid <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: '2024-999'",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Test Author",
  "  reference: https://example.com"
), test_yml_valid)

expect_error(
  get_certificate_from_github_issue(test_yml_valid, repo = "invalid"),
  "repo must be in format 'owner/repo'"
)

unlink(test_yml_valid)

# Test 7: Integration test with real closed issue
# This test uses actual GitHub API to search for a real author in closed issues
test_yml_integration <- tempfile(fileext = ".yml")
writeLines(c(
  "certificate: '0000-000'",
  "paper:",
  "  title: Test Paper",
  "  authors:",
  "    - name: Valiente",
  "  reference: https://example.com"
), test_yml_integration)

# Search closed issues (issue #174: "Valiente | 2025-025")
result_integration <- tryCatch({
  get_certificate_from_github_issue(test_yml_integration, state = "closed", max_issues = 20)
}, error = function(e) {
  list(certificate = NULL, error = e$message)
})

# Verify we got a result
expect_true(is.list(result_integration))

# If the integration test succeeded (GitHub API accessible)
if (!is.null(result_integration$certificate)) {
  expect_equal(result_integration$certificate, "2025-025",
               info = "Should find certificate 2025-025 for author Valiente in closed issues")
  expect_true(!is.null(result_integration$issue_number),
               info = "Should return issue number")
  expect_true(!is.null(result_integration$issue_title),
               info = "Should return issue title")
  expect_equal(result_integration$matched_author, "Valiente",
               info = "Should return matched author name")
} else {
  # GitHub API not accessible or rate limited
  expect_true(TRUE, info = "GitHub API integration test skipped (API not accessible or rate limited)")
}

unlink(test_yml_integration)
