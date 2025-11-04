tinytest::using(ttdo)

# Load dependencies
suppressMessages({
  library(httr)
  library(yaml)
})

# Test get_lifecycle_metadata with full DOI (using a known valid DOI)
# This tests the real API call
meta <- NULL
expect_silent(meta <- codecheck::get_lifecycle_metadata("10.71240/lcyc.355146"))
expect_true("title" %in% names(meta))
expect_true("authors" %in% names(meta))
expect_true("reference" %in% names(meta))
expect_equal(meta$reference, "https://doi.org/10.71240/lcyc.355146")
expect_true(length(meta$authors) > 0)
expect_true("name" %in% names(meta$authors[[1]]))
# Check ORCID is present for at least one author
has_orcid <- any(sapply(meta$authors, function(a) !is.null(a$ORCID)))
expect_true(has_orcid)

# Test get_lifecycle_metadata with another valid DOI
meta2 <- NULL
expect_silent(meta2 <- codecheck::get_lifecycle_metadata("10.71240/lcyc.052239"))
expect_equal(meta2$reference, "https://doi.org/10.71240/lcyc.052239")
expect_true(!is.null(meta2$title))

# Test error handling for invalid identifier
expect_error(
  codecheck::get_lifecycle_metadata("10.1234/invalid"),
  pattern = "Identifier must be either a Lifecycle Journal submission ID"
)

# Test error handling for non-existent DOI
expect_error(
  codecheck::get_lifecycle_metadata("10.71240/lcyc.999999999"),
  pattern = "Failed to retrieve metadata from CrossRef"
)

# Test update_codecheck_yml_from_lifecycle with a temporary file
# Create a temporary codecheck.yml with placeholder content
temp_dir <- tempdir()
temp_yml <- file.path(temp_dir, "test_codecheck.yml")

# Create test YAML content with placeholders
test_yaml <- list(
  version = "https://codecheck.org.uk/spec/config/1.0",
  paper = list(
    title = "FIXME: Add title",
    authors = list(
      list(name = "Test Author", ORCID = "0000-0000-0000-0000")
    ),
    reference = "http://example.com/FIXME"
  ),
  manifest = list(
    list(file = "figure1.png", comment = "Test figure")
  ),
  codechecker = list(
    list(name = "Test Checker", ORCID = "0000-0000-0000-0001")
  ),
  summary = "Test summary",
  repository = "https://github.com/test/repo",
  check_time = "2024-01-01 12:00:00",
  certificate = "2024-001",
  report = "https://doi.org/10.5281/zenodo.FIXME"
)

yaml::write_yaml(test_yaml, temp_yml)

# Test preview mode (default - should not modify file)
expect_silent(result <- codecheck::update_codecheck_yml_from_lifecycle(
  "10.71240/lcyc.355146",
  yml_file = temp_yml,
  apply_updates = FALSE
))

# Read the file - should still have FIXME in title
temp_content <- yaml::read_yaml(temp_yml)
expect_true(grepl("FIXME", temp_content$paper$title))

# Test apply mode (should modify file)
expect_silent(result2 <- codecheck::update_codecheck_yml_from_lifecycle(
  "10.71240/lcyc.355146",
  yml_file = temp_yml,
  apply_updates = TRUE
))

# Read the file - should now have real title
temp_content2 <- yaml::read_yaml(temp_yml)
expect_false(grepl("FIXME", temp_content2$paper$title))
expect_true(!is.null(temp_content2$paper$title))
expect_true(nchar(temp_content2$paper$title) > 0)

# Test that non-placeholder fields are not overwritten by default
yaml::write_yaml(list(
  version = "https://codecheck.org.uk/spec/config/1.0",
  paper = list(
    title = "My Custom Title",
    authors = list(list(name = "Real Author")),
    reference = "https://doi.org/10.1234/realref"
  ),
  manifest = list(),
  codechecker = list(),
  summary = "",
  repository = "",
  check_time = "",
  certificate = "",
  report = ""
), temp_yml)

expect_silent(result3 <- codecheck::update_codecheck_yml_from_lifecycle(
  "10.71240/lcyc.052239",
  yml_file = temp_yml,
  apply_updates = TRUE,
  overwrite_existing = FALSE
))

# Read the file - should still have custom title
temp_content3 <- yaml::read_yaml(temp_yml)
expect_equal(temp_content3$paper$title, "My Custom Title")

# Test overwrite_existing = TRUE
expect_silent(result4 <- codecheck::update_codecheck_yml_from_lifecycle(
  "10.71240/lcyc.052239",
  yml_file = temp_yml,
  apply_updates = TRUE,
  overwrite_existing = TRUE
))

# Read the file - should now have Lifecycle title
temp_content4 <- yaml::read_yaml(temp_yml)
expect_false(temp_content4$paper$title == "My Custom Title")

# Test error when file doesn't exist
nonexistent_file <- file.path(temp_dir, "nonexistent.yml")
expect_error(
  codecheck::update_codecheck_yml_from_lifecycle("10.71240/lcyc.355146", yml_file = nonexistent_file),
  pattern = "codecheck.yml file not found"
)

# Clean up
unlink(temp_yml)
