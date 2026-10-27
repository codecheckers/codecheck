# The second set of QuickStatements: what the export would add to items that
# already exist. The diffing and the origin are pure and tested here; the
# requests that feed them are not.

claim <- function(type, value) list(mainsnak = list(datavalue = list(type = type, value = value)))
item <- function(id) claim("wikibase-entityid", list(id = id))

# Comparable values ----

expect_equal(codecheck:::quickstatements_token_key("Q42"), "Q42")
expect_equal(codecheck:::quickstatements_token_key("+2025-05-15T00:00:00Z/11"), "2025-05-15")
expect_equal(codecheck:::quickstatements_token_key("en:\"A \"quoted\" title\""), "A \"QUOTED\" TITLE")
# A title stored with the backslashes of an escaped batch is a different title.
expect_false(codecheck:::quickstatements_token_key("en:\"A \"quoted\" title\"") ==
               codecheck:::wikidata_claim_key(claim("monolingualtext", list(text = "A \\\"quoted\\\" title", language = "en"))))
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

# Unless the name string is one of the names of those authors.
with_names <- codecheck:::wikidata_missing_statements(commands, claims,
                                                      author_names = c("Ada King", "Ada Lovelace"))
expect_false("P2093" %in% with_names$property)
expect_equal(with_names$action[with_names$property == "P577"], "differs")

# Names compare without case, diacritics, spaces and punctuation, but initials
# are not expanded.
expect_true(codecheck:::wikidata_value_present("P2093", "EMANUEL A.P. HABETS", "EMANUËL A. P. HABETS"))
expect_true(codecheck:::wikidata_value_present("P2093", "CARSTEN KEßLER", "Carsten Keßler"))
expect_false(codecheck:::wikidata_value_present("P2093", "J J HOPFIELD", "John Hopfield"))
expect_false(codecheck:::wikidata_value_present("P2093", "MATIAS CARDOSO1", "MATIAS CARDOSO"))
# A title is the same title without its trailing full stop.
expect_true(codecheck:::wikidata_value_present("P1476", "SHINYLEARNER: A TOOL.", "SHINYLEARNER: A TOOL"))
expect_false(codecheck:::wikidata_value_present("P1476", "GRADIENT BOOSTED", "GRADIENT BOOSTING"))
# A date matches at the precision the item stores it with.
expect_true(codecheck:::wikidata_value_present("P577", "1982-04-01", "1982-04-00"))
expect_true(codecheck:::wikidata_value_present("P577", "1982-04-01", "1982-00-00"))
expect_false(codecheck:::wikidata_value_present("P577", "1982-04-01", "1982-05-00"))
expect_false(codecheck:::wikidata_value_present("P577", "2021-02-12", "2021-02-14"))
expect_true(codecheck:::wikidata_value_present("P10283", "W1", c("W2", "W1")))
expect_false(codecheck:::wikidata_value_present("P10283", "W1", character(0)))
month <- codecheck:::wikidata_missing_statements(
  "Q1\tP577\t+1982-04-01T00:00:00Z/11",
  list(P577 = list(claim("time", list(time = "+1982-04-00T00:00:00Z", precision = 10)))))
expect_equal(nrow(month), 0L)

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

# What the export wrote itself, and the register no longer supports ----

ours <- list(list(snaks = list(P854 = list(list(datavalue = list(
  value = "https://codecheck.org.uk/register/certs/2026-001/"))))))
theirs <- list(list(snaks = list(P248 = list(list(datavalue = list(value = list(id = "Q5188229")))))))
with_refs <- function(claim, references) { claim$references <- references; claim }

expect_equal(codecheck:::wikidata_claim_provenance(with_refs(item("Q1"), ours)), "ours")
expect_equal(codecheck:::wikidata_claim_provenance(with_refs(item("Q1"), c(ours, theirs))), "shared")
expect_equal(codecheck:::wikidata_claim_provenance(with_refs(item("Q1"), theirs)), "theirs")
expect_equal(codecheck:::wikidata_claim_provenance(item("Q1")), "theirs")

# Values are written back exactly as stored, which is how QuickStatements finds
# the statement to remove.
expect_equal(codecheck:::wikidata_claim_token(claim("time", list(time = "+2026-04-29T00:00:00Z", precision = 11))),
             "+2026-04-29T00:00:00Z/11")
expect_equal(codecheck:::wikidata_claim_token(claim("string", "W4415698124")), "\"W4415698124\"")
expect_equal(codecheck:::wikidata_claim_token(item("Q50812078")), "Q50812078")

# 2026-001: OpenAlex answered the preprint's DOI with the published article, and
# the export wrote that article's OpenAlex ID, date and journal onto the
# preprint. Now the model writes the preprint's own date and nothing else.
preprint_claims <- list(
  P31 = list(with_refs(item("Q580922"), ours)),
  P1476 = list(with_refs(claim("monolingualtext", list(text = "A \\\"kite\\\" study", language = "en")), ours)),
  P10283 = list(with_refs(claim("string", "W4415698124"), ours)),
  P577 = list(with_refs(claim("time", list(time = "+2026-04-29T00:00:00Z", precision = 11)), ours)),
  P1433 = list(with_refs(item("Q50812078"), c(ours, theirs)))
)
preprint_commands <- c("Q9\tP31\tQ580922", "Q9\tP577\t+2025-10-30T00:00:00Z/11",
                       "Q9\tP1476\ten:\"A \"kite\" study\"")
fixed <- codecheck:::wikidata_missing_statements(
  preprint_commands, preprint_claims, item = "Q9",
  properties = c("P31", "P1476", "P10283", "P577", "P1433"),
  rejected = list(P10283 = "W4415698124", P1433 = "Q50812078", P577 = "2026-04-29"))

# The OpenAlex ID is known to be wrong; the date and the title are replaced by
# the model's own, and the title is removed with the backslashes it is stored
# with, which is how QuickStatements finds it.
expect_equal(sort(fixed$command[fixed$action == "remove"]),
             sort(c("-Q9\tP10283\t\"W4415698124\"", "-Q9\tP577\t+2026-04-29T00:00:00Z/11",
                    "-Q9\tP1476\ten:\"A \\\"kite\\\" study\"")))
expect_equal(fixed$action[fixed$property == "P1476" & !is.na(fixed$proposed)], "add")
# The wrong date is removed, so the right one is an addition, not a difference.
expect_equal(fixed$action[fixed$property == "P577" & !is.na(fixed$proposed)], "add")
# Somebody else referenced the journal too: reported, not removed.
expect_equal(fixed$action[fixed$property == "P1433"], "shared")
expect_true(is.na(fixed$command[fixed$property == "P1433"]))
# What the model still writes stays.
expect_false("P31" %in% fixed$property)

# What the model writes nothing for is not wrong for that reason: the arXiv
# preprint keeps "published in arXiv" after the register lost its OpenAlex
# record, and the certificate its "review of" when the work cannot be resolved.
arxiv_claims <- list(P1433 = list(with_refs(item("Q118398"), ours)),
                     P10283 = list(with_refs(claim("string", "W6948154681"), ours)))
kept <- codecheck:::wikidata_missing_statements(
  character(0), arxiv_claims, item = "Q8", properties = c("P1433", "P10283"),
  rejected = list(P10283 = "W6948154681"))
expect_equal(kept$property, "P10283")
expect_equal(kept$action, "remove")

# Without the item and the model's properties, nothing is ever removed.
expect_false(any(codecheck:::wikidata_missing_statements(preprint_commands, preprint_claims)$action == "remove"))
