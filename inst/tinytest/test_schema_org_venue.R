# Test Schema.org metadata generation for venue pages (register#183)

library(codecheck)

# Populate CONFIG (VENUE_SUBCAT_PLURAL, HYPERLINKS, VENUE_DATA) the same way
# a real render does, using the test fixture venues.csv with full metadata.
source(system.file("extdata", "config.R", package = "codecheck"))
codecheck:::load_venues_config("register/venues_metadata.csv")

create_test_register <- function() {
  data.frame(
    Certificate = c("2025-001", "2025-002"),
    Repository = c("github::example/repo1", "github::example/repo2"),
    `Check date` = c("2025-01-15", "2025-02-20"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

# Test: venue_schema_org_type() maps each register.csv Type to a sensible
# Schema.org type ----
expect_equal(codecheck:::venue_schema_org_type("journal"), "Periodical")
expect_equal(codecheck:::venue_schema_org_type("conference"), "EventSeries")
expect_equal(codecheck:::venue_schema_org_type("institution"), "Organization")
expect_equal(codecheck:::venue_schema_org_type("community"), "Organization")
expect_equal(codecheck:::venue_schema_org_type("something_unknown"), "Organization")

# Test: basic generation with full venues.csv metadata (AGILEGIS) ----
register_table <- create_test_register()
json_ld_string <- generate_venue_schema_org("AGILEGIS", "conference", register_table)

expect_true(!is.null(json_ld_string) && nchar(json_ld_string) > 0)

json_ld <- tryCatch(jsonlite::fromJSON(json_ld_string, simplifyVector = FALSE), error = function(e) NULL)
expect_false(is.null(json_ld), info = "Generated JSON-LD should be valid JSON")

expect_equal(json_ld$`@context`, "https://schema.org")
expect_true(is.list(json_ld$`@graph`))

venue_entity <- json_ld$`@graph`[[1]]
expect_equal(venue_entity$`@type`, "EventSeries")
expect_equal(venue_entity$name, "AGILE Conference on Geographic Information Science")
expect_equal(venue_entity$sameAs, "https://agile-gi.eu")
expect_equal(venue_entity$description, "A conference on geographic information science.")
expect_equal(venue_entity$logo$`@type`, "ImageObject")
expect_equal(venue_entity$logo$url, "https://example.org/agile-logo.svg")

# @id prefers an identifier's own url (ROR here) over the venue's own page
expect_equal(venue_entity$`@id`, "https://ror.org/05wg1m734")
# The page url is still included separately
expect_equal(venue_entity$url, "https://codecheck.org.uk/register/venues/conferences/agilegis/")

# Both identifiers become PropertyValues, in venues.csv order
expect_equal(length(venue_entity$identifier), 2)
expect_equal(venue_entity$identifier[[1]]$`@type`, "PropertyValue")
expect_equal(venue_entity$identifier[[1]]$propertyID, "ROR")
expect_equal(venue_entity$identifier[[1]]$value, "05wg1m734")
expect_equal(venue_entity$identifier[[1]]$url, "https://ror.org/05wg1m734")
expect_equal(venue_entity$identifier[[2]]$propertyID, "ISSN")
# ISSN's default portal link (no explicit url in the fixture) still applies
expect_equal(venue_entity$identifier[[2]]$url, "https://portal.issn.org/resource/ISSN/1234-5678")

# 1 venue entity + 2 reviews
expect_equal(length(json_ld$`@graph`), 3)
review1 <- json_ld$`@graph`[[2]]
expect_equal(review1$`@type`, "Review")
expect_equal(review1$`@id`, "https://codecheck.org.uk/register/certs/2025-001/")
expect_equal(review1$name, "CODECHECK Certificate 2025-001")
expect_equal(review1$datePublished, "2025-01-15")
# Repository points nowhere real, so no codecheck.yml - itemReviewed is
# gracefully absent rather than erroring (same as the codechecker equivalent).
expect_true(is.null(review1$itemReviewed))

# Test: a venue with no venues.csv metadata at all still produces a minimal,
# valid graph (Organization fallback, no @id/logo/identifier/description) ----
json_ld_minimal <- generate_venue_schema_org("Some Unlisted Venue", "institution", create_test_register())
parsed_minimal <- jsonlite::fromJSON(json_ld_minimal, simplifyVector = FALSE)
minimal_entity <- parsed_minimal$`@graph`[[1]]
expect_equal(minimal_entity$`@type`, "Organization")
expect_equal(minimal_entity$name, "Some Unlisted Venue")
expect_equal(minimal_entity$`@id`, "https://codecheck.org.uk/register/venues/institutions/some_unlisted_venue/")
expect_true(is.null(minimal_entity$logo))
expect_true(is.null(minimal_entity$identifier))
expect_true(is.null(minimal_entity$description))

# Test: no codechecks yields just the venue entity, no error ----
json_ld_empty <- generate_venue_schema_org("GigaByte", "journal", create_test_register()[0, ])
parsed_empty <- jsonlite::fromJSON(json_ld_empty, simplifyVector = FALSE)
expect_equal(length(parsed_empty$`@graph`), 1)

# Test: register_table$Certificate, as produced by the real add_cert_links()
# preprocessing step, must stay a plain identifier - generate_venue_schema_org()
# must not embed markdown link markup in @id/url/name (register regression: it
# used to read a column add_cert_links() had rewritten into "[id](url)") ----
table_via_add_cert_links <- codecheck:::add_cert_links(data.frame(
  Certificate = "2025-403",
  Repository = "github::example/repo3",
  `Check date` = "2025-06-01",
  stringsAsFactors = FALSE,
  check.names = FALSE
))

expect_equal(
  table_via_add_cert_links$Certificate,
  "2025-403",
  info = "add_cert_links() must leave Certificate as the plain identifier"
)

json_ld_via_add_cert_links <- generate_venue_schema_org("AGILEGIS", "conference", table_via_add_cert_links)
parsed_via_add_cert_links <- jsonlite::fromJSON(json_ld_via_add_cert_links, simplifyVector = FALSE)
review_via_add_cert_links <- parsed_via_add_cert_links$`@graph`[[2]]

expect_equal(
  review_via_add_cert_links$`@id`,
  "https://codecheck.org.uk/register/certs/2025-403/",
  info = "@id must be a plain certificate URL, not markdown link markup"
)
expect_equal(
  review_via_add_cert_links$url,
  "https://codecheck.org.uk/register/certs/2025-403/",
  info = "url must be a plain certificate URL, not markdown link markup"
)

# Test: valid JSON-LD markers present, for a schema.org validator to find ----
expect_true(grepl('"@context"', json_ld_string, fixed = TRUE))
expect_true(grepl('"@type"', json_ld_string, fixed = TRUE))
expect_true(grepl('"@graph"', json_ld_string, fixed = TRUE))

# Integration test: a rendered venue HTML page actually embeds this JSON-LD,
# and it is real per-venue metadata rather than the generic site-wide
# fallback used on pages without their own Schema.org data ----
test_register <- read.csv("register/short.csv", as.is = TRUE)
expect_silent({ capture.output(
  {
    register_render(register = test_register, filter_by = c("venues"), outputs = c("html"),
                    venues_file = "register/venues_metadata.csv")
  },
  type = "message"
  )
  })

agile_html <- paste(readLines(file.path("docs", "venues", "conferences", "agilegis", "index.html")), collapse = "\n")
expect_true(grepl('<script type="application/ld\\+json">', agile_html))
expect_true(grepl('"@type": "EventSeries"', agile_html, fixed = TRUE))
expect_true(grepl('"@id": "https://ror.org/05wg1m734"', agile_html, fixed = TRUE))
# ...not the generic website fallback (which describes "CODECHECK", not the venue)
expect_false(grepl('"name": "CODECHECK"', agile_html, fixed = TRUE))
# Review @id/url must be plain certificate URLs, not markdown link syntax
# leaked from the (real, add_cert_links()-processed) register table
expect_false(
  grepl('/register/certs/[[]', agile_html),
  info = "Review @id/url must not contain markdown link markup"
)

expect_equal(unlink("docs", recursive = TRUE), 0)
