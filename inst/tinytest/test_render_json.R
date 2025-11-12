tinytest::using(ttdo)

test_path <- "register/short.csv"
test_register <- read.csv(test_path)
venues_path <- "register/venues.csv"

expect_silent({ capture.output(
  {
    table <- register_render(register = test_register, filter_by = c(), outputs = c("json"),
                            venues_file = venues_path)
  },
  type = "message"
  )
  })

# file generation ----
expect_true(file.exists(file.path("docs/register.json")))
expect_true(file.exists(file.path("docs/featured.json")))
expect_true(file.exists(file.path("docs/stats.json")))

# stats ----
stats <- jsonlite::read_json("docs/stats.json")
expect_equal(stats$cert_count, nrow(test_register))
expect_equal(stats$source, paste0(CONFIG$HREF_DETAILS$json$base_url, "register.json"))

# featured ----
featured <- jsonlite::read_json("docs/featured.json")
expect_true(length(featured) < CONFIG$FEATURED_COUNT)
expect_equal(stats$cert_count, length(featured))
expect_equal(names(featured[[1]]), CONFIG$JSON_COLUMNS)
expect_equal(sapply(featured, "[[", "Certificate ID"), test_register$Certificate)

# register ----
register <- jsonlite::read_json("docs/register.json")
expect_equal(length(register), length(featured))
expect_equal(names(register[[1]]), CONFIG$JSON_COLUMNS)
expect_equal(sapply(register, "[[", "Certificate ID"), test_register$Certificate)

# clean up
expect_equal(unlink("docs", recursive = TRUE), 0)
