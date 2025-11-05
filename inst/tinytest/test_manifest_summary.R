## Test latex_summary_of_manifest function

# Test 1: Function works with NULL repository
metadata_null_repo <- list(
  certificate = "2024-001",
  repository = NULL
)

manifest_df <- data.frame(
  output = c("figure1.png", "table1.csv"),
  comment = c("Main figure", "Results table"),
  size = c(12345, 6789),
  dest = c("/tmp/figure1.png", "/tmp/table1.csv"),
  stringsAsFactors = FALSE
)

root <- "/tmp"

# Should not error when repository is NULL
result <- tryCatch({
  output <- capture.output(
    latex_summary_of_manifest(metadata_null_repo, manifest_df, root)
  )
  TRUE
}, error = function(e) {
  FALSE
})

expect_true(result, info = "Function should handle NULL repository without error")

# Test 2: Function works with empty string repository
metadata_empty_repo <- list(
  certificate = "2024-001",
  repository = ""
)

result_empty <- tryCatch({
  output <- capture.output(
    latex_summary_of_manifest(metadata_empty_repo, manifest_df, root)
  )
  TRUE
}, error = function(e) {
  FALSE
})

expect_true(result_empty, info = "Function should handle empty repository without error")

# Test 3: Function works with valid repository
metadata_valid_repo <- list(
  certificate = "2024-001",
  repository = "https://github.com/test/repo"
)

result_valid <- tryCatch({
  output <- capture.output(
    latex_summary_of_manifest(metadata_valid_repo, manifest_df, root)
  )
  TRUE
}, error = function(e) {
  FALSE
})

expect_true(result_valid, info = "Function should work with valid repository")

# Test 4: Function works with list of repositories (multiple)
metadata_list_repo <- list(
  certificate = "2024-001",
  repository = list("https://github.com/test/repo1", "https://github.com/test/repo2")
)

result_list <- tryCatch({
  output <- capture.output(
    latex_summary_of_manifest(metadata_list_repo, manifest_df, root)
  )
  TRUE
}, error = function(e) {
  FALSE
})

expect_true(result_list, info = "Function should handle list of repositories (uses first)")

# Test 5: Output contains expected LaTeX elements with valid repository
output_with_repo <- capture.output(
  latex_summary_of_manifest(metadata_valid_repo, manifest_df, root)
)

output_text <- paste(output_with_repo, collapse = "\n")
expect_true(grepl("\\\\href", output_text),
           info = "Output should contain href when repository is provided")
expect_true(grepl("figure1.png", output_text),
           info = "Output should contain file names")

# Test 6: Output doesn't contain href when repository is NULL
output_without_repo <- capture.output(
  latex_summary_of_manifest(metadata_null_repo, manifest_df, root)
)

output_text_no_repo <- paste(output_without_repo, collapse = "\n")
expect_false(grepl("\\\\href", output_text_no_repo),
            info = "Output should not contain href when repository is NULL")
expect_true(grepl("\\\\path", output_text_no_repo),
           info = "Output should contain path commands")
expect_true(grepl("figure1.png", output_text_no_repo),
           info = "Output should still contain file names")
