# Live services may be down while the tests run; whether that fails a render
# is tested in test_lookup_failures.R and Test 6b of test_register_edge_cases.R
options(codecheck.fail_on_outages = FALSE)

tinytest::using(ttdo)

test_path <- "register/short.csv"
test_register <- read.csv(test_path)
venues_path <- "register/venues.csv"

expect_silent({ capture.output(
  {
    register_render(register = test_register, filter_by = c("venues"), outputs = c("json"),
                    venues_file = venues_path)
  },
  type = "message"
  )
  })

# venues overview JSON should have codechecks links ----
venues_json_path <- "docs/venues/index.json"
expect_true(file.exists(venues_json_path))

venues <- jsonlite::read_json(venues_json_path)
expect_true(length(venues) > 0)

# Every venue entry should have a codechecks field
expect_true(all(sapply(venues, function(v) "codechecks" %in% names(v))))

# Check URL format: should point to the venue's register.json
for (v in venues) {
  expect_true(grepl("register\\.json$", v$codechecks))
  expect_true(grepl("^https://codecheck\\.org\\.uk/register/venues/", v$codechecks))
}

# Spot check: AGILEGIS is a conference venue
agile <- Filter(function(v) grepl("AGILE", v[["Venue name"]]), venues)
expect_equal(length(agile), 1)
expect_equal(agile[[1]]$codechecks,
             "https://codecheck.org.uk/register/venues/conferences/agilegis/register.json")

# venue type JSON should also have codechecks links ----
community_json_path <- "docs/venues/communities/index.json"
expect_true(file.exists(community_json_path))

communities <- jsonlite::read_json(community_json_path)
expect_true(length(communities) > 0)
expect_true(all(sapply(communities, function(v) "codechecks" %in% names(v))))

# clean up
expect_equal(unlink("docs", recursive = TRUE), 0)
