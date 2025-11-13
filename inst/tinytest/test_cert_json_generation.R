# Test certificate JSON generation

# Setup
library(codecheck)

# Create temporary directory for test output
test_output_dir <- file.path(tempdir(), "codecheck_test_cert_json")
if (dir.exists(test_output_dir)) {
  unlink(test_output_dir, recursive = TRUE)
}
dir.create(test_output_dir, recursive = TRUE)

# Save original CONFIG values
original_certs_dir <- CONFIG$CERTS_DIR[["cert"]]

# Set CONFIG to use test directory
CONFIG$CERTS_DIR[["cert"]] <- test_output_dir

# Test with a known certificate from the register
test_cert_id <- "2020-001"
test_repo <- "github::codecheckers/Piccolo-2020"
test_type <- "community"
test_venue <- "CODECHECK"

# Create certificate directory
cert_dir <- file.path(test_output_dir, test_cert_id)
dir.create(cert_dir, recursive = TRUE)

# Test 1: JSON file is created
expect_silent(
  generate_cert_json(test_cert_id, test_repo, test_type, test_venue)
)

json_path <- file.path(cert_dir, "index.json")
expect_true(
  file.exists(json_path),
  info = "index.json file should be created"
)

# Test 2: JSON file is valid and readable
json_data <- tryCatch({
  jsonlite::read_json(json_path)
}, error = function(e) {
  NULL
})

expect_false(
  is.null(json_data),
  info = "JSON file should be valid and readable"
)

# Test 3: JSON structure contains expected top-level fields
expect_true(
  "certificate" %in% names(json_data),
  info = "JSON should contain 'certificate' field"
)

expect_true(
  "paper" %in% names(json_data),
  info = "JSON should contain 'paper' field"
)

expect_true(
  "codecheck" %in% names(json_data),
  info = "JSON should contain 'codecheck' field"
)

# Test 4: Certificate field structure
expect_true(
  "id" %in% names(json_data$certificate),
  info = "Certificate should have 'id' field"
)

expect_true(
  "url" %in% names(json_data$certificate),
  info = "Certificate should have 'url' field"
)

# Test 5: Paper field structure
expect_true(
  "title" %in% names(json_data$paper),
  info = "Paper should have 'title' field"
)

expect_true(
  "authors" %in% names(json_data$paper),
  info = "Paper should have 'authors' field"
)

expect_true(
  "reference" %in% names(json_data$paper),
  info = "Paper should have 'reference' field"
)

# Test 6: Authors is a list
expect_true(
  is.list(json_data$paper$authors),
  info = "Authors should be a list"
)

# Test 7: CODECHECK field structure
expect_true(
  "codecheckers" %in% names(json_data$codecheck),
  info = "CODECHECK should have 'codecheckers' field"
)

expect_true(
  "check_time" %in% names(json_data$codecheck),
  info = "CODECHECK should have 'check_time' field"
)

expect_true(
  "repository" %in% names(json_data$codecheck),
  info = "CODECHECK should have 'repository' field"
)

expect_true(
  "report" %in% names(json_data$codecheck),
  info = "CODECHECK should have 'report' field"
)

expect_true(
  "type" %in% names(json_data$codecheck),
  info = "CODECHECK should have 'type' field"
)

expect_true(
  "venue" %in% names(json_data$codecheck),
  info = "CODECHECK should have 'venue' field"
)

# Test 8: Type and venue values match input
expect_equal(
  json_data$codecheck$type,
  test_type,
  info = "Type should match input value"
)

expect_equal(
  json_data$codecheck$venue,
  test_venue,
  info = "Venue should match input value"
)

# Test 9: Repository value matches input
expect_equal(
  json_data$codecheck$repository,
  test_repo,
  info = "Repository should match input value"
)

# Test 10: Codecheckers is a list
expect_true(
  is.list(json_data$codecheck$codecheckers),
  info = "Codecheckers should be a list"
)

# Test 11: Codecheckers have required fields
if (length(json_data$codecheck$codecheckers) > 0) {
  first_checker <- json_data$codecheck$codecheckers[[1]]
  expect_true(
    "name" %in% names(first_checker),
    info = "Codechecker should have 'name' field"
  )
}

# Cleanup
CONFIG$CERTS_DIR[["cert"]] <- original_certs_dir
unlink(test_output_dir, recursive = TRUE)
