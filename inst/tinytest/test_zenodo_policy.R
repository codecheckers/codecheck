# Tests for the CODECHECK Zenodo community curation policy helpers:
# split_person_name(), zenodo_policy_check(), upload_zenodo_metadata() and
# curate_zenodo_record(). All tests run offline against fixtures and mocks.

library(tinytest)

fixture <- function(name) {
  path <- system.file("tinytest", "fixtures", name, package = "codecheck")
  if (path == "") path <- file.path("fixtures", name)
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

# ---------------------------------------------------------------- name splitting

expect_equal(split_person_name("Stephen J. Eglen"),
             list(given = "Stephen J.", family = "Eglen"))
expect_equal(split_person_name("Eglen, Stephen J."),
             list(given = "Stephen J.", family = "Eglen"))
expect_equal(split_person_name("Daniel Nuest"),
             list(given = "Daniel", family = "Nuest"))
# single token: no split possible, caller falls back to an organisation
expect_null(split_person_name("codecheckers")$family)
expect_null(split_person_name("")$family)
expect_null(split_person_name(NULL)$family)

# ------------------------------------------------------- policy check: compliant

compliant <- fixture("zenodo_record_2026-019.json")
result <- zenodo_policy_check(compliant$metadata, files = unlist(compliant$files))

expect_true(is.data.frame(result))
expect_equal(sum(result$status == "fail"), 0)
expect_equal(result$status[result$check == "related work: paper"], "pass")
expect_equal(result$status[result$check == "alternate identifier (url)"], "pass")
expect_equal(result$status[result$check == "alternate identifier (other)"], "pass")
expect_equal(result$status[result$check == "creators"], "pass")

# --------------------------------------------------- policy check: non-compliant

broken <- fixture("zenodo_record_2026-023.json")
result <- zenodo_policy_check(broken$metadata, files = unlist(broken$files))

failed <- result$check[result$status == "fail"]
expect_equal(sort(failed),
             sort(c("related work: paper",
                    "alternate identifier (url)",
                    "alternate identifier (other)")))
# lowercase "certificate" in the title is a warning, not a failure
expect_equal(result$status[result$check == "title"], "warn")
# an organisational creator is reported as information, not asserted as an
# error: record metadata alone cannot tell a genuine group apart from a
# person mistakenly recorded as an organisation
expect_equal(result$status[result$check == "creators"], "info")
expect_true(grepl("Stephen J. Eglen", result$detail[result$check == "creators"]))
# the parts that are fine must stay fine
expect_equal(result$status[result$check == "publisher"], "pass")
expect_equal(result$status[result$check == "resource type"], "pass")
expect_equal(result$status[result$check == "license"], "pass")
expect_equal(result$status[result$check == "machine-readable certificate"], "pass")

# ------------------------------------------------------- upload_zenodo_metadata

# Minimal mock of a zen4R record: reuses the real zen4R record so that
# addCreator()/addRelatedIdentifier() behave exactly as in production.
mock_record <- function() {
  zen4R::ZenodoRecord$new()
}

mock_manager <- function() {
  zen <- new.env(parent = emptyenv())
  zen$deposited <- NULL
  zen$depositRecord <- function(record, ...) {
    zen$deposited <- record
    record
  }
  zen$publish_calls <- 0
  zen$publishRecord <- function(recordId) {
    zen$publish_calls <- zen$publish_calls + 1
    list(links = list(self_html = "https://zenodo.org/records/mock"))
  }
  zen
}

test_metadata <- function(checker_name = "Stephen J. Eglen") {
  list(
    certificate = "2026-023",
    summary = "A test summary.",
    check_time = "2026-08-21 10:00:00",
    repository = "https://github.com/codecheckers/HeinrichsEtAl_JVis_2026",
    paper = list(
      title = "A paper title",
      reference = "https://doi.org/10.1101/2025.11.10.687546"
    ),
    codechecker = list(list(name = checker_name, ORCID = "0000-0001-8607-8025"))
  )
}

zen <- mock_manager()
rec <- upload_zenodo_metadata(zen, mock_record(), metadata = test_metadata(),
                              resource_types = list(paper = "publication-preprint"))

# the codechecker must be a person, not an organisation
expect_equal(rec$metadata$creators[[1]]$person_or_org$type, "personal")
expect_equal(rec$metadata$creators[[1]]$person_or_org$family_name, "Eglen")
expect_equal(rec$metadata$creators[[1]]$person_or_org$given_name, "Stephen J.")

# the alternate identifiers must land in the field Zenodo actually stores
expect_equal(length(rec$metadata$identifiers), 2L)
schemes <- sapply(rec$metadata$identifiers, function(i) i$scheme)
expect_equal(sort(schemes), c("other", "url"))
expect_true(any(grepl("http://cdchck.science/register/certs/2026-023",
                      sapply(rec$metadata$identifiers, function(i) i$identifier))))

# title spelled as the policy does
expect_equal(rec$metadata$title, "CODECHECK Certificate 2026-023")

# the resulting metadata must pass its own policy check. zen4R resolves
# vocabularies (license, language, resource type) against the live Zenodo API,
# so the "reviews" relation can be absent when Zenodo is unreachable - that is
# an outage, not a defect, and is excluded from the assertion.
result <- zenodo_policy_check(rec$metadata, files = c("codecheck.pdf", "codecheck.Rmd"))
offline <- length(rec$metadata$related_identifiers) == 0
checked <- if (offline) result[result$check != "related work: paper", ] else result
expect_equal(sum(checked$status == "fail"), 0)

# a single-token name warns but does not fail
zen2 <- mock_manager()
expect_warning(
  rec2 <- upload_zenodo_metadata(zen2, mock_record(),
                                 metadata = test_metadata("codecheckers")),
  "Could not split codechecker name")
expect_equal(rec2$metadata$creators[[1]]$person_or_org$type, "organizational")

# ------------------------------------------------------------ curate: dry run

# curate_zenodo_record() with dry_run = TRUE must not write anything
zen3 <- mock_manager()
changes <- curate_zenodo_record("2026-023", zenodo = zen3,
                                metadata = test_metadata(),
                                record_metadata = broken,
                                dry_run = TRUE)
expect_null(zen3$deposited)
expect_equal(zen3$publish_calls, 0)
# and it must propose exactly the corrections the policy check flagged
expect_true(!is.null(changes$creators))
expect_true(!is.null(changes$reviews))
expect_true(!is.null(changes$identifiers))
expect_true(!is.null(changes$title))

# ------------------------------------------- register-wide check (offline)

# check_register_zenodo_policy() caches record metadata, so keep this test's
# cache out of the user's real one (restored at the end of the file;
# on.exit() would run immediately, it is not inside a function)
policy_cache_root <- file.path(tempfile("codecheck_zenodo_policy_cache"))
dir.create(policy_cache_root, recursive = TRUE)
policy_old_root <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(policy_cache_root)

# Injected metadata getter serving the two fixtures, so no network is used.
fake_getter <- function(record_id) {
  if (record_id == 21238767) return(compliant)
  if (record_id == 22094773) return(broken)
  stop("unexpected record id: ", record_id)
}

reg <- data.frame(
  Certificate = c("2026-019", "2026-023"),
  Report = c("https://doi.org/10.5281/zenodo.21238767",
             "https://doi.org/10.5281/zenodo.22094773"),
  stringsAsFactors = FALSE)

res <- check_register_zenodo_policy(reg, get_metadata = fake_getter)

expect_equal(nrow(res), 2L)
expect_equal(res$status[res$certificate == "2026-019"], "compliant")
expect_equal(res$status[res$certificate == "2026-023"], "non-compliant")
expect_equal(res$n_fail[res$certificate == "2026-023"], 3L)
expect_equal(res$n_fail[res$certificate == "2026-019"], 0L)
# the organisational creator is an info finding, not a failure, and does not
# by itself make the record non-compliant
expect_equal(res$n_info[res$certificate == "2026-023"], 1L)
expect_equal(res$n_info[res$certificate == "2026-019"], 0L)
expect_true(grepl("reviews", res$findings[res$certificate == "2026-023"]))
expect_true(grepl("creators", res$findings[res$certificate == "2026-023"]))

# a getter that throws must yield "unknown", never an error. Uses a record id
# of its own: a failed lookup is deliberately not cached, but a successful one
# from an earlier assertion would be served from the cache instead of the getter
res <- check_register_zenodo_policy(
  data.frame(Certificate = "2026-999",
             Report = "https://doi.org/10.5281/zenodo.9999999",
             stringsAsFactors = FALSE),
  get_metadata = function(record_id) stop("Zenodo is down"))
expect_equal(res$status, "unknown")
expect_true(is.na(res$n_fail))

# entries not archived on Zenodo are skipped, not reported as unknown
osf <- data.frame(Certificate = "2024-023", Report = "https://osf.io/abcde",
                  stringsAsFactors = FALSE)
expect_equal(nrow(check_register_zenodo_policy(osf, get_metadata = fake_getter)), 0L)

# a table without the expected columns is handled, not an error
expect_equal(nrow(check_register_zenodo_policy(data.frame(a = 1))), 0L)
expect_equal(nrow(check_register_zenodo_policy(NULL)), 0L)

# the reporter tolerates an empty result and returns its input invisibly
expect_silent(report_zenodo_policy_findings(check_register_zenodo_policy(NULL)))

# repeated checks are served from the cache rather than re-fetching
fetches <- 0
counting_getter <- function(record_id) {
  fetches <<- fetches + 1
  fake_getter(record_id)
}
invisible(check_register_zenodo_policy(reg, get_metadata = counting_getter))
before <- fetches
invisible(check_register_zenodo_policy(reg, get_metadata = counting_getter))
expect_equal(fetches, before)

R.cache::setCacheRootPath(policy_old_root)

# a curated record must not keep being reported from the pre-curation cache
policy_cache_root2 <- file.path(tempfile("codecheck_zenodo_policy_cache2"))
dir.create(policy_cache_root2, recursive = TRUE)
policy_old_root2 <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(policy_cache_root2)

one <- reg[reg$Certificate == "2026-023", ]
expect_equal(check_register_zenodo_policy(one, get_metadata = fake_getter)$status,
             "non-compliant")
# same fixture would be served from the cache; after invalidating, the getter
# runs again and a now-compliant record is reported as such
expect_true(clear_zenodo_policy_cache(22094773))
expect_equal(
  check_register_zenodo_policy(one, get_metadata = function(id) compliant)$status,
  "compliant")

R.cache::setCacheRootPath(policy_old_root2)

# a record with warnings but no failures must not carry an empty ": " finding
policy_cache_root3 <- file.path(tempfile("codecheck_zenodo_policy_cache3"))
dir.create(policy_cache_root3, recursive = TRUE)
policy_old_root3 <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(policy_cache_root3)

res <- check_register_zenodo_policy(reg[reg$Certificate == "2026-019", ],
                                    get_metadata = fake_getter)
expect_false(grepl("^: |\\| : ", res$findings))
expect_true(all(nchar(trimws(strsplit(res$findings, " \\| ")[[1]])) > 2))

R.cache::setCacheRootPath(policy_old_root3)

# ------------------------------------------------ fields selector and batching

policy_cache_root4 <- file.path(tempfile("codecheck_zenodo_policy_cache4"))
dir.create(policy_cache_root4, recursive = TRUE)
policy_old_root4 <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(policy_cache_root4)

# `fields` restricts which corrections are proposed
only_title <- curate_zenodo_record("2026-023", metadata = test_metadata(),
                                   record_metadata = broken, dry_run = TRUE,
                                   fields = "title")
expect_true(!is.null(only_title[["title"]]))
expect_null(only_title[["identifiers"]])
expect_null(only_title$reviews)
expect_null(only_title$creators)

# the batch default must never touch creator names: splitting a group entry
# such as "Delft 2024-05 participants" into given/family would be wrong
no_creators <- curate_zenodo_record("2026-023", metadata = test_metadata(),
                                    record_metadata = broken, dry_run = TRUE,
                                    fields = c("title", "publisher", "language",
                                               "resource_type", "identifiers",
                                               "reviews", "repository"))
expect_null(no_creators$creators)
expect_true(!is.null(no_creators$identifiers))

# a title carrying extra text is routed to the human list, never truncated
titled <- broken
titled$metadata$title <- "CODECHECK certificate 2026-023 for \"Some paper title\""
res <- curate_zenodo_record("2026-023", metadata = test_metadata(),
                            record_metadata = titled, dry_run = TRUE,
                            fields = "title")
# exact indexing: res$title would partial-match res$title_manual
expect_null(res[["title"]])
expect_true(!is.null(res[["title_manual"]]))

# a repository under codecheckers is proposed as a supplement relation
no_rel_ok <- broken
no_rel_ok$metadata$related_identifiers <- list()
res <- curate_zenodo_record("2026-023", metadata = test_metadata(),
                            record_metadata = no_rel_ok, dry_run = TRUE,
                            fields = "repository")
expect_true(!is.null(res[["repository"]]))

# a repository outside codecheckers/cdchck is surfaced, not deposited
elsewhere <- test_metadata()
elsewhere$repository <- "https://github.com/someone-else/repo"
no_rel <- broken
no_rel$metadata$related_identifiers <- list()
res <- curate_zenodo_record("2026-023", metadata = elsewhere,
                            record_metadata = no_rel, dry_run = TRUE,
                            fields = "repository")
expect_null(res[["repository"]])
expect_true(!is.null(res[["repository_manual"]]))

R.cache::setCacheRootPath(policy_old_root4)

# a token without edit rights must produce a clear message, not the
# "attempt to apply non-function" that calling a method on a non-record gives
zen_denied <- mock_manager()
zen_denied$editRecord <- function(recordId) NULL
expect_error(
  curate_zenodo_record("2026-023", zenodo = zen_denied, metadata = test_metadata(),
                       record_metadata = broken, dry_run = FALSE),
  "not allowed to edit")
expect_null(zen_denied$deposited)
expect_equal(zen_denied$publish_calls, 0)

# ------------------------------------------------------- creator overrides

# a genuine group stays an organisation instead of being split into nonsense
group_rec <- broken
group_rec$metadata$creators <- list(
  list(person_or_org = list(type = "organizational", name = "Delft 2024-05 participants")))
res <- curate_zenodo_record("2024-003", metadata = test_metadata(),
                            record_metadata = group_rec, dry_run = TRUE,
                            fields = "creators",
                            creator_overrides = list(
                              "Delft 2024-05 participants" = list(organizational = TRUE)))
expect_null(res[["creators"]])

# an explicit split beats the last-token heuristic for a compound family name
compound <- broken
compound$metadata$creators <- list(
  list(person_or_org = list(type = "organizational", name = "Gabriella Low Chew Tung")))
res <- curate_zenodo_record("2024-019", metadata = test_metadata(),
                            record_metadata = compound, dry_run = TRUE,
                            fields = "creators",
                            creator_overrides = list(
                              "Gabriella Low Chew Tung" = list(given = "Gabriella",
                                                               family = "Low Chew Tung")))
expect_equal(res[["creators"]][[1]]$family, "Low Chew Tung")
expect_equal(res[["creators"]][[1]]$given, "Gabriella")
# without the override the heuristic would get it wrong, which is why it exists
expect_equal(split_person_name("Gabriella Low Chew Tung")$family, "Tung")

# ------------------------------------------------------------------ licence

# CC-BY 4.0 must be present; further licences for other artefacts are fine
ok_multi <- broken
ok_multi$metadata$rights <- list(list(id = "other-open"), list(id = "cc-by-4.0"))
res <- zenodo_policy_check(ok_multi$metadata)
expect_equal(res$status[res$check == "license"], "pass")
expect_true(grepl("other artefacts", res$detail[res$check == "license"]))

# CC-BY alone passes
only_ccby <- broken
only_ccby$metadata$rights <- list(list(id = "cc-by-4.0"))
expect_equal(zenodo_policy_check(only_ccby$metadata)$status[1:3][3], "pass")

# without CC-BY it fails, whatever else is present
nocc <- broken
nocc$metadata$rights <- list(list(id = "other-open"))
res <- zenodo_policy_check(nocc$metadata)
expect_equal(res$status[res$check == "license"], "fail")

# curation ADDS cc-by-4.0 and keeps the existing licence
res <- curate_zenodo_record("2020-002", metadata = test_metadata(),
                            record_metadata = nocc, dry_run = TRUE, fields = "license")
expect_equal(res[["license"]]$rights, c("other-open", "cc-by-4.0"))

# a missing licence just gets cc-by-4.0
nolic <- broken
nolic$metadata$rights <- NULL
res <- curate_zenodo_record("2024-001", metadata = test_metadata(),
                            record_metadata = nolic, dry_run = TRUE, fields = "license")
expect_equal(res[["license"]]$rights, "cc-by-4.0")

# a record already carrying cc-by-4.0 needs no licence change
res <- curate_zenodo_record("2020-002", metadata = test_metadata(),
                            record_metadata = ok_multi, dry_run = TRUE, fields = "license")
expect_null(res[["license"]])

# applying the licence writes the full rights list: CC-BY for the certificate,
# keeping any other licence the record carries for its other artefacts
zen_lic <- mock_manager()
lic_rec <- zen4R::ZenodoRecord$new()
lic_rec$metadata$rights <- list(list(id = "other-open"))
zen_lic$editRecord <- function(recordId) lic_rec
nocc2 <- broken
nocc2$metadata$rights <- list(list(id = "other-open"))
invisible(curate_zenodo_record(3750741, zenodo = zen_lic, metadata = test_metadata(),
                               record_metadata = nocc2, dry_run = FALSE,
                               fields = "license"))
ids <- unlist(lapply(zen_lic$deposited$metadata$rights, function(r) r$id))
expect_equal(ids, c("other-open", "cc-by-4.0"))
