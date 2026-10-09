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

# cite_certificate() puts the report DOI in \url{}, so LaTeX can break it
citation <- capture.output(cite_certificate(list(
  codechecker = one, check_time = "2026-01-01", certificate = "2026-001",
  report = "https://doi.org/10.5281/zenodo.17123456")))
expect_true(grepl("\\url{https://doi.org/10.5281/zenodo.17123456}", citation, fixed = TRUE))

# The summary is escaped like manifest comments, and its URLs are put in \url{}
# so they can break across lines; a URL's own # is not escaped, as \url{}
# would print \# literally
with_summary <- function(summary) {
  metadata <- list(paper = list(title = "A paper", authors = one),
                   codechecker = one, summary = summary)
  paste(capture.output(latex_summary_of_metadata(metadata)), collapse = "\n")
}
out <- with_summary("Results match within 5% & figures agree, see issue #3.")
expect_true(grepl("Results match within 5\\% \\& figures agree, see issue \\#3.", out, fixed = TRUE))
out <- with_summary("Details at https://example.org/notes#section-2 & more.")
expect_true(grepl("Details at \\url{https://example.org/notes#section-2} \\& more.", out, fixed = TRUE))
# Already escaped characters and hand-written links are kept as they are
out <- with_summary("A \\& B, see \\href{https://example.org/a#b}{the notes}.")
expect_true(grepl("A \\& B, see \\href{https://example.org/a#b}{the notes}.", out, fixed = TRUE))
expect_true(grepl("Summary &\\s*\\\\\\\\", with_summary(NULL)))
# Underscores outside math are escaped, e.g. in file names; math is kept
out <- with_summary("Ran run_all.R, the error is below $\\epsilon_1$.")
expect_true(grepl("Ran run\\_all.R, the error is below $\\epsilon_1$.", out, fixed = TRUE))

# The paper title is escaped too
metadata_title <- list(paper = list(title = "Ecology & Evolution: 95% of cases_2", authors = one),
                       codechecker = one)
out <- paste(capture.output(latex_summary_of_metadata(metadata_title)), collapse = "\n")
expect_true(grepl("Ecology \\& Evolution: 95\\% of cases\\_2", out, fixed = TRUE))

# Deliberate LaTeX is kept: display and inline math, command keys and URLs in
# \href{}, while the link text is escaped
out <- with_summary("$$x_1$$, \\(y_2\\) and \\cite{smith_2020}, see \\href{https://x.org/raw_data.csv}{run_all.R}.")
expect_true(grepl("$$x_1$$, \\(y_2\\) and \\cite{smith_2020}, see \\href{https://x.org/raw_data.csv}{run\\_all.R}.",
                  out, fixed = TRUE))
# Only http(s) URLs are links, without trailing punctuation
out <- with_summary("Result:reproduced, www.example.org/data and (https://x.org/a_b).")
expect_true(grepl("Result:reproduced, www.example.org/data and (\\url{https://x.org/a_b}).", out, fixed = TRUE))
