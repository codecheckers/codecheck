# Tests for is_zenodo_latest_version()

library(tinytest)

# Helper: a mock Zenodo manager mirroring the real zen4R/Zenodo API behaviour:
# getRecordById() resolves a version-specific id to a record carrying its
# parent (concept) id, getRecordByConceptId() resolves the concept id to the
# record of the latest version.
make_mock_zenodo <- function(records) {
  zen <- new.env(parent = emptyenv())
  zen$getRecordById <- function(id) {
    rec <- records[[as.character(id)]]
    if (is.null(rec)) return(NULL)
    list(id = rec$id, parent = list(id = rec$parent_id))
  }
  zen$getRecordByConceptId <- function(id) {
    for (rec in records) {
      if (identical(rec$parent_id, id) && isTRUE(rec$latest)) {
        return(list(id = rec$id, parent = list(id = rec$parent_id)))
      }
    }
    NULL
  }
  zen
}

# Test 1: single-version record (queried id is also the latest) ----
mock_zen1 <- make_mock_zenodo(list(
  "10213244" = list(id = 10213244, parent_id = 10213243, latest = TRUE)
))
expect_true(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.10213244", zenodo = mock_zen1)
)

# Test 2: an older version of a multi-version record is not the latest ----
mock_zen2 <- make_mock_zenodo(list(
  "1110000" = list(id = 1110000, parent_id = 1000000, latest = FALSE),
  "2220000" = list(id = 2220000, parent_id = 1000000, latest = TRUE)
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

# Test 7: record resolves but the concept id can no longer be resolved to a
# latest version (e.g. transient API gap) degrades to "nothing to compare" ----
mock_zen7 <- new.env(parent = emptyenv())
mock_zen7$getRecordById <- function(id) list(id = id, parent = list(id = 1000000))
mock_zen7$getRecordByConceptId <- function(id) NULL
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

# Test 9: a ZenodoException from getRecordByConceptId() is also surfaced ----
mock_zen9 <- new.env(parent = emptyenv())
mock_zen9$getRecordById <- function(id) list(id = id, parent = list(id = 1000000))
mock_zen9$getRecordByConceptId <- function(id) exception
expect_error(
  codecheck::is_zenodo_latest_version("https://doi.org/10.5281/zenodo.1110000", zenodo = mock_zen9),
  pattern = "Could not check"
)
