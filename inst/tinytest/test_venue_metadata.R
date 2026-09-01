tinytest::using(ttdo)

# Unit tests: parse_venue_identifiers() ----

expect_equal(codecheck:::parse_venue_identifiers(""), list())
expect_equal(codecheck:::parse_venue_identifiers(NA), list())

single <- codecheck:::parse_venue_identifiers("ROR|fa-university|05wg1m734|https://ror.org/05wg1m734")
expect_equal(length(single), 1)
expect_equal(single[[1]]$name, "ROR")
expect_equal(single[[1]]$icon, "fa-university")
expect_equal(single[[1]]$value, "05wg1m734")
expect_equal(single[[1]]$link, "https://ror.org/05wg1m734")

no_link <- codecheck:::parse_venue_identifiers("ConfIDent|fa-calendar|AGILE-GI series")
expect_equal(length(no_link), 1)
expect_equal(no_link[[1]]$name, "ConfIDent")
expect_equal(no_link[[1]]$icon, "fa-calendar")
expect_equal(no_link[[1]]$value, "AGILE-GI series")
expect_true(is.null(no_link[[1]]$link))

no_icon <- codecheck:::parse_venue_identifiers("ROR||05wg1m734|https://ror.org/05wg1m734")
expect_equal(length(no_icon), 1)
expect_true(is.null(no_icon[[1]]$icon))
expect_equal(no_icon[[1]]$value, "05wg1m734")

multi <- codecheck:::parse_venue_identifiers("ROR|fa-university|05wg1m734|https://ror.org/05wg1m734;ISSN|fa-book|1234-5678")
expect_equal(length(multi), 2)
expect_equal(multi[[2]]$name, "ISSN")

# An ISSN identifier without an explicit url defaults to its ISSN Portal page
issn_default_link <- codecheck:::parse_venue_identifiers("ISSN|fa-book|2047-217X")
expect_equal(issn_default_link[[1]]$link, "https://portal.issn.org/resource/ISSN/2047-217X")

# ...but an explicit url (e.g. print vs. online ISSN) is not overridden
issn_explicit_link <- codecheck:::parse_venue_identifiers("ISSN (print)|fa-book|1435-5930|https://portal.issn.org/resource/ISSN/1435-5930")
expect_equal(issn_explicit_link[[1]]$link, "https://portal.issn.org/resource/ISSN/1435-5930")

# Unit tests: generate_venue_metadata_html() ----

empty_row <- data.frame(name = "X", longname = "X", label = "journal", stringsAsFactors = FALSE)
# The panel is never truly empty: the API & statistics link always renders,
# even for a venue with no other metadata at all.
empty_html <- codecheck:::generate_venue_metadata_html(empty_row)
expect_true(grepl("venue-metadata", empty_html, fixed = TRUE))
expect_true(grepl('API &amp; statistics:</span> <a href="index.json">index.json</a>', empty_html, fixed = TRUE))
expect_true(grepl('<i class="fa fa-cog"></i>', empty_html, fixed = TRUE))
expect_false(grepl("CODECHECK contact", empty_html, fixed = TRUE))

full_row <- data.frame(
  name = "AGILEGIS", longname = "AGILE Conference", label = "conference",
  logo_url = "https://example.org/logo.svg",
  website_url = "https://agile-gi.eu",
  contact_name = "Jane Doe",
  contact_email = "jane@example.org",
  description = "A conference on geographic information science.",
  identifiers = "ROR|fa-university|05wg1m734|https://ror.org/05wg1m734;ISSN|fa-book|1234-5678",
  stringsAsFactors = FALSE
)
html <- codecheck:::generate_venue_metadata_html(full_row)
expect_true(grepl("venue-metadata", html, fixed = TRUE))
expect_true(grepl("Jane Doe", html, fixed = TRUE))
expect_true(grepl("mailto:jane@example.org", html, fixed = TRUE))
expect_true(grepl("https://agile-gi.eu", html, fixed = TRUE))
expect_true(grepl("A conference on geographic information science.", html, fixed = TRUE))
expect_true(grepl("https://ror.org/05wg1m734", html, fixed = TRUE))
expect_true(grepl('<i class="fa fa-university"></i>', html, fixed = TRUE))
expect_true(grepl("ISSN", html, fixed = TRUE))

# A venue with only a logo set (no contact/website/description/identifiers)
# still renders a (smaller) panel rather than being treated as "nothing to show"
logo_only_row <- data.frame(
  name = "GigaByte", longname = "GigaByte", label = "journal",
  logo_url = "https://example.org/gigabyte-logo.svg",
  stringsAsFactors = FALSE
)
logo_only_html <- codecheck:::generate_venue_metadata_html(logo_only_row)
expect_true(grepl("venue-metadata", logo_only_html, fixed = TRUE))
expect_true(grepl("gigabyte-logo.svg", logo_only_html, fixed = TRUE))
expect_false(grepl("CODECHECK contact", logo_only_html, fixed = TRUE))

# The venue type (from register.csv, passed in separately - not venues.csv's
# "label" column) renders as its own row, and alone is enough to render a
# panel for a venue with no venues.csv metadata at all.
type_only_row <- data.frame(name = "X", stringsAsFactors = FALSE)
type_only_html <- codecheck:::generate_venue_metadata_html(type_only_row, venue_type = "journal")
expect_true(grepl("venue-metadata", type_only_html, fixed = TRUE))
expect_true(grepl('Venue type:</span> <a href="../index.html">journal</a>', type_only_html, fixed = TRUE))

# Unit tests: generate_venue_metadata_yaml() ----

expect_equal(codecheck:::generate_venue_metadata_yaml(empty_row), "")

yaml_str <- codecheck:::generate_venue_metadata_yaml(full_row, venue_type = "conference")
expect_true(grepl("venue_type: conference", yaml_str, fixed = TRUE))
expect_true(grepl("website: https://agile-gi.eu", yaml_str, fixed = TRUE))
expect_true(grepl("contact_name: Jane Doe", yaml_str, fixed = TRUE))
expect_true(grepl("contact_email: jane@example.org", yaml_str, fixed = TRUE))
expect_true(grepl("name: ROR", yaml_str, fixed = TRUE))
expect_true(grepl("url: https://ror.org/05wg1m734", yaml_str, fixed = TRUE))
expect_false(grepl("<div", yaml_str, fixed = TRUE))
# Valid YAML: round-trips through the parser without error
parsed <- yaml::yaml.load(yaml_str)
expect_equal(parsed$venue_type, "conference")
expect_equal(parsed$identifiers[[1]]$name, "ROR")

# Integration test: rendering an individual venue page includes the panel
# only for venues that have metadata set ----

test_path <- "register/short.csv"
test_register <- read.csv(test_path)
venues_path <- "register/venues_metadata.csv"

expect_silent({ capture.output(
  {
    register_render(register = test_register, filter_by = c("venues"), outputs = c("md", "html", "json"),
                    venues_file = venues_path)
  },
  type = "message"
  )
  })

# register.md is served as a plain markdown/API text file, not HTML - its
# venue metadata belongs in the YAML frontmatter header, not as an HTML
# <div> in the body (register#84 followup).
agile_md <- readLines(file.path("docs", "venues", "conferences", "agilegis", "register.md"))
agile_md <- paste(agile_md, collapse = "\n")
expect_false(grepl("venue-metadata", agile_md, fixed = TRUE))
expect_false(grepl("<div", agile_md, fixed = TRUE))
expect_true(grepl("venue_type: conference", agile_md, fixed = TRUE))
expect_true(grepl("website: https://agile-gi.eu", agile_md, fixed = TRUE))
expect_true(grepl("contact_name: Jane Doe", agile_md, fixed = TRUE))
expect_true(grepl("contact_email: jane@example.org", agile_md, fixed = TRUE))
expect_true(grepl("name: ROR", agile_md, fixed = TRUE))
expect_true(grepl("url: https://ror.org/05wg1m734", agile_md, fixed = TRUE))
# The venue type moved from the title into the metadata (register#84 followup).
# The title is YAML-quoted (add_markdown_title()) so that a work page's title -
# which can contain a colon ("svaRetro and svaNUMT: Modular packages...") -
# doesn't break the frontmatter; every filter's title is quoted the same way
# for consistency, this venue title included, even though it never needed it.
expect_true(grepl('title: "CODECHECKs for AGILEGIS"', agile_md, fixed = TRUE))
expect_false(grepl("(conference)", agile_md, fixed = TRUE))
# Frontmatter is well-formed: still exactly two "---" delimiter lines
frontmatter_lines <- readLines(file.path("docs", "venues", "conferences", "agilegis", "register.md"))
expect_equal(sum(frontmatter_lines == "---"), 2)

gigabyte_md <- readLines(file.path("docs", "venues", "journals", "gigabyte", "register.md"))
gigabyte_md <- paste(gigabyte_md, collapse = "\n")
# GigaByte has no venues.csv metadata, but the venue type alone still
# renders (as the only frontmatter field) now that it is no longer shown in the title.
expect_false(grepl("venue-metadata", gigabyte_md, fixed = TRUE))
expect_true(grepl("venue_type: journal", gigabyte_md, fixed = TRUE))
expect_false(grepl("contact_name", gigabyte_md, fixed = TRUE))

# The rendered HTML must contain the panel as actual markup, not as escaped
# text inside a <pre><code> block - which is what happens if any line inside
# the whisker template is indented by 4+ spaces, since pandoc then reads it
# as a Markdown indented code block instead of a raw HTML block.
agile_html <- readLines(file.path("docs", "venues", "conferences", "agilegis", "index.html"))
agile_html <- paste(agile_html, collapse = "\n")
expect_true(grepl('<div class="venue-metadata">', agile_html, fixed = TRUE))
expect_true(grepl("<p class=\"venue-metadata-description\">", agile_html, fixed = TRUE))
expect_false(grepl("<pre><code>", agile_html, fixed = TRUE))

# The JSON/Markdown export links below the table are relative (same
# directory as index.html), unlike the CSV links which point to GitHub and
# must stay absolute.
expect_true(grepl('href="register.json"', agile_html, fixed = TRUE))
expect_true(grepl('href="register.md"', agile_html, fixed = TRUE))
expect_false(grepl('href="https://codecheck.org.uk/register/venues/conferences/agilegis/register.json"', agile_html, fixed = TRUE))
expect_false(grepl('href="https://codecheck.org.uk/register/venues/conferences/agilegis/register.md"', agile_html, fixed = TRUE))
# CSV links now show only on the main, unfiltered register page - every
# filtered detail page's own CSV is a small subset of the same data already
# in the table above it (generate_html_postfix_hrefs_reg()'s has_csv).
expect_false(grepl("raw.githubusercontent.com", agile_html, fixed = TRUE))
expect_false(grepl("CSV", agile_html, fixed = TRUE))

# index.json (not stats.json/statistics.json - it carries more than
# statistics) carries the same structured metadata as the landing page
# panel (register#183) - the venue's own JSON representation, not
# register.json (which is the list of certificates).
expect_false(file.exists(file.path("docs", "venues", "conferences", "agilegis", "statistics.json")))
agile_stats <- jsonlite::read_json(file.path("docs", "venues", "conferences", "agilegis", "index.json"))
expect_equal(agile_stats$venue$name, "AGILEGIS")
expect_equal(agile_stats$venue$venue_type, "conference")
expect_equal(agile_stats$venue$website_url, "https://agile-gi.eu")
expect_equal(agile_stats$venue$contact_name, "Jane Doe")
expect_equal(agile_stats$venue$contact_email, "jane@example.org")
expect_equal(length(agile_stats$venue$identifiers), 2)
expect_equal(agile_stats$venue$identifiers[[1]]$name, "ROR")
expect_equal(agile_stats$venue$identifiers[[1]]$icon, "fa-university")
expect_equal(agile_stats$venue$identifiers[[1]]$url, "https://ror.org/05wg1m734")
# ISSN without an explicit url in venues.csv still gets its default ISSN Portal link
expect_equal(agile_stats$venue$identifiers[[2]]$name, "ISSN")
expect_equal(agile_stats$venue$identifiers[[2]]$url, "https://portal.issn.org/resource/ISSN/1234-5678")

# GigaByte has no venues.csv metadata, but the venue type is always present
gigabyte_stats <- jsonlite::read_json(file.path("docs", "venues", "journals", "gigabyte", "index.json"))
expect_equal(gigabyte_stats$venue$venue_type, "journal")
expect_true(is.null(gigabyte_stats$venue$website_url))
expect_equal(length(gigabyte_stats$venue$identifiers), 0)

# The main register's statistics.json and non-venue pages carry no "venue" key
main_stats <- jsonlite::read_json(file.path("docs", "statistics.json"))
expect_true(is.null(main_stats$venue))

# register_update_stats() (the fast stats-only path) also writes a venue's
# index.json with the same structured venue metadata, recovered from the
# docs/venues/<type_plural>/<slug> path since the venue-specific
# register.json view has no Venue/Type columns to read it from directly.
file.remove(file.path("docs", "venues", "conferences", "agilegis", "index.json"))
expect_silent({ capture.output(
  {
    register_update_stats(venues_file = venues_path)
  },
  type = "message"
  )
  })
expect_true(file.exists(file.path("docs", "venues", "conferences", "agilegis", "index.json")))
updated_stats <- jsonlite::read_json(file.path("docs", "venues", "conferences", "agilegis", "index.json"))
expect_equal(updated_stats$venue$name, "AGILEGIS")
expect_equal(updated_stats$venue$venue_type, "conference")
expect_equal(updated_stats$venue$identifiers[[1]]$name, "ROR")
# codechecker sub-registers are unaffected: still stats.json, no "venue" key
cc_stats_path <- Sys.glob(file.path("docs", "codecheckers", "*", "stats.json"))
if (length(cc_stats_path) > 0) {
  cc_stats <- jsonlite::read_json(cc_stats_path[1])
  expect_true(is.null(cc_stats$venue))
}

# clean up
expect_equal(unlink("docs", recursive = TRUE), 0)
