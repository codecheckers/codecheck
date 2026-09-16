##' Analyze and complete codecheck.yml with missing fields
##'
##' Analyzes a codecheck.yml file to identify missing mandatory and optional
##' fields according to the CODECHECK specification (https://codecheck.org.uk/spec/config/1.0/).
##' Can add placeholders for missing fields. By default, shows what would be
##' changed without actually modifying the file.
##'
##' The function identifies three categories of fields:
##' \itemize{
##'   \item \strong{Mandatory fields}: manifest, codechecker, report
##'   \item \strong{Recommended fields}: version, paper (title, authors, reference)
##'   \item \strong{Optional fields}: source, summary, repository, check_time, certificate
##' }
##'
##' @title Analyze and complete codecheck.yml with missing fields
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param add_mandatory Logical. If \code{TRUE}, add placeholders for all
##'   missing mandatory fields. Default is \code{FALSE}.
##' @param add_optional Logical. If \code{TRUE}, add placeholders for all
##'   missing optional and recommended fields. Default is \code{FALSE}.
##' @param apply_updates Logical. If \code{TRUE}, actually update the file.
##'   If \code{FALSE} (default), only show what would be changed.
##' @return Invisibly returns a list with two elements:
##'   \describe{
##'     \item{missing}{List of missing fields by category (mandatory, recommended, optional)}
##'     \item{updated}{The updated metadata list (if changes were made)}
##'   }
##' @author Daniel Nuest
##' @importFrom yaml read_yaml write_yaml
##' @export
##' @examples
##' \dontrun{
##'   # Analyze current codecheck.yml
##'   result <- complete_codecheck_yml()
##'
##'   # Add mandatory fields only
##'   complete_codecheck_yml(add_mandatory = TRUE, apply_updates = TRUE)
##'
##'   # Add all missing fields
##'   complete_codecheck_yml(add_mandatory = TRUE, add_optional = TRUE,
##'                          apply_updates = TRUE)
##' }
complete_codecheck_yml <- function(yml_file = "codecheck.yml",
                                   add_mandatory = FALSE,
                                   add_optional = FALSE,
                                   apply_updates = FALSE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file,
         "\nPlease create it first using create_codecheck_files().")
  }

  # Read existing metadata
  existing <- yaml::read_yaml(yml_file)

  # Define field specifications
  mandatory_fields <- list(
    manifest = list(
      type = "list",
      placeholder = list(list(file = "FIXME.pdf", comment = "FIXME: describe this output file"))
    ),
    codechecker = list(
      type = "list",
      placeholder = list(list(name = "FIXME", ORCID = "0000-0000-0000-0000"))
    ),
    report = list(
      type = "string",
      placeholder = "https://doi.org/10.5281/zenodo.FIXME"
    )
  )

  recommended_fields <- list(
    version = list(
      type = "string",
      placeholder = "https://codecheck.org.uk/spec/config/1.0/"
    ),
    paper = list(
      type = "list",
      placeholder = list(
        title = "FIXME: Paper title",
        authors = list(list(name = "FIXME", ORCID = "0000-0000-0000-0000")),
        reference = "https://FIXME"
      )
    )
  )

  optional_fields <- list(
    source = list(
      type = "string",
      placeholder = "FIXME: Description of material provenance"
    ),
    summary = list(
      type = "string",
      placeholder = "FIXME: Short summary of the CODECHECK certificate"
    ),
    repository = list(
      type = "string",
      placeholder = "https://FIXME"
    ),
    check_time = list(
      type = "string",
      placeholder = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    ),
    certificate = list(
      type = "string",
      placeholder = "YYYY-NNN"
    )
  )

  # Helper function to check if a field is missing or empty
  is_missing_or_placeholder <- function(value) {
    is.null(value) ||
      identical(value, "") ||
      (is.list(value) && length(value) == 0) ||
      (is.character(value) && grepl("FIXME|TODO|template|example", value, ignore.case = TRUE))
  }

  # Analyze missing fields
  missing <- list(
    mandatory = character(0),
    recommended = character(0),
    optional = character(0)
  )

  for (field in names(mandatory_fields)) {
    if (is_missing_or_placeholder(existing[[field]])) {
      missing$mandatory <- c(missing$mandatory, field)
    }
  }

  for (field in names(recommended_fields)) {
    if (is_missing_or_placeholder(existing[[field]])) {
      missing$recommended <- c(missing$recommended, field)
    }
  }

  for (field in names(optional_fields)) {
    if (is_missing_or_placeholder(existing[[field]])) {
      missing$optional <- c(missing$optional, field)
    }
  }

  # Print analysis
  cat("\n")
  cat("=", rep("=", 78), "\n", sep = "")
  cat("CODECHECK.YML ANALYSIS FOR ", yml_file, "\n", sep = "")
  cat("=", rep("=", 78), "\n", sep = "")
  cat("\n")

  cat("Missing MANDATORY fields:\n")
  if (length(missing$mandatory) > 0) {
    for (field in missing$mandatory) {
      cat("  - ", field, "\n", sep = "")
    }
  } else {
    cat("  (none - all mandatory fields present)\n")
  }
  cat("\n")

  cat("Missing RECOMMENDED fields:\n")
  if (length(missing$recommended) > 0) {
    for (field in missing$recommended) {
      cat("  - ", field, "\n", sep = "")
    }
  } else {
    cat("  (none - all recommended fields present)\n")
  }
  cat("\n")

  cat("Missing OPTIONAL fields:\n")
  if (length(missing$optional) > 0) {
    for (field in missing$optional) {
      cat("  - ", field, "\n", sep = "")
    }
  } else {
    cat("  (none - all optional fields present)\n")
  }
  cat("\n")

  # Build updated configuration if requested
  updated <- existing
  changes <- list()

  if (add_mandatory) {
    for (field in missing$mandatory) {
      changes[[field]] <- list(
        old = existing[[field]],
        new = mandatory_fields[[field]]$placeholder,
        category = "mandatory"
      )
      updated[[field]] <- mandatory_fields[[field]]$placeholder
    }
  }

  if (add_optional) {
    for (field in missing$recommended) {
      changes[[field]] <- list(
        old = existing[[field]],
        new = recommended_fields[[field]]$placeholder,
        category = "recommended"
      )
      updated[[field]] <- recommended_fields[[field]]$placeholder
    }

    for (field in missing$optional) {
      changes[[field]] <- list(
        old = existing[[field]],
        new = optional_fields[[field]]$placeholder,
        category = "optional"
      )
      updated[[field]] <- optional_fields[[field]]$placeholder
    }
  }

  # Print changes if any
  if (length(changes) > 0) {
    cat("=", rep("=", 78), "\n", sep = "")
    cat("CHANGES TO BE APPLIED\n")
    cat("=", rep("=", 78), "\n", sep = "")
    cat("\n")

    for (field_name in names(changes)) {
      change <- changes[[field_name]]
      cat("Field: ", field_name, " (", toupper(change$category), ")\n", sep = "")
      cat(rep("-", 80), "\n", sep = "")

      cat("OLD:\n")
      if (is.null(change$old)) {
        cat("  (field does not exist)\n")
      } else if (is.list(change$old)) {
        cat("  ", yaml::as.yaml(change$old), sep = "")
      } else {
        cat("  ", change$old, "\n", sep = "")
      }

      cat("\nNEW:\n")
      if (is.list(change$new)) {
        cat("  ", yaml::as.yaml(change$new), sep = "")
      } else {
        cat("  ", change$new, "\n", sep = "")
      }
      cat("\n")
    }

    cat("=", rep("=", 78), "\n", sep = "")

    if (apply_updates) {
      yaml::write_yaml(updated, yml_file)
      cat("\n\u2713 Changes applied to ", yml_file, "\n\n", sep = "")
    } else {
      cat("\n\u26a0 No changes applied. Use apply_updates = TRUE to save changes.\n\n")
    }
  } else {
    if (add_mandatory || add_optional) {
      cat("No fields to add.\n\n")
    } else {
      cat("Use add_mandatory = TRUE and/or add_optional = TRUE to add placeholders.\n\n")
    }
  }

  invisible(list(missing = missing, updated = if(length(changes) > 0) updated else NULL))
}


##' Validate codecheck.yml metadata against CrossRef
##'
##' Retrieves the Crossref record of the paper's DOI and compares it with the
##' local codecheck.yml metadata: whether the reference resolves, the title, the
##' number of authors, their names and their ORCIDs. These are the rules
##' `CC-MET-004` to `CC-MET-008`, run through [validate_codecheck_yml_rules()]
##' together with the two rules they depend on, `CC-CFG-016` paper-present and
##' `CC-CFG-021` paper-reference, and reported at the severity the rule file of
##' the declared specification version gives them.
##'
##' A Crossref record that cannot be retrieved, because the API is unreachable
##' or rate limited, makes the comparisons skip. It never fails the validation.
##'
##' Note: For comprehensive validation including ORCID name verification and
##' codechecker validation, use \code{validate_contents_references()} instead.
##'
##' @title Validate codecheck.yml metadata against CrossRef
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param strict Logical. If \code{TRUE}, report warnings as errors.
##' @param check_orcids Logical. If \code{TRUE} (default), compare author ORCIDs
##'   with Crossref (`CC-MET-008`).
##' @param stop_on_error Logical. If \code{TRUE} (default), stop when a rule
##'   failed at severity error. Rules at severity warning only ever warn.
##' @return Invisibly returns a list with validation results:
##'   \describe{
##'     \item{valid}{Logical, \code{FALSE} if any rule failed at severity error or warning}
##'     \item{issues}{Character vector of the failed rules, in words}
##'     \item{crossref_metadata}{The metadata retrieved from CrossRef (if available)}
##'     \item{results}{The per-rule results, see [validate_codecheck_yml_rules()]}
##'   }
##' @author Daniel Nuest
##' @seealso [validate_codecheck_yml_rules()]
##' @export
##' @examples
##' \dontrun{
##'   # Validate with warnings only
##'   result <- validate_codecheck_yml_crossref()
##'
##'   # Validate with strict error checking
##'   validate_codecheck_yml_crossref(strict = TRUE)
##'
##'   # Skip ORCID validation
##'   validate_codecheck_yml_crossref(check_orcids = FALSE)
##' }
validate_codecheck_yml_crossref <- function(yml_file = "codecheck.yml",
                                            strict = FALSE,
                                            check_orcids = TRUE,
                                            stop_on_error = TRUE) {
  rules <- c("CC-CFG-016", "CC-CFG-021", "CC-MET-004", "CC-MET-005",
             "CC-MET-006", "CC-MET-007",
             if (check_orcids) "CC-MET-008")
  validation <- validate_rules_on_file(yml_file, rules, strict = strict,
                                       stop_on_error = stop_on_error)

  crossref <- validation$context$lookups$crossref
  invisible(list(
    valid = validation$valid,
    issues = validation$issues,
    crossref_metadata = if (is.null(crossref)) NULL else crossref$record,
    results = validation$results
  ))
}

#' Run a selection of rules on a file, the way the older validators report
#'
#' The older validation functions warn about every finding and return a list
#' rather than a data frame. They now run the rules like
#' [validate_codecheck_yml_rules()], and this is where their results are turned
#' back into that form: a failed rule at severity warning is a `warning()`, one
#' at severity error stops (unless `stop_on_error` is `FALSE`), and "could not
#' check" is neither.
#'
#' @param people Which people the ORCID rules look at, see `context_people()`.
#' @return A list with `valid`, `issues`, `results` and the `context`, whose
#'   `lookups` hold what external services answered.
#' @keywords internal
#' @noRd
validate_rules_on_file <- function(yml_file, rules, strict = FALSE,
                                   stop_on_error = TRUE, people = NULL) {
  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file)
  }

  context <- rules_context(yml_file)
  context$people <- people
  spec_version <- codecheck_spec_version(context$yml)
  context$spec_version <- spec_version

  results <- run_rules(context, spec_version, rules, strict)
  report_rule_results(results, context, spec_version, strict)

  failed <- results[results$outcome %in% c("error", "warning"), ]
  for (i in which(failed$outcome == "warning")) {
    warning(rule_result_text(failed[i, ]), call. = FALSE)
  }
  if (stop_on_error && any(failed$outcome == "error")) {
    stop("Validation failed: ",
         rules_failure_message(failed[failed$outcome == "error", ], context$label),
         call. = FALSE)
  }

  list(valid = nrow(failed) == 0,
       issues = vapply(seq_len(nrow(failed)),
                       function(i) rule_result_text(failed[i, ]), character(1)),
       results = results,
       context = context)
}


##' Retrieve a person's name from the public ORCID API
##'
##' Looks up the name on an ORCID record via the public, unauthenticated
##' ORCID API (\url{https://pub.orcid.org}). This works for any record whose
##' name is publicly visible and requires no ORCID token, unlike
##' \code{\link[rorcid]{orcid_person}}, whose personal-authentication tokens
##' are only valid for reading the authenticated user's own record.
##'
##' @param orcid_id Character. An ORCID identifier (NNNN-NNNN-NNNN-NNNX).
##' @return Character name, or \code{NULL} if the record or name is not
##'   publicly available or the request fails.
##' @keywords internal
get_orcid_name_public <- function(orcid_id) {
  tryCatch({
    # codecheck_GET() (not a plain httr::GET()) so a request that never gets
    # a response times out into this tryCatch instead of hanging - the
    # existing status-code check below only guards against an *answered*
    # request, not one ORCID's server never answers at all.
    resp <- codecheck_GET(
      paste0("https://pub.orcid.org/v3.0/", orcid_id, "/person"),
      httr::add_headers(Accept = "application/json")
    )

    if (httr::status_code(resp) != 200) {
      return(NULL)
    }

    person_data <- jsonlite::fromJSON(
      httr::content(resp, as = "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    )

    name_data <- person_data$name
    if (is.null(name_data)) {
      return(NULL)
    }

    given_names <- name_data$`given-names`$value
    family_name <- name_data$`family-name`$value

    if (!is.null(given_names) && !is.null(family_name)) {
      paste(given_names, family_name)
    } else if (!is.null(family_name)) {
      family_name
    } else if (!is.null(given_names)) {
      given_names
    } else {
      NULL
    }
  }, error = function(e) NULL)
}


##' Validate codecheck.yml metadata against ORCID
##'
##' Validates author and codechecker information against the public ORCID API:
##' that codecheckers are present and named (`CC-CFG-008`, `CC-CFG-009`), that
##' every ORCID is well-formed (`CC-MET-001`), resolves (`CC-MET-002`), and
##' carries the name given in the codecheck.yml (`CC-MET-003`). The rules are
##' run through [validate_codecheck_yml_rules()] and reported at the severity
##' the rule file of the declared specification version gives them.
##'
##' Records are read from the public ORCID API, which needs no token and reads
##' any record whose name is public. An ORCID record that cannot be retrieved,
##' because the API is unreachable or rate limited, is skipped. It never fails
##' the validation.
##'
##' @title Validate codecheck.yml metadata against ORCID
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param strict Logical. If \code{TRUE}, report warnings as errors.
##' @param validate_authors Logical. If \code{TRUE} (default), validate author ORCIDs.
##' @param validate_codecheckers Logical. If \code{TRUE} (default), validate
##'   codecheckers and their ORCIDs.
##' @param skip_on_auth_error Deprecated and without effect: a record that
##'   cannot be retrieved is always skipped.
##' @param stop_on_error Logical. If \code{TRUE} (default), stop when a rule
##'   failed at severity error. Rules at severity warning only ever warn.
##' @return Invisibly returns a list with validation results:
##'   \describe{
##'     \item{valid}{Logical, \code{FALSE} if any rule failed at severity error or warning}
##'     \item{issues}{Character vector of the failed rules, in words}
##'     \item{skipped}{Logical, \code{TRUE} if at least one ORCID record could not be retrieved}
##'     \item{results}{The per-rule results, see [validate_codecheck_yml_rules()]}
##'   }
##' @author Daniel Nuest
##' @seealso [validate_codecheck_yml_rules()]
##' @export
##' @examples
##' \dontrun{
##'   result <- validate_codecheck_yml_orcid()
##'
##'   # Validate with strict error checking
##'   validate_codecheck_yml_orcid(strict = TRUE)
##'
##'   # Validate only codecheckers
##'   validate_codecheck_yml_orcid(validate_authors = FALSE)
##' }
validate_codecheck_yml_orcid <- function(yml_file = "codecheck.yml",
                                         strict = FALSE,
                                         validate_authors = TRUE,
                                         validate_codecheckers = TRUE,
                                         skip_on_auth_error = FALSE,
                                         stop_on_error = TRUE) {
  people <- c(if (validate_authors) "authors",
              if (validate_codecheckers) "codecheckers")
  rules <- c(if (validate_codecheckers) c("CC-CFG-008", "CC-CFG-009"),
             if (length(people) > 0) c("CC-MET-001", "CC-MET-002", "CC-MET-003"))
  validation <- validate_rules_on_file(yml_file, rules, strict = strict,
                                       stop_on_error = stop_on_error,
                                       people = people)

  lookups <- mget(ls(validation$context$lookups, pattern = "^orcid:"),
                  envir = validation$context$lookups)
  invisible(list(
    valid = validation$valid,
    issues = validation$issues,
    skipped = any(vapply(lookups, function(r) r$status == "unreachable", logical(1))),
    results = validation$results
  ))
}


##' Validate codecheck.yml metadata against external references
##'
##' Wrapper function that validates codecheck.yml metadata against both
##' CrossRef (for paper metadata) and ORCID (for author and codechecker information).
##' This provides comprehensive validation of all external references.
##'
##' @title Validate codecheck.yml metadata against external references
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param strict Logical. If \code{TRUE}, throw an error on any mismatch.
##'   If \code{FALSE} (default), a rule failed at severity error still stops,
##'   after both validations have run.
##' @param validate_crossref Logical. If \code{TRUE} (default), validate against CrossRef.
##' @param validate_orcid Logical. If \code{TRUE} (default), validate against ORCID.
##' @param check_orcids Logical. If \code{TRUE} (default), validate ORCID identifiers in CrossRef check.
##' @param skip_on_auth_error Deprecated and without effect: an ORCID record
##'   that cannot be retrieved is always skipped.
##' @return Invisibly returns a list with validation results:
##'   \describe{
##'     \item{valid}{Logical indicating if all checks passed}
##'     \item{crossref_result}{Results from CrossRef validation (if performed)}
##'     \item{orcid_result}{Results from ORCID validation (if performed)}
##'   }
##' @author Daniel Nuest
##' @export
##' @examples
##' \dontrun{
##'   # Validate everything with warnings only
##'   result <- validate_contents_references()
##'
##'   # Validate with strict error checking
##'   validate_contents_references(strict = TRUE)
##'
##'   # Validate only CrossRef
##'   validate_contents_references(validate_orcid = FALSE)
##'
##'   # Validate only ORCID
##'   validate_contents_references(validate_crossref = FALSE)
##' }
validate_contents_references <- function(yml_file = "codecheck.yml",
                                         strict = FALSE,
                                         validate_crossref = TRUE,
                                         validate_orcid = TRUE,
                                         check_orcids = TRUE,
                                         skip_on_auth_error = FALSE) {

  crossref_result <- NULL
  orcid_result <- NULL
  all_valid <- TRUE

  # Run CrossRef validation
  if (validate_crossref) {
    message("\n", rep("=", 80))
    message("CROSSREF VALIDATION")
    message(rep("=", 80), "\n")

    crossref_result <- validate_codecheck_yml_crossref(
      yml_file = yml_file,
      strict = strict,
      check_orcids = check_orcids,
      stop_on_error = FALSE  # the ORCID validation still has to run
    )

    if (!crossref_result$valid) {
      all_valid <- FALSE
    }
  }

  # Run ORCID validation
  if (validate_orcid) {
    message("\n", rep("=", 80))
    message("ORCID VALIDATION")
    message(rep("=", 80), "\n")

    orcid_result <- validate_codecheck_yml_orcid(
      yml_file = yml_file,
      strict = strict,
      stop_on_error = FALSE  # stop after the summary
    )

    if (!orcid_result$valid) {
      all_valid <- FALSE
    }
  }

  # Final result
  if (!all_valid) {
    total_issues <- 0
    if (!is.null(crossref_result)) total_issues <- total_issues + length(crossref_result$issues)
    if (!is.null(orcid_result)) total_issues <- total_issues + length(orcid_result$issues)

    message("\n", rep("=", 80))
    message("\u26a0 VALIDATION SUMMARY: ", total_issues, " issue(s) found")
    message(rep("=", 80))

    # A rule that failed at severity error stops, and with strict every
    # warning already is one.
    failed_errors <- sum(
      if (!is.null(crossref_result)) crossref_result$results$outcome == "error" else 0,
      if (!is.null(orcid_result)) orcid_result$results$outcome == "error" else 0)
    if (strict || failed_errors > 0) {
      all_issues <- c()
      if (!is.null(crossref_result)) all_issues <- c(all_issues, crossref_result$issues)
      if (!is.null(orcid_result)) all_issues <- c(all_issues, orcid_result$issues)

      stop("Validation failed with ", total_issues, " issue(s):\n",
           paste(all_issues, collapse = "\n"))
    }
  } else {
    message("\n", rep("=", 80))
    message("\u2713 ALL VALIDATIONS PASSED!")
    message(rep("=", 80))
  }

  invisible(list(
    valid = all_valid,
    crossref_result = crossref_result,
    orcid_result = orcid_result
  ))
}


##' Check if certificate identifier or DOI is a placeholder
##'
#' Internal helper: Check if a report DOI value is a placeholder
#'
#' This is an internal function used by is_placeholder_certificate() and
#' get_or_create_zenodo_record() to check if a DOI value is a placeholder.
#'
#' @param report_doi The report DOI value to check (can be NULL, empty, or string)
#' @return Logical: TRUE if the DOI is NULL, empty, or contains placeholder patterns
#' @keywords internal
#' @noRd
is_doi_placeholder <- function(report_doi) {
  # Check if DOI is missing or empty
  if (is.null(report_doi) || report_doi == "") {
    return(TRUE)
  }

  # Check for placeholder text in DOI
  if (grepl("(FIXME|TODO|placeholder|example|XXXXX)", report_doi, ignore.case = TRUE)) {
    return(TRUE)
  }

  # Check for incomplete DOI patterns
  if (grepl("doi\\.org/10\\.\\d+/[^/]*\\.(FIXME|TODO)", report_doi, ignore.case = TRUE)) {
    return(TRUE)
  }

  return(FALSE)
}

##' Determines whether a certificate identifier or report DOI in codecheck.yml is a
##' placeholder that needs to be replaced. Checks for common placeholder patterns
##' like "YYYY-NNN", "0000-000", or placeholder year prefixes in certificate ID,
##' and "FIXME", "TODO", etc. in the report DOI.
##'
##' @title Check if certificate identifier or DOI is a placeholder
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param metadata Optional metadata list. If NULL (default), loads from yml_file.
##' @param strict Logical. If TRUE and certificate or DOI is a placeholder, stops
##'   execution with an error. Default is FALSE (returns TRUE/FALSE without stopping).
##' @param check_doi Logical. If TRUE (default), also checks the report DOI field
##'   for placeholder patterns.
##' @return Logical value: TRUE if certificate or DOI is a placeholder, FALSE otherwise.
##'   If strict=TRUE and either is a placeholder, stops with an error instead.
##' @author Daniel Nuest
##' @export
##' @examples
##' \dontrun{
##'   # Check if certificate or DOI is a placeholder
##'   if (is_placeholder_certificate()) {
##'     message("Certificate ID or DOI needs to be set")
##'   }
##'
##'   # Check specific file
##'   is_placeholder_certificate("path/to/codecheck.yml")
##'
##'   # Only check certificate, not DOI
##'   is_placeholder_certificate(check_doi = FALSE)
##'
##'   # Fail if certificate or DOI is a placeholder
##'   is_placeholder_certificate(strict = TRUE)
##' }
is_placeholder_certificate <- function(yml_file = "codecheck.yml",
                                       metadata = NULL,
                                       strict = FALSE,
                                       check_doi = TRUE) {
  # Load metadata if not provided
  if (is.null(metadata)) {
    if (!file.exists(yml_file)) {
      stop("codecheck.yml file not found at: ", yml_file)
    }
    metadata <- yaml::read_yaml(yml_file)
  }

  cert_id <- metadata$certificate
  has_cert_placeholder <- FALSE
  has_doi_placeholder <- FALSE
  error_messages <- character(0)

  # Check certificate identifier
  # Check if certificate is missing or empty
  if (is.null(cert_id) || cert_id == "") {
    has_cert_placeholder <- TRUE
    error_messages <- c(error_messages,
                       "Certificate identifier is missing or empty in codecheck.yml. Please set a valid certificate ID (format: YYYY-NNN).")
  } else {
    # Placeholder patterns
    placeholder_patterns <- c("YYYY-NNN", "0000-000", "9999-999")

    # Check exact matches with placeholder patterns
    if (cert_id %in% placeholder_patterns) {
      has_cert_placeholder <- TRUE
      error_messages <- c(error_messages,
                         paste0("Certificate identifier '", cert_id, "' is a placeholder. Please set a valid certificate ID (format: YYYY-NNN)."))
    }

    # Check for placeholder year prefixes (YYYY, 0000, 9999)
    if (grepl("^(YYYY|0000|9999)-\\d{3}$", cert_id)) {
      has_cert_placeholder <- TRUE
      error_messages <- c(error_messages,
                         paste0("Certificate identifier '", cert_id, "' uses a placeholder year prefix. Please set a valid certificate ID with the correct year."))
    }

    # Check for template-like patterns
    if (grepl("(FIXME|TODO|template|example)", cert_id, ignore.case = TRUE)) {
      has_cert_placeholder <- TRUE
      error_messages <- c(error_messages,
                         paste0("Certificate identifier '", cert_id, "' contains template text. Please set a valid certificate ID (format: YYYY-NNN)."))
    }
  }

  # Check report DOI if requested
  if (check_doi) {
    report_doi <- metadata$report

    # Use shared helper function to check for placeholder
    if (is_doi_placeholder(report_doi)) {
      has_doi_placeholder <- TRUE
      if (is.null(report_doi) || report_doi == "") {
        error_messages <- c(error_messages,
                           "Report DOI is missing or empty in codecheck.yml. Please set a valid DOI for the certificate report (e.g., from Zenodo, OSF, or ResearchEquals).")
      } else if (grepl("doi\\.org/10\\.\\d+/[^/]*\\.(FIXME|TODO)", report_doi, ignore.case = TRUE)) {
        error_messages <- c(error_messages,
                           paste0("Report DOI '", report_doi, "' is incomplete. Please set a valid DOI for the certificate report."))
      } else {
        error_messages <- c(error_messages,
                           paste0("Report DOI '", report_doi, "' contains placeholder text. Please set a valid DOI for the certificate report."))
      }
    }
  }

  # Determine if any placeholder found
  is_placeholder <- has_cert_placeholder || has_doi_placeholder

  # Handle strict mode
  if (strict && is_placeholder) {
    stop(paste(error_messages, collapse = "\n"), call. = FALSE)
  }

  return(is_placeholder)
}


##' Validate certificate for rendering and display warning if placeholder
##'
##' This function checks if the certificate identifier and report DOI are
##' placeholders, or the report DOI is a Zenodo concept DOI instead of a
##' version-specific DOI (see #36), and prints a LaTeX warning box with a
##' warning icon if so. Intended for use in R Markdown or Quarto templates
##' to alert users about placeholder certificates and DOIs.
##'
##' @title Validate certificate for rendering with visual warning
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param metadata Optional metadata list. If NULL (default), loads from yml_file.
##' @param strict Logical. If TRUE and certificate or DOI is a placeholder, stops execution.
##'   Default is FALSE (displays warning but continues).
##' @param display_warning Logical. If TRUE (default), displays a warning box in
##'   the rendered output when certificate or DOI is a placeholder.
##' @param check_concept_doi Logical. If TRUE (default), checks whether a Zenodo
##'   report DOI is a concept DOI (which always resolves to the latest version)
##'   rather than a version-specific DOI, and warns if so. Requires a network
##'   request to Zenodo; if that request fails (e.g. offline rendering), the
##'   check is silently skipped rather than failing the render.
##' @return Invisibly returns TRUE if certificate and DOI are valid, FALSE if any placeholder
##' @author Daniel Nuest
##' @export
##' @examples
##' \dontrun{
##'   # In an R Markdown template, use in a chunk:
##'   validate_certificate_for_rendering()
##'
##'   # Fail rendering if certificate or DOI is a placeholder:
##'   validate_certificate_for_rendering(strict = TRUE)
##' }
validate_certificate_for_rendering <- function(yml_file = "codecheck.yml",
                                               metadata = NULL,
                                               strict = FALSE,
                                               display_warning = TRUE,
                                               check_concept_doi = TRUE) {
  # Load metadata if not provided
  if (is.null(metadata)) {
    if (!file.exists(yml_file)) {
      stop("codecheck.yml file not found at: ", yml_file)
    }
    metadata <- yaml::read_yaml(yml_file)
  }

  # Check certificate placeholder (DOI check disabled)
  has_cert_placeholder <- is_placeholder_certificate(yml_file = yml_file,
                                                       metadata = metadata,
                                                       strict = FALSE,
                                                       check_doi = FALSE)

  # Check DOI placeholder directly by examining report field
  has_doi_placeholder <- FALSE
  report_doi <- metadata$report

  if (is.null(report_doi) || report_doi == "") {
    has_doi_placeholder <- TRUE
  } else if (grepl("(FIXME|TODO|placeholder|example|XXXXX)", report_doi, ignore.case = TRUE)) {
    has_doi_placeholder <- TRUE
  } else if (grepl("doi\\.org/10\\.\\d+/[^/]*\\.(FIXME|TODO)", report_doi, ignore.case = TRUE)) {
    has_doi_placeholder <- TRUE
  }

  # Check if the report DOI is a Zenodo concept DOI rather than a version-specific DOI, see #36
  has_concept_doi <- FALSE
  has_outdated_version <- FALSE
  if (check_concept_doi && !has_doi_placeholder &&
      isTRUE(grepl("zenodo", report_doi, ignore.case = TRUE))) {
    has_concept_doi <- isTRUE(tryCatch(is_zenodo_concept_doi(report_doi),
                                       error = function(e) FALSE))
    # A version-specific DOI can still be outdated if a newer version of the
    # record was since published; only worth checking when it is not already
    # flagged as the wrong kind of DOI, see #36.
    if (!has_concept_doi) {
      has_outdated_version <- isTRUE(tryCatch(!is_zenodo_latest_version(report_doi),
                                              error = function(e) FALSE))
    }
  }

  # Check if any placeholder found
  is_placeholder <- has_cert_placeholder || has_doi_placeholder || has_concept_doi || has_outdated_version

  if (is_placeholder) {
    cert_id <- if (is.null(metadata$certificate) || metadata$certificate == "") {
      "NOT SET"
    } else {
      metadata$certificate
    }

    report_doi <- if (is.null(metadata$report) || metadata$report == "") {
      "NOT SET"
    } else {
      metadata$report
    }

    # Build warning messages
    warning_parts <- character(0)
    console_warnings <- character(0)

    if (has_cert_placeholder) {
      warning_parts <- c(warning_parts,
                        paste0("\\textbf{Certificate ID is a placeholder: \\texttt{", cert_id, "}}"))
      console_warnings <- c(console_warnings,
                           paste0("Certificate identifier '", cert_id, "' is a placeholder"))
    }

    if (has_doi_placeholder) {
      warning_parts <- c(warning_parts,
                        paste0("\\textbf{Report DOI is a placeholder: \\texttt{", report_doi, "}}"))
      console_warnings <- c(console_warnings,
                           paste0("Report DOI '", report_doi, "' is a placeholder"))
    }

    if (has_concept_doi) {
      warning_parts <- c(warning_parts,
                        paste0("\\textbf{Report DOI is a Zenodo concept DOI: \\texttt{", report_doi, "}}"))
      console_warnings <- c(console_warnings,
                           paste0("Report DOI '", report_doi, "' is a Zenodo concept DOI, ",
                                  "which always resolves to the latest version; ",
                                  "use the version-specific DOI instead"))
    }

    if (has_outdated_version) {
      warning_parts <- c(warning_parts,
                        paste0("\\textbf{Report DOI is not the latest Zenodo version: \\texttt{",
                               report_doi, "}}"))
      console_warnings <- c(console_warnings,
                           paste0("Report DOI '", report_doi, "' is not the latest version of its ",
                                  "Zenodo record; a newer version has since been published, so the ",
                                  "checked metadata may no longer be accurate. Update the report DOI ",
                                  "to the latest version, or check that version instead, for ",
                                  "transparency"))
    }

    # Display warning in PDF output if requested
    if (display_warning) {
      cat("\\begin{center}\n")
      cat("\\fcolorbox{red}{yellow}{\\parbox{0.9\\textwidth}{\\centering\n")
      cat("\\textbf{\\Large \\textcolor{red}{\u26a0} WARNING \\textcolor{red}{\u26a0}}\\\\\n")
      cat("\\vspace{0.2cm}\n")

      # Display each warning part
      for (i in seq_along(warning_parts)) {
        cat(warning_parts[i], "\\\\\n", sep = "")
        if (i < length(warning_parts)) {
          cat("\\vspace{0.1cm}\n")
        }
      }

      cat("\\vspace{0.1cm}\n")
      cat("This certificate is not yet finalized.\\\\")
      cat("Please set valid identifiers before publishing.\n")
      cat("}}\n")
      cat("\\end{center}\n\n")
    }

    # Print warning message to console
    # rule: CC-REP-001 report-doi-version-specific, CC-REP-002 report-doi-newest-version
    warning(paste(console_warnings, collapse = ". "), ". ",
            "Please set valid values before finalizing.",
            call. = FALSE)

    # Stop if strict mode
    if (strict) {
      stop("Certificate validation failed: ", paste(console_warnings, collapse = "; "), ". ",
           "Rendering stopped. Please set valid identifiers.",
           call. = FALSE)
    }

    return(invisible(FALSE))
  }

  return(invisible(TRUE))
}

#' Validate certificate identifier exists in GitHub register issues
#'
#' Checks if the certificate identifier from a codecheck.yml file has a corresponding
#' issue in the codecheckers/register GitHub repository. This function validates that:
#' \itemize{
#'   \item A matching issue exists for the certificate identifier
#'   \item Warns if the issue is closed (certificate already completed)
#'   \item Warns if the issue is unassigned (no codechecker assigned yet)
#'   \item Stops with error if no matching issue is found
#' }
#'
#' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
#' @param metadata Optional. Pre-loaded metadata list. If NULL, will be loaded from yml_file
#' @param repo GitHub repository in format "owner/repo". Defaults to "codecheckers/register"
#' @param strict Logical. If TRUE, treats warnings as errors. Default is FALSE
#'
#' @return Invisibly returns a list with the validation result:
#'   \describe{
#'     \item{valid}{Logical indicating if validation passed}
#'     \item{certificate}{The certificate identifier checked}
#'     \item{issue_number}{GitHub issue number if found, otherwise NULL}
#'     \item{issue_state}{Issue state ("open" or "closed") if found}
#'     \item{issue_assignees}{List of assignees if found}
#'     \item{warnings}{Character vector of warning messages}
#'     \item{errors}{Character vector of error messages}
#'   }
#'
#' @examples
#' \dontrun{
#' # Validate certificate in current directory
#' validate_certificate_github_issue()
#'
#' # Validate with strict mode (warnings become errors)
#' validate_certificate_github_issue(strict = TRUE)
#'
#' # Validate specific file
#' validate_certificate_github_issue("path/to/codecheck.yml")
#' }
#'
#' @author Daniel Nuest
#' @importFrom gh gh
#' @export
validate_certificate_github_issue <- function(yml_file = "codecheck.yml",
                                               metadata = NULL,
                                               repo = "codecheckers/register",
                                               strict = FALSE) {

  # Load metadata if not provided
  if (is.null(metadata)) {
    if (!file.exists(yml_file)) {
      stop("codecheck.yml file not found at: ", yml_file)
    }
    metadata <- yaml::read_yaml(yml_file)
  }

  # Get certificate identifier
  certificate <- metadata$certificate

  if (is.null(certificate) || certificate == "") {
    stop("Certificate identifier not found in codecheck.yml",
         call. = FALSE)
  }

  # Check if certificate is a placeholder
  if (is_placeholder_certificate(yml_file = yml_file,
                                  metadata = metadata,
                                  strict = FALSE)) {
    message("Certificate identifier '", certificate, "' appears to be a placeholder. ",
            "Skipping GitHub issue validation.")
    return(invisible(list(
      valid = TRUE,
      certificate = certificate,
      issue_number = NULL,
      issue_state = NULL,
      issue_assignees = NULL,
      warnings = character(0),
      errors = character(0),
      skipped = TRUE
    )))
  }

  # Split repo into owner and name
  repo_parts <- strsplit(repo, "/")[[1]]
  if (length(repo_parts) != 2) {
    stop("repo must be in format 'owner/repo'", call. = FALSE)
  }

  # Certificate pattern in issue titles: YYYY-NNN
  cert_pattern <- paste0("\\b", gsub("-", "-", certificate), "\\b")

  # Search for issues with the certificate ID (search all states)
  tryCatch({
    # Search in all issues (open + closed)
    all_issues <- gh::gh("GET /repos/:owner/:repo/issues",
                         owner = repo_parts[1],
                         repo = repo_parts[2],
                         state = "all",
                         per_page = 100)

    # Find matching issue
    matching_issue <- NULL
    for (issue in all_issues) {
      if (grepl(cert_pattern, issue$title)) {
        matching_issue <- issue
        break
      }
    }

    # Initialize result
    warnings <- character(0)
    errors <- character(0)
    valid <- TRUE

    # Check if issue was found
    if (is.null(matching_issue)) {
      error_msg <- paste0(
        "No GitHub issue found for certificate '", certificate, "' ",
        "in repository '", repo, "'. ",
        "Please ensure an issue exists in the register before proceeding."
      )
      errors <- c(errors, error_msg)
      stop(error_msg, call. = FALSE)
    }

    issue_number <- matching_issue$number
    issue_state <- matching_issue$state
    issue_assignees <- matching_issue$assignees

    # Check if issue is closed
    if (issue_state == "closed") {
      warning_msg <- paste0(
        "GitHub issue #", issue_number, " for certificate '", certificate, "' ",
        "is already CLOSED. This usually means the CODECHECK has been completed and published. ",
        "If you are still working on it, consider reopening the issue."
      )
      warnings <- c(warnings, warning_msg)
      # rule: CC-REG-006 issue-exists
      warning(warning_msg, call. = FALSE)

      if (strict) {
        valid <- FALSE
      }
    }

    # Check if issue is unassigned
    if (length(issue_assignees) == 0) {
      warning_msg <- paste0(
        "GitHub issue #", issue_number, " for certificate '", certificate, "' ",
        "is UNASSIGNED. Please assign a codechecker to this issue."
      )
      warnings <- c(warnings, warning_msg)
      # rule: CC-REG-007 issue-references-certificate
      warning(warning_msg, call. = FALSE)

      if (strict) {
        valid <- FALSE
      }
    }

    # If strict mode and we have warnings, stop
    if (strict && !valid) {
      stop("Certificate validation failed in strict mode: ",
           paste(warnings, collapse = "; "),
           call. = FALSE)
    }

    # Success message
    if (valid && length(warnings) == 0) {
      message("Certificate '", certificate, "' validated: ",
              "Found in GitHub issue #", issue_number, " (", issue_state, ")")
    }

    return(invisible(list(
      valid = valid,
      certificate = certificate,
      issue_number = issue_number,
      issue_state = issue_state,
      issue_assignees = issue_assignees,
      issue_title = matching_issue$title,
      warnings = warnings,
      errors = errors,
      skipped = FALSE
    )))

  }, error = function(e) {
    # Handle GitHub API errors
    if (grepl("HTTP 404", e$message) || grepl("Not Found", e$message)) {
      stop("GitHub repository '", repo, "' not found or not accessible. ",
           "Please check the repository name and your access permissions.",
           call. = FALSE)
    } else if (grepl("API rate limit", e$message) || grepl("403", e$message)) {
      stop("GitHub API rate limit exceeded. ",
           "Please set a GITHUB_PAT environment variable with a valid GitHub token.",
           call. = FALSE)
    } else {
      # Re-throw if already our custom error
      if (grepl("No GitHub issue found", e$message)) {
        stop(e)
      }
      stop("Error accessing GitHub API: ", e$message, call. = FALSE)
    }
  })
}
