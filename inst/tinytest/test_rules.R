# Tests for the bundled CODECHECK validation rules, see R/rules.R. The point of
# these is that a rule added to the register's rules-x.y.yml cannot be ignored:
# it has to be implemented, or deliberately listed as not implemented.

library(codecheck)

spec_versions <- codecheck_spec_versions()
expect_equal(spec_versions, c("2.0", "1.0"))

# --- the files parse and carry what the rest of the package expects ---

for (spec_version in spec_versions) {
  rules <- codecheck_rules(spec_version)

  expect_true(nrow(rules) > 0,
              info = paste("rules for", spec_version, "are not empty"))
  expect_equal(colnames(rules),
               c("id", "name", "area", "severity", "status", "reference",
                 "description"))
  expect_true(!any(duplicated(rules$id)),
              info = paste("rule identifiers unique in", spec_version))
  expect_true(all(grepl("^CC-(CFG|MET|BUN|REP|REG)-[0-9]{3}$", rules$id)),
              info = paste("rule identifiers well-formed in", spec_version))
  expect_true(all(rules$severity %in% c("error", "warning", "info")),
              info = paste("severities known in", spec_version))
  expect_true(all(rules$status %in% c("active", "deprecated")),
              info = paste("statuses known in", spec_version))
  expect_true(all(nchar(rules$description) > 0),
              info = paste("every rule described in", spec_version))
}

# Identifiers are permanent across specification versions: a rule that exists in
# both files is the same rule, so its name must not have been reused.
rules_2_0 <- codecheck_rules("2.0")
rules_1_0 <- codecheck_rules("1.0")
shared <- intersect(rules_2_0$id, rules_1_0$id)
expect_equal(rules_2_0$name[match(shared, rules_2_0$id)],
             rules_1_0$name[match(shared, rules_1_0$id)])

# 2.0 only ever tightens 1.0, never relaxes it, so no severity goes the other
# way. This is what makes a 2.0-compliant codecheck.yml valid under 1.0.
rank <- c(info = 1, warning = 2, error = 3)
expect_true(all(rank[rules_2_0$severity[match(shared, rules_2_0$id)]] >=
                  rank[rules_1_0$severity[match(shared, rules_1_0$id)]]),
            info = "2.0 does not lower the severity of any 1.0 rule")

# --- accessors ---

expect_equal(codecheck_rule("CC-CFG-016")$name, "paper-present")
expect_equal(rule_severity("CC-CFG-016"), "error")
expect_equal(rule_severity("CC-CFG-016", spec_version = "1.0"), "warning")
expect_error(codecheck_rule("CC-CFG-999"), pattern = "No rule CC-CFG-999")

# --- every rule is accounted for ---

# Register-wide checks are a separate table, run by validate_register_rules(),
# but they count the same.
checks <- c(codecheck:::rule_checks(), codecheck:::register_rule_checks())
implementations <- codecheck:::rule_implementations()
not_implemented <- codecheck:::rules_not_implemented()
covered <- c(names(checks), names(implementations))
all_ids <- unique(c(rules_2_0$id, rules_1_0$id))

expect_true(length(intersect(covered, not_implemented)) == 0,
            info = "no rule is both implemented and listed as not implemented")
expect_true(!any(duplicated(covered)),
            info = "no rule is checked in two places")

# A rule in the register that is neither implemented nor listed fails here. The
# fix is to implement it, or to add it to rules_not_implemented() with a comment
# saying why not.
expect_equal(sort(setdiff(all_ids, c(covered, not_implemented))),
             character(0))

# And the reverse: a rule dropped from the register, or an identifier typed
# wrongly in either list, fails here.
expect_equal(sort(setdiff(c(covered, not_implemented), all_ids)),
             character(0))

# Every function claimed as a check or an implementation exists.
for (id in names(checks)) {
  expect_true(exists(checks[[id]], envir = asNamespace("codecheck"),
                     mode = "function"),
              info = paste(id, "is checked by", checks[[id]]))
}
for (id in names(implementations)) {
  expect_true(exists(implementations[[id]], envir = asNamespace("codecheck"),
                     mode = "function"),
              info = paste(id, "is implemented by", implementations[[id]]))
}

# A rule whose reference names an R function must name one that exists, so the
# register's rules and this package cannot drift apart unnoticed.
for (spec_version in spec_versions) {
  rules <- codecheck_rules(spec_version)
  referenced <- rules$reference[startsWith(rules$reference, "R:")]
  for (reference in referenced) {
    # A reference can name alternatives, e.g. "R:get_codecheck_yml_github|gitlab"
    functions <- strsplit(sub("^R:", "", reference), "|", fixed = TRUE)[[1]]
    expect_true(any(vapply(functions, exists, logical(1),
                           envir = asNamespace("codecheck"),
                           mode = "function")),
                info = paste(reference, "names a function of this package"))
  }
}

# --- provenance ---

# Which register commit the bundled files came from, so that a rule that
# changed upstream can be told apart from one that never did.
provenance <- codecheck_rules_provenance()

expect_equal(sort(provenance$file),
             c("rules-1.0.yml", "rules-2.0.yml"))
expect_equal(sort(provenance$spec_version), sort(spec_versions))

for (i in seq_len(nrow(provenance))) {
  entry <- provenance[i, ]
  bundled <- system.file("extdata", "rules", entry$file, package = "codecheck")

  expect_true(nzchar(bundled),
              info = paste(entry$file, "is bundled"))
  # The recorded checksum is what ties the provenance to the file: an edit to a
  # bundled rule file without a refresh fails here.
  expect_equal(unname(tools::md5sum(bundled)), entry$md5,
               info = paste(entry$file, "matches its recorded checksum"))
  expect_equal(nrow(codecheck_rules(entry$spec_version)), entry$rules,
               info = paste(entry$file, "holds the recorded number of rules"))
  expect_true(is.na(entry$commit) || grepl("^[0-9a-f]{40}$", entry$commit),
              info = paste(entry$file, "records a register commit"))
  expect_true(!is.na(parsedate::parse_date(entry$retrieved)),
              info = paste(entry$file, "records when it was retrieved"))
}
