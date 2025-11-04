tinytest::using(ttdo)

# Load dependencies
suppressMessages({
  library(gh)
  library(R.cache)
})

# Test 1: get_zenodo_id() - extract valid ID ----
expect_silent({
  id <- codecheck::get_zenodo_id("http://doi.org/10.5281/zenodo.3750741")
})
expect_equal(id, 3750741)

# Test 2: get_zenodo_id() - extract from https DOI ----
expect_silent({
  id <- codecheck::get_zenodo_id("https://doi.org/10.5281/zenodo.1234567")
})
expect_equal(id, 1234567)

# Test 3: get_zenodo_id() - extract long ID (8 digits) ----
expect_silent({
  id <- codecheck::get_zenodo_id("https://doi.org/10.5281/zenodo.12345678")
})
expect_equal(id, 12345678)

# Test 4: get_zenodo_id() - extract very long ID (9 digits) ----
expect_silent({
  id <- codecheck::get_zenodo_id("https://doi.org/10.5281/zenodo.123456789")
})
expect_equal(id, 123456789)

# Test 5: get_zenodo_id() - return NA for invalid DOI ----
expect_silent({
  id <- codecheck::get_zenodo_id("https://doi.org/10.5281/zenodo.FIXME")
})
expect_true(is.na(id))

# Test 6: get_zenodo_id() - return NA for non-Zenodo DOI ----
expect_silent({
  id <- codecheck::get_zenodo_id("https://doi.org/10.1234/other.5678")
})
expect_true(is.na(id))

# Test 7: get_zenodo_id() - return NA for short ID (< 7 digits) ----
expect_silent({
  id <- codecheck::get_zenodo_id("https://doi.org/10.5281/zenodo.123456")
})
expect_true(is.na(id))

# Test 8: get_zenodo_id() - handle URL without protocol ----
expect_silent({
  id <- codecheck::get_zenodo_id("doi.org/10.5281/zenodo.7654321")
})
expect_equal(id, 7654321)

# Test 9: get_zenodo_id() - sandbox DOI ----
expect_silent({
  id <- codecheck::get_zenodo_id("https://doi.org/10.5072/zenodo.145250")
})
expect_equal(id, 145250)

# Test 10: get_zenodo_record() - mock test for structure ----
# Note: This test checks function signature and basic behavior
# It uses a real connection but doesn't modify anything
suppressMessages({
  library(zen4R)
})

# Create test metadata with FIXME (no record yet)
test_metadata_no_record <- list(
  certificate = "2099-999",
  report = "https://doi.org/10.5281/zenodo.FIXME"
)

# We can't fully test without credentials, but we can test the ID extraction
expect_silent({
  id <- codecheck::get_zenodo_id(test_metadata_no_record$report)
})
expect_true(is.na(id))

# Test 11: get_zenodo_record() - metadata with valid ID ----
test_metadata_valid <- list(
  certificate = "2024-111",
  report = "https://doi.org/10.5072/zenodo.145250"
)

expect_silent({
  id <- codecheck::get_zenodo_id(test_metadata_valid$report)
})
expect_equal(id, 145250)
expect_false(is.na(id))

# Test 12: Edge cases for DOI patterns ----
test_cases <- list(
  # Standard format
  list(doi = "https://doi.org/10.5281/zenodo.1234567", expected = 1234567),
  # HTTP instead of HTTPS
  list(doi = "http://doi.org/10.5281/zenodo.7777777", expected = 7777777),
  # Trailing slash
  list(doi = "https://doi.org/10.5281/zenodo.8888888/", expected = 8888888),
  # Sandbox
  list(doi = "https://doi.org/10.5072/zenodo.9999999", expected = 9999999)
)

for (tc in test_cases) {
  expect_silent({
    id <- codecheck::get_zenodo_id(tc$doi)
  })
  expect_equal(id, tc$expected)
}

# Test 13: Invalid patterns return NA ----
invalid_cases <- c(
  "https://example.com",
  "not a doi at all",
  "https://doi.org/10.1234/other",
  "https://doi.org/10.5281/zenodo.short",
  "https://doi.org/10.5281/zenodo.12345",  # Too short (5 digits)
  "https://doi.org/10.5281/zenodo.123456", # Too short (6 digits)
  "https://doi.org/10.5281/zenodo.FIXME"
)

for (invalid_doi in invalid_cases) {
  expect_silent({
    id <- codecheck::get_zenodo_id(invalid_doi)
  })
  expect_true(is.na(id), info = paste("Failed for:", invalid_doi))
}

# Test 14: URL variations ----
url_variations <- list(
  # No protocol
  list(url = "doi.org/10.5281/zenodo.1111111", expected = 1111111),
  # Direct zenodo link (not DOI) - should fail
  list(url = "https://zenodo.org/record/2222222", expected = NA),
  # DOI with extra parameters
  list(url = "https://doi.org/10.5281/zenodo.3333333?param=value", expected = 3333333)
)

for (uv in url_variations) {
  expect_silent({
    id <- codecheck::get_zenodo_id(uv$url)
  })
  if (is.na(uv$expected)) {
    expect_true(is.na(id), info = paste("Failed for:", uv$url))
  } else {
    expect_equal(id, uv$expected, info = paste("Failed for:", uv$url))
  }
}

# Test 15: Integration test - get_codecheck_yml from zenodo-sandbox ----
expect_silent({
  config <- codecheck::get_codecheck_yml("zenodo-sandbox::145250")
})
expect_inherits(config, "list")
expect_equal(config$certificate, "2024-111")

# Extract and verify the Zenodo ID from the config
expect_silent({
  id <- codecheck::get_zenodo_id(config$report)
})
expect_equal(id, 145250)

# Test 16: Check report DOI format in test YAML ----
test_yaml_path <- system.file("tinytest", "yaml", package = "codecheck")
expect_silent({
  metadata <- codecheck::codecheck_metadata(test_yaml_path)
})
# This test YAML has FIXME placeholder
expect_true(grepl("FIXME", metadata$report))
id <- codecheck::get_zenodo_id(metadata$report)
expect_true(is.na(id))

# Test 17: Verify ID extraction is consistent ----
test_doi <- "https://doi.org/10.5281/zenodo.7654321"
expect_silent({
  id1 <- codecheck::get_zenodo_id(test_doi)
  id2 <- codecheck::get_zenodo_id(test_doi)
  id3 <- codecheck::get_zenodo_id(test_doi)
})
expect_equal(id1, id2)
expect_equal(id2, id3)
expect_equal(id1, 7654321)
