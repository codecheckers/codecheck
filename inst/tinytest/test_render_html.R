tinytest::using(ttdo)

test_path <- "register/short.csv"
test_register <- read.csv(test_path)
venues_path <- "register/venues.csv"

register_render(register = test_register, filter_by = c(), outputs = c("html"),
                config = c(system.file("extdata", "config.R", package = "codecheck"),
                           "config/render_html.R"),
                venues_file = venues_path
                )

# file generation ----
expect_true(file.exists(file.path("docs/index.html")))
expect_true(file.exists(file.path("docs/certs/2024-017/index.html")))
expect_false(file.exists(file.path("docs/certs/2024-017/cert.pdf")))
expect_false(file.exists(file.path("docs/certs/2024-017/cert_20.png")))

expect_true(file.exists(file.path("docs/certs/2021-010/index.html")))
expect_true(file.exists(file.path("docs/certs/2022-018/index.html")))

# citation metadata of certificate pages (register#52) ----
# The Highwire tags Google Scholar indexes and Zotero reads. Asserted
# structurally rather than by value: the record title comes from Zenodo and is
# not this test's to pin down.

cert_head <- xml2::read_html("docs/certs/2024-017/index.html")
meta_content <- function(doc, name) {
  xml2::xml_attr(xml2::xml_find_all(doc, paste0("//meta[@name='", name, "']")), "content")
}
property_content <- function(doc, property) {
  xml2::xml_attr(xml2::xml_find_all(doc, paste0("//meta[@property='", property, "']")), "content")
}

# the three tags without which Google Scholar ignores the page entirely
expect_true(length(meta_content(cert_head, "citation_title")) == 1)
expect_true(length(meta_content(cert_head, "citation_author")) >= 1)
expect_true(length(meta_content(cert_head, "citation_publication_date")) == 1)

# what makes Zotero read the page as a report rather than a web page
expect_equal(meta_content(cert_head, "citation_technical_report_institution"),
             "CODECHECK Initiative")
expect_equal(meta_content(cert_head, "citation_technical_report_number"), "2024-017")

# this certificate has no PDF next to it, so none may be advertised
expect_equal(length(meta_content(cert_head, "citation_pdf_url")), 0L)

# the page describes the certificate, not the register
expect_equal(property_content(cert_head, "og:url"),
             "https://codecheck.org.uk/register/certs/2024-017/")
expect_true(grepl("2024-017", property_content(cert_head, "og:title"), fixed = TRUE))

# register pages are unchanged by the shared header template gaining those slots
index_head <- xml2::read_html("docs/index.html")
expect_equal(property_content(index_head, "og:title"), "CODECHECK Register")
expect_equal(property_content(index_head, "og:url"), "https://codecheck.org.uk/register/")
expect_equal(length(meta_content(index_head, "citation_title")), 0L,
             info = "citation metadata belongs on certificate pages only")

# whisker treats "" as true, so the optional blocks are switched on explicit
# flags: a page with no og:image must emit no og:image tag at all, and a page
# with no Schema.org metadata of its own must fall back to the generic website
# JSON-LD rather than an empty <script>
expect_equal(length(property_content(index_head, "og:image")), 0L,
             info = "no empty og:image on pages without a preview image")

index_jsonld <- xml2::xml_text(xml2::xml_find_all(index_head, "//script[@type='application/ld+json']"))
expect_true(all(nzchar(trimws(index_jsonld))),
            info = "no empty ld+json script; the generic website metadata is used")
expect_true(any(grepl("WebSite", index_jsonld, fixed = TRUE)))

cert_jsonld <- xml2::xml_text(xml2::xml_find_all(cert_head, "//script[@type='application/ld+json']"))
expect_true(any(grepl("\"@type\": \"Review\"", cert_jsonld)),
            info = "the certificate page carries its own Review metadata")

# sortable table headers (click-to-sort via stupidtable.js) ----

th_data_sort <- function(doc, header_text) {
  xml2::xml_attr(
    xml2::xml_find_all(doc, paste0("//table/thead//th[normalize-space(text())='", header_text, "']")),
    "data-sort"
  )
}

expect_equal(th_data_sort(index_head, "Certificate"), "string")
expect_equal(th_data_sort(index_head, "Venue"), "string")
expect_equal(th_data_sort(index_head, "Type"), "string")
expect_equal(th_data_sort(index_head, "Check date"), "string")
expect_true(is.na(th_data_sort(index_head, "Report")),
            info = "Report holds a link, not a sortable value")
expect_true(is.na(th_data_sort(index_head, "Work")),
            info = "Work holds a link, not a sortable value")

postfix_scripts <- xml2::xml_attr(xml2::xml_find_all(index_head, "//script"), "src")
expect_true(any(grepl("stupidtable.min.js", postfix_scripts, fixed = TRUE)))
expect_true(any(grepl("table-sort-init.js", postfix_scripts, fixed = TRUE)))

# the shipped initialiser keeps the sort state of each table in the URL
# ("?sort=-check-date"), so a sorted view can be linked and bookmarked
table_sort_init <- paste(
  readLines(system.file("extdata", "js", "table-sort-init.js", package = "codecheck")),
  collapse = "\n"
)
expect_true(grepl("URLSearchParams", table_sort_init, fixed = TRUE),
            info = "the sort state is read from the query string")
expect_true(grepl("replaceState", table_sort_init, fixed = TRUE),
            info = "sorting updates the URL without adding a history entry")

# TODO ----

# clean up
expect_equal(unlink("docs", recursive = TRUE), 0)
