# Tests for the ROR-based organisation pages (register#53): the ror.org and
# Wikidata metadata, the organisation records derived from the register's
# people, and the overview table. All tests run offline against fixtures and
# mocks.

library(tinytest)
source("mocks.R")

config_path <- system.file("extdata", "config.R", package = "codecheck")
if (config_path == "" || !file.exists(config_path)) {
  exit_file("Package not installed properly")
}
source(config_path)

# keep the cache of this test out of the user's real cache, restored at the end
# of this file (on.exit() would run immediately, it is not inside a function)
cache_root <- file.path(tempfile("codecheck_cache"))
dir.create(cache_root, recursive = TRUE)
old_root <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(cache_root)

fixture_path <- function(...) {
  path <- system.file("tinytest", "fixtures", ..., package = "codecheck")
  if (path == "") path <- file.path("fixtures", ...)
  path
}

fixture <- function(...) jsonlite::fromJSON(fixture_path(...), simplifyVector = FALSE)

# an httr response carrying a fixture as its body, enough for httr::content()
json_response <- function(url, path, status = 200L) {
  body <- paste(readLines(path, warn = FALSE), collapse = "\n")
  structure(list(url = url,
                 status_code = as.integer(status),
                 headers = list(`content-type` = "application/json"),
                 all_headers = list(),
                 content = charToRaw(body)),
            class = "response")
}

full <- fixture("ror", "organisation_full.json")
minimal <- fixture("ror", "organisation_minimal.json")

# --- reading a ROR record ----------------------------------------------------

ror_fixtures <- list(
  "02e2c7k09" = "organisation_full.json",
  "00000000a" = "organisation_minimal.json"
)

mock_ror_GET <- function(url, ...) {
  id <- sub("^.*organizations/", "", url)
  if (id == "09unknown") return(mock_response(url, 404L))
  if (id == "05broken0") return(mock_response(url, 500L))
  json_response(url, fixture_path("ror", ror_fixtures[[id]]))
}

record_result <- function(ror) {
  with_mocked_codecheck(list(codecheck_GET_retry = mock_ror_GET),
                        codecheck:::get_ror_record_result(ror))
}

expect_equal(record_result("02e2c7k09")$status, "found")
expect_equal(record_result("02e2c7k09")$value$id, "https://ror.org/02e2c7k09")
# the full URL is accepted as well as the bare id
expect_equal(record_result("https://ror.org/02e2c7k09")$status, "found")
# an id ROR does not know is a conclusive absence, a server error is not
expect_equal(record_result("09unknown")$status, "absent")
expect_equal(record_result("05broken0")$status, "failed")

# --- the fields the pages are built from -------------------------------------

fields <- codecheck:::ror_metadata_fields(full)
expect_equal(fields$ror, "02e2c7k09")
expect_equal(fields$name, "Delft University of Technology")
# the display name is not repeated among the alternatives
expect_true("TU Delft" %in% fields$aliases)
expect_false("Delft University of Technology" %in% fields$aliases)
expect_equal(fields$types, c("education", "funder"))
expect_equal(fields$city, "Delft")
expect_equal(fields$country, "The Netherlands")
expect_equal(fields$established, "1842")
expect_equal(fields$website_url, "https://www.tudelft.nl")
expect_equal(fields$wikidata, "Q752663")

identifier_names <- vapply(fields$identifiers, function(i) i$name, character(1))
expect_equal(identifier_names, c("ROR", "GRID", "ISNI", "FUNDREF", "Wikidata"))
# an external id without a "preferred" still yields its only value
isni <- fields$identifiers[[which(identifier_names == "ISNI")]]
expect_equal(isni$value, "0000 0001 2097 4740")

# A record that carries nothing but a name must not render "NA" or "NULL" into
# the page: every optional field comes back missing, and only the ROR itself
# is listed as an identifier.
minimal_fields <- codecheck:::ror_metadata_fields(minimal)
expect_true(is.na(minimal_fields$country))
expect_true(is.na(minimal_fields$established))
expect_true(is.na(minimal_fields$website_url))
expect_true(is.na(minimal_fields$wikidata))
expect_equal(length(minimal_fields$aliases), 0)
expect_equal(length(minimal_fields$identifiers), 1)

# a record that could not be read at all still names the organisation by its id
unknown_fields <- codecheck:::ror_metadata_fields(NULL, "09unknown")
expect_equal(unknown_fields$name, "09unknown")
expect_equal(unknown_fields$ror_url, "https://ror.org/09unknown")

# --- the logo from Wikidata --------------------------------------------------

claims_for <- function(claims) {
  function(handle, params, api) list(entities = list(Q1 = list(claims = claims)))
}
snak <- function(property, file) {
  setNames(list(list(list(mainsnak = list(datavalue = list(value = file))))), property)
}

logo_with <- function(claims) {
  with_mocked_codecheck(list(wikibase_get = claims_for(claims)),
                        codecheck:::get_wikidata_logo_result("Q1"))
}

logo <- logo_with(snak("P154", "Logo of Delft.svg"))
expect_equal(logo$status, "found")
# a Commons file name resolves through Special:FilePath, spaces encoded
expect_equal(logo$value,
             "https://commons.wikimedia.org/wiki/Special:FilePath/Logo%20of%20Delft.svg?width=320")

# P18 is the fallback when the item has no logo
expect_equal(logo_with(snak("P18", "Campus.jpg"))$status, "found")
# and P154 wins when the item has both
both <- c(snak("P154", "Logo.svg"), snak("P18", "Campus.jpg"))
expect_true(grepl("Logo.svg", logo_with(both)$value, fixed = TRUE))

# an item with neither is a conclusive absence, an API error is not
expect_equal(logo_with(list())$status, "absent")
expect_equal(
  with_mocked_codecheck(
    list(wikibase_get = function(...) stop("no network")),
    codecheck:::get_wikidata_logo_result("Q1")
  )$status,
  "failed"
)
# no Wikidata item, no request at all
expect_equal(codecheck:::get_wikidata_logo_result(NA_character_)$status, "absent")

# --- organisation records from the register's people -------------------------

# Three people: one at two organisations, one at the same organisation as the
# first (so a certificate is not double counted), and one whose only
# ROR-identified affiliation had ended by the time of the work.
affiliation <- function(ror, start, end = NULL) {
  list(ror = ror, start = list(year = list(value = start)), end = end)
}
affiliations <- list(
  "0000-0000-0000-0001" = list(affiliation("02e2c7k09", "2015"),
                               affiliation("00000000a", "2015")),
  "0000-0000-0000-0002" = list(affiliation("02e2c7k09", "2015")),
  "0000-0000-0000-0003" = list(affiliation("00000000a", "2001",
                                           list(year = list(value = "2005"))))
)

mock_affiliations <- function(orcid) {
  entries <- affiliations[[orcid]]
  if (is.null(entries)) entries <- list()
  table <- data.frame(
    section = rep("employments", length(entries)),
    organization = rep(NA_character_, length(entries)),
    ror = vapply(entries, function(e) e$ror, character(1)),
    stringsAsFactors = FALSE
  )
  table$start <- lapply(entries, function(e) e$start)
  table$end <- lapply(entries, function(e) e$end)
  table
}

register_table <- data.frame(
  `Certificate ID` = c("2020-001", "2021-002"),
  `Check date` = c("2020-06-01", "2021-05-02"),
  OpenAlex = c(NA_character_, NA_character_),
  stringsAsFactors = FALSE, check.names = FALSE
)
register_table$Person <- list(
  list(list(orcid = "0000-0000-0000-0001", role = "author"),
       list(orcid = "0000-0000-0000-0002", role = "author"),
       list(orcid = "0000-0000-0000-0003", role = "codechecker")),
  list(list(orcid = "0000-0000-0000-0001", role = "codechecker"))
)

with_records <- with_mocked_codecheck(
  list(get_orcid_affiliations_cached = mock_affiliations,
       get_openalex_publication_date_cached = function(...) NA_character_),
  suppressMessages(codecheck:::add_organisation_records(register_table))
)

rors_of <- function(records) sort(vapply(records, function(r) r$ror, character(1)))
# the first certificate: two organisations for person 1, one for person 2, and
# nothing for person 3, whose affiliation ended in 2005
expect_equal(rors_of(with_records$Organisation[[1]]),
             c("00000000a", "02e2c7k09", "02e2c7k09"))
expect_equal(rors_of(with_records$Organisation[[2]]), c("00000000a", "02e2c7k09"))
expect_false("0000-0000-0000-0003" %in%
               vapply(with_records$Organisation[[1]], function(r) r$orcid, character(1)))

exploded <- codecheck:::explode_organisation_records(with_records)
expect_equal(nrow(exploded), 5)
expect_equal(sort(unique(exploded$Organisation)), c("00000000a", "02e2c7k09"))
# the role rides along, so the page can split works authored from checks
expect_equal(sort(unique(exploded$Role)), c("author", "codechecker"))

# a register whose people have no ROR at all yields no rows, not an error
none <- with_mocked_codecheck(
  list(get_orcid_affiliations_cached = function(orcid) mock_affiliations("nobody"),
       get_openalex_publication_date_cached = function(...) NA_character_),
  suppressMessages(codecheck:::add_organisation_records(register_table))
)
expect_equal(nrow(codecheck:::explode_organisation_records(none)), 0)

# --- the overview table ------------------------------------------------------

table <- with_mocked_codecheck(
  list(get_organisation_metadata = function(ror) list(
    name = if (ror == "02e2c7k09") "Delft University of Technology" else "Small Institute",
    country = "The Netherlands")),
  codecheck:::create_all_organisations_table(with_records)
)$organisations

col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["organisations"]]
expect_equal(colnames(table), unname(col_names))
expect_equal(nrow(table), 2)

delft <- table[table[[col_names[["Organisation"]]]] == "02e2c7k09", ]
# 2020-001 has two Delft authors, which is one authored work, not two
expect_equal(delft[[col_names[["no_works"]]]], 1)
expect_equal(delft[[col_names[["no_checks"]]]], 1)
expect_equal(delft[[col_names[["no_persons"]]]], 2)
expect_equal(delft[[col_names[["organisation_name"]]]], "Delft University of Technology")

small <- table[table[[col_names[["Organisation"]]]] == "00000000a", ]
expect_equal(small[[col_names[["no_works"]]]], 1)
expect_equal(small[[col_names[["no_checks"]]]], 1)
expect_equal(small[[col_names[["no_persons"]]]], 1)

# an empty register still produces the table's columns, for the index page
empty_table <- codecheck:::create_all_organisations_table(none)$organisations
expect_equal(colnames(empty_table), unname(col_names))
expect_equal(nrow(empty_table), 0)

linked <- codecheck:::add_all_organisations_hyperlink(table)
expect_true(any(grepl("[Delft University of Technology](./02e2c7k09/)",
                      linked[[col_names[["organisation_name"]]]], fixed = TRUE)))
expect_true(any(grepl("(https://ror.org/02e2c7k09)",
                      linked[[col_names[["Organisation"]]]], fixed = TRUE)))

# --- the venue cross-link ----------------------------------------------------

identifiers <- codecheck:::parse_venue_identifiers(
  "ROR|fa-university|05grdyy37|https://ror.org/05grdyy37")
# only a ROR that actually got a page this run is linked to
CONFIG$ORGANISATION_RORS <- character(0)
expect_true(is.na(codecheck:::venue_organisation_ror(identifiers)))
CONFIG$ORGANISATION_RORS <- c("05grdyy37")
expect_equal(codecheck:::venue_organisation_ror(identifiers), "05grdyy37")
# a venue with no ROR identifier at all
expect_true(is.na(codecheck:::venue_organisation_ror(
  codecheck:::parse_venue_identifiers("ISSN|fa-book|2047-217X"))))

# --- the provenance note -----------------------------------------------------

# The pages must say the data is derived and incomplete - both the landing
# pages and the overview table carry the same note.
note <- CONFIG$PAGE_NOTES[["organisations"]]
expect_true(grepl("Best effort", note, fixed = TRUE))
expect_true(grepl("ORCID", note, fixed = TRUE))
expect_true(grepl("ROR-identified", note, fixed = TRUE))
# the note is the same on the landing pages and above the overview table
expect_true(grepl("page-note", note, fixed = TRUE))
expect_identical(CONFIG$NON_REG_EXTRA_TEXT[["organisations"]], note)

R.cache::setCacheRootPath(old_root)
