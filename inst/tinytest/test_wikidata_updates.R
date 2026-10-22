# The second set of QuickStatements: what the export would add to items that
# already exist. The diffing and the origin are pure and tested here; the
# requests that feed them are not.

claim <- function(type, value) list(mainsnak = list(datavalue = list(type = type, value = value)))
item <- function(id) claim("wikibase-entityid", list(id = id))

# Comparable values ----

expect_equal(codecheck:::quickstatements_token_key("Q42"), "Q42")
expect_equal(codecheck:::quickstatements_token_key("+2025-05-15T00:00:00Z/11"), "2025-05-15")
expect_equal(codecheck:::quickstatements_token_key("en:\"A \\\"quoted\\\" title\""), "A \"QUOTED\" TITLE")
# Wikidata stores DOIs uppercased, mostly; the comparison does not care.
expect_equal(codecheck:::quickstatements_token_key("\"10.71240/lcyc.052239\""), "10.71240/LCYC.052239")

expect_equal(codecheck:::wikidata_claim_key(item("Q42")), "Q42")
expect_equal(codecheck:::wikidata_claim_key(claim("time", list(time = "+2025-05-15T00:00:00Z"))), "2025-05-15")
expect_equal(codecheck:::wikidata_claim_key(claim("monolingualtext", list(text = "A title", language = "en"))), "A TITLE")
expect_equal(codecheck:::wikidata_claim_key(claim("string", "10.71240/LCYC.052239")), "10.71240/LCYC.052239")
# "No value" and "unknown value" have no datavalue.
expect_true(is.na(codecheck:::wikidata_claim_key(list(mainsnak = list(snaktype = "novalue")))))

# Missing statements ----

commands <- c(
  "Q1\tP31\tQ13442814",
  "Q1\tP356\t\"10.71240/LCYC.052239\"",
  "Q1\tP1433\tQ141249936\tS854\t\"https://codecheck.org.uk/register/certs/2025-005/\"",
  "Q1\tP577\t+2025-04-23T00:00:00Z/11",
  "Q1\tP2093\t\"Ada Lovelace\""
)
claims <- list(
  P31 = list(item("Q13442814")),
  P356 = list(claim("string", "10.71240/lcyc.052239")),
  P577 = list(claim("time", list(time = "+2025-04-01T00:00:00Z"))),
  P50 = list(item("Q7259"))
)
missing <- codecheck:::wikidata_missing_statements(commands, claims)

# What the item has already is not written again.
expect_false(any(missing$property %in% c("P31", "P356")))
# A property it lacks is an addition, written with the export's reference.
expect_equal(missing$action[missing$property == "P1433"], "add")
expect_true(grepl("S854", missing$command[missing$property == "P1433"], fixed = TRUE))
# A property it carries with another value is a difference, never an addition:
# on Wikidata it would be a second publication date, not a corrected one.
expect_equal(missing$action[missing$property == "P577"], "differs")
expect_equal(missing$current[missing$property == "P577"], "2025-04-01")
# Authors as items count as authors: no name strings on top of them.
expect_equal(missing$action[missing$property == "P2093"], "differs")

expect_equal(nrow(codecheck:::wikidata_missing_statements(character(0), claims)), 0L)
# A label or description command is not a statement.
expect_equal(nrow(codecheck:::wikidata_missing_statements("Q1\tLen\t\"x\"", list())), 0L)

# Where an item came from ----

expect_equal(codecheck:::wikidata_item_origin(
  "/* wbeditentity-create-item:0| */ #quickstatements; #temporary_batch_1788464327978",
  c("1788464327978")), "codecheck export")
expect_equal(codecheck:::wikidata_item_origin(
  "/* wbeditentity-create-item:0| */ #quickstatements; [[:toollabs:quickstatements/#/batch/270374|batch #270374]]",
  c("270374")), "codecheck export")
# A batch the log does not record is somebody's QuickStatements run, not ours.
expect_equal(codecheck:::wikidata_item_origin(
  "#quickstatements; #temporary_batch_1", c("1788464327978")), "quickstatements")
expect_equal(codecheck:::wikidata_item_origin(
  "/* wbeditentity-create:2|en */ CODECHECK Certificate 2020-001", "270374"), "other")
expect_equal(codecheck:::wikidata_item_origin(NA_character_), "other")

# The batch ids come from the log's URLs and notes.
log <- tempfile(fileext = ".csv")
codecheck:::wikibase_log(target = "wikidata", action = "quickstatements", kind = "batch",
                         id = "https://editgroups.toolforge.org/b/QSv2T/1788464327978",
                         status = "submitted", batch = "wikidata-works", file = log)
codecheck:::wikibase_log(target = "wikidata", action = "quickstatements", kind = "batch",
                         id = NA, status = "submitted", batch = "merge",
                         detail = "background run, batch #270374", file = log)
codecheck:::wikibase_log(target = "wikidata", action = "quickstatements", kind = "batch",
                         id = "https://quickstatements.toolforge.org/#/batch/999999",
                         status = "prepared", batch = "never-run", file = log)
ids <- codecheck:::wikidata_logged_batch_ids(log)
expect_true(all(c("1788464327978", "270374") %in% ids))
# A batch that was only prepared created nothing.
expect_false("999999" %in% ids)
