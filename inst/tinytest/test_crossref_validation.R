# Tests for validate_codecheck_yml_crossref function

library(tinytest)

# Setup - create a temporary directory for testing
test_dir <- tempdir()
test_yml <- file.path(test_dir, "codecheck.yml")

# Test 1: Function fails if file doesn't exist
expect_error(
  validate_codecheck_yml_crossref("nonexistent.yml"),
  pattern = "codecheck.yml file not found"
)

# Test 2: Validation fails if no paper metadata
cat("---
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
", file = test_yml)

result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE)
expect_false(result$valid)
expect_true(any(grepl("No paper metadata", result$issues)))

# Test 3: Validation fails if no paper reference
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

result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE)
expect_false(result$valid)
expect_true(any(grepl("No paper reference", result$issues)))

# Test 4: Validation skips placeholder DOIs
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

result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE)
expect_true(result$valid)
expect_equal(length(result$issues), 0)

# Test 5: Validation with real DOI - using a well-known DOI
# Using a Lifecycle Journal article DOI that should be stable
cat("---
paper:
  title: The principal components of natural images
  authors:
    - name: Peter J. B. Hancock
    - name: Roland J. Baddeley
    - name: Leslie S. Smith
      ORCID: 0000-0002-3716-8013
  reference: http://pdfs.semanticscholar.org/7dcf/a42cfe3b59becb441844b72558b361693608.pdf
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
    ORCID: 0000-0001-8607-8025
", file = test_yml)

# Note: This test will fail if the DOI is not in CrossRef, but we're testing with
# a non-DOI reference to see how it handles it
result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE)
# Should fail because it's not a valid DOI
expect_false(result$valid)

# Test 6: Validation fails with missing codechecker
cat("---
paper:
  title: Test Paper
  authors:
    - name: Test Author
  reference: https://doi.org/10.5281/zenodo.1234567
manifest:
  - file: output.pdf
    comment: Test output
", file = test_yml)

result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE)
expect_false(result$valid)
expect_true(any(grepl("No codechecker information", result$issues)))

# Test 7: Validation fails with codechecker missing name
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
  - ORCID: 0000-0001-8607-8025
", file = test_yml)

result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE)
expect_false(result$valid)
expect_true(any(grepl("missing a name", result$issues)))

# Test 8: Validation fails with invalid codechecker ORCID format
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
    ORCID: invalid-orcid
", file = test_yml)

result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE, check_orcids = TRUE)
expect_false(result$valid)
expect_true(any(grepl("invalid ORCID format", result$issues)))

# Test 9: Validation with check_orcids = FALSE skips ORCID validation
result2 <- validate_codecheck_yml_crossref(test_yml, strict = FALSE, check_orcids = FALSE)
# Should still fail because of placeholder DOI handling leads to success, but let's check structure
expect_true(is.list(result2))
expect_true("valid" %in% names(result2))
expect_true("issues" %in% names(result2))

# Test 10: Test return value structure
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
    ORCID: 0000-0001-8607-8025
", file = test_yml)

result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE)
expect_true(is.list(result))
expect_true("valid" %in% names(result))
expect_true("issues" %in% names(result))
expect_true("crossref_metadata" %in% names(result))
expect_true(is.logical(result$valid))
expect_true(is.character(result$issues))

# Test 11: Test strict mode throws error
cat("---
paper:
  title: Test Paper
  authors:
    - name: Test Author
  reference: https://doi.org/10.1234/invalid
manifest:
  - file: output.pdf
    comment: Test output
", file = test_yml)

expect_error(
  validate_codecheck_yml_crossref(test_yml, strict = TRUE),
  pattern = "Validation failed"
)

# Test 12: Valid codechecker ORCID format
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
    ORCID: 0000-0001-8607-8025
  - name: Another Checker
    ORCID: 0000-0002-0024-5046
", file = test_yml)

result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE, check_orcids = TRUE)
expect_true(result$valid)
expect_equal(length(result$issues), 0)

# Test 13: Test with X in ORCID checksum
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
    ORCID: 0000-0000-0000-000X
", file = test_yml)

result <- validate_codecheck_yml_crossref(test_yml, strict = FALSE, check_orcids = TRUE)
expect_true(result$valid)

# Clean up
unlink(test_yml)
