# Tests for validating a codecheck.yml against the rules of one specification
# version, see R/rules_validate.R.

library(codecheck)

fixture <- "yaml/codecheck.yml"

# --- which specification version applies ---

expect_equal(codecheck_spec_version(
  list(version = "https://codecheck.org.uk/spec/config/1.0/")), "1.0")
expect_equal(codecheck_spec_version(
  list(version = "https://codecheck.org.uk/spec/config/2.0")), "2.0")
# The fixture declares 1.0 without a trailing slash.
expect_equal(codecheck_spec_version(fixture), "1.0")
# No version node: the specification says to assume the newest one.
expect_equal(codecheck_spec_version(list()), codecheck_spec_versions()[1])
# A version that names no published specification does not silently become one.
expect_equal(codecheck_spec_version(list(version = "https://example.com/spec")),
             codecheck_spec_versions()[1])
expect_true(is.na(codecheck:::spec_version_from_url("https://example.com/spec")))

# --- the same file, two specification versions ---

# Network-dependent rules are not exercised here; they skip when offline, which
# would make the counts depend on the machine. CC-CFG-012 is the only one.
without_report_check <- function(results) {
  results[results$id != "CC-CFG-012", ]
}

as_1_0 <- without_report_check(
  validate_codecheck_yml_rules(fixture, spec_version = "1.0",
                               stop_on_error = FALSE, quiet = TRUE))
as_2_0 <- without_report_check(
  validate_codecheck_yml_rules(fixture, spec_version = "2.0",
                               stop_on_error = FALSE, quiet = TRUE))

# 2.0 has rules 1.0 does not, and never the other way round.
expect_true(all(as_1_0$id %in% as_2_0$id))
expect_equal(sort(setdiff(as_2_0$id, as_1_0$id)),
             c("CC-CFG-029", "CC-CFG-030", "CC-MET-009"))

# Two of the fixture's authors have no ORCID: advice under 1.0, a failure under
# 2.0. Same check function, different severity, which is the point.
expect_equal(as_1_0$outcome[as_1_0$id == "CC-CFG-020"], "warning")
expect_equal(as_2_0$outcome[as_2_0$id == "CC-CFG-020"], "error")

# The same for a missing summary, which 2.0 made a MUST.
no_summary <- yaml::read_yaml(fixture)
no_summary$summary <- NULL
expect_equal(validate_codecheck_yml_rules(no_summary, spec_version = "1.0",
                                          stop_on_error = FALSE,
                                          quiet = TRUE)$outcome[
  codecheck_rules("1.0")$id[codecheck_rules("1.0")$status == "active"] ==
    "CC-CFG-024"], "info")
expect_equal(validate_codecheck_yml_rules(no_summary, spec_version = "2.0",
                                          stop_on_error = FALSE,
                                          quiet = TRUE)$outcome[
  codecheck_rules("2.0")$id[codecheck_rules("2.0")$status == "active"] ==
    "CC-CFG-024"], "error")

# The certificate is present in the fixture, so the rule passes under both.
expect_equal(as_1_0$outcome[as_1_0$id == "CC-CFG-025"], "ok")
expect_equal(as_2_0$outcome[as_2_0$id == "CC-CFG-025"], "ok")

# --- individual outcomes on a known file ---

# A direct PDF link that is not archived: a warning, and the archived-snapshot
# rule reports the same reference as advice.
expect_equal(as_1_0$outcome[as_1_0$id == "CC-CFG-022"], "warning")
expect_equal(as_1_0$outcome[as_1_0$id == "CC-CFG-031"], "info")
# The report DOI is a FIXME placeholder.
expect_equal(as_1_0$outcome[as_1_0$id == "CC-CFG-013"], "error")
expect_equal(as_1_0$outcome[as_1_0$id == "CC-CFG-023"], "error")
# Manifest, codechecker and paper metadata are all there.
expect_equal(as_1_0$outcome[as_1_0$id == "CC-CFG-004"], "ok")
expect_equal(as_1_0$outcome[as_1_0$id == "CC-CFG-008"], "ok")
expect_equal(as_1_0$outcome[as_1_0$id == "CC-CFG-016"], "ok")

# --- strict escalates warnings, and only warnings ---

strict_1_0 <- without_report_check(
  validate_codecheck_yml_rules(fixture, spec_version = "1.0", strict = TRUE,
                               stop_on_error = FALSE, quiet = TRUE))
expect_equal(strict_1_0$outcome[strict_1_0$id == "CC-CFG-022"], "error")
# Advice stays advice.
expect_equal(strict_1_0$outcome[strict_1_0$id == "CC-CFG-031"], "info")
# Nothing that passed becomes a failure.
expect_equal(strict_1_0$id[strict_1_0$outcome == "ok"],
             as_1_0$id[as_1_0$outcome == "ok"])

# --- a configuration in memory ---

complete <- list(
  version = "https://codecheck.org.uk/spec/config/2.0/",
  manifest = list(list(file = "figure1.png", comment = "Figure 1")),
  codechecker = list(list(name = "J. Carberry", ORCID = "0000-0002-1825-0097")),
  report = "https://doi.org/10.5281/zenodo.123456",
  paper = list(
    title = "A good paper",
    authors = list(list(name = "J. Carberry", ORCID = "0000-0002-1825-0097")),
    reference = "https://doi.org/10.5555/preprint.1"
  ),
  summary = "All outputs reproduced.",
  certificate = "2026-001"
)
results <- validate_codecheck_yml_rules(complete, stop_on_error = FALSE,
                                        quiet = TRUE)
expect_equal(codecheck_spec_version(complete), "2.0")
expect_true(!any(results$outcome %in% c("error", "warning")),
            info = "a complete 2.0 configuration has nothing to report")
# Checks about the file on disk skip when there is no file.
expect_equal(results$outcome[results$id == "CC-CFG-002"], "skipped")
expect_equal(results$outcome[results$id == "CC-CFG-003"], "skipped")

# A missing certificate is an error under 2.0 and advice under 1.0.
incomplete <- complete
incomplete$certificate <- NULL
expect_equal(
  validate_codecheck_yml_rules(incomplete, spec_version = "2.0",
                               stop_on_error = FALSE,
                               quiet = TRUE)$outcome[
                                 codecheck_rules("2.0")$id[
                                   codecheck_rules("2.0")$status == "active"] ==
                                   "CC-CFG-025"],
  "error")

# --- stopping ---

expect_error(validate_codecheck_yml_rules(fixture, spec_version = "2.0",
                                          quiet = TRUE),
             pattern = "rule\\(s\\) failed")
# Nothing to fail, nothing to stop for.
expect_silent(validate_codecheck_yml_rules(complete, quiet = TRUE))

# --- reporting ---

# The report goes to the message stream, so that capturing results does not
# capture the human-readable report with them.
report <- capture.output(
  validate_codecheck_yml_rules(fixture, spec_version = "1.0",
                               stop_on_error = FALSE),
  type = "message")
expect_true(any(grepl("CC-CFG-022 reference-not-bare-pdf", report)),
            info = "every rule is named in the report")
expect_true(any(grepl("passed", report)),
            info = "the report ends with a summary")

# --- a file that is not there, and one that is not YAML ---

expect_error(validate_codecheck_yml_rules("does-not-exist.yml"),
             pattern = "No such codecheck.yml")
expect_error(validate_codecheck_yml_rules("yaml/invalid_utf8/codecheck.yml"),
             pattern = "CC-CFG-001|not valid YAML|invalid")

# --- the bundle around the file ---

# These rules are about the directory the codecheck.yml sits in, so they need a
# bundle on disk rather than a fixture in memory.
bundle <- file.path(tempdir(), "bundle")
dir.create(file.path(bundle, "codecheck"), recursive = TRUE,
           showWarnings = FALSE)
writeLines("LICENSE", file.path(bundle, "LICENSE"))
file.create(file.path(bundle, "codecheck", "codecheck.pdf"))
yaml::write_yaml(complete, file.path(bundle, "codecheck.yml"))

in_bundle <- validate_codecheck_yml_rules(file.path(bundle, "codecheck.yml"),
                                          stop_on_error = FALSE, quiet = TRUE)
expect_equal(in_bundle$outcome[in_bundle$id == "CC-BUN-002"], "ok")
expect_equal(in_bundle$outcome[in_bundle$id == "CC-BUN-003"], "ok")
expect_equal(in_bundle$outcome[in_bundle$id == "CC-BUN-005"], "ok")

# The same file in a bare directory: the bundle rules report, the rest does not
# change.
bare <- file.path(tempdir(), "bare")
dir.create(bare, showWarnings = FALSE)
yaml::write_yaml(complete, file.path(bare, "codecheck.yml"))
in_bare <- validate_codecheck_yml_rules(file.path(bare, "codecheck.yml"),
                                        stop_on_error = FALSE, quiet = TRUE)
expect_equal(in_bare$outcome[in_bare$id == "CC-BUN-002"], "warning")
expect_equal(in_bare$outcome[in_bare$id == "CC-BUN-005"], "warning")
# No codecheck/ directory to look in, so the report file cannot be judged.
expect_equal(in_bare$outcome[in_bare$id == "CC-BUN-003"], "skipped")

# A configuration in memory has no bundle at all, and skips rather than fails.
no_bundle <- validate_codecheck_yml_rules(complete, stop_on_error = FALSE,
                                          quiet = TRUE)
expect_equal(no_bundle$outcome[no_bundle$id == "CC-BUN-002"], "skipped")
expect_equal(no_bundle$outcome[no_bundle$id == "CC-BUN-005"], "skipped")

unlink(c(bundle, bare), recursive = TRUE)
