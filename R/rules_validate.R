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
##' @param strict Escalate warnings to errors. It never works the other way:
##'   an error stays an error.
##' @param stop_on_error Stop with an error when any rule failed at severity
##'   `error`. Set to `FALSE` to get the results back for reporting.
##' @param quiet Do not print the per-rule report.
##' @return Invisibly, a data frame with one row per rule and the columns `id`,
##'   `name`, `severity`, `outcome` and `detail`. An outcome is `"ok"`,
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
                                         strict = FALSE,
                                         stop_on_error = TRUE,
                                         quiet = FALSE) {
  context <- rules_context(configuration)
  if (is.null(spec_version)) {
    spec_version <- codecheck_spec_version(context$yml)
  }
  spec_version <- match.arg(spec_version, codecheck_spec_versions())
  context$spec_version <- spec_version

  rules <- codecheck_rules(spec_version)
  rules <- rules[rules$status == "active", ]
  checks <- rule_checks()

  results <- do.call(rbind, lapply(seq_len(nrow(rules)), function(i) {
    rule <- rules[i, ]
    # A rule with no check function is reported as unchecked, not skipped over.
    check_name <- if (rule$id %in% names(checks)) checks[[rule$id]] else NULL
    run_rule_check(rule, check_name, context, strict)
  }))

  if (!quiet) {
    report_rule_results(results, context, spec_version, strict)
  }

  failed <- results$outcome == "error"
  if (stop_on_error && any(failed)) {
    stop(sum(failed), " rule(s) failed for ", context$label, ":\n",
         paste0("  ", results$id[failed], " ", results$name[failed], ": ",
                results$detail[failed], collapse = "\n"),
         call. = FALSE)
  }

  invisible(results)
}

#' Everything the check functions need about the file under validation
#'
#' @keywords internal
#' @noRd
rules_context <- function(configuration) {
  if (is.character(configuration) && length(configuration) == 1) {
    if (!file.exists(configuration)) {
      stop("No such codecheck.yml: ", configuration)
    }
    lines <- readLines(configuration, warn = FALSE)
    yml <- tryCatch(yaml::read_yaml(configuration), error = function(e) {
      stop("CC-CFG-001 yaml-parses: ", configuration, " is not valid YAML: ",
           conditionMessage(e), call. = FALSE)
    })
    return(list(yml = yml, path = configuration, lines = lines,
                label = configuration))
  }
  if (is.list(configuration)) {
    # A configuration in memory has no file to inspect, so the checks that are
    # about the file on disk skip rather than fail.
    return(list(yml = configuration, path = NULL, lines = NULL,
                label = "the given configuration"))
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
             stringsAsFactors = FALSE)
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
    detail <- if (is.na(result$detail)) "" else paste0(" - ", result$detail)
    # cli_verbatim() rather than cli_text(), because a detail can contain
    # braces from the file under validation, which glue would try to
    # interpret. It keeps the whole report on one stream.
    cli::cli_verbatim(paste0(rule_outcome_symbol(result$outcome), " ",
                             result$id, " ", result$name, detail))
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
