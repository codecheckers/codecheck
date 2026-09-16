# Driver for the per-rule check functions in R/rules_checks.R.
#
# The rules to run are not written down here: they are read from the rule file
# of the specification version the codecheck.yml declares. A new rule in the
# register is run as soon as a check function is registered for it, and a rule
# that only exists in 2.0 is never run against a 1.0 file.

#' Which specification version a URL names
#'
#' @param version Value of the `version` node, e.g.
#'   `https://codecheck.org.uk/spec/config/1.0/`.
#' @return The version as a string, or `NA` if it names none.
#' @keywords internal
#' @noRd
spec_version_from_url <- function(version) {
  if (!has_value(version)) {
    return(NA_character_)
  }
  known <- codecheck_spec_versions()
  # Tolerate a trailing slash, http, and the /spec/config/<version> form used
  # in the specification's own examples.
  matched <- vapply(known, function(candidate) {
    grepl(paste0("spec/config/", candidate, "/?$"), trimws(version))
  }, logical(1))
  if (any(matched)) known[matched][1] else NA_character_
}

##' The specification version a `codecheck.yml` is validated against
##'
##' Read from the `version` node. A file without one is validated against the
##' newest specification this package knows, which is what the specification
##' asks tools to assume.
##'
##' @param configuration A parsed `codecheck.yml` as a list, or a path to one.
##' @return The version as a string, e.g. `"2.0"`.
##' @examples
##' codecheck_spec_version(list(version = "https://codecheck.org.uk/spec/config/1.0/"))
##' codecheck_spec_version(list())
##' @seealso [validate_codecheck_yml_rules()], [codecheck_rules()]
##' @export
codecheck_spec_version <- function(configuration) {
  if (is.character(configuration) && file.exists(configuration)) {
    configuration <- yaml::read_yaml(configuration)
  }
  detected <- spec_version_from_url(configuration$version)
  if (is.na(detected)) codecheck_spec_versions()[1] else detected
}

##' Validate a `codecheck.yml` against the CODECHECK rules
##'
##' Runs the rules of one version of the configuration file specification, see
##' [codecheck_rules()]. Which rules run follows from that version's rule file,
##' so a rule added to a newer specification is not applied to a file that
##' declares an older one.
##'
##' Each rule has one check function, shared by every version that has the rule.
##' What differs between versions is the `severity` in the rule file, not the
##' check: a `MUST` in 2.0 that was a `SHOULD` in 1.0 is the same check reported
##' more loudly.
##'
##' A check that cannot reach a verdict, because a server is unreachable or the
##' file is not on disk, is reported as skipped. "Could not check" never counts
##' as a failed check.
##'
##' @param configuration A parsed `codecheck.yml` as a list, or a path to one.
##' @param spec_version Specification version to validate against. Defaults to
##'   the version the file declares, see [codecheck_spec_version()].
##' @param rules Identifiers of the rules to run, e.g.
##'   `c("CC-MET-002", "CC-MET-003")`. The default, `NULL`, runs every active
##'   rule of the specification version. Rules left out are not reported.
##' @param strict Escalate warnings to errors. It never works the other way:
##'   an error stays an error.
##' @param stop_on_error Stop with an error when any rule failed at severity
##'   `error`. Set to `FALSE` to get the results back for reporting.
##' @param quiet Do not print the per-rule report.
##' @return Invisibly, a data frame with one row per rule and the columns `id`,
##'   `name`, `severity`, `outcome`, `detail` and the rule's `description`. An outcome is `"ok"`,
##'   `"error"`, `"warning"` or `"info"` for a rule that was checked,
##'   `"skipped"` when no verdict was possible, `"elsewhere"` for a rule one of
##'   the older validation functions enforces, and `"unchecked"` for one
##'   nothing checks yet.
##' @examples
##' \dontrun{
##' validate_codecheck_yml_rules("codecheck.yml")
##' validate_codecheck_yml_rules("codecheck.yml", spec_version = "1.0")
##' }
##' @seealso [codecheck_rules()], [codecheck_spec_version()]
##' @export
validate_codecheck_yml_rules <- function(configuration,
                                         spec_version = NULL,
                                         rules = NULL,
                                         strict = FALSE,
                                         stop_on_error = TRUE,
                                         quiet = FALSE) {
  context <- rules_context(configuration)
  if (is.null(spec_version)) {
    spec_version <- codecheck_spec_version(context$yml)
  }
  spec_version <- match.arg(spec_version, codecheck_spec_versions())
  context$spec_version <- spec_version

  results <- run_rules(context, spec_version, rules, strict)

  if (!quiet) {
    report_rule_results(results, context, spec_version, strict)
  }

  failed <- results$outcome == "error"
  if (stop_on_error && any(failed)) {
    stop(rules_failure_message(results[failed, ], context$label), call. = FALSE)
  }

  invisible(results)
}

#' Run the active rules of one specification version against a context
#'
#' @param context See `rules_context()`.
#' @param rules Identifiers to run, or `NULL` for all active rules.
#' @param checks The table of check functions to look rules up in.
#' @return The results data frame, see [validate_codecheck_yml_rules()].
#' @keywords internal
#' @noRd
run_rules <- function(context, spec_version, rules = NULL, strict = FALSE,
                      checks = rule_checks()) {
  catalogue <- codecheck_rules(spec_version)
  catalogue <- catalogue[catalogue$status == "active", ]
  if (!is.null(rules)) {
    catalogue <- catalogue[catalogue$id %in% rules, ]
  }
  results <- lapply(seq_len(nrow(catalogue)), function(i) {
    rule <- catalogue[i, ]
    # A rule with no check function is reported as unchecked, not skipped over.
    check_name <- if (rule$id %in% names(checks)) checks[[rule$id]] else NULL
    run_rule_check(rule, check_name, context, strict)
  })
  if (length(results) == 0) {
    return(rule_result_row(catalogue, character(0), character(0)))
  }
  do.call(rbind, results)
}

##' Validate the register against the CODECHECK rules
##'
##' Runs the rules about the register as a whole, rather than about one
##' `codecheck.yml`: that certificate identifiers continue their year's sequence
##' (`CC-REG-002`), that every `Type` is one of the four venue types
##' (`CC-REG-004`), and that every `Venue` is listed in `venues.csv`
##' (`CC-REG-005`). Severities come from the rule file, as for
##' [validate_codecheck_yml_rules()]. [register_check()] runs this first.
##'
##' @param register The register as a data frame, or a path to `register.csv`.
##' @param venues_file Path to `venues.csv`. When it does not exist, `CC-REG-005`
##'   is skipped.
##' @param spec_version Specification version whose rule file gives the
##'   severities, defaulting to the newest.
##' @inheritParams validate_codecheck_yml_rules
##' @return Invisibly, a data frame with one row per rule, see
##'   [validate_codecheck_yml_rules()].
##' @examples
##' \dontrun{
##' validate_register_rules("register.csv", venues_file = "venues.csv")
##' }
##' @seealso [register_check()], [codecheck_rules()]
##' @export
validate_register_rules <- function(register = "register.csv",
                                    venues_file = "venues.csv",
                                    spec_version = codecheck_spec_versions()[1],
                                    strict = FALSE,
                                    stop_on_error = TRUE,
                                    quiet = FALSE) {
  spec_version <- match.arg(spec_version, codecheck_spec_versions())
  context <- register_rules_context(register, venues_file)
  checks <- register_rule_checks()

  results <- run_rules(context, spec_version, names(checks), strict,
                       checks = checks)

  if (!quiet) {
    report_rule_results(results, context, spec_version, strict)
  }

  failed <- results$outcome == "error"
  if (stop_on_error && any(failed)) {
    stop(rules_failure_message(results[failed, ], context$label), call. = FALSE)
  }

  invisible(results)
}

#' Everything the register-wide checks need
#'
#' @keywords internal
#' @noRd
register_rules_context <- function(register, venues_file = "venues.csv") {
  label <- "the register"
  if (is.character(register) && length(register) == 1) {
    if (!file.exists(register)) {
      stop("No such register: ", register)
    }
    label <- register
    register <- utils::read.csv(register, as.is = TRUE, comment.char = "#")
  }
  venues <- if (!is.null(venues_file) && file.exists(venues_file)) {
    utils::read.csv(venues_file, as.is = TRUE)$name
  }
  list(register = register, venues = venues, today = Sys.Date(), label = label)
}

#' What to say when rules failed
#'
#' One failed rule is reported in full, with the rule's own words. Several are
#' listed by identifier and finding only: the descriptions belong to the report,
#' not to a list that has to stay readable.
#'
#' @param failed The failing rows of the results.
#' @param label What was validated.
#' @keywords internal
#' @noRd
rules_failure_message <- function(failed, label) {
  if (nrow(failed) == 1) {
    return(paste0("rule failed for ", label, ": ", rule_result_text(failed)))
  }
  paste0(nrow(failed), " rules failed for ", label, ":\n",
         paste0("  ", failed$id,
                ifelse(is.na(failed$detail), "", paste0(": ", failed$detail)),
                collapse = "\n"))
}

#' Everything the check functions need about the file under validation
#'
#' `lookups` is an environment, so that the answers of external services are
#' shared by every check of one validation run: the Crossref record and each
#' ORCID record are requested once per file, however many rules read them. See
#' `context_crossref()` and `context_orcid()`.
#'
#' @keywords internal
#' @noRd
rules_context <- function(configuration) {
  if (is.character(configuration) && length(configuration) == 1) {
    if (!file.exists(configuration)) {
      stop("No such codecheck.yml: ", configuration)
    }
    # The encoding check needs the raw bytes and must happen before the YAML
    # parser sees them: an invalid byte inside a quoted scalar makes the parser
    # fail with a scanner error rather than saying the file is not UTF-8.
    raw_lines <- readLines(configuration, warn = FALSE, encoding = "bytes")
    # Sanitise for the checks that work on the text: an invalid byte otherwise
    # makes every string operation downstream fail, and the encoding itself is
    # already reported by CC-CFG-001.
    lines <- iconv(raw_lines, from = "UTF-8", to = "UTF-8", sub = "?")
    # A file that does not parse is a failure of CC-CFG-001, not an exception:
    # the driver reports it like any other rule, and the checks that need the
    # parsed content skip for want of it.
    parse_error <- NULL
    yml <- tryCatch(yaml::read_yaml(configuration), error = function(e) {
      parse_error <<- conditionMessage(e)
      list()
    })
    return(list(yml = yml, path = configuration, lines = lines,
                raw_lines = raw_lines, parse_error = parse_error,
                bundle_dir = dirname(configuration), label = configuration,
                lookups = new.env(parent = emptyenv())))
  }
  if (is.list(configuration)) {
    # A configuration in memory has no file to inspect, so the checks that are
    # about the file on disk skip rather than fail.
    return(list(yml = configuration, path = NULL, lines = NULL,
                raw_lines = NULL, bundle_dir = NULL,
                label = "the given configuration",
                lookups = new.env(parent = emptyenv())))
  }
  stop("Could not load codecheck configuration from input '", configuration, "'")
}

#' Run one rule's check and turn its outcome into a reportable severity
#'
#' @keywords internal
#' @noRd
run_rule_check <- function(rule, check_name, context, strict) {
  if (is.null(check_name)) {
    # Several rules are enforced by the older validation functions, which need
    # more than a codecheck.yml to run. Saying so is more use than calling them
    # unchecked.
    implementations <- rule_implementations()
    if (rule$id %in% names(implementations)) {
      elsewhere <- implementations[[rule$id]]
      return(rule_result_row(rule, "elsewhere",
                             paste0("checked by ", elsewhere, "()")))
    }
    return(rule_result_row(rule, "unchecked",
                           "no check function for this rule yet"))
  }

  check <- get(check_name, envir = asNamespace("codecheck"), mode = "function")
  result <- check(context)

  outcome <- switch(result$status,
    pass = "ok",
    skip = "skipped",
    # A failed check is reported at the rule's own severity, which strict only
    # ever raises.
    fail = if (strict && rule$severity == "warning") "error" else rule$severity
  )
  rule_result_row(rule, outcome, result$detail)
}

#' @keywords internal
#' @noRd
rule_result_row <- function(rule, outcome, detail) {
  data.frame(id = rule$id, name = rule$name, severity = rule$severity,
             outcome = outcome,
             detail = if (is.null(detail)) NA_character_ else detail,
             description = rule$description,
             stringsAsFactors = FALSE)
}

#' One reported rule, in words
#'
#' A single rule is always reported with what the rule says, because an
#' identifier on its own tells a reader nothing. Where several identifiers are
#' listed or counted the descriptions would bury the list, so those carry the
#' identifier alone.
#'
#' @param result One row of the results.
#' @param with_name Include the rule's short handle.
#' @keywords internal
#' @noRd
rule_result_text <- function(result, with_name = TRUE) {
  paste0(result$id,
         if (with_name) paste0(" ", result$name) else "",
         if (is.na(result$detail)) "" else paste0(": ", result$detail),
         " (", result$description, ")")
}

#' Print the per-rule report
#'
#' One line per rule, led by a symbol for the outcome, so that a long report can
#' be skimmed for the lines that need attention.
#'
#' @keywords internal
#' @noRd
report_rule_results <- function(results, context, spec_version, strict) {
  cli::cli_h2("CODECHECK rules {spec_version}: {context$label}")

  for (i in seq_len(nrow(results))) {
    result <- results[i, ]
    # A rule that has something to report says what it is about; one that
    # passed, skipped or is checked elsewhere stays on one short line.
    line <- if (result$outcome %in% c("error", "warning", "info")) {
      rule_result_text(result)
    } else {
      paste0(result$id, " ", result$name,
             if (is.na(result$detail)) "" else paste0(": ", result$detail))
    }
    # cli_verbatim() rather than cli_text(), because a detail can contain
    # braces from the file under validation, which glue would try to
    # interpret. It keeps the whole report on one stream.
    cli::cli_verbatim(paste0(rule_outcome_symbol(result$outcome), " ", line))
  }

  counts <- table(factor(results$outcome,
                         levels = c("ok", "error", "warning", "info",
                                    "skipped", "elsewhere", "unchecked")))
  cli::cli_h3("{counts[['ok']]} passed, {counts[['error']]} failed, {counts[['warning']]} warning{?s}, {counts[['info']]} note{?s}, {counts[['skipped']]} skipped, {counts[['elsewhere']]} checked elsewhere, {counts[['unchecked']]} not checked")
  if (strict) {
    cli::cli_alert_info("strict: warnings are reported as errors")
  }
}

#' Symbol for one rule outcome
#'
#' @keywords internal
#' @noRd
rule_outcome_symbol <- function(outcome) {
  switch(outcome,
    ok = cli::col_green(cli::symbol$tick),
    error = cli::col_red(cli::symbol$cross),
    warning = cli::col_yellow(cli::symbol$warning),
    info = cli::col_blue(cli::symbol$info),
    skipped = cli::col_grey(cli::symbol$ellipsis),
    elsewhere = cli::col_grey(cli::symbol$arrow_right),
    unchecked = cli::col_grey(cli::symbol$line)
  )
}
