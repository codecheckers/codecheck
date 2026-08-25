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
             sort(c("creators",
                    "related work: paper",
                    "alternate identifier (url)",
                    "alternate identifier (other)")))
# lowercase "certificate" in the title is a warning, not a failure
expect_equal(result$status[result$check == "title"], "warn")
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
