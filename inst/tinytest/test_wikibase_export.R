tinytest::using(ttdo)

# Everything up to wikibase_entity_payload() is pure: rows and a mapping in,
# the data a write would send out. That is what makes a rehearsal meaningful,
# and it is all testable without an account.

local <- c(P31 = "P9", P13046 = "P10", P1476 = "P11", P356 = "P12", P577 = "P13",
           P50 = "P14", P2093 = "P15", P6977 = "P16", P973 = "P17", P528 = "P18",
           P972 = "P26", P953 = "P19", P1324 = "P20", P1433 = "P21", P1343 = "P22",
           P854 = "P27", P813 = "P28", P496 = "P23", P236 = "P24", P856 = "P25",
           P10283 = "P29",
           Q116740091 = "Q7", Q116740071 = "Q8", Q111935840 = "Q9", Q13442814 = "Q10",
           Q580922 = "Q11", Q265158 = "Q12", Q5 = "Q13", Q141254857 = "Q14",
           Q22661177 = "Q15", Q18691678 = "Q16", Q115504497 = "Q17")
local <- as.list(local)

# Transforms ----

# Wikidata stores DOIs bare and uppercased; a lookup that does not match that
# exactly finds nothing.
expect_equal(codecheck:::wikidata_transform("https://doi.org/10.1093/gigascience/giaa026", "doi"),
             "10.1093/GIGASCIENCE/GIAA026")
expect_equal(codecheck:::wikidata_transform("http://dx.doi.org/10.5281/zenodo.3674056", "doi"),
             "10.5281/ZENODO.3674056")
# Not every "Paper reference" is a DOI - some are publisher or arXiv URLs, and
# pretending they are would create one item per URL shape.
expect_true(is.na(codecheck:::wikidata_transform("https://arxiv.org/abs/2101.00001", "doi")))
expect_equal(codecheck:::wikidata_transform("2019-02-14 10:00:00", "date_day"), "2019-02-14")
expect_equal(codecheck:::wikidata_transform("https://orcid.org/0000-0001-8607-8025", "orcid"),
             "0000-0001-8607-8025")

# The register stores an OpenAlex work as a URL; Wikidata's P10283 wants the id.
expect_equal(codecheck:::wikidata_transform("https://openalex.org/W3014157798", "openalex"),
             "W3014157798")
expect_equal(codecheck:::wikidata_transform("W3014157798", "openalex"), "W3014157798")
# An author or venue id is not a work id, and neither is a stray URL.
expect_true(is.na(codecheck:::wikidata_transform("https://openalex.org/A5023888391", "openalex")))
expect_true(is.na(codecheck:::wikidata_transform("not an id", "openalex")))

# venues.csv packs identifiers; once extracted the value is the ISSN itself.
# The model resolves a venue by this value whichever shape it arrives in.
expect_equal(codecheck:::wikidata_transform(
  "ISSN|fa-book|2047-217X|https://portal.issn.org/resource/ISSN/2047-217X", "issn"),
  "2047-217X")
expect_equal(codecheck:::wikidata_transform("2047-217X", "issn"), "2047-217X")
expect_true(is.na(codecheck:::wikidata_transform("ROR|fa-university|abc|url", "issn")))

# Platform detection stays offline for the DOI prefixes we publish under.
expect_equal(codecheck:::wikidata_transform("http://doi.org/10.5281/zenodo.3674056", "report_platform"),
             "zenodo")
expect_equal(codecheck:::wikidata_transform("https://doi.org/10.17605/OSF.IO/ABCDE", "report_platform"),
             "osf")
expect_equal(codecheck:::wikidata_transform("https://doi.org/10.53962/abcd-efgh", "report_platform"),
             "researchequals")
expect_error(codecheck:::wikidata_transform("x", "not_a_transform"), pattern = "Unknown transform")

# Evaluating a value against a row ----

row <- list(
  `Certificate ID` = "2020-001",
  `Certificate Link` = "https://codecheck.org.uk/register/certs/2020-001/",
  `Certificate PDF` = "https://zenodo.org/records/3674056/files/codecheck.pdf",
  `Repository Link` = "https://github.com/codecheckers/Piccolo-2020",
  Report = "http://doi.org/10.5281/zenodo.3674056",
  Title = "ShinyLearner",
  `Paper reference` = "https://doi.org/10.1093/gigascience/giaa026",
  Venue = "GigaScience",
  `Check date` = "2019-02-14",
  Codechecker = list(list(
    list(name = "Stephen J. Eglen", orcid = "0000-0001-8607-8025"),
    list(name = "Nameless Checker", orcid = NA)
  ))
)
resolve <- function(kind, key) switch(kind, person = "Q18", paper = "Q87", venue = "Q85", NA_character_)

expect_equal(codecheck:::evaluate_model_value(list(kind = "constant", item = "Q7"), row), "Q7")
# A constant marked pending names an item that does not exist yet, and nothing
# is emitted for it - visibly, via wikidata_pending(), rather than silently.
expect_equal(length(codecheck:::evaluate_model_value(
  list(kind = "constant", item = NULL, pending = "no item yet"), row)), 0L)
expect_equal(codecheck:::evaluate_model_value(list(kind = "field", field = "Title"), row),
             "ShinyLearner")
# A field the row does not have means the statement does not apply.
expect_equal(length(codecheck:::evaluate_model_value(list(kind = "field", field = "Nope"), row)), 0L)
# Only the codecheckers without an ORCID become name strings; the others get an
# item and a P50 statement instead.
expect_equal(codecheck:::evaluate_model_value(
  list(kind = "field", field = "Codechecker", transform = "unresolved_names"), row),
  "Nameless Checker")
expect_equal(codecheck:::evaluate_model_value(
  list(kind = "entity", entity = "person", field = "Codechecker"), row, resolve), "Q18")
# Venue decides the type: the AGILE reviews are not branded CODECHECKs.
switch_value <- list(kind = "switch", field = "Venue",
                     cases = list(`AGILE conference` = "Q8"), default = "Q7")
expect_equal(codecheck:::evaluate_model_value(switch_value, row), "Q7")
expect_equal(codecheck:::evaluate_model_value(switch_value, list(Venue = "AGILE conference")), "Q8")
expect_equal(codecheck:::evaluate_model_value(
  list(kind = "mapped", field = "Report", transform = "report_platform", map = "platforms"), row),
  "Q22661177")

# Datavalues ----

expect_equal(codecheck:::wikibase_datavalue("wikibase-item", "Q7")$value$id, "Q7")
expect_equal(codecheck:::wikibase_datavalue("wikibase-item", "Q7")$type, "wikibase-entityid")
# Day precision, Gregorian: the register records a day, and claiming more would
# be inventing it.
time <- codecheck:::wikibase_datavalue("time", "2019-02-14")
expect_equal(time$value$time, "+2019-02-14T00:00:00Z")
expect_equal(time$value$precision, 11)
expect_equal(codecheck:::wikibase_datavalue("monolingualtext", "T")$value$language, "en")
expect_equal(codecheck:::wikibase_datavalue("external-id", "10.1/A")$value, "10.1/A")

# Claims ----

claims <- codecheck:::wikibase_claims("certificate", row, local, resolve)
properties <- vapply(claims, function(claim) claim$mainsnak$property, character(1))

# Local property numbers, not Wikidata's: P31 is "father" on a stock Wikibase.
expect_true(all(properties %in% unlist(local)))
expect_true("P9" %in% properties)
expect_false("P31" %in% properties)

# Every statement carries the reference block, which is what distinguishes a
# statement this pipeline wrote from one somebody added by hand.
expect_true(all(vapply(claims, function(claim) length(claim$references) == 1, logical(1))))
reference_snaks <- names(claims[[1]]$references[[1]]$snaks)
expect_equal(sort(reference_snaks), c("P27", "P28"))

# A catalog code without its catalog says nothing, so P528 carries P972.
catalog <- Filter(function(claim) claim$mainsnak$property == "P18", claims)[[1]]
expect_equal(names(catalog$qualifiers), "P26")
expect_equal(catalog$qualifiers$P26[[1]]$datavalue$value$id, "Q14")

# An item the model names is translated to the local item standing for it. A
# value that came out of resolve() is already local and must not be translated
# again - "Q5" is the human class on Wikidata and Douglas Adams in the seed data.
type <- Filter(function(claim) claim$mainsnak$property == "P9", claims)[[1]]
expect_equal(type$mainsnak$datavalue$value$id, "Q7")
author <- Filter(function(claim) claim$mainsnak$property == "P14", claims)[[1]]
expect_equal(author$mainsnak$datavalue$value$id, "Q18")

# A property the instance does not have yet is skipped rather than written with
# a Wikidata id that means something else locally.
partial <- codecheck:::wikibase_claims("certificate", row, local[c("P356", "P854", "P813")], resolve)
expect_equal(unique(vapply(partial, function(claim) claim$mainsnak$property, character(1))), "P12")
# The same holds for an item value: without the local item standing for the
# class, the statement has no target and is not written.
no_items <- codecheck:::wikibase_claims("certificate", row, local[c("P31", "P854", "P813")], resolve)
expect_equal(length(no_items), 0L)

# Several values, several statements: three codecheckers are three authors.
two_checkers <- row
two_checkers$Codechecker <- list(list(list(name = "A", orcid = "0000-0001-0000-0001"),
                                      list(name = "B", orcid = "0000-0001-0000-0002")))
resolve_two <- function(kind, key) if (kind == "person") paste0("Q", substr(key, 18, 19)) else NA_character_
authors <- Filter(function(claim) claim$mainsnak$property == "P14",
                  codecheck:::wikibase_claims("certificate", two_checkers, local, resolve_two))
expect_equal(length(authors), 2L)

# Payloads ----

payload <- codecheck:::wikibase_entity_payload("certificate", row, local, resolve)
# Mustache cannot address a key with a space, so the model addresses the
# register's "Certificate ID" column as {{Certificate_ID}}.
expect_equal(payload$labels$en$value, "CODECHECK Certificate 2020-001")
expect_equal(payload$descriptions$en$value,
             "reproducibility check of a paper published in GigaScience")

# Wikibase rejects a label over 250 characters, and paper titles reach that.
long <- list(Title = paste(rep("word", 100), collapse = " "),
             `Paper reference` = "https://doi.org/10.1234/x")
long_payload <- codecheck:::wikibase_entity_payload("paper", long, local)
expect_true(nchar(long_payload$labels$en$value) <= 250)
expect_true(endsWith(long_payload$labels$en$value, "..."))

# A checked work carries its OpenAlex id: it is the identifier most likely to be
# there when the DOI alone does not find the work, and it leads to the authors,
# venue and citations this export deliberately does not mirror.
paper_row <- list(`Paper reference` = "https://doi.org/10.1093/gigascience/giaa026",
                  Title = "ShinyLearner", Venue = "GigaScience",
                  OpenAlex = "https://openalex.org/W3014157798")
paper_payload <- codecheck:::wikibase_entity_payload("paper", paper_row, local)
openalex <- Filter(function(claim) claim$mainsnak$property == "P29", paper_payload$claims)
expect_equal(length(openalex), 1L)
expect_equal(openalex[[1]]$mainsnak$datavalue$value, "W3014157798")

# A paper the register has no OpenAlex id for simply gets no such statement.
paper_row$OpenAlex <- NA_character_
expect_equal(length(Filter(function(claim) claim$mainsnak$property == "P29",
                           codecheck:::wikibase_entity_payload("paper", paper_row, local)$claims)), 0L)

# Keys and deduplication ----

expect_equal(codecheck:::wikibase_entity_key("certificate", row), "10.5281/ZENODO.3674056")
expect_equal(codecheck:::wikibase_entity_key("paper", row), "10.1093/GIGASCIENCE/GIAA026")
expect_true(is.na(codecheck:::wikibase_entity_key("paper", list(`Paper reference` = "no-doi"))))

# A person is one item however many certificates they checked, and a paper one
# item however many times it was checked.
records <- list(
  certificates = do.call(rbind, lapply(1:2, function(i) {
    frame <- data.frame(`Certificate ID` = paste0("2020-00", i),
                        `Paper reference` = "https://doi.org/10.1234/same",
                        Report = paste0("https://doi.org/10.5281/zenodo.", i),
                        Title = "Same paper", Venue = "GigaScience",
                        `Check date` = "2020-01-01", check.names = FALSE,
                        stringsAsFactors = FALSE)
    frame$Codechecker <- I(list(list(list(name = "A", orcid = "0000-0001-0000-0001"))))
    frame
  })),
  venues = data.frame(name = "GigaScience", longname = "GigaScience",
                      identifiers = "ISSN|fa-book|2047-217X|url",
                      website_url = "https://example.org", stringsAsFactors = FALSE)
)
rows <- codecheck:::wikibase_export_rows(records)
expect_equal(nrow(rows$certificate), 2L)
expect_equal(nrow(rows$paper), 1L)     # one paper, checked twice
expect_equal(nrow(rows$person), 1L)    # one person, two certificates
expect_equal(nrow(rows$venue), 1L)
expect_equal(rows$venue$issn, "2047-217X")

# The certificate index ----

# An item number says nothing to somebody looking for certificate 2020-001, so
# the load writes the page that connects the two.
written <- data.frame(
  kind = c("paper", "certificate", "certificate"),
  # Uppercased, the way wikidata_transform() normalises a DOI and the way the
  # load's own keys are written.
  key = c("10.1234/SAME", "10.5281/ZENODO.1", "10.5281/ZENODO.2"),
  action = "create", id = c("Q87", "Q89", "Q90"), statements = 3L,
  stringsAsFactors = FALSE
)
certificates <- records$certificates
certificates$Report <- c("https://doi.org/10.5281/zenodo.1", "https://doi.org/10.5281/zenodo.2")
certificates$`Certificate Link` <- "https://codecheck.org.uk/register/certs/2020-001/"
page <- paste(codecheck:::wikibase_certificates_wikitext(written, certificates), collapse = "\n")

expect_true(grepl("== 2 certificates ==", page, fixed = TRUE))
expect_true(grepl("[[Item:Q89|2020-001]]", page, fixed = TRUE))
expect_true(grepl("[[Item:Q90|2020-002]]", page, fixed = TRUE))
# Both certificates checked the same paper, and both link to its one item.
expect_equal(length(gregexpr("[[Item:Q87|Q87]]", page, fixed = TRUE)[[1]]), 2L)
expect_true(grepl("[[Project:Data model]]", page, fixed = TRUE))
expect_true(grepl("load_wikibase_register()", page, fixed = TRUE))

# A certificate whose paper has no DOI has no paper item to link to, and says so
# rather than printing NA.
no_paper <- certificates
no_paper$`Paper reference` <- "https://example.org/no-doi"
sparse <- paste(codecheck:::wikibase_certificates_wikitext(written, no_paper), collapse = "\n")
expect_false(grepl("Item:NA", sparse, fixed = TRUE))
expect_true(grepl("&mdash;", sparse, fixed = TRUE))

# Two entities, one identifier ----

# Every entity is found again by the identifier the model resolves it on, so two
# rows sharing one are not two entities: they are one, written twice, and the
# second overwrites the first. On Wikidata the loser is gone without a trace.
collide <- records
collide$certificates$Report <- rep("https://doi.org/10.5281/zenodo.1", 2)
collide$certificates$`Certificate ID` <- c("2025-009", "2025-010")
expect_error(
  codecheck:::check_export_keys(codecheck:::wikibase_export_rows(collide)),
  pattern = "2025-009, 2025-010"
)
expect_error(
  codecheck:::check_export_keys(codecheck:::wikibase_export_rows(collide)),
  pattern = "overwrite"
)

# The register as it stands passes, and so does a check limited to the kinds
# that go to Wikidata.
expect_true(codecheck:::check_export_keys(rows))
expect_true(codecheck:::check_export_keys(rows, kinds = c("paper", "certificate")))

# Rows with no identifier are not all the same entity: they are simply not
# exported, and must not read as a collision.
no_keys <- records
no_keys$certificates$`Paper reference` <- c("https://example.org/a", "https://example.org/b")
expect_true(codecheck:::check_export_keys(codecheck:::wikibase_export_rows(no_keys),
                                          kinds = "paper"))

# Where and when a checked work appeared ----

# The register's own Venue column names the venue that commissioned the check,
# which is a different fact: one register venue spans several publications over
# the years. The publication comes from the work's own OpenAlex record.
work_row <- list(
  Title = "ShinyLearner",
  `Paper reference` = "https://doi.org/10.1093/gigascience/giaa026",
  Venue = "AGILEGIS",
  `Paper ISSN` = "2047-217X",
  `Paper publication date` = "2020-04-01"
)
local_with_venue <- c(local, list(P577 = "P13"))
work_payload <- codecheck:::wikibase_entity_payload(
  "paper", work_row, local_with_venue,
  resolve = function(kind, key) if (kind == "venue" && key == "2047-217X") "Q85" else NA)

published_in <- Filter(function(claim) claim$mainsnak$property == "P21", work_payload$claims)
expect_equal(length(published_in), 1L)
expect_equal(published_in[[1]]$mainsnak$datavalue$value$id, "Q85")

published_on <- Filter(function(claim) claim$mainsnak$property == "P13", work_payload$claims)
expect_equal(published_on[[1]]$mainsnak$datavalue$value$time, "+2020-04-01T00:00:00Z")

# A work whose publication has no ISSN - a preprint, a report - gets no venue
# statement rather than a guess from the register's venue.
no_issn <- work_row
no_issn$`Paper ISSN` <- NA_character_
expect_equal(length(Filter(
  function(claim) claim$mainsnak$property == "P21",
  codecheck:::wikibase_entity_payload("paper", no_issn, local_with_venue)$claims)), 0L)

# A register rendered before this enrichment existed has neither column, and
# the work is exported without those statements rather than failing.
older <- work_row[c("Title", "Paper reference", "Venue")]
expect_true(length(codecheck:::wikibase_entity_payload("paper", older, local_with_venue)$claims) > 0)

# The publications the works appeared in ----

# venues.csv covers the venues that commission checks, which is not the set of
# publications the checked works appeared in. The mirror holds everything, so a
# publication the register does not know still gets an item - otherwise the
# work's "published in" statement has no target and is silently dropped.
with_publications <- records
with_publications$certificates$`Paper ISSN` <- c("2047-217X", "0027-8424")
with_publications$certificates$`Paper venue` <- c("GigaScience",
                                                  "Proceedings of the National Academy of Sciences")
venues <- codecheck:::wikibase_export_rows(with_publications)$venue
expect_equal(nrow(venues), 2L)
expect_true("Proceedings of the National Academy of Sciences" %in% venues$longname)
# The register's own row wins for a publication it already describes: it has a
# website and a curated name, which the OpenAlex record does not.
expect_equal(venues$longname[venues$issn == "2047-217X"], "GigaScience")
expect_equal(sum(venues$issn == "2047-217X"), 1L)

# Two works in one publication are one venue item.
same_venue <- with_publications
same_venue$certificates$`Paper ISSN` <- c("0027-8424", "0027-8424")
same_venue$certificates$`Paper venue` <- rep("Proceedings of the National Academy of Sciences", 2)
expect_equal(nrow(codecheck:::wikibase_export_rows(same_venue)$venue), 2L)

# A publication OpenAlex has no name for cannot be labelled, and an item with an
# ISSN and nothing else says less than no item at all.
unnamed <- with_publications
unnamed$certificates$`Paper venue` <- c("GigaScience", NA_character_)
expect_equal(nrow(codecheck:::wikibase_export_rows(unnamed)$venue), 1L)

# Every venue row still has the identifier it is found again by.
expect_true(all(!is.na(codecheck:::wikibase_key_column(venues, "venue"))))

# A venue item states the identifier it is found again by ----

# The statement and the resolve rule have to read the same field: reading
# venues.csv's packed "identifiers" for the statement while resolving on "issn"
# left every venue built from a work's own record with a label and no ISSN, so
# the next run could not find it and created it again.
venue_payload <- codecheck:::wikibase_entity_payload(
  "venue",
  list(longname = "Proceedings of the National Academy of Sciences", issn = "0027-8424"),
  c(local, list(P236 = "P24")))
issn_claim <- Filter(function(claim) claim$mainsnak$property == "P24", venue_payload$claims)
expect_equal(length(issn_claim), 1L)
expect_equal(issn_claim[[1]]$mainsnak$datavalue$value, "0027-8424")
expect_equal(venue_payload$labels$en$value, "Proceedings of the National Academy of Sciences")

# venues.csv's packed form still works, since the transform accepts both.
packed <- codecheck:::wikibase_entity_payload(
  "venue",
  list(longname = "GigaScience", issn = "ISSN|fa-book|2047-217X|https://portal.issn.org/x"),
  c(local, list(P236 = "P24")))
expect_equal(Filter(function(claim) claim$mainsnak$property == "P24",
                    packed$claims)[[1]]$mainsnak$datavalue$value, "2047-217X")
