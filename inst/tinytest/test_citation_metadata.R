# Citation metadata of certificate pages: the Highwire "citation_*" tags Google
# Scholar indexes and Zotero's Embedded Metadata translator reads, and the
# per-certificate OpenGraph tags, see codecheckers/register#52.

library(codecheck)
source("mocks.R")
source(system.file("extdata", "config.R", package = "codecheck"))

# a codecheck.yml as create_test_config() in test_schema_org_generation.R, with
# the fields the citation metadata is built from
create_citation_config <- function() {
  list(
    certificate = "2025-028",
    paper = list(
      title = "Example Research Paper on Computational Methods",
      authors = list(
        list(name = "Jane Doe", ORCID = "0000-0001-2345-6789"),
        list(name = "John Smith", ORCID = NULL)
      ),
      reference = "https://doi.org/10.1234/example.2025"
    ),
    codechecker = list(
      list(name = "Alice Checker", ORCID = "0000-0003-4567-8901"),
      list(name = "Bob Verifier", ORCID = "0000-0004-5678-9012")
    ),
    summary = "This CODECHECK verified the computational reproducibility of the analysis.",
    check_time = "2025-01-15 14:30:00",
    report = "https://doi.org/10.5281/zenodo.123456"
  )
}

# the content of every meta tag with the given name, parsed rather than matched
# with a regular expression so that escaping is actually exercised
meta_contents <- function(html, name) {
  doc <- xml2::read_html(paste0("<html><head>", html, "</head><body></body></html>"))
  nodes <- xml2::xml_find_all(doc, paste0("//meta[@name='", name, "']"))
  xml2::xml_attr(nodes, "content")
}

config <- create_citation_config()
meta <- generate_cert_citation_meta("2025-028", config,
                                    cert_title = "CODECHECK Certificate 2025-028",
                                    cert_venue = "GigaScience",
                                    has_pdf = TRUE)

# --- the three tags Google Scholar requires -----------------------------------
# Without title, author and publication date Scholar processes the page "as if
# it had no meta tags", so their absence would silently undo the whole feature.

expect_equal(meta_contents(meta, "citation_title"),
             "CODECHECK Certificate 2025-028",
             info = "citation_title is the record title")

expect_equal(meta_contents(meta, "citation_author"),
             c("Alice Checker", "Bob Verifier"),
             info = "one citation_author per codechecker, in order")

expect_equal(meta_contents(meta, "citation_publication_date"),
             "2025/01/15",
             info = "check_time formatted as Google Scholar's date format")

# --- what makes Zotero read the page as a report ------------------------------

expect_equal(meta_contents(meta, "citation_technical_report_institution"),
             "CODECHECK Initiative",
             info = "the tag Zotero maps to itemType 'report'")

expect_equal(meta_contents(meta, "citation_technical_report_number"), "2025-028")
expect_equal(meta_contents(meta, "citation_publisher"), "CODECHECK Initiative")

# The publisher is deliberately not the Zenodo curation policy's "CODECHECK
# Community on Zenodo": certificates are also published on OSF and
# ResearchEquals, and that string names one archived copy, not the publisher.
expect_false(grepl("Community on Zenodo", meta, fixed = TRUE),
             info = "citation metadata does not claim Zenodo published the certificate")

# --- remaining fields ---------------------------------------------------------

expect_equal(meta_contents(meta, "citation_doi"), "10.5281/zenodo.123456",
             info = "citation_doi is the bare DOI, without the resolver prefix")

expect_equal(meta_contents(meta, "citation_abstract"), config$summary)

expect_equal(meta_contents(meta, "citation_pdf_url"),
             "https://codecheck.org.uk/register/certs/2025-028/cert.pdf",
             info = "absolute URL, as Google Scholar requires")

expect_equal(meta_contents(meta, "citation_language"), "en")

expect_true(grepl("GigaScience", meta_contents(meta, "citation_keywords"), fixed = TRUE),
            info = "the venue is among the keywords")

# --- the tags must describe the certificate, not the checked paper ------------
# Emitting the paper's title or authors would make Scholar treat this page as a
# duplicate of the paper and Zotero save the wrong item.

expect_false(grepl(config$paper$title, meta, fixed = TRUE),
             info = "the paper title is not the citation_title of the certificate page")

expect_false(any(grepl("Jane Doe", meta, fixed = TRUE)),
             info = "the paper's authors are not citation_authors of the certificate")

# --- no PDF next to the page --------------------------------------------------

meta_no_pdf <- generate_cert_citation_meta("2025-028", config,
                                           cert_title = "CODECHECK Certificate 2025-028",
                                           has_pdf = FALSE)
expect_equal(length(meta_contents(meta_no_pdf, "citation_pdf_url")), 0L,
             info = "no citation_pdf_url is offered when there is no PDF to point at")

# --- escaping -----------------------------------------------------------------
# Meta tag values are HTML attributes; Google Scholar's guidelines require them
# to be escaped, and certificate summaries routinely contain & and quotes.

nasty <- create_citation_config()
nasty$summary <- 'Checked "figures & tables" <all of them>'
nasty$codechecker <- list(list(name = "Ann O'Neill & Co"))

meta_nasty <- generate_cert_citation_meta("2025-029", nasty,
                                          cert_title = 'A "quoted" & <odd> title',
                                          has_pdf = FALSE)

expect_equal(meta_contents(meta_nasty, "citation_title"),
             'A "quoted" & <odd> title',
             info = "special characters round-trip through the escaped attribute")

expect_equal(meta_contents(meta_nasty, "citation_author"), "Ann O'Neill & Co")

expect_equal(meta_contents(meta_nasty, "citation_abstract"),
             'Checked "figures & tables" <all of them>')

# --- degrading on incomplete configurations -----------------------------------
# codecheck.yml files in the register are not uniform; a missing field must drop
# its tag, never abort the render of the certificate page.

sparse <- list(certificate = "2025-030", codechecker = list(list(name = "Solo Checker")))
meta_sparse <- generate_cert_citation_meta("2025-030", sparse, has_pdf = FALSE)

expect_equal(meta_contents(meta_sparse, "citation_title"),
             "CODECHECK Certificate 2025-030",
             info = "falls back to the constructed title when none is known")
expect_equal(meta_contents(meta_sparse, "citation_author"), "Solo Checker")
expect_equal(length(meta_contents(meta_sparse, "citation_publication_date")), 0L)
expect_equal(length(meta_contents(meta_sparse, "citation_doi")), 0L)
expect_equal(length(meta_contents(meta_sparse, "citation_abstract")), 0L)

no_checkers <- create_citation_config()
no_checkers$codechecker <- list()
expect_silent(generate_cert_citation_meta("2025-031", no_checkers, has_pdf = FALSE))

# a report reference that is not a DOI must not produce a citation_doi
not_a_doi <- create_citation_config()
not_a_doi$report <- "https://example.com/reports/42"
expect_equal(length(meta_contents(generate_cert_citation_meta("2025-032", not_a_doi), "citation_doi")), 0L,
             info = "only an actual DOI becomes citation_doi")

# --- OpenGraph ----------------------------------------------------------------
# Every certificate page used to advertise itself as "CODECHECK Register" at the
# register's own URL, which is what these replace.

og <- codecheck:::generate_cert_opengraph("2025-028", config,
                              cert_title = "CODECHECK Certificate 2025-028",
                              has_preview = TRUE)

expect_equal(og$og_title, "CODECHECK Certificate 2025-028")
expect_equal(og$og_url, "https://codecheck.org.uk/register/certs/2025-028/")
expect_equal(og$og_type, "article")
expect_equal(og$og_image, "https://codecheck.org.uk/register/certs/2025-028/cert_1.png")
expect_true(grepl("reproducibility of the analysis", og$og_description, fixed = TRUE))

og_no_preview <- codecheck:::generate_cert_opengraph("2025-028", config, has_preview = FALSE)
expect_equal(og_no_preview$og_image, "",
             info = "no og:image when the preview was not rendered")

# a long summary is shortened for the social preview
long <- create_citation_config()
long$summary <- paste(rep("word", 200), collapse = " ")
expect_true(nchar(codecheck:::generate_cert_opengraph("2025-028", long)$og_description) <= 301)

# --- helpers ------------------------------------------------------------------

expect_equal(codecheck:::bare_doi("https://doi.org/10.5281/zenodo.123456"), "10.5281/zenodo.123456")
expect_equal(codecheck:::bare_doi("http://dx.doi.org/10.5281/zenodo.123456"), "10.5281/zenodo.123456")
expect_equal(codecheck:::bare_doi("doi:10.5281/zenodo.123456"), "10.5281/zenodo.123456")
expect_equal(codecheck:::bare_doi("10.53962/abcd-1234"), "10.53962/abcd-1234")
expect_null(codecheck:::bare_doi("https://osf.io/abc12/"))
expect_null(codecheck:::bare_doi(NULL))
expect_null(codecheck:::bare_doi(""))
