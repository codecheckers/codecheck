# Tests for the venue of a preprint whose OpenAlex locations name a journal.
# Certificate 2024-016 references the Zenodo preprint 10.5281/zenodo.13734819,
# whose `journal` field names Geospatial Health, the journal it was submitted
# to. OpenAlex record W6893062762 is of type "preprint", yet gives that journal
# as the source of both Zenodo copies. The record below is a trimmed copy; no
# test here reaches the network.

library(codecheck)
source("mocks.R")

journal <- list(display_name = "Geospatial health", issn_l = "1827-1987",
                issn = list("1827-1987", "1970-7096"), type = "journal")
repository <- list(display_name = "Zenodo (CERN European Organization for Nuclear Research)",
                   issn_l = NULL, issn = NULL, type = "repository")
concept <- "https://doi.org/10.5281/zenodo.13734818"
version <- "https://doi.org/10.5281/zenodo.13734819"

openalex_record <- function(type = "preprint", source = journal) {
  list(id = "https://openalex.org/W6893062762", doi = concept, type = type,
       publication_date = "2024-09-10",
       primary_location = list(doi = concept, source = source),
       locations = list(list(doi = concept, source = source),
                        list(doi = version, source = source)))
}

read_fields <- function(record) {
  respond <- function(url, ...) mock_json_response(url, record)
  with_mocked_codecheck(list(codecheck_GET_openalex = respond), {
    codecheck:::get_openalex_work_fields_result("https://openalex.org/W6893062762")$value
  })
}

# --- a preprint with a journal source -------------------------------------------

fields <- read_fields(openalex_record())
# The journal it was submitted to is not where the preprint appeared.
expect_true(is.na(fields$issn))
expect_true(is.na(fields$venue))
# Nothing else of the record is lost.
expect_equal(fields$doi, concept)
expect_equal(fields$publication_date, "2024-09-10")
expect_equal(vapply(fields$locations, function(l) l$doi, character(1)), c(concept, version))
# The locations leave the journal out as well, so the version DOI the register
# references (which is not the record's DOI) gets no venue either.
for (location in fields$locations) {
  expect_true(is.na(location$issn))
  expect_true(is.na(location$venue))
}
cached <- function(openalex_id) list(status = "found", value = fields)
with_mocked_codecheck(list(get_openalex_work_fields_cached_result = cached), {
  of_version <- codecheck:::get_openalex_work_fields_for("W6893062762", version)$value
})
expect_true(is.na(of_version$issn))
expect_true(is.na(of_version$venue))

# --- what is left as it was -----------------------------------------------------

# A preprint on a repository keeps it as its venue.
on_server <- read_fields(openalex_record(source = repository))
expect_equal(on_server$venue, "Zenodo (CERN European Organization for Nuclear Research)")
expect_true(is.na(on_server$issn))
# An article keeps its journal.
article <- read_fields(openalex_record(type = "article"))
expect_equal(article$issn, "1827-1987")
expect_equal(article$venue, "Geospatial health")
expect_equal(article$locations[[2]]$issn, "1827-1987")
# A preprint record holding the published article keeps the article's journal.
merged <- openalex_record()
merged$locations[[2]]$version <- "publishedVersion"
merged <- read_fields(merged)
expect_true(is.na(merged$venue))
expect_equal(merged$locations[[2]]$venue, "Geospatial health")
