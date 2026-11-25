# Tests for the preprint and the article of a checked work in the Wikidata
# export (codecheckers/register#247). 2024-016 checked a Zenodo preprint and
# names the article published since in reference-other; 2026-023 checked the
# article and names its bioRxiv preprint. Both versions get an item, linked by
# P629 "edition or translation of" (preprint to article) and P747 "has edition
# or translation" (article to preprint). No test here reaches the network.

library(codecheck)
source("mocks.R")

preprint <- "https://doi.org/10.5281/zenodo.13734819"
article <- "https://doi.org/10.4081/gh.2025.1326"
jov <- "https://doi.org/10.1167/jov.26.10.14"
biorxiv <- "https://doi.org/10.1101/2025.11.10.687546"

other <- function(url, type) list(url = url, doi = sub("^https://doi.org/", "", url), type = type)
certificates <- data.frame(
  `Certificate ID` = c("2024-016", "2026-023", "2025-019"),
  `Paper reference` = c(preprint, jov, "https://doi.org/10.48550/arXiv.2503.21065"),
  `Paper kind` = c("preprint", "article", "preprint"),
  `Certificate Link` = paste0("https://codecheck.org.uk/register/certs/",
                              c("2024-016", "2026-023", "2025-019"), "/"),
  check.names = FALSE, stringsAsFactors = FALSE)
certificates$`Paper reference other` <- I(list(
  list(other(article, "Journal article")),
  list(other(biorxiv, "Preprint")),
  # another copy of the same preprint is not a version to link
  list(other("https://doi.org/10.2139/ssrn.5287999", "Preprint"))))

# --- which further references are versions ---------------------------------------

expect_equal(codecheck:::reference_version_kind(
  c("Preprint", "Journal article", "Conference paper", "Dataset", NA)),
  c("preprint", "article", "article", NA, NA))

# --- the registry record's title and authors -------------------------------------

expect_equal(codecheck:::registry_title(list("Integrating <i>agent-based</i>\n  models")),
             "Integrating agent-based models")
expect_true(is.na(codecheck:::registry_title(list())))
expect_equal(codecheck:::registry_authors(list(
  list(given = "Néstor", family = "DelaPaz-Ruíz"),         # Crossref
  list(givenName = "Raul", familyName = "Zurita-Milla"),   # DataCite
  list(name = "CHECK-NL"),                                 # an organisation
  list(family = "Augustijn"))),
  c("Néstor DelaPaz-Ruíz", "Raul Zurita-Milla", "CHECK-NL", "Augustijn"))

# --- rows for the works named in reference-other ----------------------------------

dir <- tempfile("register")
dir.create(file.path(dir, "docs", "works", "10.4081", "gh.2025.1326"), recursive = TRUE)
writeLines('{"work": {"doi": "10.4081/gh.2025.1326", "openalex": "https://openalex.org/W4407369653"}}',
           file.path(dir, "docs", "works", "10.4081", "gh.2025.1326", "index.json"))
registry <- function(reference) {
  if (grepl("gh.2025.1326", reference, fixed = TRUE)) {
    return(list(status = "found", value = list(
      type = "Journal article", publication_date = "2025-02-11",
      title = "Integrating agent-based disease, mobility and wastewater models for the study of the spread of communicable diseases",
      authors = c("Néstor DelaPaz-Ruíz", "Ellen-Wien Augustijn"))))
  }
  if (grepl("687546", reference, fixed = TRUE)) {
    return(list(status = "found", value = list(type = "Preprint", publication_date = "2025-11-2",
                                               title = "Circadian timing", authors = "Hannah Sophie Heinrichs")))
  }
  list(status = "found", value = list(type = "Preprint", title = NA_character_, authors = character(0)))
}
openalex_fields <- function(openalex_id, paper_reference) {
  list(status = "found", value = list(issn = "1827-1987", venue = "Geospatial health",
                                      publication_date = "2025-02-11"))
}
with_mocked_codecheck(list(get_registry_record_cached_result = registry,
                           get_openalex_work_fields_for = openalex_fields), {
  # 2025-019's SSRN copy is a preprint of a preprint: no item, so no lookup
  expect_silent(works <- codecheck:::reference_other_works(certificates, dir))
})
expect_equal(works$`Paper reference`, c(article, biorxiv))
expect_equal(works$`Paper kind`, c("article", "preprint"))
# The article's own title, not the preprint's, and its own publication
expect_equal(works$Title[1], "Integrating agent-based disease, mobility and wastewater models for the study of the spread of communicable diseases")
expect_equal(works$OpenAlex, c("https://openalex.org/W4407369653", NA))
expect_equal(works$`Paper ISSN`, c("1827-1987", NA))
# OpenAlex's date first, then the registry's, written as a full ISO date
expect_equal(works$`Work publication date`, c("2025-02-11", "2025-11-02"))
expect_equal(works$`Paper authors`[[1]], list("Néstor DelaPaz-Ruíz", "Ellen-Wien Augustijn"))
# The statements' reference is the page of the certificate that names it
expect_equal(works$`Certificate Link`[1], "https://codecheck.org.uk/register/certs/2024-016/")
# A checked work is not repeated as a further reference of another certificate
certificates_twice <- certificates
certificates_twice$`Paper reference other`[[3]] <- list(other(jov, "Journal article"))
with_mocked_codecheck(list(get_registry_record_cached_result = registry,
                           get_openalex_work_fields_for = openalex_fields), {
  expect_false(jov %in% codecheck:::reference_other_works(certificates_twice, dir)$`Paper reference`)
})

# A reference whose registry record cannot be had, or has no title, gets no item
untitled <- certificates[1, ]
untitled$`Paper reference other` <- I(list(list(other("https://doi.org/10.1234/untitled", "Journal article"),
                                                 other("https://doi.org/10.1234/offline", "Journal article"))))
lookup <- function(reference) {
  if (grepl("offline", reference)) return(list(status = "failed", value = NULL))
  list(status = "found", value = list(type = "Journal article", title = NA_character_))
}
said <- character(0)
with_mocked_codecheck(list(get_registry_record_cached_result = lookup), {
  none <- withCallingHandlers(codecheck:::reference_other_works(untitled, dir), message = function(m) {
    said <<- c(said, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
})
expect_null(none)
expect_true(any(grepl("no title in its registry record for https://doi.org/10.1234/untitled", said, fixed = TRUE)))
expect_true(any(grepl("the registry lookup failed for https://doi.org/10.1234/offline", said, fixed = TRUE)))
# OpenAlex without a date of the work's own leaves it to the registry record
undated <- function(openalex_id, paper_reference) {
  list(status = "found", value = list(issn = NA_character_, venue = NA_character_,
                                      publication_date = NA_character_))
}
with_mocked_codecheck(list(get_registry_record_cached_result = registry,
                           get_openalex_work_fields_for = undated), {
  expect_equal(codecheck:::reference_other_works(certificates[1, ], dir)$`Work publication date`,
               "2025-02-11")
})
# The type decides without a venue column, too
expect_equal(codecheck:::paper_kind(c(NA, "Preprint"), NULL), c("article", "preprint"))

# --- the links between them -------------------------------------------------------

papers <- codecheck:::bind_export_rows(certificates, works)
expect_equal(nrow(papers), 5L)
expect_true(is.data.frame(papers) && !inherits(papers, "tbl_df"))
expect_true(is.na(papers$`Certificate ID`[4]))
papers <- codecheck:::wikibase_version_links(papers, certificates)
link <- function(column, url) papers[[column]][[which(papers$`Paper reference` == url)]]
# The checked preprint is a version of its article, the article has it as one
expect_equal(link("Version of", preprint), article)
expect_equal(link("Has version", article), preprint)
# and the other way round for the checked article
expect_equal(link("Has version", jov), biorxiv)
expect_equal(link("Version of", biorxiv), jov)
# Two copies of the same preprint are not linked
expect_equal(link("Version of", "https://doi.org/10.48550/arXiv.2503.21065"), character(0))
expect_equal(link("Has version", preprint), character(0))

# --- what the export writes -------------------------------------------------------

items <- c("10.5281/ZENODO.13734819" = "Q141269441", "10.4081/GH.2025.1326" = "Q900")
resolve <- function(kind, key) {
  if (kind != "paper") return(NA_character_)
  unname(items[codecheck:::wikidata_transform(key, "doi")])
}
row <- papers[papers$`Paper reference` == preprint, , drop = FALSE]
commands <- codecheck:::quickstatements_for_entity("paper", row, qid = "Q141269441", resolve = resolve)
expect_true(any(startsWith(commands, "Q141269441\tP629\tQ900\t")))
expect_true(any(startsWith(commands, "Q141269441\tP31\tQ580922\t")))
row <- papers[papers$`Paper reference` == article, , drop = FALSE]
commands <- codecheck:::quickstatements_for_entity("paper", row, resolve = resolve)
expect_true(any(grepl("^LAST\tP747\tQ141269441\t", commands)))
expect_true(any(grepl("^LAST\tP31\tQ13442814\t", commands)))
expect_true(any(grepl("^LAST\tLen\t\"Integrating agent-based disease, mobility and wastewater", commands)))
# A version that has no item yet is left out until it has one
row <- papers[papers$`Paper reference` == jov, , drop = FALSE]
expect_false(any(grepl("\tP747\t", codecheck:::quickstatements_for_entity("paper", row, resolve = resolve))))
