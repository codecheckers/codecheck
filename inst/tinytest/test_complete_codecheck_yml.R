# Tests for complete_codecheck_yml function

library(tinytest)

# Setup - create a temporary directory for testing
test_dir <- tempdir()
test_yml <- file.path(test_dir, "codecheck.yml")

# Test 1: Function fails if file doesn't exist
expect_error(
  complete_codecheck_yml("nonexistent.yml"),
  pattern = "codecheck.yml file not found"
)

# Test 2: Minimal valid file (only manifest) - should report missing fields
cat("---
manifest:
  - file: output.pdf
    comment: Test output
", file = test_yml)

result <- complete_codecheck_yml(test_yml)
expect_true("codechecker" %in% result$missing$mandatory)
expect_true("report" %in% result$missing$mandatory)
expect_true("version" %in% result$missing$recommended)
expect_true("paper" %in% result$missing$recommended)

# Test 3: Add mandatory fields only
cat("---
manifest:
  - file: output.pdf
    comment: Test output
", file = test_yml)

result <- complete_codecheck_yml(test_yml, add_mandatory = TRUE, apply_updates = TRUE)
updated_yml <- yaml::read_yaml(test_yml)

# Check that mandatory fields were added
expect_true(!is.null(updated_yml$codechecker))
expect_true(!is.null(updated_yml$report))
expect_true(!is.null(updated_yml$manifest))

# Check that optional fields were NOT added
expect_true(is.null(updated_yml$summary))
expect_true(is.null(updated_yml$source))

# Test 4: Add all fields (mandatory and optional)
cat("---
manifest:
  - file: output.pdf
    comment: Test output
", file = test_yml)

result <- complete_codecheck_yml(test_yml,
                                 add_mandatory = TRUE,
                                 add_optional = TRUE,
                                 apply_updates = TRUE)
updated_yml <- yaml::read_yaml(test_yml)

# Check that all fields were added
expect_true(!is.null(updated_yml$codechecker))
expect_true(!is.null(updated_yml$report))
expect_true(!is.null(updated_yml$version))
expect_true(!is.null(updated_yml$paper))
expect_true(!is.null(updated_yml$summary))
expect_true(!is.null(updated_yml$repository))
expect_true(!is.null(updated_yml$check_time))
expect_true(!is.null(updated_yml$certificate))

# Test 5: Complete file - no missing fields
cat("---
version: https://codecheck.org.uk/spec/config/1.0/
paper:
  title: Test Paper
  authors:
    - name: Test Author
      ORCID: 0000-0000-0000-0000
  reference: https://example.com/paper
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: Test Checker
    ORCID: 0000-0000-0000-0001
report: https://doi.org/10.5281/zenodo.1234567
summary: Test summary
repository: https://github.com/test/repo
check_time: '2025-01-01 00:00:00'
certificate: 2025-001
source: Test source
", file = test_yml)

result <- complete_codecheck_yml(test_yml)
expect_equal(length(result$missing$mandatory), 0)
expect_equal(length(result$missing$recommended), 0)
expect_equal(length(result$missing$optional), 0)

# Test 6: File with FIXME placeholders should be detected as missing
cat("---
manifest:
  - file: output.pdf
    comment: Test output
codechecker:
  - name: FIXME
report: https://doi.org/10.5281/zenodo.FIXME
paper:
  title: FIXME
  authors:
    - name: FIXME
  reference: https://FIXME
", file = test_yml)

result <- complete_codecheck_yml(test_yml)
# Report should be in missing because it contains FIXME
expect_true("report" %in% result$missing$mandatory)

# Test 7: Test that apply_updates = FALSE doesn't modify the file
cat("---
manifest:
  - file: output.pdf
    comment: Test output
", file = test_yml)

original_content <- readLines(test_yml)
result <- complete_codecheck_yml(test_yml, add_mandatory = TRUE, apply_updates = FALSE)
new_content <- readLines(test_yml)

expect_equal(original_content, new_content)

# Test 8: Test return value structure
cat("---
manifest:
  - file: output.pdf
    comment: Test output
", file = test_yml)

result <- complete_codecheck_yml(test_yml)
expect_true(is.list(result))
expect_true("missing" %in% names(result))
expect_true("updated" %in% names(result))
expect_true(is.list(result$missing))
expect_true("mandatory" %in% names(result$missing))
expect_true("recommended" %in% names(result$missing))
expect_true("optional" %in% names(result$missing))

# Clean up
unlink(test_yml)
