# Tests for is_zenodo_concept_doi()

library(tinytest)

# Helper: a mock `fetch_record` mirroring the real Zenodo API: a concept
# (parent) id 302-redirects instead of serving a record directly, a
# version-specific id serves its record with a plain 200.
make_mock_fetch <- function(concept_id = 10213243) {
  function(id, sandbox, follow_redirect) {
    if (identical(as.integer(id), as.integer(concept_id))) {
      list(status = 302L, body = NULL)
    } else {
      list(status = 200L, body = list(id = id))
    }
  }
}

# Test 1: version-specific DOI is not a concept DOI ----
expect_false(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.10213244",
                                    fetch_record = make_mock_fetch(concept_id = 10213243))
)

# Test 2: concept DOI is detected as such ----
expect_true(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.10213243",
                                    fetch_record = make_mock_fetch(concept_id = 10213243))
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
expect_true(
  codecheck::is_zenodo_concept_doi("10.5281/zenodo.10213243",
                                    fetch_record = make_mock_fetch(concept_id = 10213243))
)

# Test 7: a withdrawn/deleted id (404) is "not a concept DOI" ----
mock_fetch_404 <- function(id, sandbox, follow_redirect) list(status = 404L, body = NULL)
expect_false(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.9999999", fetch_record = mock_fetch_404)
)

# Test 8: a request that fails entirely (e.g. exhausted retries) is surfaced
# as an error, not misread as "not a concept DOI" ----
mock_fetch_fail <- function(id, sandbox, follow_redirect) NULL
expect_error(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.9999999", fetch_record = mock_fetch_fail),
  pattern = "Could not check"
)

# Test 9: a persistent 429 is surfaced as an error, not misread as "not a
# concept DOI" ----
mock_fetch_429 <- function(id, sandbox, follow_redirect) list(status = 429L, body = NULL)
expect_error(
  codecheck::is_zenodo_concept_doi("https://doi.org/10.5281/zenodo.9999999", fetch_record = mock_fetch_429),
  pattern = "Could not check"
)

# Test 10: live integration test against the real DOI pair from issue #36 ----
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
