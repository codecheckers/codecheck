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

# Test 13: file names with spaces are copied to names with underscores (codecheck#98) ----
spaces_metadata <- function(files) {
  list(manifest = lapply(files, function(f) list(file = f, comment = f)))
}
env <- setup_test_env()
dir.create(file.path(env$root, "my figs"))
for (f in c("Figure 1.jpeg", "my figs/Figure ESM 4.2.jpeg")) {
  writeLines("image", file.path(env$root, f))
}
metadata <- spaces_metadata(c("Figure 1.jpeg", "my figs/Figure ESM 4.2.jpeg"))
expect_silent(result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir))
expect_equal(result$output, c("Figure 1.jpeg", "my figs/Figure ESM 4.2.jpeg"))
expect_equal(basename(result$dest), c("Figure_1.jpeg", "Figure_ESM_4.2.jpeg"))
expect_true(all(file.exists(result$dest)))
expect_false(any(is.na(result$size)))
expect_equal(codecheck::list_manifest_files(env$root, metadata, env$dest_dir)$dest,
             result$dest)

# Test 14: with keep_full_path, folder names lose their spaces too ----
result <- codecheck::copy_manifest_files(env$root, metadata, env$dest_dir,
                                         keep_full_path = TRUE)
expect_equal(result$dest[2], file.path(env$dest_dir, "my_figs/Figure_ESM_4.2.jpeg"))
expect_true(file.exists(result$dest[2]))

# Test 15: names that are the same after replacing spaces give a warning ----
writeLines("other", file.path(env$root, "Figure_1.jpeg"))
expect_warning(
  codecheck::copy_manifest_files(env$root,
                                 spaces_metadata(c("Figure 1.jpeg", "Figure_1.jpeg")),
                                 env$dest_dir, overwrite = TRUE),
  pattern = "Figure 1.jpeg -> .*/Figure_1.jpeg")

# Test: an empty manifest, or none, renders with a warning box -----------------
# The certificate is drafted before the manifest is filled in.
for (manifest in list(list(), NULL)) {
  empty_df <- NULL
  expect_warning(empty_df <- copy_manifest_files(tempdir(), list(manifest = manifest), tempdir()),
                 pattern = "codecheck.yml lists no manifest files")
  expect_equal(nrow(empty_df), 0L)
  expect_equal(names(empty_df), c("output", "comment", "dest", "size"))
  expect_warning(list_manifest_files(tempdir(), list(manifest = manifest), tempdir()),
                 pattern = "lists no manifest files")
}
invisible(knitr::knit_meta(clean = TRUE))
summary_text <- paste(capture.output(latex_summary_of_manifest(
  list(repository = "https://github.com/test/repo"), empty_df, tempdir())), collapse = "\n")
expect_true(grepl("\\fcolorbox{red}{yellow}", summary_text, fixed = TRUE))
expect_true(grepl("\\textbf{\\Large \\textcolor{red}{\\faExclamationTriangle} WARNING",
                  summary_text, fixed = TRUE))
expect_false(grepl("\u26a0", summary_text, fixed = TRUE),
             info = "the certificate fonts have no U+26A0 glyph, it renders as a blank")
# Declared to knitr too, for workspaces with an older preamble
expect_true("fontawesome5" %in% vapply(knitr::knit_meta(clean = TRUE), `[[`, "", "name"))
expect_true(grepl("No output files are listed in the manifest", summary_text, fixed = TRUE))
expect_false(grepl("longtable", summary_text, fixed = TRUE))
expect_false(grepl("\n\n}}", summary_text, fixed = TRUE), info = "no blank line in the box")
expect_false(grepl("\\\\\n}}", summary_text, fixed = TRUE), info = "no line break at the end of the box")
expect_equal(capture.output(render_manifest_files(empty_df, base_dir = NULL))[1],
             "The manifest lists no files.")

# Test: a single item with only a comment declares a check without output
# files: no warning and no box, the comment is shown instead
no_files_md <- list(manifest = list(list(comment = "Results are printed, 95% & more_1.")),
                    repository = "https://github.com/test/repo")
expect_silent(no_files_df <- copy_manifest_files(tempdir(), no_files_md, tempdir()))
expect_equal(nrow(no_files_df), 0L)
expect_silent(list_manifest_files(tempdir(), no_files_md, tempdir()))
no_files_text <- paste(capture.output(latex_summary_of_manifest(no_files_md, no_files_df,
                                                                tempdir())), collapse = "\n")
expect_false(grepl("WARNING", no_files_text, fixed = TRUE))
expect_true(grepl("\\textbf{No output files:} Results are printed, 95\\% \\& more\\_1.",
                  no_files_text, fixed = TRUE))
no_files_md_out <- capture.output(render_manifest_files(no_files_df, base_dir = NULL,
                                                         metadata = no_files_md))
expect_equal(no_files_md_out[1:3], c("```{=latex}", "Results are printed, 95\\% \\& more\\_1.", "```"))
# a blank file: is an entry not filled in yet, and a bare string no item
expect_error(list_manifest_files(tempdir(), list(manifest = list(
  list(file = "", comment = "Figure 2"))), tempdir()), pattern = "exactly one 'file'")
expect_error(list_manifest_files(tempdir(), list(manifest = "see stdout"), tempdir()),
             pattern = "exactly one 'file'")
# a comment-only item among files is still an error
expect_error(list_manifest_files(tempdir(), list(manifest = list(
  list(file = "a.txt"), list(comment = "only a comment"))), tempdir()),
  pattern = "exactly one 'file'")

# Test: a manifest item without the optional comment gets an empty one
no_comment_dir <- tempfile("no_comment_")
dir.create(file.path(no_comment_dir, "outputs"), recursive = TRUE)
writeLines("x", file.path(no_comment_dir, "a.txt"))
writeLines("y", file.path(no_comment_dir, "b.txt"))
no_comment_df <- copy_manifest_files(no_comment_dir,
  list(manifest = list(list(file = "a.txt", comment = "A"), list(file = "b.txt"))),
  file.path(no_comment_dir, "outputs"))
expect_equal(no_comment_df$comment, c("A", ""))
unlink(no_comment_dir, recursive = TRUE)

# Test: a manifest written as a single mapping is one item, and an item
# without exactly one file is named
single_df <- suppressWarnings(list_manifest_files(tempdir(),
  list(manifest = list(file = "a.txt", comment = "A")), tempdir()))
expect_equal(single_df$output, "a.txt")
expect_error(list_manifest_files(tempdir(), list(manifest = list(
  list(file = "a.txt"), list(comment = "no file"))), tempdir()),
  pattern = "manifest item\\(s\\) 2 .* exactly one 'file'")

# Clean up
unlink(file.path(tempdir(), "test_manifest"), recursive = TRUE)
