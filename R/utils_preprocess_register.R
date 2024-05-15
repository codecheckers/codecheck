#' Function for clearing the register cache
#'
#' @return 0 for success, 1 for failure, invisibly (see `unlink`)
#'
#' @author Daniel Nüst
#' @importFrom R.cache getCacheRootPath
#' @export
register_clear_cache <- function() {
  path <- R.cache::getCacheRootPath()
  message("Deleting cache path ", path)
  unlink(path, recursive = TRUE)
}

#' Function for adding clickable links to the repor for each entry in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return register_table

add_report_links <- function(register_table, register) {

  reports <- c()

  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml(register[i, ]$Repo)

    report <- NA
    if (!is.null(config_yml)) {
      report <- config_yml$report
    }

    reports <- c(reports, report)
  }
  register_table$Report <- reports
  return(register_table)
}

#' Function for adding clickable links to the issue number of each report in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return register_table

add_issue_number_links <- function(register_table, register) {
  register_table$Issue <- sapply(
    X = register$Issue,
    FUN = function(issue_id) {
      if (!is.na(issue_id)) {
        paste0(
          "[",
          issue_id,
          "](https://github.com/codecheckers/register/issues/",
          issue_id, ")"
        )
      } else {
        issue_id
      }
    }
  )
  return(register_table)
}

#' Function for adding check time to each report in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return register_table

add_check_time <- function(register_table, register) {
  check_times <- c()

  # Looping over the entries in the register
  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml(register[i, ]$Repo)

    check_time <- NA
    if (!is.null(config_yml)) {
      check_time <- config_yml$check_time
    }

    check_times <- c(check_times, check_time)
  }
  check_times <- parsedate::parse_date(check_times)
  register_table$`Check date` <- format(check_times, "%Y-%m-%d")

  return(register_table)
}

#' Function for preprocessing the register to create and return the register_table.
#' 
#' @param register_table The register table
#' @return register_table

preprocess_register <- function(register) {
    register_table <- register
    register_table <- add_report_links(register_table, register)
    register_table <- add_issue_number_links(register_table, register)
    register_table <- add_check_time(register_table, register)
    return(register_table)
}