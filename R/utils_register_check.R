#' Function for checking ceritificate id if there is a codecheck_yaml.
#' If there is a mismatch a stop is sent. Else a warning is thrown.
#' 
#' @param codecheck_yaml The codecheck yaml file
#' @return None
check_certificate_id <- function(codecheck_yaml) {
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
        entry$Certificate, " issue is still open: ",
        "<https://github.com/codecheckers/register/issues/",
        entry$Issue, ">"
      )
    }
  }
}
