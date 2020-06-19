#' Function for clearing the register cache
#' 
#' @return 0 for success, 1 for failure, invisibly (see `unlink`)
#' 
#' @importFrom R.cache getCacheRootPath
#' @export
register_clear_cache <- function() {
  unlink(R.cache::getCacheRootPath())
}

#' Function for rendering the register into different view
#' 
#' NOTE: You should put a GitHub API token inth the environment variable `GITHUB_PAT` to fix rate limits. Acquire one at see https://github.com/settings/tokens.
#'
#' - `.html`
#' - `.md``
#' 
#' @param register_table A `data.frame` with all required information for the register's view
#' @param outputs The output formats to create
#' 
#' @return A `data.frame` of the register enriched with information from the configuration files of respective CODECHECKs from the online repositories
#' 
#' @importFrom parsedate parse_date
#' @importFrom rmarkdown render
#' @importFrom knitr kable
#' @importFrom utils capture.output read.csv
#' 
#' @export
register_render <- function(register = read.csv("register.csv", as.is = TRUE),
                            outputs = c("html", "md", "json")) {
  register_table <- register
  
  # add report links if available
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
  
  # turn IDs into links for table rendering
  register_table$Issue <- sapply(X = register$Issue,
                                 FUN = function(issue_id) {
                                   if (!is.na(issue_id)) {
                                     paste0("[",
                                            issue_id,
                                            "](https://github.com/codecheckers/register/issues/",
                                            issue_id, ")")
                                   } else {
                                     issue_id
                                   }
                                 })
  
  check_times <- c()
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
  
  if("md" %in% outputs) {
    capture.output(
      cat("---\ntitle: CODECHECK Register\n---"),
      knitr::kable(register_table, format = "markdown"),
      file = "register.md"
    )
    # hack to reduce colum width of 4th column
    md_table <- readLines("register.md")
    md_table[6] <- "|:-----------|:--------------------------|:---------------------|:---|:--------------------------------------|:----------|"
    writeLines(md_table, "docs/register.md")
    file.remove("register.md")
    # TODO: fix table colum width, e.g. via using a register.Rmd with kableExtra
  }
  
  # render register to HTML
  if("html" %in% outputs) {
    rmarkdown::render(input = "docs/register.md",
                      # next paths are relative to input file
                      output_yaml = "html_document.yml",
                      output_file = "index.html")
  }
  
  # render register to JSON
  if("json" %in% outputs) {
    # get paper titles
    titles <- c()
    for (i in seq_len(nrow(register))) {
      config_yml <- get_codecheck_yml(register[i, ]$Repo)
      
      title <- NA
      if (!is.null(config_yml)) {
        title <- config_yml$paper$title
      }
      
      titles <- c(titles, title)
    }
    
    # get paper titles
    titles <- c()
    for (i in seq_len(nrow(register))) {
      config_yml <- get_codecheck_yml(register[i, ]$Repo)
      
      title <- NA
      if (!is.null(config_yml)) {
        title <- config_yml$paper$title
      }
      
      titles <- c(titles, title)
    }
    register_table$Title <- stringr::str_trim(titles)
    
    jsonlite::write_json(register_table[, c(
      "Certificate",
      "Repository",
      "Type",
      "Report",
      "Title",
      "Check date")],
      path = "docs/register.json",
      pretty = TRUE)
  }
  
  return(register_table)
}

#' Function for checking all entries in the register
#' 
#' This functions starts of a `data.frame` read from the local register file.
#' 
#' Futher test ideas:
#' 
#' - Does the repo have a LICENSE?
#' 
#' @param register_table A `data.frame` with all required information for the register's view
#' 
#' @importFrom gh gh
#' @export
register_check <- function(register = read.csv("register.csv", as.is = TRUE)) {
  for (i in seq_len(nrow(register))) {
    cat("Checking", toString(register[i, ]), "\n")
    entry <- register[i, ]
    
    # check certificate IDs if there is a codecheck.yml
    codecheck_yaml <- get_codecheck_yml(entry$Repository)
    if (!is.null(codecheck_yaml)) {
      if (entry$Certificate != codecheck_yaml$certificate) {
        stop("Certificate mismatch, register: ", entry$Certificate,
             " vs. repo ", codecheck_yaml$certificate)
      }
      
      if (is.null(codecheck_yaml$report)) {
        warning("Report mis missing for ", entry$Certificate)
      }
    } else {
      warning(entry$Certificate, " does not have a codecheck.yml file")
    }
    
    # check issue status
    if (!is.na(entry$Issue)) {
      # get the status and labels from an issue
      issue <- gh::gh("GET /repos/codecheckers/:repo/issues/:issue",
                      repo = "register",
                      issue = entry$Issue)
      issue$state
      issue$labels
      if (issue$state != "closed") {
        warning(entry$Certificate, " issue is still open: ",
                "<https://github.com/codecheckers/register/issues/",
                entry$Issue, ">")
      }
    }
  }
}
