using(ttdo)

# normalize_orcid -------------------------------------------------------

expect_equal(codecheck:::normalize_orcid("0000-0001-8607-8025"), "0000-0001-8607-8025")
expect_equal(codecheck:::normalize_orcid("0000-0002-3124-5364"), "0000-0002-3124-5364")
# checksum character is case-insensitive but canonically uppercase
expect_equal(codecheck:::normalize_orcid("0009-0009-4474-171x"), "0009-0009-4474-171X")
expect_equal(codecheck:::normalize_orcid("0009-0009-4474-171X"), "0009-0009-4474-171X")
# URL prefix is stripped
expect_equal(codecheck:::normalize_orcid("https://orcid.org/0000-0001-8607-8025"), "0000-0001-8607-8025")
expect_equal(codecheck:::normalize_orcid("http://orcid.org/0000-0001-8607-8025"), "0000-0001-8607-8025")
# malformed input -> NA, never an error
expect_true(is.na(codecheck:::normalize_orcid("not-an-orcid")))
expect_true(is.na(codecheck:::normalize_orcid("")))
expect_true(is.na(codecheck:::normalize_orcid(NA)))
expect_true(is.na(codecheck:::normalize_orcid(NULL)))

# normalize_work_key -----------------------------------------------------

expect_equal(
  codecheck:::normalize_work_key("https://doi.org/10.1093/gigascience/giaa026"),
  "10.1093/gigascience/giaa026"
)
# case-insensitive, must collapse to one key (register#192-style bug for DOIs)
expect_equal(
  codecheck:::normalize_work_key("https://doi.org/10.3397/IN_2024_3491"),
  "10.3397/in_2024_3491"
)
expect_equal(
  codecheck:::normalize_work_key("https://doi.org/10.3397/in_2024_3491"),
  "10.3397/in_2024_3491"
)
# dx.doi.org and doi: forms are also DOIs
expect_equal(
  codecheck:::normalize_work_key("https://dx.doi.org/10.1093/gigascience/giaa026"),
  "10.1093/gigascience/giaa026"
)
expect_equal(
  codecheck:::normalize_work_key("doi:10.1093/gigascience/giaa026"),
  "10.1093/gigascience/giaa026"
)
# a non-DOI paper reference yields no work page, per #150
expect_true(is.na(codecheck:::normalize_work_key(
  "https://pure.tue.nl/ws/portalfiles/portal/339520759/IN_2024_3491.pdf"
)))
expect_true(is.na(codecheck:::normalize_work_key(NA)))
expect_true(is.na(codecheck:::normalize_work_key(NULL)))
expect_true(is.na(codecheck:::normalize_work_key("")))

# leading/trailing whitespace is tolerated
expect_equal(
  codecheck:::normalize_work_key("  https://doi.org/10.1093/gigascience/giaa026  "),
  "10.1093/gigascience/giaa026"
)

# add_markdown_title -----------------------------------------------------

# certificate 2022-009's paper title itself starts with a quoted phrase
# followed by a colon ("\"Landmark Route\": A Comparison to the Shortest
# Route") - gsub()'s regex-mode replacement scanning silently drops a lone
# backslash before a `"` in the replacement text, so the escaped internal
# quote never made it into the YAML frontmatter and broke the parse for
# every certificate after it in a full render. fixed = TRUE on both the
# pattern and replacement is what fixes it.
source(system.file("extdata", "config.R", package = "codecheck"))
title_with_quote <- '"Landmark Route": A Comparison to the Shortest Route'
md_table <- c("---", "title: $title$", "---")
out <- codecheck:::add_markdown_title(
  list(name = "10.5194/agile-giss-3-12-2022", title = title_with_quote),
  md_table,
  "works"
)
expect_equal(
  out[2],
  'title: "CODECHECKs of \\"Landmark Route\\": A Comparison to the Shortest Route"'
)
parsed <- yaml::yaml.load(paste(out, collapse = "\n"))
expect_equal(parsed$title, paste0("CODECHECKs of ", title_with_quote))
