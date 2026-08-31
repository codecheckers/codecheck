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
# renders nothing, regardless of network availability (get_codecheckers_data()
# degrades to an empty data frame on a failed fetch).
expect_equal(codecheck:::generate_codechecker_metadata_html("0000-0000-0000-0001"), "")
expect_equal(codecheck:::generate_codechecker_metadata_yaml("0000-0000-0000-0001"), "")

# ...but the panel still renders for the contributed-venues row alone, even
# with no ORCID/GitHub on file.
venues_only_html <- codecheck:::generate_codechecker_metadata_html("0000-0000-0000-0001", reg_table, table_details)
expect_true(grepl("venue-metadata", venues_only_html, fixed = TRUE))
expect_true(grepl("fa-check-square-o", venues_only_html, fixed = TRUE))
expect_true(grepl("Contributed checks:", venues_only_html, fixed = TRUE))
expect_false(grepl("ORCID:", venues_only_html, fixed = TRUE))
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
