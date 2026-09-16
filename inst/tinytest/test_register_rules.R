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

run <- function(register, ...) {
  validate_register_rules(register, venues_file = venues_csv,
                          stop_on_error = FALSE, quiet = TRUE, ...)
}
outcome_of <- function(results, id) results$outcome[results$id == id]
detail_of <- function(results, id) results$detail[results$id == id]

# --- a good register passes every rule ---

good <- register_of(c("2025-001", "2025-002", "2026-001"))
results <- run(good)
expect_equal(sort(results$id), c("CC-REG-002", "CC-REG-004", "CC-REG-005"))
expect_true(all(results$outcome == "ok"))

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
             "2026-003,github::codecheckers/c,community,codecheck,3"),
           register_csv)
from_file <- validate_register_rules(register_csv, venues_file = venues_csv,
                                     stop_on_error = FALSE, quiet = TRUE)
expect_true(all(from_file$outcome == "ok"),
            info = "a commented-out row is not part of the register")

# The report names the file and every rule.
report <- capture.output(validate_register_rules(register_csv, venues_file = venues_csv),
                         type = "message")
expect_true(any(grepl(register_csv, report, fixed = TRUE)))
expect_true(any(grepl("CC-REG-004 type-known", report, fixed = TRUE)))

# --- the real register, when it is checked out next to this package ---

real_register <- file.path("..", "..", "..", "register", "register.csv")
if (file.exists(real_register)) {
  real <- validate_register_rules(real_register,
                                  venues_file = file.path(dirname(real_register), "venues.csv"),
                                  stop_on_error = FALSE, quiet = TRUE)
  expect_true(all(real$outcome == "ok"),
              info = paste("the published register passes:", paste(real$detail, collapse = "; ")))
}

unlink(c(venues_csv, register_csv))
