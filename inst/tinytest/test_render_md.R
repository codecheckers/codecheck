tinytest::using(ttdo)

test_path <- "register/short.csv"
test_register <- read.csv(test_path)
venues_path <- "register/venues.csv"

expect_silent({ register_render(register = test_register, filter_by = c(), outputs = c("md"),
                                venues_file = venues_path) })

# file generation ----
expect_true(file.exists("docs/register.md"))
content <- readLines("docs/register.md")
expect_true(grep("svaRetro and svaNUM", content) != 0)

# TODO more tests ----

# clean up
expect_equal(unlink("docs", recursive = TRUE), 0)
