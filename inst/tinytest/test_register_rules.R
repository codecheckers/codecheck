# Tests for the register-wide rules, see validate_register_rules()

library(codecheck)

register_of <- function(ids, types = "community", venues = "codecheck") {
  data.frame(Certificate = ids,
             Repository = "github::codecheckers/example",
             Type = rep_len(types, length(ids)),
             Venue = rep_len(venues, length(ids)),
             Issue = NA, stringsAsFactors = FALSE)
}

venues_csv <- tempfile(fileext = ".csv")
write.csv(data.frame(name = c("codecheck", "GigaScience"),
                     longname = c("CODECHECK", "GigaScience"),
                     label = c("a", "b")),
          venues_csv, row.names = FALSE)

# The register repository's issues, instead of asking GitHub
fake_issues <- function() {
  data.frame(number = c(1L, 2L, 3L),
             title = c("2026-001 A check", "2026-002 B check", "a pull request"),
             stringsAsFactors = FALSE)
}

run <- function(register, ...) {
  validate_register_rules(register, venues_file = venues_csv, get_issues = fake_issues,
                          stop_on_error = FALSE, quiet = TRUE, ...)
}
outcome_of <- function(results, id) results$outcome[results$id == id]
detail_of <- function(results, id) results$detail[results$id == id]

# --- a good register passes every rule ---

good <- register_of(c("2025-001", "2025-002", "2026-001"))
results <- run(good)
expect_equal(sort(results$id), c("CC-REG-002", "CC-REG-004", "CC-REG-005",
                                  "CC-REG-006", "CC-REG-007"))
expect_true(all(results$outcome[results$id %in% c("CC-REG-002", "CC-REG-004", "CC-REG-005")] == "ok"))
# without Issue numbers there is nothing to look up
expect_true(all(results$outcome[results$id %in% c("CC-REG-006", "CC-REG-007")] == "skipped"))

# --- CC-REG-002 certificate-id-sequence ---

# Gaps from reserved, unused identifiers are normal: today's register jumps
# from 2025-022 to 2025-025 and from 2026-019 to 2026-023.
with_gaps <- register_of(c(sprintf("2025-%03d", c(1:22, 25, 27, 28)),
                           sprintf("2026-%03d", c(1, 4:19, 23))))
expect_equal(outcome_of(run(with_gaps), "CC-REG-002"), "ok")

# A jump of nine is still allowed, ten is not.
expect_equal(outcome_of(run(register_of(c("2026-001", "2026-010"))), "CC-REG-002"), "ok")
jump <- run(register_of(c("2026-001", "2026-011")))
expect_equal(outcome_of(jump, "CC-REG-002"), "error")
expect_true(grepl("2026-011 (after 2026-001)", detail_of(jump, "CC-REG-002"), fixed = TRUE))

# A typo in the number, the first of a year starting high, a future year and a
# malformed identifier all fail; the order of the rows does not matter.
expect_equal(outcome_of(run(register_of(c("2026-002", "2026-230", "2026-001"))), "CC-REG-002"), "error")
expect_equal(outcome_of(run(register_of("2024-111")), "CC-REG-002"), "error")
future <- run(register_of(paste0(as.integer(format(Sys.Date(), "%Y")) + 1, "-001")))
expect_true(grepl("future year", detail_of(future, "CC-REG-002")))
malformed <- run(register_of(c("2026-001", "2026-2")))
expect_true(grepl("not YYYY-NNN: 2026-2", detail_of(malformed, "CC-REG-002"), fixed = TRUE))

# --- CC-REG-004 type-known ---

bad_type <- run(register_of(c("2026-001", "2026-002"), types = c("journal", "Journal")))
expect_equal(outcome_of(bad_type, "CC-REG-004"), "error")
expect_true(grepl("2026-002 'Journal'", detail_of(bad_type, "CC-REG-004"), fixed = TRUE))

# --- CC-REG-005 venue-known, a warning ---

bad_venue <- run(register_of(c("2026-001", "2026-002"), venues = c("codecheck", "Nature")))
expect_equal(outcome_of(bad_venue, "CC-REG-005"), "warning")
expect_true(grepl("2026-002 'Nature'", detail_of(bad_venue, "CC-REG-005"), fixed = TRUE))
# No venues.csv, nothing to compare with.
no_venues <- validate_register_rules(good, venues_file = "does-not-exist.csv",
                                     stop_on_error = FALSE, quiet = TRUE)
expect_equal(outcome_of(no_venues, "CC-REG-005"), "skipped")

# --- CC-REG-006 issue-exists and CC-REG-007 issue-references-certificate ---

with_issues <- function(ids, issues) {
  register <- register_of(ids)
  register$Issue <- issues
  run(register)
}
ok_issues <- with_issues(c("2026-001", "2026-002"), c(1, 2))
expect_equal(outcome_of(ok_issues, "CC-REG-006"), "ok")
expect_equal(outcome_of(ok_issues, "CC-REG-007"), "ok")

# a row without an issue is fine, one with an issue that does not exist is not
missing_issue <- with_issues(c("2026-001", "2026-002"), c(NA, 99))
expect_equal(outcome_of(missing_issue, "CC-REG-006"), "warning")
expect_true(grepl("2026-002 (#99)", detail_of(missing_issue, "CC-REG-006"), fixed = TRUE))
expect_equal(outcome_of(missing_issue, "CC-REG-007"), "skipped")

# an issue whose title does not name the certificate
wrong_title <- with_issues(c("2026-001", "2026-002"), c(1, 3))
expect_equal(outcome_of(wrong_title, "CC-REG-006"), "ok")
expect_equal(outcome_of(wrong_title, "CC-REG-007"), "warning")
expect_true(grepl("2026-002 (#3 'a pull request')", detail_of(wrong_title, "CC-REG-007"),
                  fixed = TRUE))

# a group's issue names a range of identifiers
title_ids <- codecheck:::title_certificate_ids
expect_true("2025-012" %in% title_ids("AGILE Reproducibility Reviews 2025 (2025-008 - 2025-017)"))
expect_true("2026-010" %in% title_ids("AGILEGIS 2026 | 2026-004/2026-017"))
expect_false("2026-018" %in% title_ids("AGILEGIS 2026 | 2026-004/2026-017"))
expect_equal(title_ids("Baetzel | 2026-020"), "2026-020")
expect_equal(title_ids("Update licensing information"), character(0))
expect_equal(title_ids("2026-0012"), character(0))

# GitHub unreachable: both skip, and the issues are asked for only once
calls <- 0
unreachable <- validate_register_rules(
  transform(register_of("2026-001"), Issue = 1), venues_file = venues_csv,
  get_issues = function() { calls <<- calls + 1; stop("offline") },
  stop_on_error = FALSE, quiet = TRUE)
expect_equal(outcome_of(unreachable, "CC-REG-006"), "skipped")
expect_equal(outcome_of(unreachable, "CC-REG-007"), "skipped")
expect_equal(calls, 1)

# --- stopping, strict and reading from a file ---

expect_error(validate_register_rules(register_of("2026-042"), venues_file = venues_csv,
                                     quiet = TRUE),
             pattern = "CC-REG-002")
# A warning does not stop, unless strict makes it an error.
expect_silent(validate_register_rules(bad_venue_register <- register_of("2026-001", venues = "Nature"),
                                      venues_file = venues_csv, quiet = TRUE))
expect_error(validate_register_rules(bad_venue_register, venues_file = venues_csv,
                                     strict = TRUE, quiet = TRUE),
             pattern = "CC-REG-005")

register_csv <- tempfile(fileext = ".csv")
writeLines(c("Certificate,Repository,Type,Venue,Issue",
             "2026-001,github::codecheckers/a,community,codecheck,1",
             "#2026-002,github::codecheckers/b,community,codecheck,2",
             "2026-003,github::codecheckers/c,community,codecheck,NA"),
           register_csv)
from_file <- validate_register_rules(register_csv, venues_file = venues_csv, get_issues = fake_issues,
                                     stop_on_error = FALSE, quiet = TRUE)
expect_true(all(from_file$outcome == "ok"),
            info = "a commented-out row is not part of the register")

# The report names the file and every rule.
report <- capture.output(validate_register_rules(register_csv, venues_file = venues_csv,
                                                 get_issues = fake_issues),
                         type = "message")
expect_true(any(grepl(register_csv, report, fixed = TRUE)))
expect_true(any(grepl("CC-REG-004 type-known", report, fixed = TRUE)))

# --- the real register, when it is checked out next to this package ---

real_register <- file.path("..", "..", "..", "register", "register.csv")
if (file.exists(real_register)) {
  real <- validate_register_rules(real_register,
                                  venues_file = file.path(dirname(real_register), "venues.csv"),
                                  get_issues = function() stop("not asking GitHub in tests"),
                                  stop_on_error = FALSE, quiet = TRUE)
  real <- real[!real$id %in% c("CC-REG-006", "CC-REG-007"), ]
  expect_true(all(real$outcome == "ok"),
              info = paste("the published register passes:", paste(real$detail, collapse = "; ")))
}

unlink(c(venues_csv, register_csv))
