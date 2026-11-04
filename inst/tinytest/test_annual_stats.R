# compute_annual_stats() runs for every per-item JSON, so a works page whose
# only certificate has no usable check date (its codecheck.yml could not be
# fetched, or carries no check_time) or no type reaches it with nothing to
# count. That crashed the whole render with "argument 1 is not a vector" from
# order(names(<empty tapply() result>)), see codecheckers/register#241.

source(system.file("extdata", "config.R", package = "codecheck"))

one_row <- function(check_date, type = "community", venue = "codecheck") {
  data.frame(
    Certificate = "2026-999",
    `Check date` = check_date,
    Type = type,
    Venue = venue,
    Report = "https://doi.org/10.5281/zenodo.1",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

# no check date: nothing to count, but no error either
stats <- codecheck:::compute_annual_stats(one_row(NA_character_))
expect_equal(stats$venue_count, 0L)
expect_equal(stats$venues_per_type, list())
expect_equal(stats$checks_per_type_per_year, list())
expect_equal(length(stats$checks_per_year), 0L)

# a check date but no type: the per-type counts are empty, the rest is not
stats <- codecheck:::compute_annual_stats(one_row("2026-11-03", type = NA_character_))
expect_equal(stats$venues_per_type, list())
expect_equal(stats$checks_per_year, list(`2026` = 1L))

# the normal case still sorts the per-type counts by type
two_rows <- rbind(one_row("2026-11-03"),
                  one_row("2025-01-01", type = "journal", venue = "JOSIS"))
stats <- codecheck:::compute_annual_stats(two_rows)
expect_equal(stats$venues_per_type, list(community = 1L, journal = 1L))

# a page whose statistics cannot be computed is named in the error, rather
# than failing the render with a bare R message nobody can trace to a page
bad <- one_row("not a date") # as.Date() refuses this outright
err <- tryCatch(codecheck:::compute_annual_stats(bad, context = "works page 10.1234/abc"),
                error = function(e) conditionMessage(e))
expect_true(is.character(err) && grepl("works page 10.1234/abc", err, fixed = TRUE),
            info = "the error names the page being rendered")
expect_true(grepl("2026-999", err, fixed = TRUE),
            info = "the error lists the page's certificates")

# the same two cases with the venue metadata loaded, which adds the per-venue
# detail block (venues_detail, publishers)
codecheck:::load_venues_config("register/venues.csv")
full_row <- function(check_date, type = "community") {
  d <- one_row(check_date, type = type)
  d$Codechecker <- I(list(NA))
  d$`Work publication date` <- NA_character_
  d
}
stats <- codecheck:::compute_annual_stats(full_row(NA_character_))
expect_equal(stats$venues_detail, list())
stats <- codecheck:::compute_annual_stats(full_row("2026-11-03", type = NA_character_))
expect_equal(length(stats$venues_detail), 1L)
expect_true(is.na(stats$venues_detail[[1]]$page_type))
