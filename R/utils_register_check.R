#' Function for checking ceritificate id if there is a codecheck_yaml.
#' If there is a mismatch a stop is sent. Else a warning is thrown.
#' 
#' @param codecheck_yaml The codecheck yaml file
#' @param entry The registry entry
#' @return None
check_certificate_id <- function(entry, codecheck_yaml) {
  # Codecheck.yml found, proceeding to check certificate id
  if (!is.null(codecheck_yaml)) {
    # validate config file
    validate_codecheck_yml(codecheck_yaml)

    # check certificate ID
    if (entry$Certificate != codecheck_yaml$certificate) {
      stop(
        "Certificate mismatch, register: ", entry$Certificate,
        " vs. repo ", codecheck_yaml$certificate
      )
    }
  }

  # Codecheck.yml not found, throwing warning
  else {
    warning(entry$Certificate, " does not have a codecheck.yml file")
  }
}

#' Check that a repository is in the codecheckers/cdchck organisation
#'
#' A pure string check on the repository spec, no network call: registry
#' policy requires the checked repository to live in the `codecheckers`
#' GitHub organisation or the `cdchck` GitLab group (the same rule already
#' enforced for Zenodo records, see `check_register_zenodo_policy()`). A
#' violation stops the check for this entry, it is not a hint to fix later.
#'
#' @param entry The registry entry
#' @param spec The parsed repository spec, see `parse_repository_spec()`
#' @return None
check_repository_org <- function(entry, spec) {
  if (spec[["type"]] == "github") {
    org <- split_github_repo_spec(spec[["repo"]])$org
    if (!identical(org, "codecheckers")) {
      stop(entry$Certificate, " repository is not in the codecheckers GitHub organisation: ",
           spec[["repo"]])
    }
  } else if (spec[["type"]] == "gitlab") {
    group <- strsplit(spec[["repo"]], "/", fixed = TRUE)[[1]][[1]]
    if (!identical(group, "cdchck")) {
      stop(entry$Certificate, " repository is not in the cdchck GitLab group: ",
           spec[["repo"]])
    }
  }
}

#' Check that a repository is archived
#'
#' The checked repository should be archived (read-only) once the check is
#' complete, see codecheckers/codecheck#25. Only applies to GitHub/GitLab
#' repositories; a lookup failure degrades to a no-op rather than aborting the
#' whole register check.
#'
#' @param entry The registry entry
#' @param spec The parsed repository spec, see `parse_repository_spec()`
#' @return None
check_repository_archived <- function(entry, spec) {
  metadata <- switch(spec[["type"]],
    "github" = get_github_repo_metadata(spec[["repo"]]),
    "gitlab" = get_gitlab_project_metadata(spec[["repo"]]),
    NULL
  )

  if (is.null(metadata)) {
    return(invisible(NULL))
  }

  if (identical(metadata$archived, FALSE)) {
    warning(entry$Certificate, " repository is not archived: ", spec[["repo"]])
  }
}

#' Check that a repository advertises the CODECHECK badge
#'
#' The community workflow asks codecheckers to add a CODECHECK badge to the
#' original repository, see codecheckers/codecheck#75. A missing badge is
#' informational only, not a defect, so this reports via `cli::cli_alert_info()`
#' rather than `warning()`.
#'
#' @param entry The registry entry
#' @param spec The parsed repository spec, see `parse_repository_spec()`
#' @return None
check_repository_badge <- function(entry, spec) {
  readme <- switch(spec[["type"]],
    "github" = get_github_readme_raw(spec[["repo"]]),
    "gitlab" = get_gitlab_readme_raw(spec[["repo"]]),
    NULL
  )

  if (is.null(readme)) {
    return(invisible(NULL))
  }

  badge_markers <- c("codeworks-badge", "codecheck-badge", "codecheck.org.uk/img")
  if (!any(sapply(badge_markers, grepl, x = readme, fixed = TRUE))) {
    cli::cli_alert_info("{entry$Certificate} repository does not yet have a CODECHECK badge: {spec[['repo']]}")
  }
}

#' Check that a repository has a license
#'
#' Not required by the CODECHECK spec, but good practice, see the TODO in
#' `register_check()`. Informational only.
#'
#' @param entry The registry entry
#' @param spec The parsed repository spec, see `parse_repository_spec()`
#' @return None
check_repository_license <- function(entry, spec) {
  metadata <- switch(spec[["type"]],
    "github" = get_github_repo_metadata(spec[["repo"]]),
    "gitlab" = get_gitlab_project_metadata(spec[["repo"]]),
    NULL
  )

  if (is.null(metadata)) {
    return(invisible(NULL))
  }

  if (is.null(metadata$license)) {
    cli::cli_alert_info("{entry$Certificate} repository has no license: {spec[['repo']]}")
  }
}

#' Function issue status. If the issue is not closed a warning is thrown
#' stating that the issue is still open.
#'
#' @param entry The codecheck entry
#' @return None
check_issue_status <- function(entry) {
  if (!is.na(entry$Issue)) {
    # get the status and labels from an issue
    issue <- gh::gh("GET /repos/codecheckers/:repo/issues/:issue",
      repo = "register",
      issue = entry$Issue
    )
    if (issue$state != "closed") {
      warning(
        entry$Certificate, " issue is still open: <",
        CONFIG$HYPERLINKS[["codecheck_issue"]],
        entry$Issue, ">"
      )
    }
  }
}
