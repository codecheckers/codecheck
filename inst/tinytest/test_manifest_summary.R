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

# Test 7: LaTeX table specials in comments are escaped (codecheck#93)
manifest_special <- data.frame(
  output = c("fig1.pdf", "fig2.pdf", "out.csv"),
  comment = c("Fig 1 & example signals (panels fig1a-fig1h)",
              "50% of runs, see #3",
              "already escaped \\& with $x_1$"),
  size = c(NA, 123, 3e9),
  dest = c("/tmp/fig1.pdf", "/tmp/fig2.pdf", "/tmp/out.csv"),
  stringsAsFactors = FALSE
)
output_special <- capture.output(
  latex_summary_of_manifest(metadata_valid_repo, manifest_special, root)
)
rows <- grep("\\\\\\\\\\s*$", output_special, value = TRUE)
rows <- rows[!grepl("^Output", rows)]
expect_equal(length(rows), 3)
unescaped_amps <- vapply(gregexpr("(?<!\\\\)&", rows, perl = TRUE),
                         function(m) sum(m > 0), numeric(1))
expect_equal(unescaped_amps, c(2, 2, 2),
             info = "Every row has exactly three cells")
expect_true(grepl("Fig 1 \\& example signals", rows[1], fixed = TRUE))
expect_true(grepl("50\\% of runs, see \\#3", rows[2], fixed = TRUE))
expect_true(grepl("already escaped \\& with $x_1$", rows[3], fixed = TRUE),
            info = "Escaped characters and math are left alone")

# Test 8: missing files show 'missing' as size, sizes have no decimals
expect_true(grepl("& missing \\\\", rows[1], fixed = TRUE))
expect_true(grepl("& 123 \\\\", rows[2], fixed = TRUE))
expect_true(grepl("& 3000000000 \\\\", rows[3], fixed = TRUE))
