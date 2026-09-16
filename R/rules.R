#' Where the register publishes the authoritative rule files
#' @keywords internal
#' @noRd
RULES_REGISTER_RAW <- "https://raw.githubusercontent.com/codecheckers/register/master/"

##' The CODECHECK validation rules
##'
##' The checks that CODECHECK tooling applies to a `codecheck.yml` file are
##' maintained as a machine-readable list in the register repository, one file
##' per version of the configuration file specification, with the identifier
##' scheme documented in
##' <https://github.com/codecheckers/register/blob/master/RULES.md>. Both
##' implementations of the rules, this package and the Go bot, tag their checks
##' with the same identifiers so that the two can be compared mechanically.
##'
##' The rule files are bundled with this package and read from disk, so no
##' network access is needed. [update_codecheck_rules()] refreshes them from the
##' register, and [codecheck_rules_provenance()] reports which register commit
##' the bundled copies came from and when they were fetched.
##'
##' The `severity` of a rule is a property of the rule, derived from the RFC 2119
##' keyword the specification uses: `error` for a MUST, `warning` for a SHOULD,
##' `info` for a MAY or for advice. It is not affected by how a check is invoked:
##' the `strict` argument of the validation functions escalates warnings to
##' errors, it never lowers an error.
##'
##' @param spec_version Version of the configuration file specification, as a
##'   string, e.g. `"2.0"`. Defaults to the version the register's tooling
##'   currently targets.
##' @return `codecheck_rules()` returns a data frame with one row per rule and
##'   the columns `id`, `name`, `area`, `severity`, `status`, `reference` and
##'   `description`, ordered as in the file.
##' @examples
##' rules <- codecheck_rules()
##' head(rules[, c("id", "name", "severity")])
##' @seealso [codecheck_rule()], [rule_severity()],
##'   [codecheck_rules_provenance()]
##' @export
codecheck_rules <- function(spec_version = codecheck_spec_versions()[1]) {
  spec_version <- match.arg(spec_version, codecheck_spec_versions())

  cached <- .rules_cache[[spec_version]]
  if (!is.null(cached)) {
    return(cached)
  }

  parsed <- yaml::read_yaml(rules_file(spec_version))
  fields <- c("id", "name", "area", "severity", "status", "reference",
              "description")
  rules <- do.call(rbind, lapply(parsed$rules, function(rule) {
    missing_fields <- setdiff(fields, names(rule))
    if (length(missing_fields) > 0) {
      stop("Rule ", rule$id, " in rules-", spec_version,
           ".yml is missing: ", paste(missing_fields, collapse = ", "))
    }
    data.frame(rule[fields], stringsAsFactors = FALSE)
  }))

  .rules_cache[[spec_version]] <- rules
  rules
}

##' @describeIn codecheck_rules The specification versions this package carries
##'   rules for, newest first.
##' @export
codecheck_spec_versions <- function() {
  c("2.0", "1.0")
}

##' One CODECHECK validation rule
##'
##' @param id Rule identifier, e.g. `"CC-CFG-016"`.
##' @inheritParams codecheck_rules
##' @return A one-row data frame, see [codecheck_rules()]. Stops if the
##'   identifier is unknown, because a typo in a rule tag should not pass
##'   silently.
##' @examples
##' codecheck_rule("CC-CFG-016")
##' @seealso [codecheck_rules()]
##' @export
codecheck_rule <- function(id, spec_version = codecheck_spec_versions()[1]) {
  rules <- codecheck_rules(spec_version)
  row <- rules[rules$id == id, ]
  if (nrow(row) == 0) {
    stop("No rule ", id, " in the rules for specification ", spec_version)
  }
  row
}

##' The severity of a CODECHECK validation rule
##'
##' @inheritParams codecheck_rule
##' @return `"error"`, `"warning"` or `"info"`, see [codecheck_rules()] for what
##'   these mean.
##' @examples
##' rule_severity("CC-CFG-016")
##' rule_severity("CC-CFG-016", spec_version = "1.0")
##' @seealso [codecheck_rules()]
##' @export
rule_severity <- function(id, spec_version = codecheck_spec_versions()[1]) {
  codecheck_rule(id, spec_version)$severity
}

#' Path to a bundled rule file
#'
#' @inheritParams codecheck_rules
#' @return Path to the file in the installed package.
#' @keywords internal
#' @noRd
rules_file <- function(spec_version) {
  path <- system.file("extdata", "rules",
                      paste0("rules-", spec_version, ".yml"),
                      package = "codecheck")
  if (!nzchar(path)) {
    stop("No bundled rules for specification ", spec_version,
         "; run data-raw/update_rules.R")
  }
  path
}

#' Parsed rule files, one entry per specification version
#' @keywords internal
#' @noRd
.rules_cache <- new.env(parent = emptyenv())

#' Rules checked outside the per-rule framework
#'
#' Most rules have one check function each, see `rule_checks()`. These are the
#' rest: rules enforced by the older validation functions, which check a whole
#' `codecheck.yml` against an external service in one pass and cannot be split
#' per rule without re-issuing the same request several times.
#'
#' @return Named character vector, rule identifier to function name.
#' @keywords internal
#' @noRd
rule_implementations <- function() {
  c(
    "CC-MET-002" = "validate_codecheck_yml_orcid",
    "CC-MET-003" = "validate_codecheck_yml_orcid",
    "CC-MET-004" = "validate_codecheck_yml_crossref",
    "CC-MET-005" = "validate_codecheck_yml_crossref",
    "CC-MET-006" = "validate_codecheck_yml_crossref",
    "CC-MET-007" = "validate_codecheck_yml_crossref",
    "CC-MET-008" = "validate_codecheck_yml_crossref",
    "CC-BUN-001" = "copy_manifest_files",
    "CC-BUN-004" = "get_codecheck_yml",
    "CC-REP-001" = "validate_certificate_for_rendering",
    "CC-REP-002" = "validate_certificate_for_rendering",
    "CC-REP-003" = "zenodo_policy_check",
    "CC-REP-004" = "zenodo_policy_check",
    "CC-REP-005" = "zenodo_policy_check",
    "CC-REP-006" = "zenodo_policy_check",
    "CC-REG-001" = "register_check",
    "CC-REG-003" = "parse_repository_spec",
    "CC-REG-006" = "validate_certificate_github_issue",
    "CC-REG-007" = "validate_certificate_github_issue"
  )
}

#' Rules nothing checks yet
#'
#' Every rule is checked by `rule_checks()`, by [rule_implementations()], or
#' listed here, and the tests fail when that stops being true - so a rule added
#' to the register shows up as a test failure rather than being quietly
#' ignored, and implementing a rule requires removing it from this list.
#'
#' @return Character vector of rule identifiers.
#' @keywords internal
#' @noRd
rules_not_implemented <- function() {
  c(
    # Register-wide rules about columns of register.csv rather than about a
    # codecheck.yml: nothing validates the Type column against the four known
    # venue types, the Venue against venues.csv, or a certificate identifier
    # against the year's sequence.
    "CC-REG-002", "CC-REG-004", "CC-REG-005"
  )
}

##' Where the bundled rules came from
##'
##' The rule files are copied into this package from the register repository by
##' [update_codecheck_rules()], which records what it fetched. Without that
##' record a bundled copy is an undated snapshot, and a rule that changed in the
##' register cannot be told apart from one that never did.
##'
##' @return A data frame with one row per bundled rule file and the columns
##'   `file`, `spec_version`, `rules` (how many the file holds), `commit` (the
##'   register commit the file was taken from), `commit_date`, `retrieved`
##'   (when [update_codecheck_rules()] ran), `source`, `via` and `md5`. `commit` and
##'   `commit_date` are `NA` when the register's history was not reachable at
##'   the time. `via` says whether the files were downloaded or taken from a
##'   local register checkout.
##' @examples
##' codecheck_rules_provenance()
##' @seealso [codecheck_rules()], [update_codecheck_rules()]
##' @export
codecheck_rules_provenance <- function() {
  path <- system.file("extdata", "rules", "provenance.json",
                      package = "codecheck")
  if (!nzchar(path)) {
    stop("The bundled rules carry no provenance; run update_codecheck_rules()")
  }

  read_rules_provenance(path)
}

#' Read a provenance file written by [update_codecheck_rules()]
#'
#' Separate from [codecheck_rules_provenance()] so that a refresh can report
#' the file it has just written, rather than the installed package's copy.
#'
#' @param path Path to a `provenance.json`.
#' @keywords internal
#' @noRd
read_rules_provenance <- function(path) {
  recorded <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  do.call(rbind, lapply(recorded$files, function(entry) {
    data.frame(
      file = entry$file,
      spec_version = entry$spec_version,
      rules = entry$rules,
      commit = if (is.null(entry$commit)) NA_character_ else entry$commit,
      commit_date = if (is.null(entry$commit_date)) NA_character_ else entry$commit_date,
      retrieved = recorded$retrieved,
      source = recorded$source,
      via = recorded$via,
      md5 = entry$md5,
      stringsAsFactors = FALSE
    )
  }))
}

##' Refresh the bundled CODECHECK validation rules
##'
##' Copies the rule files from the register into this package's sources and
##' records where they came from, see [codecheck_rules_provenance()]. This is a
##' maintenance function: it writes into a source checkout of the package, not
##' into an installed one, and the refreshed files are meant to be committed.
##'
##' @param path Root of the package source checkout to write into.
##' @param from The register to take the files from. A path to a local register
##'   checkout, or `NULL` to download from the register on GitHub.
##' @param spec_versions Specification versions to fetch, defaulting to the
##'   versions this package knows about.
##' @return Invisibly, the provenance data frame that was written.
##' @examples
##' \dontrun{
##' update_codecheck_rules()
##' update_codecheck_rules(from = "../register")
##' }
##' @seealso [codecheck_rules()], [codecheck_rules_provenance()]
##' @export
update_codecheck_rules <- function(path = ".", from = NULL,
                                   spec_versions = codecheck_spec_versions()) {
  target_dir <- file.path(path, "inst", "extdata", "rules")
  dir.create(target_dir, showWarnings = FALSE, recursive = TRUE)

  entries <- lapply(spec_versions, function(spec_version) {
    file_name <- paste0("rules-", spec_version, ".yml")
    target <- file.path(target_dir, file_name)

    if (is.null(from)) {
      url <- paste0(RULES_REGISTER_RAW, file_name)
      response <- codecheck_GET(url)
      httr::stop_for_status(response, task = paste("download", url))
      writeBin(httr::content(response, as = "raw"), target)
      commit <- rules_commit_github(file_name)
    } else {
      source_path <- file.path(from, file_name)
      if (!file.exists(source_path)) {
        stop("No ", file_name, " in ", from)
      }
      file.copy(source_path, target, overwrite = TRUE)
      commit <- rules_commit_local(from, file_name)
    }

    # Fail here rather than at load time if the register published something
    # this package cannot read.
    rules <- yaml::read_yaml(target)$rules
    if (length(rules) == 0) {
      stop("No rules in ", target)
    }

    cli::cli_alert_success(
      "{.file {file_name}}: {length(rules)} rule{?s} for specification {spec_version}")

    list(file = file_name,
         spec_version = spec_version,
         rules = length(rules),
         commit = commit$sha,
         commit_date = commit$date,
         md5 = unname(tools::md5sum(target)))
  })

  provenance <- list(
    comment = paste("Written by codecheck::update_codecheck_rules().",
                    "The rules themselves are maintained in the register,",
                    "see https://github.com/codecheckers/register/blob/master/RULES.md"),
    # The register is the source either way; a local checkout is only how the
    # files were reached, and its path says nothing to anyone else.
    source = RULES_REGISTER_RAW,
    via = if (is.null(from)) "download" else "local register checkout",
    retrieved = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    files = entries
  )
  provenance_file <- file.path(target_dir, "provenance.json")
  jsonlite::write_json(provenance, provenance_file,
                       auto_unbox = TRUE, pretty = TRUE)
  cat("\n", file = provenance_file, append = TRUE)

  invisible(read_rules_provenance(provenance_file))
}

#' The register commit a rule file was last changed in
#'
#' Provenance is best effort: a rate-limited or unreachable API, or a register
#' directory that is not a git checkout, must not stop a refresh.
#'
#' @return List with `sha` and `date`, both `NA` when unavailable.
#' @keywords internal
#' @noRd
rules_commit_github <- function(file_name) {
  commit <- tryCatch(
    gh::gh("/repos/codecheckers/register/commits",
           path = file_name, per_page = 1)[[1]],
    error = function(e) {
      cli::cli_alert_warning(
        "Could not read the register history for {.file {file_name}}: {conditionMessage(e)}")
      NULL
    }
  )
  if (is.null(commit)) {
    return(list(sha = NA_character_, date = NA_character_))
  }
  list(sha = commit$sha, date = commit$commit$committer$date)
}

#' @rdname rules_commit_github
#' @keywords internal
#' @noRd
rules_commit_local <- function(register_dir, file_name) {
  commit <- tryCatch({
    repository <- git2r::repository(register_dir, discover = TRUE)
    git2r::commits(repository, n = 1, path = file_name)[[1]]
  }, error = function(e) {
    cli::cli_alert_warning(
      "Could not read the register history in {.path {register_dir}}: {conditionMessage(e)}")
    NULL
  })
  if (is.null(commit)) {
    return(list(sha = NA_character_, date = NA_character_))
  }
  list(sha = commit$sha,
       date = format(as.POSIXct(commit$author$when), "%Y-%m-%dT%H:%M:%S%z"))
}
