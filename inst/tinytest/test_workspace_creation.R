tinytest::using(ttdo)

# Test 1: create_codecheck_files() - basic functionality ----
expect_silent({
  test_dir <- file.path(tempdir(), "test_create_workspace")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir)
  old_wd <- getwd()
  setwd(test_dir)
  codecheck::create_codecheck_files()
  setwd(old_wd)
})
expect_true(file.exists(file.path(test_dir, "codecheck.yml")))
expect_true(dir.exists(file.path(test_dir, "codecheck")))
unlink(test_dir, recursive = TRUE)

# Test 2: create_codecheck_files() - codecheck.yml content ----
expect_silent({
  test_dir <- file.path(tempdir(), "test_create_workspace2")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir)
  old_wd <- getwd()
  setwd(test_dir)
  codecheck::create_codecheck_files()
  setwd(old_wd)
})
yml_content <- readLines(file.path(test_dir, "codecheck.yml"))
expect_true(length(yml_content) > 0)
expect_true(any(grepl("^version:", yml_content)))
expect_true(any(grepl("^paper:", yml_content)))
expect_true(any(grepl("^manifest:", yml_content)))
unlink(test_dir, recursive = TRUE)

# Test 3: create_codecheck_files() - codecheck folder created ----
expect_silent({
  test_dir <- file.path(tempdir(), "test_create_workspace3")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir)
  old_wd <- getwd()
  setwd(test_dir)
  codecheck::create_codecheck_files()
  setwd(old_wd)
})
expect_true(dir.exists(file.path(test_dir, "codecheck")))
# Check for common files in codecheck folder
files <- list.files(file.path(test_dir, "codecheck"))
expect_true(length(files) > 0)
unlink(test_dir, recursive = TRUE)

# Test 4: create_codecheck_files() - warning when codecheck.yml exists ----
expect_warning({
  test_dir <- file.path(tempdir(), "test_create_workspace4")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir)
  old_wd <- getwd()
  setwd(test_dir)
  # Create first time
  codecheck::create_codecheck_files()
  # Try to create again
  codecheck::create_codecheck_files()
  setwd(old_wd)
}, pattern = "codecheck.yml already exists")
unlink(test_dir, recursive = TRUE)

# Test 5: create_codecheck_files() - error when codecheck folder exists ----
expect_error({
  test_dir <- file.path(tempdir(), "test_create_workspace5")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir)
  old_wd <- getwd()
  setwd(test_dir)
  # Remove codecheck.yml but keep codecheck folder
  codecheck::create_codecheck_files()
  file.remove("codecheck.yml")
  # Try to create again - should error on existing folder
  codecheck::create_codecheck_files()
  setwd(old_wd)
}, pattern = "codecheck folder exists")
unlink(test_dir, recursive = TRUE)

# Test 6: codecheck_metadata() - read from current directory ----
expect_silent({
  test_dir <- file.path(tempdir(), "test_metadata1")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir)
  old_wd <- getwd()
  setwd(test_dir)
  codecheck::create_codecheck_files()
  metadata <- codecheck::codecheck_metadata()
  setwd(old_wd)
})
expect_inherits(metadata, "list")
expect_true("paper" %in% names(metadata))
expect_true("manifest" %in% names(metadata))
expect_true("codechecker" %in% names(metadata))
unlink(test_dir, recursive = TRUE)

# Test 7: codecheck_metadata() - read from specified directory ----
expect_silent({
  test_dir <- file.path(tempdir(), "test_metadata2")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir)
  old_wd <- getwd()
  setwd(test_dir)
  codecheck::create_codecheck_files()
  setwd(old_wd)
  # Read from specified directory
  metadata <- codecheck::codecheck_metadata(test_dir)
})
expect_inherits(metadata, "list")
expect_true("paper" %in% names(metadata))
unlink(test_dir, recursive = TRUE)

# Test 8: codecheck_metadata() - read test yaml ----
test_yaml_path <- system.file("tinytest", "yaml", package = "codecheck")
expect_silent({
  metadata <- codecheck::codecheck_metadata(test_yaml_path)
})
expect_inherits(metadata, "list")
expect_equal(metadata$certificate, "2020-000")
expect_equal(metadata$paper$title, "The principal components of natural images")

# Test 9: codecheck_metadata() - verify structure ----
test_yaml_path <- system.file("tinytest", "yaml", package = "codecheck")
expect_silent({
  metadata <- codecheck::codecheck_metadata(test_yaml_path)
})
expect_inherits(metadata$paper, "list")
expect_inherits(metadata$paper$authors, "list")
expect_inherits(metadata$manifest, "list")
expect_inherits(metadata$codechecker, "list")

# Test 10: codecheck_metadata() - error on missing file ----
expect_error({
  test_dir <- file.path(tempdir(), "test_metadata_missing")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir)
  # Try to read from directory without codecheck.yml
  metadata <- codecheck::codecheck_metadata(test_dir)
  unlink(test_dir, recursive = TRUE)
}, pattern = "No such file")

# Clean up any remaining test directories
test_dirs <- list.files(tempdir(), pattern = "^test_(create_workspace|metadata)", full.names = TRUE)
for (d in test_dirs) {
  if (dir.exists(d)) unlink(d, recursive = TRUE)
}
