source("mocks.R")

register <- data.frame(
  Certificate = c("2020-001", "2020-002", "2020-003", "2020-004"),
  Repository = c("github::a/one", "github::a/two", "github::a/three", "github::a/four"),
  stringsAsFactors = FALSE
)

ymls <- list(
  "github::a/one" = list(codechecker = list(list(name = "Stephen J. Eglen", ORCID = "0000-0001-8607-8025"))),
  "github::a/two" = list(codechecker = list(
    list(name = "Stephen J. Eglen", ORCID = "0000-0001-8607-8025"),
    list(name = "Adhitya Bhawiyuga", ORCID = NULL)
  )),
  "github::a/three" = list(codechecker = list(list(name = "Delft 2024-05 participants", ORCID = NULL))),
  "github::a/four" = list(codechecker = NULL)
)

fake_get_yml <- function(repo, cert_id = NULL) ymls[[repo]]

# Unit tests: build_zenodo_contributors() ----

with_mocked_codecheck(list(get_codecheck_yml_or_null = fake_get_yml), {
  contributors <- codecheck:::build_zenodo_contributors(register)
})

expect_equal(length(contributors), 2)
# unnamed, so it serializes to a JSON array rather than an object
expect_null(names(contributors))

names <- vapply(contributors, function(c) c$name, character(1))
expect_true("Stephen J. Eglen" %in% names)
expect_true("Adhitya Bhawiyuga" %in% names)
expect_false("Delft 2024-05 participants" %in% names)

eglen <- contributors[[which(names == "Stephen J. Eglen")]]
expect_equal(eglen$orcid, "0000-0001-8607-8025")
expect_equal(eglen$type, "Other")

bhawiyuga <- contributors[[which(names == "Adhitya Bhawiyuga")]]
expect_null(bhawiyuga$orcid)
expect_equal(bhawiyuga$type, "Other")

# Sorted by name
expect_equal(names, sort(names, method = "radix"))

# Custom type
with_mocked_codecheck(list(get_codecheck_yml_or_null = fake_get_yml), {
  custom <- codecheck:::build_zenodo_contributors(register, type = "Researcher")
})
expect_true(all(vapply(custom, function(c) c$type, character(1)) == "Researcher"))

# Empty register -> empty list
empty_register <- register[0, , drop = FALSE]
expect_equal(codecheck:::build_zenodo_contributors(empty_register), list())

# Unit tests: update_zenodo_json() ----

fixture <- list(
  title = "codecheckers/register",
  creators = list(list(name = "Nüst, Daniel", orcid = "0000-0002-0024-5046")),
  contributors = list(),
  license = "cc-by-4.0"
)

tmp <- tempfile(fileext = ".json")
jsonlite::write_json(fixture, tmp, auto_unbox = TRUE, pretty = TRUE)

with_mocked_codecheck(list(get_codecheck_yml_or_null = fake_get_yml), {
  result <- codecheck:::update_zenodo_json(register, path = tmp)
})
expect_true(result)

updated <- jsonlite::fromJSON(tmp, simplifyVector = FALSE)
expect_equal(updated$title, "codecheckers/register")
expect_equal(updated$license, "cc-by-4.0")
expect_equal(length(updated$creators), 1)
expect_equal(length(updated$contributors), 2)
# A named list serializes as a JSON object ("contributors":{...}), not an
# array ("contributors":[...]) - assert on the raw text, since
# fromJSON(simplifyVector = FALSE) parses either shape into an R list and
# would not otherwise catch the regression.
raw_json <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
expect_true(grepl('"contributors":\\s*\\[', raw_json))

# Missing file -> no-op, no error
missing_path <- tempfile(fileext = ".json")
result_missing <- codecheck:::update_zenodo_json(register, path = missing_path)
expect_false(result_missing)
expect_false(file.exists(missing_path))
