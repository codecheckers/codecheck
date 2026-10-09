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

expect_true(result_list, info = "Function should handle list of repositories")

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

# Test 9: links use the default branch (HEAD), not master (codecheck#97)
expect_true(grepl("https://github.com/test/repo/blob/HEAD/figure1.png", output_text, fixed = TRUE))
expect_false(grepl("blob/master", output_text, fixed = TRUE))

# Test 10: several repositories as yaml::read_yaml() returns them, a character
# vector; the first code forge is linked, even when it is not listed first
metadata_multi <- yaml::read_yaml(file.path("yaml", "repository_multiple", "codecheck.yml"))
metadata_multi$repository <- rev(metadata_multi$repository)
out_multi <- paste(capture.output(
  latex_summary_of_manifest(metadata_multi, manifest_df, root)), collapse = "\n")
expect_true(grepl("\\href{https://github.com/codecheckers/analysis-code/blob/HEAD/figure1.png}",
                  out_multi, fixed = TRUE))
expect_false(grepl("zenodo", out_multi, fixed = TRUE))

# Test 11: DOIs and unknown hosts are not linked
for (repo in c("https://doi.org/10.5281/zenodo.1234567", "https://codeberg.org/test/repo")) {
  out <- paste(capture.output(
    latex_summary_of_manifest(list(repository = repo), manifest_df, root)), collapse = "\n")
  expect_false(grepl("\\href", out), info = repo)
  expect_true(grepl("\\path{figure1.png}", out, fixed = TRUE), info = repo)
}

# Test 12: GitLab file URLs, also for nested groups and with .git suffix
out_gitlab <- paste(capture.output(
  latex_summary_of_manifest(list(repository = "https://gitlab.com/group/sub/project.git/"),
                            manifest_df, root)), collapse = "\n")
expect_true(grepl("https://gitlab.com/group/sub/project/-/blob/HEAD/figure1.png", out_gitlab, fixed = TRUE))

# Test 13: repository_url overrides the metadata or turns links off
out_override <- paste(capture.output(
  latex_summary_of_manifest(metadata_null_repo, manifest_df, root,
                            repository_url = "https://github.com/other/repo")), collapse = "\n")
expect_true(grepl("https://github.com/other/repo/blob/HEAD/table1.csv", out_override, fixed = TRUE))
out_off <- paste(capture.output(
  latex_summary_of_manifest(metadata_valid_repo, manifest_df, root,
                            repository_url = FALSE)), collapse = "\n")
expect_false(grepl("\\href", out_off))

# Test: file names with spaces keep them in the table, links use the copy (codecheck#98)
manifest_spaces <- data.frame(
  output = "Figure 1.jpeg",
  comment = "Figure with a space",
  size = 1,
  dest = "/tmp/codecheck/outputs/Figure_1.jpeg",
  stringsAsFactors = FALSE
)
spaces_text <- paste(capture.output(
  latex_summary_of_manifest(list(repository = "https://github.com/test/repo"),
                            manifest_spaces, "/tmp")
), collapse = "\n")
expect_true(grepl("\\path{Figure 1.jpeg}", spaces_text, fixed = TRUE))
expect_true(grepl("\\href{https://github.com/test/repo/blob/HEAD/codecheck/outputs/Figure_1.jpeg}",
                  spaces_text, fixed = TRUE))

# Test: the certificate preamble keeps spaces in \path (codecheck#98)
preamble <- readLines(system.file("extdata", "templates", "codecheck",
                                  "codecheck-preamble.sty", package = "codecheck"))
expect_true(any(grepl("\\PassOptionsToPackage{obeyspaces,spaces}{url}", preamble, fixed = TRUE)))
expect_true(which(grepl("PassOptionsToPackage", preamble)) <
            which(grepl("usepackage\\{hyperref\\}", preamble)))


# Test: the table is a longtable that repeats its header on every page, and the
# preamble loads longtable (codecheck#93)
long_text <- paste(capture.output(
  latex_summary_of_manifest(metadata_valid_repo, manifest_df, root)), collapse = "\n")
expect_true(grepl("\\begin{longtable}", long_text, fixed = TRUE))
expect_true(grepl("Size (b) \\\\ \n  \\hline\n\\endhead", long_text, fixed = TRUE))
expect_false(grepl("\\begin{table}", long_text, fixed = TRUE))
expect_true(grepl("\\caption{Summary of output files generated}", long_text, fixed = TRUE))
expect_true(any(grepl("\\usepackage{longtable}", preamble, fixed = TRUE)))
# Declared to knitr too, for workspaces with an older preamble
invisible(knitr::knit_meta(clean = TRUE))
invisible(capture.output(latex_summary_of_manifest(metadata_valid_repo, manifest_df, root)))
expect_true("longtable" %in% vapply(knitr::knit_meta(clean = TRUE), `[[`, "", "name"))
