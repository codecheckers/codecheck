# A work's publication date from its DOI's own registry record, asked when
# OpenAlex has none of the work's own - a preprint OpenAlex merged into its
# published version, or one it never had (register#50).

# CrossRef: the date posted content was posted comes before the issue date.
expect_equal(codecheck:::crossref_publication_date(list(
  posted = list(`date-parts` = list(list(2025L, 10L, 30L))),
  issued = list(`date-parts` = list(list(2026L, 4L, 29L))))), "2025-10-30")
expect_equal(codecheck:::crossref_publication_date(list(
  `published-online` = list(`date-parts` = list(list(2023L, 7L))))), "2023-7")
expect_true(is.na(codecheck:::crossref_publication_date(list())))
# A partial date is filled in the way the page fallback does it.
expect_equal(codecheck:::parse_partial_publication_date("2023-7-12"), "2023-07-12")

# DataCite: arXiv records every version as Submitted, and the first is the
# preprint's date; the bare Issued year comes last.
arxiv <- list(publicationYear = 2021L, dates = list(
  list(date = "2021-07-14T17:51:38Z", dateType = "Submitted"),
  list(date = "2021-04-01T18:53:48Z", dateType = "Submitted"),
  list(date = "2021-04-05T00:01:26Z", dateType = "Updated"),
  list(date = "2021-04", dateType = "Available"),
  list(date = "2021", dateType = "Issued")))
expect_equal(codecheck:::datacite_publication_date(arxiv), "2021-04-01")
expect_equal(codecheck:::datacite_publication_date(list(
  dates = list(list(date = "2019-11-13", dateType = "Issued")))), "2019-11-13")
expect_equal(codecheck:::datacite_publication_date(list(publicationYear = 2019L, dates = list())), "2019")
# An update is not a publication.
expect_equal(codecheck:::datacite_publication_date(list(
  publicationYear = 2020L,
  dates = list(list(date = "2021-01-01", dateType = "Updated")))), "2020")

# Anything that is not a DOI is not asked about.
expect_equal(codecheck:::get_registry_publication_date_result("https://example.org/paper")$status, "absent")
expect_equal(codecheck:::get_registry_publication_date_result(NULL)$status, "absent")
