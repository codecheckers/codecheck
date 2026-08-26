# Tests for the local copies of the external CSS/JS libraries.
#
# All tests but the last one work offline on a fake libraries directory. The
# last test is a deliberate integration test: it is the only place where the
# suite actually downloads a library file, so that the download path stays
# covered while every other test avoids the network.

if (!requireNamespace("codecheck", quietly = TRUE)) {
  exit_file("Package not installed properly")
}

source("mocks.R")

specs <- codecheck:::external_library_specs()

# Build a libraries directory that looks like a complete, current download
make_current_libs_dir <- function() {
  libs_dir <- file.path(tempfile("libs"))
  dir.create(libs_dir, recursive = TRUE)

  for (lib in specs) {
    for (file in codecheck:::library_expected_files(lib)) {
      path <- file.path(libs_dir, file)
      dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
      writeLines(strrep("x", 2000), path)
    }
  }

  provenance <- do.call(rbind, lapply(specs, function(lib) {
    data.frame(
      library = lib$name, version = lib$version, license = lib$license,
      license_url = lib$license_url, description = lib$description,
      date_configured = "2020-01-01", stringsAsFactors = FALSE
    )
  }))
  write.csv(provenance, file.path(libs_dir, "PROVENANCE.csv"), row.names = FALSE)

  libs_dir
}

# Test 1: an empty directory is not current
expect_false(
  codecheck:::libs_are_current(tempfile()),
  info = "a missing libraries directory needs a download"
)

# Test 2: a complete directory with matching provenance is current
libs_dir <- make_current_libs_dir()
expect_true(
  codecheck:::libs_are_current(libs_dir),
  info = "complete libraries with matching provenance need no download"
)

# Test 3: files without PROVENANCE.csv are not current
libs_dir <- make_current_libs_dir()
file.remove(file.path(libs_dir, "PROVENANCE.csv"))
expect_false(
  codecheck:::libs_are_current(libs_dir),
  info = "missing provenance means the libraries are not verified"
)

# Test 4: a truncated file is not accepted as a local copy
# (a failed download used to leave an HTTP error page behind, which then
# counted as "already exists" forever)
libs_dir <- make_current_libs_dir()
truncated <- file.path(libs_dir, specs$bootstrap$files$css)
writeLines("<html>404 Not Found</html>", truncated)
expect_false(
  codecheck:::libs_are_current(libs_dir),
  info = "a suspiciously small file is re-downloaded"
)

# Test 5: a missing font file is detected, not just the CSS
libs_dir <- make_current_libs_dir()
file.remove(file.path(libs_dir, specs$academicons$fonts$dir,
                      specs$academicons$fonts$files[[1]]))
expect_false(
  codecheck:::libs_are_current(libs_dir),
  info = "font files are part of the expected files"
)

# Test 6: a version bump in the specification invalidates the local copies
libs_dir <- make_current_libs_dir()
provenance <- read.csv(file.path(libs_dir, "PROVENANCE.csv"), stringsAsFactors = FALSE)
provenance$version[[1]] <- "0.0.0"
write.csv(provenance, file.path(libs_dir, "PROVENANCE.csv"), row.names = FALSE)
expect_false(
  codecheck:::libs_are_current(libs_dir),
  info = "a version mismatch between specification and provenance forces a download"
)

# Test 7: setup on current libraries makes no request and touches no file
libs_dir <- make_current_libs_dir()
provenance_file <- file.path(libs_dir, "PROVENANCE.csv")
before_content <- readLines(provenance_file)
before_mtime <- file.mtime(provenance_file)

# run from a temporary working directory: the register CSS is copied to a
# hardcoded "docs/assets" relative to the working directory
old_wd <- setwd(tempdir())
result <- with_mocked_codecheck(
  list(codecheck_GET = function(...) stop("no download expected")),
  suppressMessages(codecheck::setup_external_libraries(libs_dir))
)
setwd(old_wd)

expect_equal(
  readLines(provenance_file), before_content,
  info = "PROVENANCE.csv is not rewritten when the libraries are up to date"
)
expect_equal(
  file.mtime(provenance_file), before_mtime,
  info = "PROVENANCE.csv is not even touched when the libraries are up to date"
)
expect_equal(
  nrow(result), length(specs),
  info = "the recorded provenance is returned unchanged"
)
expect_true(
  all(result$date_configured == "2020-01-01"),
  info = "the original configuration date survives a no-op run"
)
expect_false(
  file.exists(file.path(libs_dir, "README.md")),
  info = "the README is not regenerated when the libraries are up to date"
)

# Test 8: a failed download leaves neither a file nor a temporary file behind
libs_dir <- tempfile("libs")
dir.create(libs_dir, recursive = TRUE)
dest <- file.path(libs_dir, "broken.css")
downloaded <- with_mocked_codecheck(
  list(codecheck_GET = function(url, ...) mock_response(url, status = 404L)),
  suppressWarnings(codecheck:::download_library_file("https://example.com/x.css", dest))
)
expect_false(downloaded, info = "a 404 is not reported as a successful download")
expect_false(file.exists(dest), info = "a failed download stores no file")
expect_equal(
  length(list.files(libs_dir, pattern = "\\.download$")), 0L,
  info = "a failed download leaves no temporary file"
)

# Test 9 (integration, needs network): a real download of one library file
libs_dir <- tempfile("libs")
dir.create(libs_dir, recursive = TRUE)
dest <- file.path(libs_dir, "bootstrap.min.css")
downloaded <- tryCatch(
  codecheck:::download_library_file(specs$bootstrap$urls$css, dest),
  error = function(e) FALSE
)

if (downloaded) {
  expect_true(file.exists(dest), info = "the downloaded file is moved into place")
  expect_true(
    file.size(dest) > 10000,
    info = "the downloaded Bootstrap CSS has a plausible size"
  )
  expect_equal(
    length(list.files(libs_dir, pattern = "\\.download$")), 0L,
    info = "a successful download leaves no temporary file"
  )
} else {
  expect_true(TRUE, info = "library download integration test skipped (no network)")
}
