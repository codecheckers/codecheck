# One unreachable repository must not abort the render of all the others:
# every enrichment loop goes through get_codecheck_yml_or_null(), which turns
# the error into a warning naming the certificate and renders the entry
# without the metadata.
tinytest::using(ttdo)

source("mocks.R")

library(codecheck)

register <- data.frame(
  Certificate = c("2020-001", "2020-002"),
  Repository = c("osf::AAAAA", "github::codecheckers/Piccolo-2020"),
  Type = c("community", "community"),
  Venue = c("codecheck", "codecheck"),
  Issue = c(1, 2),
  stringsAsFactors = FALSE
)

# the first entry fails, the second one is fine
failing_get_codecheck_yml <- function(x) {
  if (grepl("AAAAA", x, fixed = TRUE)) {
    stop("Forbidden (HTTP 403)")
  }

  list(
    certificate = "2020-002",
    check_time = "2020-02-02 10:00:00",
    report = "https://doi.org/10.5281/zenodo.3674056",
    paper = list(title = "A paper", reference = "https://doi.org/10.1000/xyz")
  )
}

add_paper_links_ <- getFromNamespace("add_paper_links", "codecheck")
add_check_time_ <- getFromNamespace("add_check_time", "codecheck")
add_report_links_ <- getFromNamespace("add_report_links", "codecheck")
get_codecheck_yml_or_null_ <- getFromNamespace("get_codecheck_yml_or_null", "codecheck")

with_mocked_codecheck(list(get_codecheck_yml = failing_get_codecheck_yml), {

  # the wrapper itself ----
  expect_warning(result <- get_codecheck_yml_or_null_("osf::AAAAA", "2020-001"),
                 pattern = "Could not retrieve codecheck.yml from osf::AAAAA for certificate 2020-001")
  expect_null(result)
  expect_silent(ok <- get_codecheck_yml_or_null_("github::codecheckers/Piccolo-2020"))
  expect_equal(ok$certificate, "2020-002")

  # paper links: the failing entry keeps its row, with an empty cell ----
  papers <- NULL
  expect_warning(papers <- add_paper_links_(register, register),
                 pattern = "Could not retrieve codecheck.yml")
  expect_equal(nrow(papers), 2L)
  expect_true(is.na(papers$`Paper Title`[1]))
  expect_equal(papers$`Paper Title`[2], "[A paper](https://doi.org/10.1000/xyz)")

  # check dates ----
  times <- NULL
  expect_warning(times <- add_check_time_(register, register),
                 pattern = "Could not retrieve codecheck.yml")
  expect_true(is.na(times$`Check date`[1]))
  expect_equal(times$`Check date`[2], "2020-02-02")

  # report links ----
  reports <- NULL
  expect_warning(reports <- add_report_links_(register, register),
                 pattern = "Could not retrieve codecheck.yml")
  expect_true(is.na(reports$Report[1]))
  expect_equal(reports$Report[2], "https://doi.org/10.5281/zenodo.3674056")
})
