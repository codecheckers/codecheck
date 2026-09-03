tinytest::using(ttdo)

source(system.file("extdata", "config.R", package = "codecheck"))

# Unit tests: get_codechecker_venues() ----

no_venue_cols <- data.frame(x = 1)
expect_equal(nrow(codecheck:::get_codechecker_venues(no_venue_cols)), 0)

empty_table <- data.frame(Venue = character(0), Type = character(0))
expect_equal(nrow(codecheck:::get_codechecker_venues(empty_table)), 0)

reg_table <- data.frame(
  Venue = c("AGILEGIS", "AGILEGIS", "GigaByte", NA),
  Type = c("conference", "conference", "journal", NA),
  stringsAsFactors = FALSE
)
venues <- codecheck:::get_codechecker_venues(reg_table)
expect_equal(nrow(venues), 2)
# Sorted by Venue name
expect_equal(venues$Venue, c("AGILEGIS", "GigaByte"))
expect_equal(venues$Type, c("conference", "journal"))
expect_equal(venues$cert_count[venues$Venue == "AGILEGIS"], 2)
expect_equal(venues$cert_count[venues$Venue == "GigaByte"], 1)

# Unit tests: markdown_link_to_html() / generate_contributed_venues_html() ----

expect_equal(
  codecheck:::markdown_link_to_html("[AGILEGIS](../../venues/conferences/agilegis)"),
  '<a href="../../venues/conferences/agilegis">AGILEGIS</a>'
)

table_details <- list(output_dir = "docs/codecheckers/0000-0000-0000-0001")
venues_html <- codecheck:::generate_contributed_venues_html(reg_table, table_details)
expect_true(grepl('conference <a href="[^"]*agilegis[^"]*">AGILEGIS</a> \\(2\\)', venues_html))
expect_true(grepl('journal <a href="[^"]*gigabyte[^"]*">GigaByte</a> \\(1\\)', venues_html))
expect_false(grepl("^Contributed checks", venues_html))

expect_equal(codecheck:::generate_contributed_venues_html(empty_table, table_details), "")

# Unit tests: resolve_codechecker_profile() / generate_codechecker_metadata_html()/yaml() ----

# An identifier with no matching entry in codecheckers.csv and no venues
# still renders an ORCID line when the identifier is itself a well-formed
# ORCID - it is this person's own page identifier, not something that needs
# a codecheckers.csv match to be "known" (an author-only person on their
# own /persons/<ORCID>/ page is never in that list, and previously got no
# metadata panel at all as a result - codecheckers/register#123 followup).
# generate_codechecker_metadata_yaml() is unrelated to that page (persons
# pages never emit register.md/YAML frontmatter) and keeps the old,
# lookup-only behaviour.
html_orcid_only <- codecheck:::generate_codechecker_metadata_html("0000-0000-0000-0001")
expect_true(grepl("ORCID:", html_orcid_only, fixed = TRUE))
expect_true(grepl("0000-0000-0000-0001", html_orcid_only, fixed = TRUE))
expect_false(grepl("codechecker-metadata-avatar", html_orcid_only, fixed = TRUE))
expect_equal(codecheck:::generate_codechecker_metadata_yaml("0000-0000-0000-0001"), "")

# ...and the panel renders for the contributed-venues row alongside the
# ORCID line, even with no GitHub handle on file.
venues_only_html <- codecheck:::generate_codechecker_metadata_html("0000-0000-0000-0001", reg_table, table_details)
expect_true(grepl("venue-metadata", venues_only_html, fixed = TRUE))
expect_true(grepl("fa-check-square-o", venues_only_html, fixed = TRUE))
expect_true(grepl("Contributed checks:", venues_only_html, fixed = TRUE))
expect_true(grepl("ORCID:", venues_only_html, fixed = TRUE))
expect_false(grepl("codechecker-metadata-avatar", venues_only_html, fixed = TRUE))

venues_only_yaml <- codecheck:::generate_codechecker_metadata_yaml("0000-0000-0000-0001", reg_table)
expect_true(grepl("venues:", venues_only_yaml, fixed = TRUE))
parsed_venues_only <- yaml::yaml.load(venues_only_yaml)
expect_equal(length(parsed_venues_only$venues), 2)
expect_true(is.null(parsed_venues_only$orcid))

# A known codechecker with both ORCID and GitHub handle set in the live
# codecheckers.csv registry (network-dependent, like the venue metadata
# integration test's live repo fetches elsewhere in this suite).
known_orcid <- "0000-0001-8607-8025"
known_profile <- codecheck:::get_codechecker_profile(known_orcid)
if (!is.null(known_profile) && !is.null(known_profile$github_handle)) {
  html <- codecheck:::generate_codechecker_metadata_html(known_orcid, reg_table, table_details)
  expect_true(grepl("venue-metadata", html, fixed = TRUE))
  expect_true(grepl("codechecker-metadata-avatar", html, fixed = TRUE))
  expect_true(grepl(paste0("https://github.com/", known_profile$github_handle, ".png"), html, fixed = TRUE))
  expect_true(grepl(paste0("https://orcid.org/", known_orcid), html, fixed = TRUE))
  expect_true(grepl("Contributed checks:", html, fixed = TRUE))
  expect_true(grepl('conference <a href="[^"]*agilegis[^"]*">AGILEGIS</a> \\(2\\)', html))

  yaml_str <- codecheck:::generate_codechecker_metadata_yaml(known_orcid, reg_table)
  expect_true(grepl(paste0("orcid: ", known_orcid), yaml_str, fixed = TRUE))
  expect_true(grepl(paste0("github_username: ", known_profile$github_handle), yaml_str, fixed = TRUE))
  parsed <- yaml::yaml.load(yaml_str)
  expect_equal(parsed$orcid, known_orcid)
  expect_equal(length(parsed$venues), 2)

  # No register_table passed - html/yaml still work, just without the venues row
  html_no_venues <- codecheck:::generate_codechecker_metadata_html(known_orcid)
  expect_false(grepl("Contributed checks:", html_no_venues, fixed = TRUE))
  yaml_no_venues <- codecheck:::generate_codechecker_metadata_yaml(known_orcid)
  expect_false(grepl("venues:", yaml_no_venues, fixed = TRUE))
} else {
  cat("Skipping live codecheckers.csv-dependent assertions (network unavailable or entry changed)\n")
}

# Unit tests: get_codechecker_type_counts() and the donut in the panel (register#207) ----

expect_equal(length(codecheck:::get_codechecker_type_counts(empty_table)), 0)

# reg_table has two AGILEGIS conference checks and one GigaByte journal check
type_counts <- codecheck:::get_codechecker_type_counts(reg_table)
expect_equal(as.integer(type_counts[["conference"]]), 2L)
expect_equal(as.integer(type_counts[["journal"]]), 1L)
# Ordered largest first, so the donut and the bar segment alike
expect_equal(names(type_counts), c("conference", "journal"))

# The panel carries the donut, one <path> per type, and the JSON twin
expect_true(grepl("codechecker-type-chart", venues_only_html, fixed = TRUE))
expect_equal(length(gregexpr("<path", venues_only_html)[[1]]), 2L)
expect_true(grepl('id="codechecker-types"', venues_only_html, fixed = TRUE))
expect_true(grepl('{"conference":2,"journal":1}', venues_only_html, fixed = TRUE))

# Every slice's tooltip lists *every* type, so no hover shows a partial list.
# The line breaks must be &#10; entities, not literal newlines: pandoc reflows
# the whitespace of a raw HTML block and would collapse real ones into spaces.
expect_false(grepl("<title>[^<]*\n", venues_only_html))
slice_titles <- regmatches(
  venues_only_html,
  gregexpr("<title>[^<]*</title>", venues_only_html)
)[[1]]
expect_equal(length(slice_titles), 2L)
for (title in slice_titles) {
  expect_true(grepl("conference: 2 (67%)", title, fixed = TRUE))
  expect_true(grepl("journal: 1 (33%)", title, fixed = TRUE))
  expect_true(grepl("&#10;", title, fixed = TRUE))
  # The indent is entities too, so pandoc cannot collapse it and leave the
  # unmarked lines misaligned under the marked one
  expect_true(grepl("&#160;&#160;", title, fixed = TRUE))
}
# ...each marking its own type
expect_true(any(grepl("▸ conference", slice_titles, fixed = TRUE)))
expect_true(any(grepl("▸ journal", slice_titles, fixed = TRUE)))

# A single venue type is a stroked circle, not a degenerate 360-degree arc
one_type_table <- data.frame(
  Venue = c("AGILEGIS", "AGILEGIS"),
  Type = c("conference", "conference"),
  stringsAsFactors = FALSE
)
one_type_html <- codecheck:::generate_codechecker_metadata_html(
  "0000-0000-0000-0001", one_type_table, table_details
)
expect_true(grepl("<circle", one_type_html, fixed = TRUE))
expect_false(grepl("<path", one_type_html, fixed = TRUE))

# The YAML export is unchanged by all of the above - it is a markdown/API file,
# not HTML, and already carries venues[].type/cert_count
expect_false(grepl("svg", venues_only_yaml, fixed = TRUE))
expect_false(grepl("codechecker-type-chart", venues_only_yaml, fixed = TRUE))

# The Wikidata row (register#50) ----

# The item is shown next to ORCID and GitHub rather than only in the page's
# head and JSON: a reader looking for the exported record should not have to
# read the metadata to find it.
CONFIG$WIKIDATA_IDS <- list(certificate = character(0), paper = character(0),
                            person = c("0000-0000-0000-0001" = "Q38324721"))

with_item <- codecheck:::generate_codechecker_metadata_html("0000-0000-0000-0001")
expect_true(grepl("https://www.wikidata.org/wiki/Q38324721", with_item, fixed = TRUE))
expect_true(grepl(">Wikidata:<", with_item, fixed = TRUE))

# A person the register knows no item for gets no row at all, rather than an
# empty one.
without_item <- codecheck:::generate_codechecker_metadata_html("0000-0000-0000-0002")
expect_false(grepl("Wikidata", without_item, fixed = TRUE))

# Reset explicitly: tinytest runs every file in one session, so a lookup left
# in CONFIG would follow the next file. (on.exit() is no use here - at top
# level it fires at the end of its own statement.)
CONFIG$WIKIDATA_IDS <- NULL
