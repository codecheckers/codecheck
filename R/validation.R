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
##' Retrieves metadata from CrossRef for the paper's DOI and compares it with
##' the local codecheck.yml metadata. Validates title and author information
##' (names and ORCIDs against CrossRef data).
##'
##' This function is useful for ensuring consistency between the published paper
##' metadata and the CODECHECK certificate, helping to catch typos, outdated
##' information, or missing data.
##'
##' Note: For comprehensive validation including ORCID name verification and
##' codechecker validation, use \code{validate_contents_references()} instead.
##'
##' @title Validate codecheck.yml metadata against CrossRef
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param strict Logical. If \code{TRUE}, throw an error on any mismatch.
##'   If \code{FALSE} (default), only issue warnings.
##' @param check_orcids Logical. If \code{TRUE} (default), validate ORCID
##'   identifiers. If \code{FALSE}, skip ORCID validation.
##' @return Invisibly returns a list with validation results:
##'   \describe{
##'     \item{valid}{Logical indicating if all checks passed}
##'     \item{issues}{Character vector of any issues found}
##'     \item{crossref_metadata}{The metadata retrieved from CrossRef (if available)}
##'   }
##' @author Daniel Nuest
##' @importFrom httr GET content status_code
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
                                            check_orcids = TRUE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file)
  }

  # Read local metadata
  local_meta <- yaml::read_yaml(yml_file)

  issues <- character(0)
  crossref_meta <- NULL

  # Check if paper metadata exists
  if (is.null(local_meta$paper)) {
    issues <- c(issues, "No paper metadata found in codecheck.yml")
    if (strict) {
      stop("Validation failed: No paper metadata found in codecheck.yml")
    }
    return(invisible(list(valid = FALSE, issues = issues, crossref_metadata = NULL)))
  }

  # Check if paper reference (DOI) exists
  if (is.null(local_meta$paper$reference)) {
    issues <- c(issues, "No paper reference (DOI) found in codecheck.yml")
    if (strict) {
      stop("Validation failed: No paper reference found")
    }
    return(invisible(list(valid = FALSE, issues = issues, crossref_metadata = NULL)))
  }

  # Extract DOI from reference
  paper_ref <- local_meta$paper$reference

  # Skip validation if reference contains placeholder
  if (grepl("FIXME|TODO|template|example", paper_ref, ignore.case = TRUE)) {
    message("Skipping CrossRef validation: paper reference contains placeholder")
    return(invisible(list(valid = TRUE, issues = character(0), crossref_metadata = NULL)))
  }

  # Try to extract DOI
  doi <- sub("^https?://(dx\\.)?doi\\.org/", "", paper_ref)
  doi <- sub("^doi:", "", doi)

  # Fetch metadata from CrossRef
  api_url <- paste0("https://api.crossref.org/works/", doi)
  message("Fetching metadata from CrossRef: ", api_url)

  response <- tryCatch(
    httr::GET(api_url),
    error = function(e) {
      issues <<- c(issues, paste("Failed to connect to CrossRef API:", e$message))
      return(NULL)
    }
  )

  if (is.null(response)) {
    if (strict) {
      stop("Validation failed: Could not connect to CrossRef API")
    }
    return(invisible(list(valid = FALSE, issues = issues, crossref_metadata = NULL)))
  }

  if (httr::status_code(response) != 200) {
    msg <- paste0("CrossRef API returned status code ", httr::status_code(response),
                  " for DOI: ", doi)
    issues <- c(issues, msg)
    if (strict) {
      stop("Validation failed: ", msg)
    }
    return(invisible(list(valid = FALSE, issues = issues, crossref_metadata = NULL)))
  }

  crossref_meta <- httr::content(response, "parsed")$message

  # Validate title
  if (!is.null(local_meta$paper$title) && !is.null(crossref_meta$title)) {
    local_title <- tolower(trimws(local_meta$paper$title))
    # CrossRef returns title as a list, take first element
    crossref_title <- tolower(trimws(crossref_meta$title[[1]]))

    # Remove common differences (punctuation, extra spaces)
    local_title_clean <- gsub("[[:punct:]]", "", gsub("\\s+", " ", local_title))
    crossref_title_clean <- gsub("[[:punct:]]", "", gsub("\\s+", " ", crossref_title))

    if (local_title_clean != crossref_title_clean) {
      issue <- paste0("Title mismatch:\n",
                     "  Local:    ", local_meta$paper$title, "\n",
                     "  CrossRef: ", crossref_meta$title[[1]])
      issues <- c(issues, issue)
      warning(issue)
    } else {
      message("\u2713 Title matches CrossRef metadata")
    }
  }

  # Validate authors
  if (!is.null(local_meta$paper$authors) && !is.null(crossref_meta$author)) {
    local_authors <- local_meta$paper$authors
    crossref_authors <- crossref_meta$author

    # Check author count
    if (length(local_authors) != length(crossref_authors)) {
      issue <- paste0("Author count mismatch: local has ", length(local_authors),
                     " authors, CrossRef has ", length(crossref_authors), " authors")
      issues <- c(issues, issue)
      warning(issue)
    }

    # Compare each author
    for (i in seq_along(local_authors)) {
      if (i > length(crossref_authors)) break

      local_author <- local_authors[[i]]
      crossref_author <- crossref_authors[[i]]

      # Build full name from CrossRef
      crossref_name <- paste(
        if (!is.null(crossref_author$given)) crossref_author$given else "",
        if (!is.null(crossref_author$family)) crossref_author$family else ""
      )
      crossref_name <- trimws(crossref_name)

      # Compare names (case-insensitive)
      if (!is.null(local_author$name)) {
        local_name_clean <- tolower(trimws(local_author$name))
        crossref_name_clean <- tolower(trimws(crossref_name))

        # Allow for different name formats (e.g., "John Smith" vs "Smith, John")
        # Just check if key parts are present
        local_parts <- strsplit(local_name_clean, "\\s+")[[1]]
        crossref_parts <- strsplit(crossref_name_clean, "\\s+")[[1]]

        # Check if all significant parts match (at least 2 characters)
        local_parts_sig <- local_parts[nchar(local_parts) >= 2]
        crossref_parts_sig <- crossref_parts[nchar(crossref_parts) >= 2]

        if (!all(local_parts_sig %in% crossref_parts_sig) &&
            !all(crossref_parts_sig %in% local_parts_sig)) {
          issue <- paste0("Author ", i, " name mismatch:\n",
                         "  Local:    ", local_author$name, "\n",
                         "  CrossRef: ", crossref_name)
          issues <- c(issues, issue)
          warning(issue)
        } else {
          message("\u2713 Author ", i, " name matches: ", local_author$name)
        }
      }

      # Compare ORCIDs if checking is enabled
      if (check_orcids && !is.null(local_author$ORCID)) {
        if (!is.null(crossref_author$ORCID)) {
          # Normalize ORCIDs (remove URL prefix if present)
          local_orcid <- sub("^https?://orcid\\.org/", "", local_author$ORCID)
          crossref_orcid <- sub("^https?://orcid\\.org/", "", crossref_author$ORCID)

          if (local_orcid != crossref_orcid) {
            issue <- paste0("Author ", i, " ORCID mismatch:\n",
                           "  Local:    ", local_orcid, "\n",
                           "  CrossRef: ", crossref_orcid)
            issues <- c(issues, issue)
            warning(issue)
          } else {
            message("\u2713 Author ", i, " ORCID matches: ", local_orcid)
          }
        } else {
          msg <- paste0("Author ", i, " has ORCID in local file but not in CrossRef")
          message("\u2139 ", msg)
        }
      }
    }
  }

  # Final validation result
  valid <- length(issues) == 0

  if (!valid) {
    message("\n\u26a0 Validation completed with ", length(issues), " issue(s)")
    if (strict) {
      stop("Validation failed with ", length(issues), " issue(s):\n",
           paste(issues, collapse = "\n"))
    }
  } else {
    message("\n\u2713 All validations passed!")
  }

  invisible(list(
    valid = valid,
    issues = issues,
    crossref_metadata = crossref_meta
  ))
}


##' Validate codecheck.yml metadata against ORCID
##'
##' Validates author and codechecker information against the ORCID API.
##' For each person with an ORCID, retrieves their ORCID record and compares
##' the name in the ORCID record with the name in the local codecheck.yml file.
##'
##' Note: This function requires access to the ORCID API. If you encounter
##' authentication issues, you can either:
##' \itemize{
##'   \item Set the \code{ORCID_TOKEN} environment variable with your ORCID token
##'   \item Run \code{rorcid::orcid_auth()} to authenticate interactively
##'   \item Set \code{skip_on_auth_error = TRUE} to skip validation if authentication fails
##' }
##'
##' @title Validate codecheck.yml metadata against ORCID
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param strict Logical. If \code{TRUE}, throw an error on any mismatch.
##'   If \code{FALSE} (default), only issue warnings.
##' @param validate_authors Logical. If \code{TRUE} (default), validate author ORCIDs.
##' @param validate_codecheckers Logical. If \code{TRUE} (default), validate codechecker ORCIDs.
##' @param skip_on_auth_error Logical. If \code{TRUE}, skip validation when ORCID
##'   authentication fails instead of throwing an error. Default is \code{FALSE},
##'   which requires ORCID authentication. Set to \code{TRUE} to allow the function
##'   to work without ORCID authentication (e.g., CI/CD pipelines, test environments).
##' @return Invisibly returns a list with validation results:
##'   \describe{
##'     \item{valid}{Logical indicating if all checks passed}
##'     \item{issues}{Character vector of any issues found}
##'     \item{skipped}{Logical indicating if validation was skipped due to auth issues}
##'   }
##' @author Daniel Nuest
##' @importFrom rorcid orcid_person
##' @export
##' @examples
##' \dontrun{
##'   # Validate with warnings only (requires ORCID authentication)
##'   result <- validate_codecheck_yml_orcid()
##'
##'   # Validate with strict error checking
##'   validate_codecheck_yml_orcid(strict = TRUE)
##'
##'   # Validate only codecheckers
##'   validate_codecheck_yml_orcid(validate_authors = FALSE)
##'
##'   # Skip ORCID validation if authentication is not available
##'   validate_codecheck_yml_orcid(skip_on_auth_error = TRUE)
##' }
validate_codecheck_yml_orcid <- function(yml_file = "codecheck.yml",
                                         strict = FALSE,
                                         validate_authors = TRUE,
                                         validate_codecheckers = TRUE,
                                         skip_on_auth_error = FALSE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file)
  }

  # Read local metadata
  local_meta <- yaml::read_yaml(yml_file)

  issues <- character(0)
  validation_skipped <- FALSE

  # Helper function to normalize names for comparison
  normalize_name <- function(name) {
    tolower(trimws(gsub("\\s+", " ", name)))
  }

  # Helper function to extract name from ORCID record
  get_orcid_name <- function(orcid_id) {
    tryCatch({
      # Query ORCID API
      person_data <- rorcid::orcid_person(orcid_id)

      if (is.null(person_data) || length(person_data) == 0) {
        return(NULL)
      }

      # Extract name from nested structure
      name_data <- person_data[[1]]$name

      if (is.null(name_data)) {
        return(NULL)
      }

      # Try to get given and family names
      given_names <- name_data$`given-names`$value
      family_name <- name_data$`family-name`$value

      if (!is.null(given_names) && !is.null(family_name)) {
        return(paste(given_names, family_name))
      } else if (!is.null(family_name)) {
        return(family_name)
      } else if (!is.null(given_names)) {
        return(given_names)
      }

      return(NULL)
    }, error = function(e) {
      error_msg <- conditionMessage(e)

      # Check if this is an authentication error
      if (grepl("Unauthorized|401|authentication|token", error_msg, ignore.case = TRUE)) {
        if (skip_on_auth_error) {
          validation_skipped <<- TRUE
          message("\u2139 ORCID authentication required but not available. Skipping validation for ", orcid_id)
          message("  To enable ORCID validation, set ORCID_TOKEN environment variable or run rorcid::orcid_auth()")
          return("AUTH_ERROR")
        } else {
          stop("ORCID authentication failed for ", orcid_id, ": ", error_msg,
               "\n  Set ORCID_TOKEN environment variable or run rorcid::orcid_auth() to authenticate.",
               "\n  Or set skip_on_auth_error = TRUE to skip validation when authentication fails.")
        }
      }

      warning("Failed to retrieve ORCID record for ", orcid_id, ": ", error_msg)
      return(NULL)
    })
  }

  # Validate authors
  if (validate_authors && !is.null(local_meta$paper$authors)) {
    message("Validating author ORCIDs...")

    for (i in seq_along(local_meta$paper$authors)) {
      author <- local_meta$paper$authors[[i]]

      if (!is.null(author$ORCID)) {
        # Validate ORCID format
        orcid_regex <- "^(\\d{4}\\-\\d{4}\\-\\d{4}\\-\\d{3}(\\d|X))$"
        if (!grepl(orcid_regex, author$ORCID, perl = TRUE)) {
          issue <- paste0("Author ", i, " has invalid ORCID format: ", author$ORCID,
                         " (should be NNNN-NNNN-NNNN-NNNX)")
          issues <- c(issues, issue)
          warning(issue)
          next
        }

        # Query ORCID for name
        orcid_name <- get_orcid_name(author$ORCID)

        # Skip this author if authentication failed and we're in skip mode
        if (!is.null(orcid_name) && orcid_name == "AUTH_ERROR") {
          next
        }

        if (!is.null(orcid_name)) {
          local_name_norm <- normalize_name(author$name)
          orcid_name_norm <- normalize_name(orcid_name)

          # Compare names - check if key parts match
          local_parts <- strsplit(local_name_norm, "\\s+")[[1]]
          orcid_parts <- strsplit(orcid_name_norm, "\\s+")[[1]]

          # Filter to significant parts (at least 2 characters)
          local_parts_sig <- local_parts[nchar(local_parts) >= 2]
          orcid_parts_sig <- orcid_parts[nchar(orcid_parts) >= 2]

          if (!all(local_parts_sig %in% orcid_parts_sig) &&
              !all(orcid_parts_sig %in% local_parts_sig)) {
            issue <- paste0("Author ", i, " name mismatch with ORCID record:\n",
                           "  Local:  ", author$name, "\n",
                           "  ORCID:  ", orcid_name, "\n",
                           "  (ORCID: ", author$ORCID, ")")
            issues <- c(issues, issue)
            warning(issue)
          } else {
            message("\u2713 Author ", i, " name matches ORCID: ", author$name, " (", author$ORCID, ")")
          }
        } else {
          message("\u2139 Could not retrieve ORCID record for author ", i, ": ", author$ORCID)
        }
      }
    }
  }

  # Validate codecheckers
  if (validate_codecheckers) {
    if (is.null(local_meta$codechecker) || length(local_meta$codechecker) == 0) {
      issue <- "No codechecker information found in codecheck.yml"
      issues <- c(issues, issue)
      warning(issue)
    } else {
      message("Validating codechecker information...")

      for (i in seq_along(local_meta$codechecker)) {
        checker <- local_meta$codechecker[[i]]

        # Check if name exists
        if (is.null(checker$name) || trimws(checker$name) == "") {
          issue <- paste0("Codechecker ", i, " is missing a name")
          issues <- c(issues, issue)
          warning(issue)
          next
        }

        message("\u2713 Codechecker ", i, ": ", checker$name)

        # Validate ORCID if present
        if (!is.null(checker$ORCID)) {
          # Validate ORCID format
          orcid_regex <- "^(\\d{4}\\-\\d{4}\\-\\d{4}\\-\\d{3}(\\d|X))$"
          if (!grepl(orcid_regex, checker$ORCID, perl = TRUE)) {
            issue <- paste0("Codechecker ", i, " has invalid ORCID format: ", checker$ORCID,
                           " (should be NNNN-NNNN-NNNN-NNNX)")
            issues <- c(issues, issue)
            warning(issue)
            next
          }

          # Query ORCID for name
          orcid_name <- get_orcid_name(checker$ORCID)

          # Skip this codechecker if authentication failed and we're in skip mode
          if (!is.null(orcid_name) && orcid_name == "AUTH_ERROR") {
            next
          }

          if (!is.null(orcid_name)) {
            local_name_norm <- normalize_name(checker$name)
            orcid_name_norm <- normalize_name(orcid_name)

            # Compare names
            local_parts <- strsplit(local_name_norm, "\\s+")[[1]]
            orcid_parts <- strsplit(orcid_name_norm, "\\s+")[[1]]

            local_parts_sig <- local_parts[nchar(local_parts) >= 2]
            orcid_parts_sig <- orcid_parts[nchar(orcid_parts) >= 2]

            if (!all(local_parts_sig %in% orcid_parts_sig) &&
                !all(orcid_parts_sig %in% local_parts_sig)) {
              issue <- paste0("Codechecker ", i, " name mismatch with ORCID record:\n",
                             "  Local:  ", checker$name, "\n",
                             "  ORCID:  ", orcid_name, "\n",
                             "  (ORCID: ", checker$ORCID, ")")
              issues <- c(issues, issue)
              warning(issue)
            } else {
              message("\u2713 Codechecker ", i, " ORCID matches: ", checker$name, " (", checker$ORCID, ")")
            }
          } else {
            message("\u2139 Could not retrieve ORCID record for codechecker ", i, ": ", checker$ORCID)
          }
        }
      }
    }
  }

  # Final validation result
  valid <- length(issues) == 0

  if (validation_skipped) {
    message("\n\u2139 ORCID validation skipped due to authentication issues")
    message("  Set ORCID_TOKEN environment variable or run rorcid::orcid_auth() to enable ORCID validation")
  } else if (!valid) {
    message("\n\u26a0 ORCID validation completed with ", length(issues), " issue(s)")
    if (strict) {
      stop("ORCID validation failed with ", length(issues), " issue(s):\n",
           paste(issues, collapse = "\n"))
    }
  } else {
    message("\n\u2713 All ORCID validations passed!")
  }

  invisible(list(
    valid = valid,
    issues = issues,
    skipped = validation_skipped
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
##'   If \code{FALSE} (default), only issue warnings.
##' @param validate_crossref Logical. If \code{TRUE} (default), validate against CrossRef.
##' @param validate_orcid Logical. If \code{TRUE} (default), validate against ORCID.
##' @param check_orcids Logical. If \code{TRUE} (default), validate ORCID identifiers in CrossRef check.
##' @param skip_on_auth_error Logical. If \code{TRUE}, skip ORCID validation
##'   when authentication fails instead of throwing an error. Default is \code{FALSE},
##'   which requires ORCID authentication. Set to \code{TRUE} to allow the function
##'   to work without ORCID authentication (e.g., CI/CD pipelines, test environments).
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
##'
##'   # Skip ORCID validation if authentication is not available
##'   validate_contents_references(skip_on_auth_error = TRUE)
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
      strict = FALSE,  # Don't stop on CrossRef errors if we still need to run ORCID
      check_orcids = check_orcids
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
      strict = FALSE,  # Don't stop yet
      skip_on_auth_error = skip_on_auth_error
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

    if (strict) {
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
##' placeholders and prints a LaTeX warning box with a warning icon if they are.
##' Intended for use in R Markdown templates to alert users about placeholder
##' certificates and DOIs.
##'
##' @title Validate certificate for rendering with visual warning
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param metadata Optional metadata list. If NULL (default), loads from yml_file.
##' @param strict Logical. If TRUE and certificate or DOI is a placeholder, stops execution.
##'   Default is FALSE (displays warning but continues).
##' @param display_warning Logical. If TRUE (default), displays a warning box in
##'   the rendered output when certificate or DOI is a placeholder.
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
                                               display_warning = TRUE) {
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

  # Check if any placeholder found
  is_placeholder <- has_cert_placeholder || has_doi_placeholder

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
