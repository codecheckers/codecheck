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

# Several repositories, as yaml::read_yaml() returns them: a character vector
# (codecheck#97)
metadata <- yaml::read_yaml(file.path("yaml", "repository_multiple", "codecheck.yml"))
expect_true(is.character(metadata$repository) && length(metadata$repository) == 2)
out <- capture.output(latex_summary_of_metadata(metadata))
repo_row <- trimws(grep("^\\s*Repositor", out, value = TRUE))
expect_equal(length(repo_row), 1, info = "One table row for all repositories")
expect_true(startsWith(repo_row, "Repositories &"))
expect_true(grepl("\\url{https://github.com/codecheckers/analysis-code} \\newline \\url{https://doi.org/10.5281/zenodo.1234567}",
                  repo_row, fixed = TRUE))

# A list of repositories works the same way
metadata$repository <- as.list(metadata$repository)
expect_equal(capture.output(latex_summary_of_metadata(metadata)), out)

# A single repository keeps the singular label, no repository gives an empty row
out <- summary_of(one, one)
expect_true(grepl("Repository & \\url{https://github.com/codecheckers/x}", out, fixed = TRUE))
metadata$repository <- NULL
out <- capture.output(latex_summary_of_metadata(metadata))
expect_true(any(grepl("^\\s*Repository &\\s*\\\\\\\\", out)))
