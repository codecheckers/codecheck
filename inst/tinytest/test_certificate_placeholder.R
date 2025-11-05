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

expect_true(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 3: Empty certificate is detected as placeholder
cat("---
certificate: ''
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 4: YYYY-NNN pattern is detected as placeholder
cat("---
certificate: YYYY-NNN
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 5: 0000-000 pattern is detected as placeholder
cat("---
certificate: 0000-000
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 6: 9999-999 pattern is detected as placeholder
cat("---
certificate: 9999-999
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 7: YYYY-123 pattern is detected as placeholder
cat("---
certificate: YYYY-123
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 8: 0000-456 pattern is detected as placeholder
cat("---
certificate: 0000-456
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 9: FIXME pattern is detected as placeholder
cat("---
certificate: FIXME-001
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 10: TODO pattern is detected as placeholder
cat("---
certificate: TODO
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 11: Valid certificate is NOT detected as placeholder
cat("---
certificate: 2024-001
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_false(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 12: Valid certificate with different year
cat("---
certificate: 2023-042
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_false(is_placeholder_certificate(test_yml, check_doi = FALSE))

# Test 13: is_placeholder_certificate works with metadata parameter
metadata_test <- list(
  certificate = "YYYY-NNN",
  paper = list(title = "Test")
)

expect_true(is_placeholder_certificate(metadata = metadata_test, check_doi = FALSE))

# Test 14: is_placeholder_certificate works with valid certificate via metadata
metadata_valid <- list(
  certificate = "2024-005",
  paper = list(title = "Test")
)

expect_false(is_placeholder_certificate(metadata = metadata_valid, check_doi = FALSE))

# Test 15: update_certificate_from_github fails if file doesn't exist
expect_error(
  update_certificate_from_github("nonexistent.yml"),
  pattern = "codecheck.yml file not found"
)

# Test 16: update_certificate_from_github detects non-placeholder
cat("---
certificate: 2024-001
report: https://doi.org/10.5281/zenodo.123456
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

  result <- is_placeholder_certificate(test_yml, check_doi = FALSE)
  expect_equal(result, test_case$expected,
               info = paste("Failed for certificate:", test_case$cert))
}

# Test 20: is_placeholder_certificate with strict=TRUE throws error
cat("---
certificate: YYYY-NNN
report: https://doi.org/10.5281/zenodo.123456
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_error(
  is_placeholder_certificate(test_yml, strict = TRUE),
  pattern = "is a placeholder"
)

# Test 21: is_placeholder_certificate with strict=TRUE and valid certificate
cat("---
certificate: 2024-001
report: https://doi.org/10.5281/zenodo.123456
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

# Should NOT error with valid certificate
result_strict_valid <- tryCatch({
  is_placeholder_certificate(test_yml, strict = TRUE)
  TRUE
}, error = function(e) {
  FALSE
})

expect_true(result_strict_valid, info = "strict mode should not error with valid certificate")

# Test 22: validate_certificate_for_rendering returns FALSE for placeholder
cat("---
certificate: YYYY-NNN
report: https://doi.org/10.5281/zenodo.123456
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

result_val <- suppressWarnings(
  validate_certificate_for_rendering(test_yml, display_warning = FALSE)
)

expect_false(result_val, info = "Should return FALSE for placeholder")

# Test 23: validate_certificate_for_rendering returns TRUE for valid
cat("---
certificate: 2024-001
report: https://doi.org/10.5281/zenodo.123456
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

result_val_valid <- validate_certificate_for_rendering(test_yml, display_warning = FALSE)

expect_true(result_val_valid, info = "Should return TRUE for valid certificate")

# Test 24: validate_certificate_for_rendering with strict=TRUE fails
cat("---
certificate: YYYY-NNN
report: https://doi.org/10.5281/zenodo.123456
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_error(
  validate_certificate_for_rendering(test_yml, strict = TRUE, display_warning = FALSE),
  pattern = "Certificate validation failed"
)

# Test 25: validate_certificate_for_rendering displays warning (check output)
cat("---
certificate: TODO-001
report: https://doi.org/10.5281/zenodo.123456
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

output <- capture.output(
  suppressWarnings(
    validate_certificate_for_rendering(test_yml, display_warning = TRUE)
  )
)

output_text <- paste(output, collapse = "\n")
expect_true(grepl("WARNING", output_text), info = "Should display WARNING in output")
expect_true(grepl("TODO-001", output_text), info = "Should show certificate ID in warning")

# Test 26: validate_certificate_for_rendering with NULL certificate
cat("---
report: https://doi.org/10.5281/zenodo.123456
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

output_null <- capture.output(
  suppressWarnings(
    validate_certificate_for_rendering(test_yml, display_warning = TRUE)
  )
)

output_text_null <- paste(output_null, collapse = "\n")
expect_true(grepl("NOT SET", output_text_null), info = "Should show 'NOT SET' for NULL certificate")

# Test 27: NULL report DOI is detected as placeholder (when check_doi=TRUE)
cat("---
certificate: 2024-001
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "NULL report should be detected as placeholder when check_doi=TRUE")

# Test 28: Empty report DOI is detected as placeholder
cat("---
certificate: 2024-001
report: ''
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Empty report should be detected as placeholder")

# Test 29: Report DOI with FIXME is detected as placeholder
cat("---
certificate: 2024-001
report: 'https://doi.org/10.5281/zenodo.FIXME'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Report with FIXME should be detected as placeholder")

# Test 30: Report DOI with TODO is detected as placeholder
cat("---
certificate: 2024-001
report: 'TODO: set DOI'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Report with TODO should be detected as placeholder")

# Test 31: Report DOI with placeholder text is detected
cat("---
certificate: 2024-001
report: 'placeholder'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Report with placeholder text should be detected")

# Test 32: Report DOI with XXXXX is detected as placeholder
cat("---
certificate: 2024-001
report: 'https://doi.org/10.XXXXX/zenodo.12345'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Report with XXXXX should be detected as placeholder")

# Test 33: Valid certificate and valid DOI (should pass)
cat("---
certificate: 2024-001
report: 'https://doi.org/10.5281/zenodo.12345'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_false(is_placeholder_certificate(test_yml, check_doi = TRUE),
             info = "Valid certificate and DOI should NOT be detected as placeholder")

# Test 34: Placeholder certificate with valid DOI (should fail due to cert)
cat("---
certificate: YYYY-NNN
report: 'https://doi.org/10.5281/zenodo.12345'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Placeholder certificate should fail even with valid DOI")

# Test 35: Valid certificate with placeholder DOI (should fail due to DOI)
cat("---
certificate: 2024-001
report: 'FIXME'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Valid certificate should fail with placeholder DOI")

# Test 36: Both certificate and DOI placeholders (should fail)
cat("---
certificate: YYYY-NNN
report: 'TODO'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Both placeholders should be detected")

# Test 37: check_doi=FALSE ignores DOI placeholder
cat("---
certificate: 2024-001
report: 'FIXME'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_false(is_placeholder_certificate(test_yml, check_doi = FALSE),
             info = "Should pass when check_doi=FALSE even with placeholder DOI")

# Test 38: DOI placeholder with strict=TRUE throws error
cat("---
certificate: 2024-001
report: 'FIXME'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_error(
  is_placeholder_certificate(test_yml, check_doi = TRUE, strict = TRUE),
  pattern = "Report DOI",
  info = "strict mode should error for DOI placeholder"
)

# Test 39: Both placeholders with strict=TRUE throws error mentioning both
cat("---
certificate: YYYY-NNN
report: 'TODO'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

error_caught <- tryCatch({
  is_placeholder_certificate(test_yml, check_doi = TRUE, strict = TRUE)
  FALSE
}, error = function(e) {
  error_msg <- conditionMessage(e)
  # Should mention both certificate and report issues
  has_cert_msg <- grepl("Certificate identifier", error_msg)
  has_doi_msg <- grepl("Report DOI", error_msg)
  has_cert_msg && has_doi_msg
})

expect_true(error_caught, info = "strict mode should mention both placeholders")

# Test 40: validate_certificate_for_rendering detects DOI placeholder
cat("---
certificate: 2024-001
report: 'FIXME'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

result_doi_placeholder <- suppressWarnings(
  validate_certificate_for_rendering(test_yml, display_warning = FALSE)
)

expect_false(result_doi_placeholder, info = "Should return FALSE for DOI placeholder")

# Test 41: validate_certificate_for_rendering displays DOI warning
cat("---
certificate: 2024-001
report: 'TODO'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

output_doi <- capture.output(
  suppressWarnings(
    validate_certificate_for_rendering(test_yml, display_warning = TRUE)
  )
)

output_text_doi <- paste(output_doi, collapse = "\n")
expect_true(grepl("WARNING", output_text_doi), info = "Should display WARNING for DOI")
expect_true(grepl("Report DOI", output_text_doi), info = "Should mention Report DOI in warning")
expect_true(grepl("TODO", output_text_doi), info = "Should show DOI value in warning")

# Test 42: validate_certificate_for_rendering displays both warnings
cat("---
certificate: YYYY-NNN
report: 'FIXME'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

output_both <- capture.output(
  suppressWarnings(
    validate_certificate_for_rendering(test_yml, display_warning = TRUE)
  )
)

output_text_both <- paste(output_both, collapse = "\n")
expect_true(grepl("Certificate ID", output_text_both), info = "Should mention Certificate ID")
expect_true(grepl("Report DOI", output_text_both), info = "Should mention Report DOI")
expect_true(grepl("YYYY-NNN", output_text_both), info = "Should show certificate value")
expect_true(grepl("FIXME", output_text_both), info = "Should show DOI value")

# Test 43: validate_certificate_for_rendering with strict=TRUE fails for DOI
cat("---
certificate: 2024-001
report: 'TODO'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_error(
  validate_certificate_for_rendering(test_yml, strict = TRUE, display_warning = FALSE),
  pattern = "Report DOI",
  info = "strict mode should fail for DOI placeholder"
)

# Test 44: Incomplete DOI pattern (doi.org/10.XXXX/YYYY.FIXME)
cat("---
certificate: 2024-001
report: 'https://doi.org/10.5281/zenodo.FIXME'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Incomplete DOI with .FIXME should be detected")

# Test 45: Incomplete DOI pattern with TODO
cat("---
certificate: 2024-001
report: 'https://doi.org/10.5281/zenodo.TODO'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Incomplete DOI with .TODO should be detected")

# Test 46: Case-insensitive matching for DOI placeholders
cat("---
certificate: 2024-001
report: 'fixme'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Case-insensitive matching should detect lowercase fixme")

# Test 47: Example text in DOI
cat("---
certificate: 2024-001
report: 'example DOI here'
paper:
  title: Test Paper
manifest:
  - file: output.pdf
", file = test_yml)

expect_true(is_placeholder_certificate(test_yml, check_doi = TRUE),
            info = "Example text in DOI should be detected")

# Clean up
unlink(test_yml)
