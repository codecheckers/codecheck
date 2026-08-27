tinytest::using(ttdo)

# Integration test: actually renders codecheck.qmd to a PDF with the Quarto
# CLI, exercising the dynamic-title metadata block and the demo R/Python/
# Julia chunks end to end. Requires the external `quarto` binary and a
# working (tinytex-based) LaTeX install, so this is skipped wherever those
# are not available (e.g. plain R CI).
if (Sys.which("quarto") == "") {
  exit_file("quarto not installed - skipping codecheck.qmd render test")
}

local({
  test_dir <- file.path(tempdir(), "test_render_qmd_workspace")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir)
  old_wd <- getwd()
  on.exit({setwd(old_wd); unlink(test_dir, recursive = TRUE)})
  setwd(test_dir)

  codecheck::create_codecheck_files(template = "qmd")

  cert_dir <- file.path(test_dir, "codecheck")
  setwd(cert_dir)
  result <- system2("quarto", c("render", "codecheck.qmd", "--to", "pdf"),
                     stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    cat(result, sep = "\n")
  }

  expect_true(file.exists(file.path(cert_dir, "codecheck.pdf")),
              info = paste(result, collapse = "\n"))
})
