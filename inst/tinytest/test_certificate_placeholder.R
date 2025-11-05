# Tests for is_placeholder_certificate and update_certificate_from_github functions

library(tinytest)

# Setup - create a temporary directory for testing
test_dir <- tempdir()
test_yml <- file.path(test_dir, "codecheck_cert_test.yml")

# Test 1: is_placeholder_certificate fails if file doesn't exist
expect_error(
  is_placeholder_certificate("nonexistent.yml"),
  pattern = "codecheck.yml file not found"
)

# Test 2: NULL certificate is detected as placeholder
cat("---
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml))

# Test 3: Empty certificate is detected as placeholder
cat("---
certificate: ''
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml))

# Test 4: YYYY-NNN pattern is detected as placeholder
cat("---
certificate: YYYY-NNN
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml))

# Test 5: 0000-000 pattern is detected as placeholder
cat("---
certificate: 0000-000
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml))

# Test 6: 9999-999 pattern is detected as placeholder
cat("---
certificate: 9999-999
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml))

# Test 7: YYYY-123 pattern is detected as placeholder
cat("---
certificate: YYYY-123
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml))

# Test 8: 0000-456 pattern is detected as placeholder
cat("---
certificate: 0000-456
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml))

# Test 9: FIXME pattern is detected as placeholder
cat("---
certificate: FIXME-001
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml))

# Test 10: TODO pattern is detected as placeholder
cat("---
certificate: TODO
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml))

# Test 11: Valid certificate is NOT detected as placeholder
cat("---
certificate: 2024-001
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_false(is_placeholder_certificate(test_yml))

# Test 12: Valid certificate with different year
cat("---
certificate: 2023-042
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_false(is_placeholder_certificate(test_yml))

# Test 13: is_placeholder_certificate works with metadata parameter
metadata_test <- list(
  certificate = "YYYY-NNN",
  paper = list(title = "Test")
)

expect_true(is_placeholder_certificate(metadata = metadata_test))

# Test 14: is_placeholder_certificate works with valid certificate via metadata
metadata_valid <- list(
  certificate = "2024-005",
  paper = list(title = "Test")
)

expect_false(is_placeholder_certificate(metadata = metadata_valid))

# Test 15: update_certificate_from_github fails if file doesn't exist
expect_error(
  update_certificate_from_github("nonexistent.yml"),
  pattern = "codecheck.yml file not found"
)

# Test 16: update_certificate_from_github detects non-placeholder
cat("---
certificate: 2024-001
paper:
  title: Test Paper
  authors:
    - name: Test Author
manifest:
  - file: output.pdf
", file = test_yml)

result <- suppressMessages(
  update_certificate_from_github(test_yml, apply_update = FALSE)
)

expect_false(result$updated)
expect_equal(result$certificate, "2024-001")
expect_false(result$was_placeholder)

# Test 17: update_certificate_from_github return structure
cat("---
certificate: YYYY-NNN
paper:
  title: Test Paper
  authors:
    - name: Nonexistent Author XYZ123
manifest:
  - file: output.pdf
", file = test_yml)

result <- suppressMessages(
  update_certificate_from_github(test_yml, apply_update = FALSE)
)

expect_true(is.list(result))
expect_true("updated" %in% names(result))
expect_true("certificate" %in% names(result))
expect_true("issue_number" %in% names(result))
expect_true("was_placeholder" %in% names(result))
expect_true(is.logical(result$updated))
expect_true(is.logical(result$was_placeholder))

# Test 18: update_certificate_from_github with force parameter
cat("---
certificate: 2024-001
paper:
  title: Test Paper
  authors:
    - name: Test Author
manifest:
  - file: output.pdf
", file = test_yml)

# Without force - should not proceed
result_no_force <- suppressMessages(
  update_certificate_from_github(test_yml, force = FALSE, apply_update = FALSE)
)
expect_false(result_no_force$updated)

# With force - should proceed (but probably not find anything)
result_with_force <- suppressMessages(
  update_certificate_from_github(test_yml, force = TRUE, apply_update = FALSE)
)
expect_true(is.list(result_with_force))

# Test 19: Placeholder patterns comprehensive test
placeholder_tests <- list(
  list(cert = NULL, expected = TRUE),
  list(cert = "", expected = TRUE),
  list(cert = "YYYY-NNN", expected = TRUE),
  list(cert = "0000-000", expected = TRUE),
  list(cert = "9999-999", expected = TRUE),
  list(cert = "YYYY-001", expected = TRUE),
  list(cert = "0000-123", expected = TRUE),
  list(cert = "9999-456", expected = TRUE),
  list(cert = "FIXME", expected = TRUE),
  list(cert = "TODO-001", expected = TRUE),
  list(cert = "template-123", expected = TRUE),
  list(cert = "2024-001", expected = FALSE),
  list(cert = "2023-999", expected = FALSE),
  list(cert = "2025-042", expected = FALSE)
)

for (test_case in placeholder_tests) {
  if (is.null(test_case$cert)) {
    cat("---
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)
  } else {
    cat(paste0("---
certificate: ", test_case$cert, "
paper:
  title: Test Paper
manifest:
  - file: output.pdf
"), file = test_yml)
  }

  result <- is_placeholder_certificate(test_yml)
  expect_equal(result, test_case$expected,
               info = paste("Failed for certificate:", test_case$cert))
}

# Clean up
unlink(test_yml)
