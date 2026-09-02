# FAIR Signposting on register pages, expressed as HTML <link> elements because
# GitHub Pages cannot set HTTP Link headers, see codecheckers/register#55.

library(codecheck)
source(system.file("extdata", "config.R", package = "codecheck"))
codecheck:::load_venues_config("register/venues_metadata.csv")

# a codecheck.yml with the fields signposting is built from, same shape as
# create_citation_config() in test_citation_metadata.R
create_signposting_config <- function() {
  list(
    certificate = "2025-028",
    paper = list(
      title = "Example Research Paper on Computational Methods",
      authors = list(list(name = "Jane Doe", ORCID = "0000-0001-2345-6789")),
      reference = "https://doi.org/10.1234/example.2025"
    ),
    codechecker = list(
      list(name = "Alice Checker", ORCID = "0000-0003-4567-8901"),
      list(name = "Bob Verifier", ORCID = "0000-0004-5678-9012")
    ),
    check_time = "2025-01-15 14:30:00",
    report = "https://doi.org/10.5281/zenodo.123456"
  )
}

rels <- function(html) {
  matches <- regmatches(html, gregexpr('rel="[^"]+"', html))[[1]]
  gsub('rel="|"', "", matches)
}

# --- certificate pages ------------------------------------------------------

cert <- generate_cert_signposting("2025-028", create_signposting_config(),
                                  has_pdf = TRUE, has_jsonld = TRUE)

# cite-as is the certificate's own DOI, not the checked paper's: the paper has
# its own landing page at its own PID
expect_true(grepl('rel="cite-as" href="https://doi.org/10.5281/zenodo.123456"', cert, fixed = TRUE))
expect_false(grepl("10.1234/example.2025", cert, fixed = TRUE))

# the profile asks for two type links, the object's class and the page's
expect_equal(sum(rels(cert) == "type"), 2L)
expect_true(grepl("https://schema.org/Review", cert, fixed = TRUE))
expect_true(grepl("https://schema.org/AboutPage", cert, fixed = TRUE))

# one author link per codechecker with an ORCID
expect_equal(sum(rels(cert) == "author"), 2L)
expect_true(grepl("https://orcid.org/0000-0003-4567-8901", cert, fixed = TRUE))

# machine-readable metadata, correctly typed, and the PDF as the content resource
expect_true(grepl('rel="describedby" href="index.json" type="application/json"', cert, fixed = TRUE))
expect_true(grepl('rel="describedby" href="index.jsonld" type="application/ld+json"', cert, fixed = TRUE))
expect_true(grepl('rel="item" href="cert.pdf" type="application/pdf"', cert, fixed = TRUE))

# a certificate is CC-BY 4.0, per the Zenodo community curation policy
expect_true(grepl("creativecommons.org/licenses/by/4.0/", cert, fixed = TRUE))

# Relations that cannot be stated truthfully are omitted, never guessed.
no_doi <- create_signposting_config()
no_doi$report <- NULL
minimal <- generate_cert_signposting("2025-028", no_doi, has_pdf = FALSE, has_jsonld = FALSE)
expect_false("cite-as" %in% rels(minimal))
expect_false("item" %in% rels(minimal))
expect_false(grepl("index.jsonld", minimal, fixed = TRUE))
# the index.json describedby is unconditional, that file is always written
expect_true(grepl("index.json", minimal, fixed = TRUE))

# A codechecker without an ORCID contributes no author link rather than an
# empty one.
no_orcid <- create_signposting_config()
no_orcid$codechecker <- list(list(name = "Nameless Checker"))
expect_equal(sum(rels(generate_cert_signposting("2025-028", no_orcid)) == "author"), 0L)

# --- work pages -------------------------------------------------------------

work_table <- data.frame(
  Certificate = "2025-001",
  `Paper Title` = "Example Research Paper",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
work <- generate_work_signposting("10.1234/example.2025", work_table, has_jsonld = TRUE)

# a work page is about a paper, which has a real PID of its own
expect_true(grepl('rel="cite-as" href="https://doi.org/10.1234/example.2025"', work, fixed = TRUE))
expect_true(grepl("https://schema.org/ScholarlyArticle", work, fixed = TRUE))
expect_true(grepl('rel="alternate" href="register.json"', work, fixed = TRUE))
# the register data is ODC-By, unlike the CC-BY certificates
expect_true(grepl("opendatacommons.org/licenses/by/1-0/", work, fixed = TRUE))

# --- person pages -----------------------------------------------------------

person <- generate_person_signposting("0000-0003-4567-8901", has_jsonld = TRUE)
expect_true(grepl('rel="cite-as" href="https://orcid.org/0000-0003-4567-8901"', person, fixed = TRUE))
expect_true(grepl("https://schema.org/ProfilePage", person, fixed = TRUE))
# the person authors the checks listed on the page, not the page itself
expect_false("author" %in% rels(person))
expect_true(grepl('href="index.jsonld" type="application/ld+json"', person, fixed = TRUE))

# --- venue pages ------------------------------------------------------------

# AGILEGIS carries a wikidata item in the fixture, so it gets a cite-as; the
# Schema.org class follows the venue type
venue <- generate_venue_signposting("AGILEGIS", "conference")
expect_true(grepl('rel="cite-as" href="https://www.wikidata.org/entity/Q12345678"', venue, fixed = TRUE))
expect_true(grepl("https://schema.org/EventSeries", venue, fixed = TRUE))
expect_true(grepl('rel="alternate" href="register.csv" type="text/csv"', venue, fixed = TRUE))

# A row of venues.csv that is a publication state rather than a venue carries a
# class item from the Wikidata data model (Q580922, "preprint") in its wikidata
# column. That is not an identifier of the page's subject, so no cite-as.
expect_false("cite-as" %in% rels(generate_venue_signposting("Preprints", "journal")))

# GigaByte has no wikidata item in the fixture: no cite-as rather than a made-up one
gigabyte <- generate_venue_signposting("GigaByte", "journal")
expect_false("cite-as" %in% rels(gigabyte))
expect_true(grepl("https://schema.org/Periodical", gigabyte, fixed = TRUE))

# --- listing pages ----------------------------------------------------------

main <- generate_list_signposting(is_main_register = TRUE, has_register_files = TRUE)
expect_true(grepl("https://schema.org/CollectionPage", main, fixed = TRUE))
# the JSON and CSV exports become discoverable from the HTML
expect_true(grepl('href="register-full.json"', main, fixed = TRUE))
expect_true(grepl('href="register-full.csv" type="text/csv"', main, fixed = TRUE))
expect_false("cite-as" %in% rels(main))

overview <- generate_list_signposting(is_main_register = FALSE,
                                      has_register_files = FALSE,
                                      has_index_json = TRUE)
expect_false(grepl("register.json", overview, fixed = TRUE))
expect_true(grepl('rel="describedby" href="index.json"', overview, fixed = TRUE))

# No listing page enumerates its members as `item`: that relation means a
# content resource of the described object, and enumerating members is what a
# Level 2 link set is for, which GitHub Pages cannot serve.
for (page in list(main, overview, venue, person, work)) {
  expect_false("item" %in% rels(page))
}

# --- dispatch ---------------------------------------------------------------

expect_equal(
  generate_page_signposting("venues", list(is_reg_table = TRUE, name = "AGILEGIS", subcat = "conference")),
  generate_venue_signposting("AGILEGIS", "conference")
)
expect_equal(
  generate_page_signposting("persons", list(is_reg_table = TRUE, name = "0000-0003-4567-8901")),
  generate_person_signposting("0000-0003-4567-8901")
)
# codechecker pages describe the same person as the person page they redirect to
expect_equal(
  generate_page_signposting("codecheckers", list(is_reg_table = TRUE, name = "0000-0003-4567-8901")),
  generate_person_signposting("0000-0003-4567-8901")
)
# the main register page
expect_equal(
  generate_page_signposting(NA, list()),
  generate_list_signposting(is_main_register = TRUE, has_register_files = TRUE)
)
# a venue type overview page lists subpages, so it has an index.json but no
# register.json
expect_equal(
  generate_page_signposting("venues", list(is_reg_table = FALSE, subcat = "journal")),
  generate_list_signposting(is_main_register = FALSE, has_register_files = FALSE,
                            has_index_json = TRUE)
)

# --- the JSON-LD document the describedby links point at ---------------------

tmp <- tempfile("signposting")
dir.create(tmp)
expect_true(codecheck:::write_schema_org_jsonld('{"@context":"https://schema.org"}', tmp))
expect_true(file.exists(file.path(tmp, "index.jsonld")))
expect_false(codecheck:::write_schema_org_jsonld("", tmp))
unlink(tmp, recursive = TRUE)
