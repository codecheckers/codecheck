tinytest::using(ttdo)

# Load dependencies
suppressMessages({
  library(gh)
  library(R.cache)
})

# Test copy_package_javascript function ----
temp_dir <- tempdir()
test_output_dir <- file.path(temp_dir, "test_libs")
dir.create(test_output_dir, showWarnings = FALSE, recursive = TRUE)

codecheck::copy_package_javascript(test_output_dir)

libs_dir <- file.path(test_output_dir, "libs", "codecheck")
expect_true(
  dir.exists(libs_dir),
  info = "copy_package_javascript should create libs/codecheck directory"
)

# Test that JavaScript files are copied
js_files <- list.files(libs_dir, pattern = "\\.js$")
expect_true(
  length(js_files) > 0,
  info = "copy_package_javascript should copy JavaScript files"
)

# Verify specific files exist
expected_files <- c("citation.min.js", "cert-utils.js", "cert-citation.js")
for (file in expected_files) {
  expect_true(
    file %in% js_files,
    info = paste("Expected file", file, "should be copied to libs/codecheck")
  )
}

# Verify file contents are not empty
for (file in js_files) {
  file_path <- file.path(libs_dir, file)
  file_size <- file.info(file_path)$size
  expect_true(
    file_size > 0,
    info = paste("JavaScript file", file, "should not be empty")
  )
}

# Clean up
unlink(test_output_dir, recursive = TRUE)
