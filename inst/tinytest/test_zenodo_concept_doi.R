# Tests for is_zenodo_concept_doi()

library(tinytest)

# Helper: a mock Zenodo manager where only `concept_id` resolves via
# getRecordByConceptId(), mirroring the real zen4R/Zenodo API behaviour:
# a concept ID resolves to a record this way, a version-specific record ID
# does not (it is not itself a "concept").
make_mock_zenodo <- function(concept_id = 10213243) {
  zen <- new.env(parent = emptyenv())
  zen$getRecordByConceptId <- function(id) {
    if (identical(as.integer(id), as.integer(concept_id))) {
      record <- new.env(parent = emptyenv())
      record$getConceptDOI <- function() paste0("10.5281/zenodo.", concept_id)
      return(record)
    }
    NULL
  }
  zen
}

# Test 1: version-specific DOI is not a concept DOI ----
mock_zen1 <- make_mock_zenodo(concept_id = 10213243)
expect_false(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.10213244", zenodo = mock_zen1)
)

# Test 2: concept DOI is detected as such ----
mock_zen2 <- make_mock_zenodo(concept_id = 10213243)
expect_true(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.10213243", zenodo = mock_zen2)
)

# Test 3: non-Zenodo DOI is never a concept DOI (no network/mock call needed) ----
expect_false(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.17605/OSF.IO/ABC12")
)

# Test 4: placeholder/unmatchable Zenodo DOI is not a concept DOI ----
expect_false(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.FIXME")
)

# Test 5: sandbox DOI (10.5072) is not matched by get_zenodo_id(), so not flagged ----
expect_false(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5072/zenodo.145250")
)

# Test 6: bare DOI (no https://doi.org/ prefix) works the same way ----
mock_zen6 <- make_mock_zenodo(concept_id = 10213243)
expect_true(
  codecheck::is_zenodo_concept_doi("10.5281/zenodo.10213243", zenodo = mock_zen6)
)

# Test 7: no matching record at all (e.g. deleted/withdrawn) is "not a concept DOI" ----
mock_zen7 <- new.env(parent = emptyenv())
mock_zen7$getRecordByConceptId <- function(id) NULL
expect_false(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.9999999", zenodo = mock_zen7)
)

# Test 8: live integration test against the real DOI pair from issue #36 ----
# https://github.com/codecheckers/codecheck/issues/36
# 10.5281/zenodo.10213244 is the version-specific DOI,
# 10.5281/zenodo.10213243 is the concept DOI.
version_result <- tryCatch(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.10213244"),
  error = function(e) NA
)
if (!is.na(version_result)) {
  expect_false(version_result, info = "version-specific DOI from issue #36 should not be flagged")
  expect_true(
    codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.10213243"),
    info = "concept DOI from issue #36 should be flagged"
  )
} else {
  expect_true(TRUE, info = "live Zenodo API integration test skipped (no network)")
}
