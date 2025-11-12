tinytest::using(ttdo)

# Load dependencies
suppressMessages({
  library(gh)
  library(R.cache)
})

# Test 1: get_codecheck_yml() - unsupported repository type ----
expect_error({
  codecheck::get_codecheck_yml("bitbucket::user/repo")
}, pattern = "Unsupported repository type")

# Test 2: get_codecheck_yml() - malformed specification (missing ::) ----
expect_error({
  codecheck::get_codecheck_yml("github-user-repo")
}, pattern = "Malformed repository specification")

# Test 3: get_codecheck_yml() - incomplete GitHub spec ----
expect_error({
  codecheck::get_codecheck_yml("github::justuser")
}, pattern = "Incomplete repo specification")

# Test 4: get_codecheck_yml() - incomplete GitHub spec (no org) ----
expect_error({
  codecheck::get_codecheck_yml("github::/repo")
}, pattern = "Incomplete repo specification|GitHub API error")

# Test 5: get_codecheck_yml() - warning for missing codecheck.yml on GitHub ----
expect_warning({
  result <- codecheck::get_codecheck_yml("github::codecheckers/register")
}, pattern = "codecheck.yml not found")
# Result should be NULL
expect_null(result)

# Test 6: get_codecheck_yml() - warning for missing codecheck.yml on OSF ----
expect_warning({
  result <- codecheck::get_codecheck_yml("osf::6K5FH")
}, pattern = "codecheck.yml not found")
expect_null(result)

# Test 7: get_codecheck_yml() - warning for missing codecheck.yml on GitLab ----
expect_warning({
  result <- codecheck::get_codecheck_yml("gitlab::nuest/sensebox-binder")
}, pattern = "codecheck.yml not found")
expect_null(result)

# Test 8: get_codecheck_yml() - warning for missing codecheck.yml on Zenodo ----
expect_warning({
  result <- codecheck::get_codecheck_yml("zenodo::8385350")
}, pattern = "codecheck.yml not found")
expect_null(result)

# Test 9: validate_codecheck_yml() - missing certificate ----
invalid_yaml_path <- system.file("tinytest", "yaml", "certificate_id_missing", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "codecheck.yml"))
}, pattern = "is missing or invalid")

# Test 10: validate_codecheck_yml() - invalid certificate pattern ----
invalid_yaml_path <- system.file("tinytest", "yaml", "certificate_id_invalid", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "codecheck1.yml"))
}, pattern = "is missing or invalid")

# Test 11: validate_codecheck_yml() - missing manifest ----
invalid_yaml_path <- system.file("tinytest", "yaml", "manifest_missing", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "codecheck.yml"))
}, pattern = "must have a root-level node 'manifest'")

# Test 12: validate_codecheck_yml() - invalid report DOI ----
invalid_yaml_path <- system.file("tinytest", "yaml", "report_doi_invalid", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "codecheck.yml"))
}, pattern = "not a valid DOI")

# Test 13: validate_codecheck_yml() - missing author name ----
invalid_yaml_path <- system.file("tinytest", "yaml", "author_name_missing", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "codecheck.yml"))
}, pattern = "must have a 'name'")

# Test 14: validate_codecheck_yml() - missing codechecker name ----
invalid_yaml_path <- system.file("tinytest", "yaml", "codechecker_name_missing", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "codecheck.yml"))
}, pattern = "must have a 'name'")

# Test 15: validate_codecheck_yml() - invalid ORCID format ----
invalid_yaml_path <- system.file("tinytest", "yaml", "orcids", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "invalid.yml"))
}, pattern = "author's ORCID")

# Test 16: validate_codecheck_yml() - invalid checker ORCID format ----
invalid_yaml_path <- system.file("tinytest", "yaml", "orcids", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "invalid_checker.yml"))
}, pattern = "checker's ORCID")

# Test 17: validate_codecheck_yml() - ORCID with URL prefix ----
invalid_yaml_path <- system.file("tinytest", "yaml", "orcids", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "with_url_prefix.yml"))
}, pattern = "author's ORCID.*https://orcid.org")

# Test 18: validate_codecheck_yml() - invalid repository URL ----
invalid_yaml_path <- system.file("tinytest", "yaml", "repository_url_invalid", package = "codecheck")
expect_error({
  codecheck::validate_codecheck_yml(file.path(invalid_yaml_path, "codecheck.yml"))
}, pattern = "URL returns error")

# Test 19: validate_codecheck_yml() - file doesn't exist ----
expect_error({
  codecheck::validate_codecheck_yml("/nonexistent/path/codecheck.yml")
}, pattern = "Could not load")

# Test 20: validate_codecheck_yml() - invalid input type ----
expect_error({
  codecheck::validate_codecheck_yml(12345)
}, pattern = "Could not load")

# Test 21: copy_manifest_files() - missing source files ----
test_dir <- file.path(tempdir(), "test_missing_manifest")
if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
dir.create(test_dir, recursive = TRUE)

test_metadata <- list(
  manifest = list(
    list(file = "nonexistent1.txt", comment = "Missing file 1"),
    list(file = "nonexistent2.txt", comment = "Missing file 2")
  )
)

# Changed from expect_error to expect_warning - graceful handling now warns instead of stopping
expect_warning({
  dest_dir <- file.path(test_dir, "outputs")
  dir.create(dest_dir, recursive = TRUE)
  result <- codecheck::copy_manifest_files(test_dir, test_metadata, dest_dir)
}, pattern = "Manifest files missing")

# Verify that function returns data frame with missing files marked
expect_true(is.data.frame(result))
expect_equal(nrow(result), 2)
expect_true(all(is.na(result$size)))  # Both files should have NA size

unlink(test_dir, recursive = TRUE)

# Test 22: codecheck_metadata() - missing codecheck.yml ----
test_dir <- file.path(tempdir(), "test_no_yaml")
if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
dir.create(test_dir, recursive = TRUE)

expect_error({
  codecheck::codecheck_metadata(test_dir)
}, pattern = "No codecheck.yml file found")
unlink(test_dir, recursive = TRUE)

# Test 23: get_zenodo_id() - various invalid inputs ----
invalid_dois <- c(
  "",
  "not a doi",
  "https://example.com",
  "10.5281/zenodo.short",
  "https://doi.org/10.1234/notzenodo"
)

for (invalid_doi in invalid_dois) {
  expect_silent({
    result <- codecheck::get_zenodo_id(invalid_doi)
  })
  expect_true(is.na(result), info = paste("Failed for:", invalid_doi))
}

# Test 24: parse_repository_spec() - empty string ----
expect_error({
  # This is an internal function, but we can test through get_codecheck_yml
  codecheck::get_codecheck_yml("")
}, pattern = "Malformed|Unsupported")

# Test 25: register_check() - certificate mismatch ----
bad_register <- data.frame(
  Certificate = c("9999-999"),  # Wrong ID
  Repository = c("zenodo-sandbox::145250"),  # Has 2024-111
  Type = c("community"),
  Venue = c("test"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

expect_error({
  suppressMessages({
    codecheck::register_check(bad_register, from = 1, to = 1)
  })
}, pattern = "Certificate mismatch")

# Test 26: Edge case - very long certificate ID ----
long_cert_metadata <- list(
  certificate = "2024-001-EXTRA-LONG-ID-THAT-IS-INVALID",
  manifest = list(list(file = "test.txt", comment = "test")),
  paper = list(
    title = "Test",
    authors = list(list(name = "Test Author")),
    reference = "https://example.com"
  ),
  codechecker = list(list(name = "Test Checker")),
  check_time = "2024-01-01 10:00:00",
  report = "https://doi.org/10.5281/zenodo.1234567",
  repository = "https://github.com/codecheckers/register"  # Use real repo
)

expect_error({
  codecheck::validate_codecheck_yml(long_cert_metadata)
}, pattern = "is missing or invalid")

# Test 27: Edge case - certificate ID with wrong format ----
wrong_format_metadata <- list(
  certificate = "2024/001",  # Should be 2024-001
  manifest = list(list(file = "test.txt", comment = "test")),
  paper = list(
    title = "Test",
    authors = list(list(name = "Test Author")),
    reference = "https://example.com"
  ),
  codechecker = list(list(name = "Test Checker")),
  check_time = "2024-01-01 10:00:00",
  report = "https://doi.org/10.5281/zenodo.1234567",
  repository = "https://github.com/codecheckers/register"  # Use real repo
)

expect_error({
  codecheck::validate_codecheck_yml(wrong_format_metadata)
}, pattern = "is missing or invalid")

# Test 28: Empty manifest list ----
empty_manifest_metadata <- list(
  certificate = "2024-001",
  manifest = list(),  # Empty manifest
  paper = list(
    title = "Test",
    authors = list(list(name = "Test Author")),
    reference = "https://example.com"
  ),
  codechecker = list(list(name = "Test Checker")),
  check_time = "2024-01-01 10:00:00",
  report = "https://doi.org/10.5281/zenodo.1234567",
  repository = "https://github.com/codecheckers/register"  # Use real repo
)

# Empty manifest is technically valid per spec, but may cause issues
expect_silent({
  result <- codecheck::validate_codecheck_yml(empty_manifest_metadata)
})
expect_true(result)

# Test 29: Manifest item without file field ----
no_file_manifest_metadata <- list(
  certificate = "2024-001",
  manifest = list(
    list(comment = "No file field")
  ),
  paper = list(
    title = "Test",
    authors = list(list(name = "Test Author")),
    reference = "https://example.com"
  ),
  codechecker = list(list(name = "Test Checker")),
  check_time = "2024-01-01 10:00:00",
  report = "https://doi.org/10.5281/zenodo.1234567",
  repository = "https://github.com/codecheckers/register"
)

expect_error({
  codecheck::validate_codecheck_yml(no_file_manifest_metadata)
}, pattern = "file")

# Test 30: Author without name ----
no_author_name_metadata <- list(
  certificate = "2024-001",
  manifest = list(list(file = "test.txt", comment = "test")),
  paper = list(
    title = "Test",
    authors = list(list(ORCID = "0000-0001-2345-6789")),  # No name
    reference = "https://example.com"
  ),
  codechecker = list(list(name = "Test Checker")),
  check_time = "2024-01-01 10:00:00",
  report = "https://doi.org/10.5281/zenodo.1234567",
  repository = "https://github.com/codecheckers/register"
)

expect_error({
  codecheck::validate_codecheck_yml(no_author_name_metadata)
}, pattern = "must have a 'name'")

# Clean up
test_dirs <- list.files(tempdir(), pattern = "^test_(missing|no_)", full.names = TRUE)
for (d in test_dirs) {
  if (dir.exists(d)) unlink(d, recursive = TRUE)
}
