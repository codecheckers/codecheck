tinytest::using(ttdo)

# Wikidata is not written by this code: the batches are pasted into
# QuickStatements by a person under their own account. What the package owes
# them is an exact preview, so everything that builds one is pure and tested.

row <- list(
  `Certificate ID` = "2020-001",
  `Certificate Link` = "https://codecheck.org.uk/register/certs/2020-001/",
  `Certificate PDF` = "https://zenodo.org/records/3674056/files/codecheck.pdf",
  `Repository Link` = "https://github.com/codecheckers/Piccolo-2020",
  Report = "http://doi.org/10.5281/zenodo.3674056",
  Title = "ShinyLearner",
  `Paper reference` = "https://doi.org/10.1093/gigascience/giaa026",
  OpenAlex = "https://openalex.org/W3014157798",
  Venue = "GigaScience",
  `Check date` = "2019-02-14",
  `Paper authors` = list(list(list(name = "Terry J Lee"), list(name = "Erica Suh"))),
  Codechecker = list(list(list(name = "Stephen J. Eglen", orcid = "0000-0001-8607-8025")))
)

# Values, as QuickStatements v1 writes them ----

expect_equal(codecheck:::quickstatements_value("wikibase-item", "Q42"), "Q42")
expect_equal(codecheck:::quickstatements_value("time", "2019-02-14"), "+2019-02-14T00:00:00Z/11")
expect_equal(codecheck:::quickstatements_value("monolingualtext", "A title"), "en:\"A title\"")
expect_equal(codecheck:::quickstatements_value("external-id", "10.1/A"), "\"10.1/A\"")
# A quote in a title would otherwise end the value early and shift every
# following column of the command.
expect_equal(codecheck:::quickstatements_value("string", 'He said "no"'), '"He said \\"no\\""')

# Commands for one entity ----

commands <- codecheck:::quickstatements_for_entity(
  "certificate", row, resolve = function(kind, key) if (kind == "paper") "Q91579802" else NA)

expect_equal(commands[1], "CREATE")
expect_true(any(grepl("^LAST\tLen\t\"CODECHECK Certificate 2020-001\"$", commands)))
expect_true(any(grepl("^LAST\tDen\t", commands)))

# Wikidata's property numbers, not the Wikibase mirror's: this batch is pasted
# into Wikidata, where P31 is "instance of".
statements <- grep("^LAST\t[PL]", commands, value = TRUE)
properties <- vapply(strsplit(statements, "\t"), `[`, character(1), 2)
expect_true(all(c("P31", "P356", "P6977", "P528") %in% properties))
expect_false("P9" %in% properties)

# Every statement carries the reference block, on the same line.
values <- statements[!properties %in% c("Len", "Den")]
expect_true(all(grepl("\tS854\t", values, fixed = TRUE)))
expect_true(all(grepl("\tS813\t\\+[0-9]{4}", values)))

# A catalog code says nothing without its catalog, and the qualifier comes
# before the reference on the line.
catalog <- grep("\tP528\t", commands, value = TRUE)
expect_equal(length(catalog), 1L)
expect_true(grepl("\tP528\t\"2020-001\"\tP972\tQ141254857\tS854\t", catalog, fixed = TRUE))

# The resolved paper is named by its Wikidata item.
expect_true(any(grepl("\tP6977\tQ91579802\t", commands, fixed = TRUE)))

# An item that already exists keeps its label and description - somebody chose
# those, and this export has no business overwriting them - and its statements
# are added to it rather than to a new item.
existing <- codecheck:::quickstatements_for_entity("certificate", row, qid = "Q116702174")
expect_false("CREATE" %in% existing)
expect_false(any(grepl("\tLen\t", existing, fixed = TRUE)))
expect_true(all(grepl("^Q116702174\t", existing)))

# A created work says who wrote it ----

# P50 would need an item per author, and people are resolved on Wikidata, never
# minted by this export - so the authors are name strings.
paper <- codecheck:::quickstatements_for_entity("paper", row)
authors <- grep("\tP2093\t", paper, value = TRUE)
expect_equal(length(authors), 2L)
expect_true(any(grepl("\"Terry J Lee\"", authors, fixed = TRUE)))
expect_true(any(grepl("\tP10283\t\"W3014157798\"", paper, fixed = TRUE)))
# The checked works are created on Wikidata now, not only mirrored.
expect_true(codecheck::wikidata_creates("paper", "wikidata"))
# People and venues are still resolved there, never created.
expect_false(codecheck::wikidata_creates("person", "wikidata"))
expect_false(codecheck::wikidata_creates("venue", "wikidata"))

# The preview page ----

preview <- data.frame(
  kind = c("paper", "paper", "certificate"),
  key = c("10.1093/GIGASCIENCE/GIAA026", "10.1234/MISSING", "10.5281/ZENODO.3674056"),
  wikidata = c("Q91579802", NA, NA),
  action = c("exists", "create", "create"),
  commands = c(0L, 6L, 14L), stringsAsFactors = FALSE
)
certificates <- data.frame(
  `Paper reference` = c("https://doi.org/10.1093/gigascience/giaa026",
                        "https://doi.org/10.1234/missing"),
  Title = c("ShinyLearner", "A missing work"), Venue = c("GigaScience", "codecheck"),
  check.names = FALSE, stringsAsFactors = FALSE
)
page <- paste(codecheck:::wikidata_preview_wikitext(
  preview, certificates, list(paper = rep("x", 6), certificate = commands)), collapse = "\n")

expect_true(grepl("QuickStatements", page, fixed = TRUE))
expect_true(grepl("| checked works || 1 || 1 || 6", page, fixed = TRUE))
# The ordering constraint is the thing a person has to know before pasting.
expect_true(grepl("The order matters", page, fixed = TRUE))
expect_true(grepl("LAST", page, fixed = TRUE))
# A work that exists links to its item; one that does not is marked.
expect_true(grepl("https://www.wikidata.org/wiki/Q91579802", page, fixed = TRUE))
expect_true(grepl("'''to create'''", page, fixed = TRUE))
# Tabs would collapse in the rendered <pre>, so the example is spaced out.
expect_false(grepl("\t", page, fixed = TRUE))

# Finding items again after a batch has run ----

# One keyword, values OR'd inside it. Repeating the keyword ANDs the terms, and
# no item carries two DOIs, so that form finds almost nothing - it returned 3 of
# 33 known works before this was written the right way round.
expect_equal(
  codecheck:::haswbstatement_search("P356", c("10.1/A", "10.2/B")),
  "haswbstatement:P356=10.1/A|P356=10.2/B"
)
expect_equal(codecheck:::haswbstatement_search("P496", "0000-0001-8607-8025"),
             "haswbstatement:P496=0000-0001-8607-8025")
expect_equal(length(gregexpr("haswbstatement:",
                             codecheck:::haswbstatement_search("P356", letters[1:5]),
                             fixed = TRUE)[[1]]), 1L)

# Not pasting the same batch twice ----

# QuickStatements' CREATE has no idempotency and Wikidata will not stop a second
# paste, so the log is what stands between a re-run and 91 duplicate items.
log_file <- tempfile(fileext = ".csv")
expect_true(is.na(codecheck:::wikidata_batch_conflict("paper", 91, log_file)))

codecheck:::wikibase_log(target = "wikidata", action = "quickstatements",
                         kind = "batch", label = "wikidata-papers",
                         status = "prepared", batch = "wikidata-papers",
                         file = log_file)
# Prepared is not submitted: a batch written but never pasted is no reason to
# withhold the next one.
expect_true(is.na(codecheck:::wikidata_batch_conflict("paper", 91, log_file)))

codecheck:::wikibase_log(target = "wikidata", action = "quickstatements",
                         kind = "batch", label = "wikidata-papers",
                         status = "submitted", batch = "wikidata-papers",
                         file = log_file)
# Submitted, and the works still do not resolve: either the index is behind or
# the batch failed, and both mean wait rather than paste.
conflict <- codecheck:::wikidata_batch_conflict("paper", 91, log_file)
expect_false(is.na(conflict))
expect_true(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T", conflict))

# Nothing to create means nothing to duplicate, which is the state a successful
# run leaves behind.
expect_true(is.na(codecheck:::wikidata_batch_conflict("paper", 0, log_file)))
# A different batch is not this batch.
expect_true(is.na(codecheck:::wikidata_batch_conflict("certificate", 132, log_file)))
