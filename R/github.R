##' Update certificate ID from GitHub issue
##'
##' Automatically retrieves and updates the certificate identifier from a GitHub issue.
##' This function checks if the current certificate is a placeholder, searches for
##' matching GitHub issues, and if a unique match is found, updates the codecheck.yml
##' file with the certificate ID.
##'
##' The function provides detailed logging of all steps and will only update the file
##' if exactly one matching issue is found (to avoid ambiguity).
##'
##' @title Update certificate ID from GitHub issue
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param issue_state State of issues to search: "open" (default), "closed", or "all"
##' @param force Logical. If TRUE, update even if certificate is not a placeholder.
##'   Default is FALSE.
##' @param apply_update Logical. If TRUE, actually update the file. If FALSE (default),
##'   only show what would be changed.
##' @return Invisibly returns a list with:
##'   \describe{
##'     \item{updated}{Logical indicating if file was updated}
##'     \item{certificate}{The certificate ID (if found)}
##'     \item{issue_number}{The GitHub issue number (if found)}
##'     \item{was_placeholder}{Logical indicating if original was a placeholder}
##'   }
##' @author Daniel Nüst
##' @importFrom yaml read_yaml write_yaml
##' @export
##' @examples
##' \dontrun{
##'   # Preview what would be updated
##'   result <- update_certificate_from_github()
##'
##'   # Actually update the file
##'   update_certificate_from_github(apply_update = TRUE)
##'
##'   # Force update even if not a placeholder
##'   update_certificate_from_github(force = TRUE, apply_update = TRUE)
##' }
update_certificate_from_github <- function(yml_file = "codecheck.yml",
                                           issue_state = "open",
                                           force = FALSE,
                                           apply_update = FALSE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file)
  }

  # Load current metadata
  metadata <- yaml::read_yaml(yml_file)

  # Check if certificate is a placeholder
  is_placeholder <- is_placeholder_certificate(yml_file, metadata)

  message("\n", rep("=", 80))
  message("CERTIFICATE ID UPDATE FROM GITHUB")
  message(rep("=", 80))

  message("\nCurrent certificate ID: ", metadata$certificate)
  message("Is placeholder: ", is_placeholder)

  # Check if we should proceed
  if (!is_placeholder && !force) {
    message("\n⚠ Certificate ID is already set and is not a placeholder.")
    message("Use force = TRUE to update anyway.")
    message(rep("=", 80), "\n")

    return(invisible(list(
      updated = FALSE,
      certificate = metadata$certificate,
      issue_number = NULL,
      was_placeholder = is_placeholder
    )))
  }

  # Try to retrieve certificate from GitHub
  message("\nSearching for certificate in GitHub issues...")
  message("Issue state: ", issue_state)

  result <- tryCatch({
    get_certificate_from_github_issue(yml_file, state = issue_state)
  }, error = function(e) {
    message("✖ Error retrieving from GitHub: ", e$message)
    return(NULL)
  })

  # Check if we found a result
  if (is.null(result)) {
    message("\n✖ No certificate found in GitHub issues")
    message(rep("=", 80), "\n")

    return(invisible(list(
      updated = FALSE,
      certificate = NULL,
      issue_number = NULL,
      was_placeholder = is_placeholder
    )))
  }

  # Check if we have a certificate
  if (is.null(result$certificate)) {
    message("\n✖ No certificate ID found in matching issues")
    if (!is.null(result$message)) {
      message("Reason: ", result$message)
    }
    message(rep("=", 80), "\n")

    return(invisible(list(
      updated = FALSE,
      certificate = NULL,
      issue_number = result$issue_number,
      was_placeholder = is_placeholder
    )))
  }

  # We have a certificate!
  message("\n✓ Found certificate: ", result$certificate)
  message("  Issue #", result$issue_number, ": ", result$title)
  if (!is.null(result$matched_author)) {
    message("  Matched author: ", result$matched_author)
  }

  # Show the change
  message("\n", rep("-", 80))
  message("PROPOSED CHANGE")
  message(rep("-", 80))
  message("OLD certificate: ", metadata$certificate)
  message("NEW certificate: ", result$certificate)
  message(rep("-", 80))

  # Apply update if requested
  if (apply_update) {
    message("\nUpdating codecheck.yml...")

    # Update the certificate in metadata
    metadata$certificate <- result$certificate

    # Write back to file
    tryCatch({
      yaml::write_yaml(metadata, yml_file)
      message("✓ Successfully updated ", yml_file)
      message("  Certificate ID: ", result$certificate)
      message("  From GitHub issue #", result$issue_number)

      updated <- TRUE
    }, error = function(e) {
      message("✖ Failed to write file: ", e$message)
      updated <- FALSE
    })
  } else {
    message("\n⚠ No changes applied. Use apply_update = TRUE to save changes.")
    updated <- FALSE
  }

  message(rep("=", 80), "\n")

  invisible(list(
    updated = updated,
    certificate = result$certificate,
    issue_number = result$issue_number,
    was_placeholder = is_placeholder
  ))
}
