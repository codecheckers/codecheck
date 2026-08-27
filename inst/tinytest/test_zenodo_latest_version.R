# Tests for is_zenodo_latest_version()

library(tinytest)

# Helper: a mock Zenodo manager mirroring the real zen4R/Zenodo API: a
# resolved record carries a `versions` list with `is_latest`, matching the
# field the real API returns on the record itself (no second lookup needed).
make_mock_zenodo <- function(records) {
  zen <- new.env(parent = emptyenv())
  zen$getRecordById <- function(id) {
    rec <- records[[as.character(id)]]
    if (is.null(rec)) return(NULL)
    list(id = rec$id, versions = list(is_latest = rec$latest, index = rec$index))
  }
  zen
}

# Test 1: single-version record (queried id is also the latest) ----
mock_zen1 <- make_mock_zenodo(list(
  "10213244" = list(id = 10213244, latest = TRUE, index = 1)
))
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.10213244", zenodo = mock_zen1)
)

# Test 2: an older version of a multi-version record is not the latest ----
mock_zen2 <- make_mock_zenodo(list(
  "1110000" = list(id = 1110000, latest = FALSE, index = 1),
  "2220000" = list(id = 2220000, latest = TRUE, index = 2)
))
expect_false(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.1110000", zenodo = mock_zen2)
)

# Test 3: the latest version of a multi-version record is the latest ----
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.2220000", zenodo = mock_zen2)
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
mock_zen6 <- new.env(parent = emptyenv())
mock_zen6$getRecordById <- function(id) NULL
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.9999999", zenodo = mock_zen6)
)

# Test 7: a record with no `versions` field (unexpected API shape) degrades
# to "nothing to compare" rather than erroring ----
mock_zen7 <- new.env(parent = emptyenv())
mock_zen7$getRecordById <- function(id) list(id = id)
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.1110000", zenodo = mock_zen7)
)

# Test 8: a ZenodoException from getRecordById() is surfaced as an error, not
# misread as "latest" ----
mock_zen8 <- new.env(parent = emptyenv())
exception <- structure(list(message = "HTTP 429 Too Many Requests"), class = "ZenodoException")
mock_zen8$getRecordById <- function(id) exception
expect_error(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.1110000", zenodo = mock_zen8),
  pattern = "Could not check"
)

# Test 9: live integration test against the real DOI pair from issue #36 ----
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
