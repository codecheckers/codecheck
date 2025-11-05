##' Retrieve metadata from Lifecycle Journal via CrossRef API
##'
##' Fetches article metadata from the Lifecycle Journal using either a
##' submission ID or a DOI. The metadata includes title, authors with ORCIDs,
##' abstract, and publication date.
##'
##' @title Retrieve metadata from Lifecycle Journal
##' @param identifier Either a Lifecycle Journal submission ID (e.g., "10", "7")
##'   or a full DOI (e.g., "10.71240/lcyc.355146"). If the identifier doesn't
##'   contain a dot, it's treated as a submission ID and converted to a DOI.
##' @return A list containing parsed metadata with elements:
##'   \describe{
##'     \item{title}{Article title}
##'     \item{authors}{List of authors, each with \code{name} and optionally \code{ORCID}}
##'     \item{abstract}{Article abstract (if available)}
##'     \item{reference}{The DOI URL}
##'     \item{date}{Publication date}
##'   }
##' @author Daniel Nüst
##' @importFrom httr GET content status_code
##' @importFrom jsonlite fromJSON
##' @export
##' @examples
##' \dontrun{
##'   # Using submission ID
##'   meta <- get_lifecycle_metadata("10")
##'
##'   # Using full DOI
##'   meta <- get_lifecycle_metadata("10.71240/lcyc.355146")
##' }
get_lifecycle_metadata <- function(identifier) {
  # Convert submission ID to DOI if needed
  if (!grepl("\\.", identifier)) {
    doi <- paste0("10.71240/lcyc.", identifier)
    message("Converting submission ID to DOI: ", doi)
  } else if (grepl("^10\\.71240/lcyc\\.", identifier)) {
    doi <- identifier
  } else {
    stop("Identifier must be either a Lifecycle Journal submission ID or a DOI starting with 10.71240/lcyc.")
  }

  # Fetch metadata from CrossRef API
  api_url <- paste0("https://api.crossref.org/works/", doi)
  message("Fetching metadata from CrossRef: ", api_url)

  response <- httr::GET(api_url)

  if (httr::status_code(response) != 200) {
    stop("Failed to retrieve metadata from CrossRef. Status code: ",
         httr::status_code(response),
         "\nPlease check that the identifier is correct.")
  }

  data <- httr::content(response, "parsed")$message

  # Parse authors with ORCIDs
  authors <- lapply(data$author, function(author) {
    author_data <- list(name = paste(author$given, author$family))

    # Extract ORCID if available
    if (!is.null(author$ORCID)) {
      # Remove the URL prefix if present, keep only the ID
      orcid <- sub("^https?://orcid\\.org/", "", author$ORCID)
      author_data$ORCID <- orcid
    }

    author_data
  })

  # Extract abstract if available
  abstract <- if (!is.null(data$abstract)) {
    # Remove XML tags that might be present
    gsub("<[^>]+>", "", data$abstract)
  } else {
    NULL
  }

  # Build the metadata list
  metadata <- list(
    title = data$title[[1]],
    authors = authors,
    reference = paste0("https://doi.org/", doi),
    date = data$created$`date-parts`[[1]]
  )

  if (!is.null(abstract)) {
    metadata$abstract <- abstract
  }

  metadata
}


##' Update codecheck.yml with Lifecycle Journal metadata
##'
##' Updates the local codecheck.yml file with metadata retrieved from the
##' Lifecycle Journal. By default, shows a diff of what would be changed
##' without actually modifying the file. Use \code{apply_updates = TRUE} to
##' apply the changes.
##'
##' @title Update codecheck.yml with Lifecycle Journal metadata
##' @param identifier Either a Lifecycle Journal submission ID or DOI
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param apply_updates Logical. If \code{TRUE}, actually update the file.
##'   If \code{FALSE} (default), only show what would be changed.
##' @param overwrite_existing Logical. If \code{TRUE}, overwrite existing
##'   non-empty fields. If \code{FALSE} (default), only populate empty or
##'   placeholder fields.
##' @return Invisibly returns the updated metadata list
##' @author Daniel Nüst
##' @importFrom yaml read_yaml write_yaml
##' @export
##' @examples
##' \dontrun{
##'   # Preview changes without applying them
##'   update_codecheck_yml_from_lifecycle("10")
##'
##'   # Apply changes to the file
##'   update_codecheck_yml_from_lifecycle("10", apply_updates = TRUE)
##'
##'   # Overwrite existing fields
##'   update_codecheck_yml_from_lifecycle("10", apply_updates = TRUE,
##'                                        overwrite_existing = TRUE)
##' }
update_codecheck_yml_from_lifecycle <- function(identifier,
                                                 yml_file = "codecheck.yml",
                                                 apply_updates = FALSE,
                                                 overwrite_existing = FALSE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file,
         "\nPlease create it first using create_codecheck_files().")
  }

  # Read existing metadata
  existing <- yaml::read_yaml(yml_file)

  # Fetch Lifecycle metadata
  lifecycle_meta <- get_lifecycle_metadata(identifier)

  # Create a copy for updates
  updated <- existing

  # Track changes
  changes <- list()

  # Helper function to check if a field should be updated
  should_update <- function(current_value) {
    if (overwrite_existing) {
      return(TRUE)
    }
    # Update if empty, NULL, or contains placeholder text
    is.null(current_value) ||
      identical(current_value, "") ||
      grepl("FIXME|TODO|template|example", current_value, ignore.case = TRUE)
  }

  # Update title
  if (should_update(existing$paper$title)) {
    changes$title <- list(
      old = existing$paper$title,
      new = lifecycle_meta$title
    )
    updated$paper$title <- lifecycle_meta$title
  }

  # Update authors
  if (should_update(existing$paper$authors) || length(existing$paper$authors) == 0) {
    changes$authors <- list(
      old = existing$paper$authors,
      new = lifecycle_meta$authors
    )
    updated$paper$authors <- lifecycle_meta$authors
  }

  # Update reference
  if (should_update(existing$paper$reference)) {
    changes$reference <- list(
      old = existing$paper$reference,
      new = lifecycle_meta$reference
    )
    updated$paper$reference <- lifecycle_meta$reference
  }

  # Print diff
  if (length(changes) > 0) {
    cat("\n")
    cat("=" , rep("=", 78), "\n", sep = "")
    cat("CHANGES TO BE APPLIED TO ", yml_file, "\n", sep = "")
    cat("=" , rep("=", 78), "\n", sep = "")
    cat("\n")

    for (field_name in names(changes)) {
      cat("Field: ", field_name, "\n", sep = "")
      cat(rep("-", 80), "\n", sep = "")
      cat("OLD:\n")
      if (field_name == "authors") {
        for (i in seq_along(changes[[field_name]]$old)) {
          author <- changes[[field_name]]$old[[i]]
          cat("  - name: ", author$name, "\n", sep = "")
          if (!is.null(author$ORCID)) {
            cat("    ORCID: ", author$ORCID, "\n", sep = "")
          }
        }
      } else {
        cat("  ", changes[[field_name]]$old, "\n", sep = "")
      }

      cat("\nNEW:\n")
      if (field_name == "authors") {
        for (i in seq_along(changes[[field_name]]$new)) {
          author <- changes[[field_name]]$new[[i]]
          cat("  - name: ", author$name, "\n", sep = "")
          if (!is.null(author$ORCID)) {
            cat("    ORCID: ", author$ORCID, "\n", sep = "")
          }
        }
      } else {
        cat("  ", changes[[field_name]]$new, "\n", sep = "")
      }
      cat("\n")
    }

    cat("=" , rep("=", 78), "\n", sep = "")

    if (apply_updates) {
      yaml::write_yaml(updated, yml_file)
      cat("\n✓ Changes applied to ", yml_file, "\n\n", sep = "")
    } else {
      cat("\n⚠ No changes applied. Use apply_updates = TRUE to save changes.\n\n")
    }
  } else {
    cat("\nNo changes needed. All fields are already populated.\n")
    cat("Use overwrite_existing = TRUE to force updates.\n\n")
  }

  invisible(updated)
}
