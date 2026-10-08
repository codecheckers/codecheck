# Tests for latex_summary_of_metadata()

summary_of <- function(authors, codecheckers) {
  metadata <- list(
    paper = list(title = "A paper", authors = authors, reference = "https://doi.org/10.1/x"),
    codechecker = codecheckers,
    check_time = "2026-01-01",
    summary = "Fine.",
    repository = "https://github.com/codecheckers/x")
  paste(capture.output(latex_summary_of_metadata(metadata)), collapse = "\n")
}

one <- list(list(name = "Ada Lovelace"))
two <- list(list(name = "Ada Lovelace"), list(name = "Alan Turing", ORCID = "0000-0002-1825-0097"))

# Singular labels for a single person
out <- summary_of(one, one)
expect_true(grepl("Author &", out, fixed = TRUE))
expect_true(grepl("Codechecker &", out, fixed = TRUE))
expect_false(grepl("(s)", out, fixed = TRUE))

# Plural labels for several people
out <- summary_of(two, two)
expect_true(grepl("Authors &", out, fixed = TRUE))
expect_true(grepl("Codecheckers &", out, fixed = TRUE))

# Labels are independent of each other
out <- summary_of(two, one)
expect_true(grepl("Authors &", out, fixed = TRUE))
expect_true(grepl("Codechecker &", out, fixed = TRUE))
