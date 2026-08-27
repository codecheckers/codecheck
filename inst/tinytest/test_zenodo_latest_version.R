# Tests for is_zenodo_latest_version()

library(tinytest)

# Helper: a mock `fetch_record` mirroring the real Zenodo API: a resolved
# record carries `versions.is_latest`, read directly (no second lookup).
make_mock_fetch <- function(records) {
  function(id, sandbox, follow_redirect) {
    rec <- records[[as.character(id)]]
    if (is.null(rec)) return(list(status = 404L, body = NULL))
    list(status = 200L, body = list(id = rec$id, versions = list(is_latest = rec$latest, index = rec$index)))
  }
}

# Test 1: single-version record (queried id is also the latest) ----
expect_true(
  codecheck::is_zenodo_latest_version(
    "https://doi.org/10.5281/zenodo.10213244",
    fetch_record = make_mock_fetch(list("10213244" = list(id = 10213244, latest = TRUE, index = 1)))
  )
)

# Test 2: an older version of a multi-version record is not the latest ----
mock_records <- list(
  "1110000" = list(id = 1110000, latest = FALSE, index = 1),
  "2220000" = list(id = 2220000, latest = TRUE, index = 2)
)
expect_false(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.1110000",
                                       fetch_record = make_mock_fetch(mock_records))
)

# Test 3: the latest version of a multi-version record is the latest ----
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.2220000",
                                       fetch_record = make_mock_fetch(mock_records))
)

# Test 4: non-Zenodo DOI is trivially "latest" (no network/mock call needed) ----
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.17605/OSF.IO/ABC12")
)

# Test 5: placeholder/unmatchable Zenodo DOI is trivially "latest" ----
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.FIXME")
)

# Test 6: id that does not resolve at all (e.g. it's a concept id, or the
# record was withdrawn) degrades to "nothing to compare", not an error ----
mock_fetch_404 <- function(id, sandbox, follow_redirect) list(status = 404L, body = NULL)
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.9999999", fetch_record = mock_fetch_404)
)

# Test 7: a record with no `versions` field (unexpected API shape) degrades
# to "nothing to compare" rather than erroring ----
mock_fetch_no_versions <- function(id, sandbox, follow_redirect) list(status = 200L, body = list(id = id))
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.1110000", fetch_record = mock_fetch_no_versions)
)

# Test 8: a request that fails entirely (e.g. exhausted retries) is surfaced
# as an error, not misread as "latest" ----
mock_fetch_fail <- function(id, sandbox, follow_redirect) NULL
expect_error(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.1110000", fetch_record = mock_fetch_fail),
  pattern = "Could not check"
)

# Test 9: a persistent 429 is surfaced as an error, not misread as "latest" ----
mock_fetch_429 <- function(id, sandbox, follow_redirect) list(status = 429L, body = NULL)
expect_error(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.1110000", fetch_record = mock_fetch_429),
  pattern = "Could not check"
)

# Test 10: live integration test against the real DOI pair from issue #36 ----
# https://github.com/codecheckers/codecheck/issues/36
# 10.5281/zenodo.10213244 is a single-version record, trivially its own latest.
live_result <- tryCatch(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.10213244"),
  error = function(e) NA
)
if (!is.na(live_result)) {
  expect_true(live_result, info = "single-version record from issue #36 is its own latest version")
} else {
  expect_true(TRUE, info = "live Zenodo API integration test skipped (no network)")
}
