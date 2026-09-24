tinytest::using(ttdo)

source("mocks.R")

# The pages generated on the CODECHECK Wikibase, and how they are published
# (register#50). Everything here is offline: the generators are pure, and the
# two network calls - reading a page and writing one - are mocked.

no_pages <- function(handle, titles) stats::setNames(rep(NA_character_, length(titles)), titles)

# Every page has a generator ----

# A page in the registry that nothing generates is a page nobody writes. The
# ones that need data get it from a context; the rest must build from nothing.
pages <- codecheck:::WIKIBASE_PAGES
for (key in c("main", "about", "copyrights", "copyright_redirect")) {
  expect_true(length(codecheck:::wikibase_page_wikitext(key)) > 0, info = key)
}
expect_error(codecheck:::wikibase_page_wikitext("no_such_page"), "No generator")
expect_true(all(vapply(pages, function(page) is.character(page$title), logical(1))))

# The Main Page lists every page ----

# It used to be written by hand, which is how it came to miss the example
# queries. Built from the registry, it cannot miss a page again.
main <- codecheck:::wikibase_main_wikitext()
for (page in Filter(function(page) !is.null(page$description), pages)) {
  expect_true(any(startsWith(main, paste0("* [[", page$title, "]] &mdash; "))), info = page$title)
}
expect_true(any(grepl("[[Project:Example queries]]", main, fixed = TRUE)))
expect_true(any(grepl("publish_wikibase_pages()", main, fixed = TRUE)))
# The Main Page and the redirect are not destinations to list.
expect_false(any(grepl("[[Main Page]]", main, fixed = TRUE)))
expect_false(any(grepl("[[Project:Copyright]]", main, fixed = TRUE)))
# A leading space is preformatted text in MediaWiki.
expect_false(any(grepl("^[ \t]", main)))

# A rewrite that only moves the timestamp is not a change ----

old <- paste(c("Some text.", "", "Generated 2026-09-01 10:00:00 CEST.", ""), collapse = "\n")
new <- c("Some text.", "", "Generated 2026-09-24 12:00:00 CEST.", "")
expect_true(codecheck:::wikibase_page_unchanged(old, new))
# MediaWiki trims the trailing newline when it saves a page.
expect_true(codecheck:::wikibase_page_unchanged(sub("\n$", "", old), new))
expect_false(codecheck:::wikibase_page_unchanged(old, c("Other text.", "", new[3])))
expect_false(codecheck:::wikibase_page_unchanged(NA_character_, new))

# Only changed pages are written ----

sent <- list()
with_mocked_codecheck(list(
  wikibase_post = function(session, params, what) {
    sent[[length(sent) + 1L]] <<- params
    list(edit = list(result = "Success"))
  },
  wikibase_page_content = function(handle, titles) {
    stats::setNames(c(old, NA_character_), titles)
  }
), {
  result <- codecheck:::write_wikibase_pages(
    NULL, list(about = new, copyrights = "Licensing."), summary = "test"
  )
})
expect_equal(result$status, c("unchanged", "written"))
expect_equal(length(sent), 1L)
expect_equal(sent[[1]]$title, "Project:Copyrights")
expect_equal(sent[[1]]$summary, "test")

# A dry run compares, and writes nothing.
sent <- list()
with_mocked_codecheck(list(
  wikibase_post = function(session, params, what) stop("a dry run must not write"),
  wikibase_page_content = no_pages
), {
  result <- codecheck:::write_wikibase_pages(NULL, list(main = main), summary = "test",
                                             dry_run = TRUE)
})
expect_equal(result$status, "would create")
expect_error(codecheck:::write_wikibase_pages(NULL, list(nope = "x"), summary = "test"),
             "Not a generated Wikibase page")

# The export page after the export has run ----

# The page was last written before any batch had been pasted, and went on
# saying "to create" and "nothing has been sent" long after both were false.
done <- data.frame(
  kind = c("paper", "certificate", "certificate"),
  key = c("10.1093/GIGASCIENCE/GIAA026", "10.5281/ZENODO.3674056", "10.5281/ZENODO.1"),
  wikidata = c("Q91579802", "Q116702174", "Q141269518"),
  action = "exists", commands = 0L, stringsAsFactors = FALSE
)
certificates <- data.frame(
  `Certificate ID` = c("2020-001", "2020-008"),
  `Paper reference` = c("https://doi.org/10.1093/gigascience/giaa026", NA),
  Report = c("https://doi.org/10.5281/zenodo.3674056", "https://doi.org/10.5281/zenodo.1"),
  Title = c("ShinyLearner", "A preprint | with a pipe"), Venue = c("GigaScience", "preprint"),
  check.names = FALSE, stringsAsFactors = FALSE
)
submitted <- data.frame(
  time = "2026-09-03T21:50:36+0200", batch = "wikidata-certificates",
  id = "https://quickstatements.toolforge.org/#/batch/270374",
  detail = "background run", stringsAsFactors = FALSE
)
page <- codecheck:::wikidata_preview_wikitext(
  done, certificates, list(paper = character(0), certificate = character(0)),
  submitted = submitted,
  register_qids = c(`2020-001` = "Q116702174", `2020-008` = "Q999")
)
text <- paste(page, collapse = "\n")

expect_true(grepl("The export has run.", text, fixed = TRUE))
expect_false(grepl("Nothing has been sent", text, fixed = TRUE))
expect_false(grepl("'''to create'''", text, fixed = TRUE))
# With nothing left to create there is no ordering to explain and no batch to show.
expect_false(grepl("The order matters", text, fixed = TRUE))
expect_false(grepl("<pre>", text, fixed = TRUE))
# The batches that ran are listed with their record.
expect_true(grepl("== Batches run ==", text, fixed = TRUE))
expect_true(grepl("[https://quickstatements.toolforge.org/#/batch/270374 record]", text, fixed = TRUE))
expect_true(grepl("2026-09-03 21:50", text, fixed = TRUE))

# One row per certificate, so a certificate whose work has no DOI is on the
# page too, and says why it states no "review of".
row_008 <- grep("^\\| 2020-008 ", page, value = TRUE)
expect_equal(length(row_008), 1L)
expect_true(grepl("https://www.wikidata.org/wiki/Q141269518", row_008, fixed = TRUE))
expect_true(grepl("1 certificate checks a work with no DOI", text, fixed = TRUE))
# A pipe in a title would split the cell.
expect_true(grepl("A preprint &#124; with a pipe", row_008, fixed = TRUE))

# The register column: what matches says so, what does not is flagged.
expect_true(grepl("In register.csv", text, fixed = TRUE))
expect_true(grepl("|| yes$", grep("^\\| 2020-001 ", page, value = TRUE)))
expect_true(grepl("'''differs''': Q999", row_008, fixed = TRUE))

missing <- codecheck:::wikidata_preview_wikitext(
  done, certificates, list(), register_qids = c(`2020-001` = "Q116702174")
)
expect_true(grepl("'''missing'''", grep("^\\| 2020-008 ", missing, value = TRUE), fixed = TRUE))
# No log, no batch section - the page does not claim nothing ran.
expect_false(any(grepl("== Batches run ==", missing, fixed = TRUE)))

# Before anything was sent the page still says so.
fresh <- done
fresh$action <- "create"
fresh$wikidata <- NA_character_
before <- paste(codecheck:::wikidata_preview_wikitext(
  fresh, certificates, list(paper = "CREATE", certificate = c("CREATE", "LAST\tLen\t\"x\""))
), collapse = "\n")
expect_true(grepl("Nothing has been sent yet", before, fixed = TRUE))
expect_true(grepl("The order matters", before, fixed = TRUE))

# The register's QIDs ----

# register.json does not carry the column, so it is read from register.csv,
# which holds a commented-out row that must not become a certificate.
dir <- tempfile("register")
dir.create(dir)
writeLines(c(
  "Certificate,Repository,Type,Venue,Issue,Wikidata",
  "2020-001,github::codecheckers/Piccolo-2020,journal,GigaScience,NA,Q116702174",
  "# 2020-099,github::codecheckers/withdrawn,journal,GigaScience,NA,Q1",
  "2020-002,github::codecheckers/other,journal,GigaScience,NA,"
), file.path(dir, "register.csv"))
qids <- codecheck:::read_register_wikidata(dir)
expect_equal(qids, c(`2020-001` = "Q116702174"))
expect_equal(length(codecheck:::read_register_wikidata(tempfile())), 0L)

# The certificate index links the Wikidata item the register records.
written <- data.frame(kind = "certificate", key = "10.5281/ZENODO.3674056", action = "exists",
                      id = "Q89", stringsAsFactors = FALSE)
index <- paste(codecheck:::wikibase_certificates_wikitext(
  written, certificates[1, ], qids
), collapse = "\n")
expect_true(grepl("!! Report DOI !! Wikidata", index, fixed = TRUE))
expect_true(grepl("[https://www.wikidata.org/wiki/Q116702174 Q116702174]", index, fixed = TRUE))

# Publishing ----

expect_error(codecheck::publish_wikibase_pages(tempfile(), pages = "nope"), "Unknown page")

# A dry run of the pages that need no data touches neither the register nor
# the instance's items: the context's promises are never forced.
with_mocked_codecheck(list(
  wikibase_post = function(session, params, what) stop("a dry run must not write"),
  wikibase_page_content = no_pages,
  read_register_records = function(dir) stop("not needed for these pages")
), {
  result <- codecheck::publish_wikibase_pages(tempfile(), pages = c("main", "about"))
})
expect_equal(result$status, c("would create", "would create"))
