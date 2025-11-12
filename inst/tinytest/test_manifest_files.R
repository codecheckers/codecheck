tinytest::using(ttdo)

# Setup: Create a temporary directory structure for testing
setup_test_env <- function() {
  test_root <- tempdir()
  test_dir <- file.path(test_root, "test_manifest")

  # Clean up if exists
  if (dir.exists(test_dir)) {
    unlink(test_dir, recursive = TRUE)
  }

  dir.create(test_dir, recursive = TRUE)

  # Create test files
  test_files <- c("output1.txt", "output2.txt", "data/result.csv")
  for (f in test_files) {
    full_path <- file.path(test_dir, f)
    dir.create(dirname(full_path), recursive = TRUE, showWarnings = FALSE)
    writeLines(paste("Content of", basename(f)), full_path)
  }

  # Create codecheck.yml
  yaml_content <- '---
version: https://codecheck.org.uk/spec/config/1.0
paper:
  title: Test Paper
  authors:
    - name: Test Author
  reference: https://doi.org/10.1234/test
manifest:
  - file: output1.txt
    comment: First output
  - file: output2.txt
    comment: Second output
  - file: data/result.csv
    comment: Data result
codechecker:
  - name: Test Checker
    ORCID: 0000-0001-2345-6789
summary: Test summary
repository: https://github.com/test/repo
check_time: "2024-01-01 10:00:00"
certificate: 2024-999
report: https://doi.org/10.5281/zenodo.1234567
'
  writeLines(yaml_content, file.path(test_dir, "codecheck.yml"))

  # Create destination directory
  dest_dir <- file.path(test_dir, "codecheck", "outputs")
  dir.create(dest_dir, recursive = TRUE)

  list(root = test_dir, dest_dir = dest_dir)
}

# Test 1: copy_manifest_files() - basic functionality ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
})
expect_inherits(result, "data.frame")
expect_equal(nrow(result), 3)
expect_equal(ncol(result), 4)
expect_true(all(c("output", "comment", "dest", "size") %in% names(result)))

# Test 2: copy_manifest_files() - verify files copied ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
})
expect_true(file.exists(file.path(env$dest_dir, "output1.txt")))
expect_true(file.exists(file.path(env$dest_dir, "output2.txt")))
expect_true(file.exists(file.path(env$dest_dir, "result.csv")))

# Test 3: copy_manifest_files() - verify content ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
})
content1 <- readLines(file.path(env$dest_dir, "output1.txt"))
expect_equal(content1, "Content of output1.txt")

# Test 4: copy_manifest_files() - check file sizes ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
})
expect_true(all(result$size > 0))

# Test 5: copy_manifest_files() - warning on missing file ----
# Note: Changed from error to warning to allow graceful handling of missing files
expect_warning({
  env <- setup_test_env()
  # Add a non-existent file to manifest
  metadata <- codecheck::codecheck_metadata(env$root)
  metadata$manifest[[4]] <- list(file = "missing.txt", comment = "Missing")
  result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
}, pattern = "Manifest files missing")

# Verify that the function still returns a data frame with the missing file marked
expect_true(is.data.frame(result))
expect_equal(nrow(result), 4)  # Should include all 4 files (3 existing + 1 missing)
expect_true(is.na(result$size[4]))  # Missing file should have NA size

# Test 6: copy_manifest_files() - keep_full_path = TRUE ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir, keep_full_path = TRUE)
})
expect_true(file.exists(file.path(env$dest_dir, "data", "result.csv")))

# Test 7: copy_manifest_files() - overwrite = FALSE (default) ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  # First copy
  codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
  # Modify source
  writeLines("MODIFIED", file.path(env$root, "output1.txt"))
  # Second copy without overwrite
  result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir, overwrite = FALSE)
})
# File should NOT be overwritten
content <- readLines(file.path(env$dest_dir, "output1.txt"))
expect_equal(content, "Content of output1.txt")

# Test 8: copy_manifest_files() - overwrite = TRUE ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  # First copy
  codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
  # Modify source
  writeLines("MODIFIED", file.path(env$root, "output1.txt"))
  # Second copy with overwrite
  result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir, overwrite = TRUE)
})
# File should be overwritten
content <- readLines(file.path(env$dest_dir, "output1.txt"))
expect_equal(content, "MODIFIED")

# Test 9: list_manifest_files() - basic functionality ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  # First copy files
  codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
  # Then list them
  result <- codecheck::list_manifest_files(env$root, metadata, env$dest_dir)
})
expect_inherits(result, "data.frame")
expect_equal(nrow(result), 3)
expect_equal(ncol(result), 4)

# Test 10: list_manifest_files() - check column names ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
  result <- codecheck::list_manifest_files(env$root, metadata, env$dest_dir)
})
expect_true(all(c("output", "comment", "dest", "size") %in% names(result)))

# Test 11: list_manifest_files() - verify output paths ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
  result <- codecheck::list_manifest_files(env$root, metadata, env$dest_dir)
})
expect_true("output1.txt" %in% result$output)
expect_true("output2.txt" %in% result$output)
expect_true("data/result.csv" %in% result$output)

# Test 12: list_manifest_files() - verify comments ----
expect_silent({
  env <- setup_test_env()
  metadata <- codecheck::codecheck_metadata(env$root)
  codecheck::copy_manifest_files(env$root, metadata, env$dest_dir)
  result <- codecheck::list_manifest_files(env$root, metadata, env$dest_dir)
})
expect_true("First output" %in% result$comment)
expect_true("Second output" %in% result$comment)
expect_true("Data result" %in% result$comment)

# Clean up
unlink(file.path(tempdir(), "test_manifest"), recursive = TRUE)
