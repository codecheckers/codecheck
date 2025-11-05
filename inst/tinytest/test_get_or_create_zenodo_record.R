# Tests for get_or_create_zenodo_record() with automatic YAML updating
# Tests various scenarios for updating codecheck.yml with Zenodo DOI

library(tinytest)

# Helper function to create mock Zenodo manager
create_mock_zenodo_manager <- function() {
  zen <- new.env(parent = emptyenv())

  zen$next_record_id <- 1000000  # Start with 7-digit ID

  zen$getDepositionById <- function(id) {
    # Mock: return a record with the given ID
    record <- new.env(parent = emptyenv())
    record$id <- id
    record$metadata <- list(
      doi = paste0("10.5281/zenodo.", id),
      title = "Mock Record"
    )
    record$links <- list(
      self_html = paste0("https://zenodo.org/deposit/", id)
    )
    return(record)
  }

  zen$createEmptyRecord <- function() {
    # Mock: create a new record with prereserved DOI
    zen$next_record_id <- zen$next_record_id + 1
    record_id <- zen$next_record_id

    record <- new.env(parent = emptyenv())
    record$id <- record_id
    record$metadata <- list(
      prereserve_doi = list(
        doi = paste0("10.5281/zenodo.", record_id)
      )
    )
    record$links <- list(
      self_html = paste0("https://zenodo.org/deposit/", record_id)
    )
    return(record)
  }

  return(zen)
}

# Helper function to create test codecheck.yml
create_test_yml <- function(dir, report_value = "https://doi.org/10.5281/zenodo.FIXME") {
  yml_content <- list(
    certificate = "2024-001",
    summary = "Test summary",
    paper = list(
      title = "Test Paper",
      authors = list(
        list(name = "Test Author")
      ),
      reference = "https://doi.org/10.1234/test"
    ),
    codechecker = list(
      list(name = "Test Checker", ORCID = "0000-0001-2345-6789")
    ),
    repository = "https://github.com/test/repo",
    check_time = "2024-01-15 10:00:00",
    report = report_value,
    manifest = list(
      list(file = "output.pdf", comment = "Test output")
    )
  )

  yml_path <- file.path(dir, "codecheck.yml")
  yaml::write_yaml(yml_content, yml_path)
  return(yml_path)
}

# Test 1: Existing valid Zenodo ID - retrieves record without updating ----
test_dir1 <- file.path(tempdir(), "test_zenodo_1")
dir.create(test_dir1, showWarnings = FALSE, recursive = TRUE)

yml_path1 <- create_test_yml(test_dir1, "https://doi.org/10.5281/zenodo.1234567")
metadata1 <- codecheck::codecheck_metadata(test_dir1)

mock_zen1 <- create_mock_zenodo_manager()

# Should retrieve existing record
result1 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen1, metadata1, warn = FALSE, yml_file = yml_path1)
)

expect_equal(result1$id, 1234567, info = "Should retrieve existing record")

# YAML should not change
metadata1_after <- codecheck::codecheck_metadata(test_dir1)
expect_equal(metadata1_after$report, "https://doi.org/10.5281/zenodo.1234567",
             info = "Existing valid DOI should not be changed")

unlink(test_dir1, recursive = TRUE)

# Test 2: Empty report field - creates record and updates YAML automatically ----
test_dir2 <- file.path(tempdir(), "test_zenodo_2")
dir.create(test_dir2, showWarnings = FALSE, recursive = TRUE)

yml_path2 <- create_test_yml(test_dir2, "")
metadata2 <- codecheck::codecheck_metadata(test_dir2)

mock_zen2 <- create_mock_zenodo_manager()

# Should create record and update YAML
result2 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen2, metadata2, warn = FALSE, yml_file = yml_path2)
)

expect_true(!is.null(result2$id), info = "Should create new record")
expect_true(result2$id >= 1000000, info = "Should have valid record ID")

# YAML should be updated
metadata2_after <- codecheck::codecheck_metadata(test_dir2)
expected_doi2 <- paste0("https://doi.org/", result2$metadata$prereserve_doi$doi)
expect_equal(metadata2_after$report, expected_doi2,
             info = "Empty report field should be updated with new DOI")

unlink(test_dir2, recursive = TRUE)

# Test 3: Placeholder report field (FIXME) - updates automatically ----
test_dir3 <- file.path(tempdir(), "test_zenodo_3")
dir.create(test_dir3, showWarnings = FALSE, recursive = TRUE)

yml_path3 <- create_test_yml(test_dir3, "https://doi.org/10.5281/zenodo.FIXME")
metadata3 <- codecheck::codecheck_metadata(test_dir3)

mock_zen3 <- create_mock_zenodo_manager()

result3 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen3, metadata3, warn = FALSE, yml_file = yml_path3)
)

expect_true(!is.null(result3$id), info = "Should create new record")

# YAML should be updated
metadata3_after <- codecheck::codecheck_metadata(test_dir3)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata3_after$report),
            info = "Placeholder should be replaced with new DOI")
expect_false(grepl("FIXME", metadata3_after$report),
             info = "FIXME should be removed")

unlink(test_dir3, recursive = TRUE)

# Test 4: Placeholder report field (TODO) - updates automatically ----
test_dir4 <- file.path(tempdir(), "test_zenodo_4")
dir.create(test_dir4, showWarnings = FALSE, recursive = TRUE)

yml_path4 <- create_test_yml(test_dir4, "TODO: add DOI")
metadata4 <- codecheck::codecheck_metadata(test_dir4)

mock_zen4 <- create_mock_zenodo_manager()

result4 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen4, metadata4, warn = FALSE, yml_file = yml_path4)
)

metadata4_after <- codecheck::codecheck_metadata(test_dir4)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata4_after$report),
            info = "TODO placeholder should be replaced with new DOI")

unlink(test_dir4, recursive = TRUE)

# Test 5: Placeholder report field (XXXXX) - updates automatically ----
test_dir5 <- file.path(tempdir(), "test_zenodo_5")
dir.create(test_dir5, showWarnings = FALSE, recursive = TRUE)

yml_path5 <- create_test_yml(test_dir5, "https://doi.org/10.XXXXX/zenodo.12345")
metadata5 <- codecheck::codecheck_metadata(test_dir5)

mock_zen5 <- create_mock_zenodo_manager()

result5 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen5, metadata5, warn = FALSE, yml_file = yml_path5)
)

metadata5_after <- codecheck::codecheck_metadata(test_dir5)
expect_false(grepl("XXXXX", metadata5_after$report),
             info = "XXXXX placeholder should be replaced")

unlink(test_dir5, recursive = TRUE)

# Test 6: Non-placeholder existing value with warn=FALSE - does not overwrite ----
test_dir6 <- file.path(tempdir(), "test_zenodo_6")
dir.create(test_dir6, showWarnings = FALSE, recursive = TRUE)

existing_doi6 <- "https://doi.org/10.17605/OSF.IO/ABC12"
yml_path6 <- create_test_yml(test_dir6, existing_doi6)
metadata6 <- codecheck::codecheck_metadata(test_dir6)

mock_zen6 <- create_mock_zenodo_manager()

# Should create record but NOT update YAML (warn=FALSE means no interactive prompt)
expect_warning(
  result6 <- codecheck::get_or_create_zenodo_record(mock_zen6, metadata6, warn = FALSE, yml_file = yml_path6),
  pattern = "Not updating automatically"
)

# YAML should NOT be changed
metadata6_after <- codecheck::codecheck_metadata(test_dir6)
expect_equal(metadata6_after$report, existing_doi6,
             info = "Non-placeholder value should not be overwritten when warn=FALSE")

unlink(test_dir6, recursive = TRUE)

# Test 7: NULL report field - updates automatically ----
test_dir7 <- file.path(tempdir(), "test_zenodo_7")
dir.create(test_dir7, showWarnings = FALSE, recursive = TRUE)

# Create YAML without report field
yml_content7 <- list(
  certificate = "2024-001",
  paper = list(title = "Test"),
  codechecker = list(list(name = "Test Checker")),
  check_time = "2024-01-15 10:00:00"
)
yml_path7 <- file.path(test_dir7, "codecheck.yml")
yaml::write_yaml(yml_content7, yml_path7)

metadata7 <- codecheck::codecheck_metadata(test_dir7)
mock_zen7 <- create_mock_zenodo_manager()

result7 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen7, metadata7, warn = FALSE, yml_file = yml_path7)
)

# YAML should be updated with report field
metadata7_after <- codecheck::codecheck_metadata(test_dir7)
expect_true(!is.null(metadata7_after$report), info = "Report field should be added")
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata7_after$report),
            info = "New DOI should be added to NULL report field")

unlink(test_dir7, recursive = TRUE)

# Test 8: Incomplete DOI pattern (zenodo.TODO) - updates automatically ----
test_dir8 <- file.path(tempdir(), "test_zenodo_8")
dir.create(test_dir8, showWarnings = FALSE, recursive = TRUE)

yml_path8 <- create_test_yml(test_dir8, "https://doi.org/10.5281/zenodo.TODO")
metadata8 <- codecheck::codecheck_metadata(test_dir8)

mock_zen8 <- create_mock_zenodo_manager()

result8 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen8, metadata8, warn = FALSE, yml_file = yml_path8)
)

metadata8_after <- codecheck::codecheck_metadata(test_dir8)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata8_after$report),
            info = "Incomplete DOI pattern should be replaced")
expect_false(grepl("TODO", metadata8_after$report),
             info = "TODO in DOI should be removed")

unlink(test_dir8, recursive = TRUE)

# Test 9: YAML file preserves other fields after update ----
test_dir9 <- file.path(tempdir(), "test_zenodo_9")
dir.create(test_dir9, showWarnings = FALSE, recursive = TRUE)

yml_path9 <- create_test_yml(test_dir9, "FIXME")
metadata9 <- codecheck::codecheck_metadata(test_dir9)

# Store original values
original_cert <- metadata9$certificate
original_title <- metadata9$paper$title
original_checker <- metadata9$codechecker[[1]]$name

mock_zen9 <- create_mock_zenodo_manager()

result9 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen9, metadata9, warn = FALSE, yml_file = yml_path9)
)

metadata9_after <- codecheck::codecheck_metadata(test_dir9)

# Check that other fields are preserved
expect_equal(metadata9_after$certificate, original_cert,
             info = "Certificate should be preserved")
expect_equal(metadata9_after$paper$title, original_title,
             info = "Paper title should be preserved")
expect_equal(metadata9_after$codechecker[[1]]$name, original_checker,
             info = "Codechecker should be preserved")

# But report should be updated
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata9_after$report),
            info = "Report should be updated")

unlink(test_dir9, recursive = TRUE)

# Test 10: Record creation provides prereserved DOI ----
test_dir10 <- file.path(tempdir(), "test_zenodo_10")
dir.create(test_dir10, showWarnings = FALSE, recursive = TRUE)

yml_path10 <- create_test_yml(test_dir10, "")
metadata10 <- codecheck::codecheck_metadata(test_dir10)

mock_zen10 <- create_mock_zenodo_manager()

result10 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen10, metadata10, warn = FALSE, yml_file = yml_path10)
)

expect_true(!is.null(result10$metadata$prereserve_doi),
            info = "New record should have prereserve_doi")
expect_true(!is.null(result10$metadata$prereserve_doi$doi),
            info = "Prereserved DOI should be available")
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", result10$metadata$prereserve_doi$doi),
            info = "Prereserved DOI should have correct format")

unlink(test_dir10, recursive = TRUE)

# Test 11a: Placeholder "placeholder" is detected ----
test_dir11a <- file.path(tempdir(), "test_zenodo_11a")
dir.create(test_dir11a, showWarnings = FALSE, recursive = TRUE)
yml_path11a <- create_test_yml(test_dir11a, "placeholder")
metadata11a <- codecheck::codecheck_metadata(test_dir11a)
mock_zen11a <- create_mock_zenodo_manager()
result11a <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen11a, metadata11a, warn = FALSE, yml_file = yml_path11a)
)
metadata11a_after <- codecheck::codecheck_metadata(test_dir11a)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata11a_after$report),
            info = "Placeholder 'placeholder' should be updated")
unlink(test_dir11a, recursive = TRUE)

# Test 11b: Placeholder "example DOI" is detected ----
test_dir11b <- file.path(tempdir(), "test_zenodo_11b")
dir.create(test_dir11b, showWarnings = FALSE, recursive = TRUE)
yml_path11b <- create_test_yml(test_dir11b, "example DOI")
metadata11b <- codecheck::codecheck_metadata(test_dir11b)
mock_zen11b <- create_mock_zenodo_manager()
result11b <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen11b, metadata11b, warn = FALSE, yml_file = yml_path11b)
)
metadata11b_after <- codecheck::codecheck_metadata(test_dir11b)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata11b_after$report),
            info = "Placeholder 'example DOI' should be updated")
unlink(test_dir11b, recursive = TRUE)

# Test 11c: Placeholder "FIXME" standalone is detected ----
test_dir11c <- file.path(tempdir(), "test_zenodo_11c")
dir.create(test_dir11c, showWarnings = FALSE, recursive = TRUE)
yml_path11c <- create_test_yml(test_dir11c, "FIXME")
metadata11c <- codecheck::codecheck_metadata(test_dir11c)
mock_zen11c <- create_mock_zenodo_manager()
result11c <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen11c, metadata11c, warn = FALSE, yml_file = yml_path11c)
)
metadata11c_after <- codecheck::codecheck_metadata(test_dir11c)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata11c_after$report),
            info = "Placeholder 'FIXME' should be updated")
unlink(test_dir11c, recursive = TRUE)

# Test 11d: Placeholder "TODO" standalone is detected ----
test_dir11d <- file.path(tempdir(), "test_zenodo_11d")
dir.create(test_dir11d, showWarnings = FALSE, recursive = TRUE)
yml_path11d <- create_test_yml(test_dir11d, "TODO")
metadata11d <- codecheck::codecheck_metadata(test_dir11d)
mock_zen11d <- create_mock_zenodo_manager()
result11d <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen11d, metadata11d, warn = FALSE, yml_file = yml_path11d)
)
metadata11d_after <- codecheck::codecheck_metadata(test_dir11d)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata11d_after$report),
            info = "Placeholder 'TODO' should be updated")
unlink(test_dir11d, recursive = TRUE)

# Test 11e: Placeholder in Zenodo DOI URL is detected ----
test_dir11e <- file.path(tempdir(), "test_zenodo_11e")
dir.create(test_dir11e, showWarnings = FALSE, recursive = TRUE)
yml_path11e <- create_test_yml(test_dir11e, "https://doi.org/10.5281/zenodo.FIXME")
metadata11e <- codecheck::codecheck_metadata(test_dir11e)
mock_zen11e <- create_mock_zenodo_manager()
result11e <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen11e, metadata11e, warn = FALSE, yml_file = yml_path11e)
)
metadata11e_after <- codecheck::codecheck_metadata(test_dir11e)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata11e_after$report),
            info = "Placeholder in Zenodo DOI URL should be updated")
unlink(test_dir11e, recursive = TRUE)

# Test 11f: XXXXX placeholder is detected ----
test_dir11f <- file.path(tempdir(), "test_zenodo_11f")
dir.create(test_dir11f, showWarnings = FALSE, recursive = TRUE)
yml_path11f <- create_test_yml(test_dir11f, "https://doi.org/10.XXXXX/test")
metadata11f <- codecheck::codecheck_metadata(test_dir11f)
mock_zen11f <- create_mock_zenodo_manager()
result11f <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen11f, metadata11f, warn = FALSE, yml_file = yml_path11f)
)
metadata11f_after <- codecheck::codecheck_metadata(test_dir11f)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata11f_after$report),
            info = "XXXXX placeholder should be updated")
unlink(test_dir11f, recursive = TRUE)

# Test 12: Case-insensitive placeholder detection ----
test_dir12 <- file.path(tempdir(), "test_zenodo_12")
dir.create(test_dir12, showWarnings = FALSE, recursive = TRUE)

yml_path12 <- create_test_yml(test_dir12, "fixme")  # lowercase
metadata12 <- codecheck::codecheck_metadata(test_dir12)

mock_zen12 <- create_mock_zenodo_manager()

result12 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen12, metadata12, warn = FALSE, yml_file = yml_path12)
)

metadata12_after <- codecheck::codecheck_metadata(test_dir12)
expect_true(grepl("10\\.5281/zenodo\\.\\d{7}", metadata12_after$report),
            info = "Lowercase 'fixme' should be detected as placeholder")

unlink(test_dir12, recursive = TRUE)

# Test 13: Format of updated DOI is correct ----
test_dir13 <- file.path(tempdir(), "test_zenodo_13")
dir.create(test_dir13, showWarnings = FALSE, recursive = TRUE)

yml_path13 <- create_test_yml(test_dir13, "")
metadata13 <- codecheck::codecheck_metadata(test_dir13)

mock_zen13 <- create_mock_zenodo_manager()

result13 <- suppressMessages(
  codecheck::get_or_create_zenodo_record(mock_zen13, metadata13, warn = FALSE, yml_file = yml_path13)
)

metadata13_after <- codecheck::codecheck_metadata(test_dir13)

# Check DOI format: should be https://doi.org/10.5281/zenodo.NNNNNNN
expect_true(grepl("^https://doi\\.org/10\\.5281/zenodo\\.\\d{7,}$", metadata13_after$report),
            info = "Updated DOI should have correct full URL format")

unlink(test_dir13, recursive = TRUE)
