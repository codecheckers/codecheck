# Tests for the ORCID -> ROR lookups behind register#53: orcid_rors(),
# register_ror_coverage() and ror_coverage_summary(). All tests run offline
# against fixtures and mocks.

library(tinytest)
source("mocks.R")

# keep the cache of this test out of the user's real cache, restored at the end
# of this file (on.exit() would run immediately, it is not inside a function)
cache_root <- file.path(tempfile("codecheck_cache"))
dir.create(cache_root, recursive = TRUE)
old_root <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(cache_root)

fixture_path <- function(name) {
  path <- system.file("tinytest", "fixtures", "orcid", name, package = "codecheck")
  if (path == "") path <- file.path("fixtures", "orcid", name)
  path
}

# an httr response carrying a fixture as its body, enough for httr::content()
json_response <- function(url, name, status = 200L) {
  body <- paste(readLines(fixture_path(name), warn = FALSE), collapse = "\n")
  structure(list(url = url,
                 status_code = as.integer(status),
                 headers = list(`content-type` = "application/json"),
                 all_headers = list(),
                 content = charToRaw(body)),
            class = "response")
}

# Which fixture each test ORCID's three record sections answer with. Sections
# not named here answer with the empty affiliation group, as ORCID does for a
# person who filled in only one of them.
profiles <- list(
  # a current, ROR-identified employment
  "0000-0000-0000-0001" = list(employments = "employments_current_ror.json"),
  # a ROR-identified employment that ended in 2019
  "0000-0000-0000-0002" = list(employments = "employments_past_ror.json"),
  # affiliations, but disambiguated against RINGGOLD/GRID or not at all
  "0000-0000-0000-0003" = list(employments = "employments_other_sources.json"),
  # no affiliations at all
  "0000-0000-0000-0004" = list(),
  # only an education, with year-only dates
  "0000-0000-0000-0005" = list(educations = "educations_year_only_ror.json")
)

mock_orcid_GET <- function(url, ...) {
  orcid <- sub("^.*v3\\.0/([^/]+)/.*$", "\\1", url)
  section <- sub("^.*/", "", url)

  # the record ORCID cannot serve, so the lookup must stay inconclusive
  if (orcid == "0000-0000-0000-0666") {
    return(mock_response(url, 500L))
  }

  fixture <- profiles[[orcid]][[section]]
  if (is.null(fixture)) fixture <- "affiliations_empty.json"
  json_response(url, fixture)
}

affiliations_of <- function(orcid) {
  with_mocked_codecheck(
    list(codecheck_GET_retry = mock_orcid_GET),
    codecheck:::get_orcid_affiliations_result(orcid)
  )
}

rors_of <- function(orcid, at = NULL) {
  with_mocked_codecheck(
    list(codecheck_GET_retry = mock_orcid_GET),
    codecheck::orcid_rors(orcid, at = at)
  )
}

# --- reading affiliations off a record ---------------------------------------

current <- affiliations_of("0000-0000-0000-0001")
expect_equal(current$status, "found")
expect_equal(nrow(current$value), 1)
expect_equal(current$value$section, "employments")
expect_equal(current$value$organization, "Test University")
# the bare id, not the https://ror.org/ URL ORCID stores
expect_equal(current$value$ror, "013meh722")

# educations and qualifications count as affiliations, not just employments
education <- affiliations_of("0000-0000-0000-0005")
expect_equal(education$value$section, "educations")
expect_equal(education$value$ror, "04pp8hn57")

# only ORCID's own ROR disambiguation counts, RINGGOLD/GRID/none do not
other_sources <- affiliations_of("0000-0000-0000-0003")
expect_equal(nrow(other_sources$value), 3)
expect_true(all(is.na(other_sources$value$ror)))

# a record without any affiliation is a conclusive absence, and cacheable
empty <- affiliations_of("0000-0000-0000-0004")
expect_equal(empty$status, "absent")
expect_equal(nrow(empty$value), 0)

# a section ORCID did not serve makes the whole record inconclusive: "no ROR"
# here would be indistinguishable from a person who has none, and caching it
# would freeze that gap in place
failed <- affiliations_of("0000-0000-0000-0666")
expect_equal(failed$status, "failed")
expect_equal(nrow(failed$value), 0)

# --- partial ORCID dates -----------------------------------------------------

year_only <- list(year = list(value = "2019"), month = NULL, day = NULL)
month_only <- list(year = list(value = "2019"), month = list(value = "02"), day = NULL)
full_date <- list(year = list(value = "2019"), month = list(value = "02"),
                  day = list(value = "14"))

# a year-only bound covers the whole year at either end
expect_true(codecheck:::orcid_date_covered(year_only, year_only, as.Date("2019-12-31")))
expect_true(codecheck:::orcid_date_covered(year_only, year_only, as.Date("2019-01-01")))
expect_false(codecheck:::orcid_date_covered(year_only, year_only, as.Date("2018-12-31")))
# a month-only end bound covers to the end of that month
expect_true(codecheck:::orcid_date_covered(full_date, month_only, as.Date("2019-02-28")))
expect_false(codecheck:::orcid_date_covered(full_date, month_only, as.Date("2019-03-01")))
# no start is unbounded in the past, no end is ongoing
expect_true(codecheck:::orcid_date_covered(NULL, NULL, as.Date("1999-01-01")))
expect_true(codecheck:::orcid_date_covered(NULL, year_only, as.Date("1999-01-01")))
expect_true(codecheck:::orcid_date_covered(year_only, NULL, as.Date("2099-01-01")))
expect_false(codecheck:::orcid_date_covered(year_only, NULL, as.Date("2018-01-01")))

# --- orcid_rors() ------------------------------------------------------------

# "current" is an affiliation without an end date
expect_equal(rors_of("0000-0000-0000-0001"), "013meh722")
expect_equal(rors_of("0000-0000-0000-0002"), character(0))
expect_equal(rors_of("0000-0000-0000-0003"), character(0))
expect_equal(rors_of("0000-0000-0000-0004"), character(0))

# an ended affiliation still counts for a date it covered - this is what makes
# the "ROR at publication time" number different from the "current" one
expect_equal(rors_of("0000-0000-0000-0002", at = as.Date("2018-05-02")), "02e2c7k09")
expect_equal(rors_of("0000-0000-0000-0002", at = as.Date("2021-05-02")), character(0))
expect_equal(rors_of("0000-0000-0000-0005", at = as.Date("2020-06-01")), "04pp8hn57")
expect_equal(rors_of("0000-0000-0000-0005", at = as.Date("2021-06-01")), character(0))

# a record ORCID could not serve reports no ROR rather than failing the render
expect_equal(rors_of("0000-0000-0000-0666"), character(0))

# --- register_ror_coverage() -------------------------------------------------

register_table <- data.frame(
  `Certificate ID` = c("2020-001", "2021-002"),
  `Check date` = c("2020-06-01", "2021-05-02"),
  OpenAlex = c("https://openalex.org/W1", NA_character_),
  stringsAsFactors = FALSE, check.names = FALSE
)
register_table$Person <- list(
  list(list(orcid = "0000-0000-0000-0002", role = "author"),
       list(orcid = "0000-0000-0000-0001", role = "codechecker")),
  list(list(orcid = "0000-0000-0000-0003", role = "author"),
       list(orcid = "0000-0000-0000-0002", role = "codechecker"))
)

coverage <- with_mocked_codecheck(
  list(codecheck_GET_retry = mock_orcid_GET,
       # the paper of 2020-001 was published while 0002 still held their ROR
       get_openalex_publication_date_cached = function(openalex_id) {
         if (is.na(openalex_id)) NA_character_ else "2018-05-02"
       }),
  suppressMessages(codecheck::register_ror_coverage(register_table))
)

expect_equal(nrow(coverage), 4)
expect_equal(coverage$Role, c("author", "codechecker", "author", "codechecker"))
# an author's date comes from OpenAlex, a codechecker's from the check date
expect_equal(coverage$date_source, c("openalex", "check date", "check date", "check date"))
expect_equal(coverage$date,
             as.Date(c("2018-05-02", "2020-06-01", "2021-05-02", "2021-05-02")))

expect_equal(coverage$has_current_ror, c(FALSE, TRUE, FALSE, FALSE))
# 0002 authored the 2018 paper while employed, but checked in 2021 after leaving
expect_equal(coverage$matched_at_date, c(TRUE, TRUE, FALSE, FALSE))
expect_equal(coverage$ror_at_date[[1]], "02e2c7k09")
# affiliations without a ROR are still counted, so "has none" can be told apart
# from "has no affiliations on record"
expect_equal(coverage$n_affiliations, c(1L, 1L, 3L, 1L))
expect_equal(coverage$has_ror, c(TRUE, TRUE, FALSE, TRUE))

# The dates register_ror_coverage() matches against are computed by the shared
# helper the organisation records use too, so they must not drift apart.
dates <- with_mocked_codecheck(
  list(get_openalex_publication_date_cached = function(openalex_id) {
    if (is.na(openalex_id)) NA_character_ else "2018-05-02"
  }),
  suppressMessages(codecheck:::person_record_dates(
    codecheck:::explode_person_records(register_table)))
)
expect_equal(dates$date, coverage$date)
expect_equal(dates$date_source, coverage$date_source)

# --- ror_coverage_summary() --------------------------------------------------

summary <- ror_coverage_summary(coverage, quiet = TRUE)

all_records <- summary[summary$unit == "record" & summary$role == "all", ]
expect_equal(all_records$n, 4)
expect_equal(all_records$has_current_ror, 1)
expect_equal(all_records$pct_current_ror, 25)
expect_equal(all_records$matched_at_date, 2)
expect_equal(all_records$pct_matched_at_date, 50)

# per person a role counts once, so 0002's two author/codechecker records do
# not weigh twice as much as everybody else's
all_persons <- summary[summary$unit == "person" & summary$role == "all", ]
expect_equal(all_persons$n, 3)
expect_equal(all_persons$matched_at_date, 2)

checkers <- summary[summary$unit == "person" & summary$role == "codechecker", ]
expect_equal(checkers$n, 2)
expect_equal(checkers$has_current_ror, 1)
expect_equal(checkers$pct_current_ror, 50)

R.cache::setCacheRootPath(old_root)
