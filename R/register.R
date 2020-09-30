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

#' Function for rendering the register into different view
#' 
#' NOTE: You should put a GitHub API token inth the environment variable `GITHUB_PAT` to fix rate limits. Acquire one at see https://github.com/settings/tokens.
#'
#' - `.html`
#' - `.md``
#' 
#' @param register A `data.frame` with all required information for the register's view
#' @param outputs The output formats to create
#' 
#' @return A `data.frame` of the register enriched with information from the configuration files of respective CODECHECKs from the online repositories
#' 
#' @author Daniel Nüst
#' @importFrom parsedate parse_date
#' @importFrom rmarkdown render
#' @importFrom knitr kable
#' @importFrom utils capture.output read.csv
#' @import     jsonlite 
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
  
  # turn issue numbers into links for table rendering
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

  # turn repositories into links for table rendering
  register_table$Repository <- sapply(X = register$Repository,
                                 FUN = function(repository) {
                                   spec <- parse_repository_spec(repository)
                                   
                                   if (!any(is.na(spec))) {
                                     urrl <- "#"
                                     
                                     if (spec[["type"]] == "github") {
                                       urrl <- paste0("https://github.com/", spec[["repo"]])
                                       paste0("[", spec[["repo"]], "](", urrl, ")")
                                     } else if (spec[["type"]] == "osf") {
                                       urrl <- paste0("https://osf.io/", spec[["repo"]])
                                       paste0("[", spec[["repo"]], "](", urrl, ")")
                                     } else {
                                       repository
                                     }
                                   } else {
                                     repository
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

  md_columns_widths <- "|:-------|:--------------------------------|:------------------|:---|:--------------------------|:----------|"  
  if("md" %in% outputs) {
    capture.output(
      cat("---\ntitle: CODECHECK Register\n---"),
      knitr::kable(register_table, format = "markdown"),
      file = "register.md"
    )
    # hack to reduce column width of 4th column
    md_table <- readLines("register.md")
    md_table[6] <- md_columns_widths
    writeLines(md_table, "docs/register.md")
    file.remove("register.md")
    # TODO: fix table column width, e.g. via using a register.Rmd with kableExtra
  }
  
  # render register to HTML
  if("html" %in% outputs) {
    # add icons to the Repository column for HTML output, use a copy of the register.md
    # so the inline HTML is not in the .md output
    register_table$Repository <- sapply(X = register$Repository,
                                        FUN = function(repository) {
                                          spec <- parse_repository_spec(repository)
                                          
                                          if (!any(is.na(spec))) {
                                            urrl <- "#"
                                            
                                            if (spec[["type"]] == "github") {
                                              urrl <- paste0("https://github.com/", spec[["repo"]])
                                              paste0("<i class='fa fa-github'></i>&nbsp;[", spec[["repo"]], "](", urrl, ")")
                                            } else if (spec[["type"]] == "osf") {
                                              urrl <- paste0("https://osf.io/", spec[["repo"]])
                                              paste0("<i class='ai ai-osf'></i>&nbsp;[", spec[["repo"]], "](", urrl, ")")
                                            } else {
                                              repository
                                            }
                                          } else {
                                            repository
                                          }
                                        })
    capture.output(
      cat("---\ntitle: CODECHECK Register\n---"),
      knitr::kable(register_table, format = "markdown"),
      file = "docs/register-icons.md"
    )
    md_table <- readLines("docs/register-icons.md")
    file.remove("docs/register-icons.md")
    md_table[6] <- md_columns_widths
    writeLines(md_table, "docs/register-icons.md")
    
    rmarkdown::render(input = "docs/register-icons.md",
                      # next paths are relative to input file
                      output_yaml = "html_document.yml",
                      output_file = "index.html")
    file.remove("docs/register-icons.md")
  }
  
  # render register to JSON
  if("json" %in% outputs) {
    # get paper titles and references
    titles <- c()
    references <- c()
    for (i in seq_len(nrow(register))) {
      config_yml <- get_codecheck_yml(register[i, ]$Repo)
      
      title <- NA
      reference <- NA
      if (!is.null(config_yml)) {
        title <- config_yml$paper$title
        reference <- config_yml$paper$reference
      }
      
      titles <- c(titles, title)
      references <- c(references, reference)
    }

    register_table$Title <- stringr::str_trim(titles)
    register_table$`Paper reference` <- stringr::str_trim(references)
    register_table$`Repository Link` <- sapply(
      X = register$Repository,
      FUN = function(repository) {
        spec <- parse_repository_spec(repository)
        if (spec[["type"]] == "github") {
          paste0("https://github.com/", spec[["repo"]])
        } else if (spec[["type"]] == "osf") {
          paste0("https://osf.io/", spec[["repo"]])
        } else {
          repository
        }
      }
    )
  
    jsonlite::write_json(register_table[, c(
      "Certificate",
      "Repository Link",
      "Type",
      "Report",
      "Title",
      "Paper reference",
      "Check date")],
      path = "docs/register.json",
      pretty = TRUE)
    
    jsonlite::write_json(tail(register_table, 10)[, c(
      "Certificate",
      "Repository Link",
      "Type",
      "Report",
      "Title",
      "Paper reference",
      "Check date")],
      path = "docs/featured.json",
      pretty = TRUE)
  }
  
  return(register_table)
}

#' Function for checking all entries in the register
#' 
#' This functions starts of a `data.frame` read from the local register file.
#' 
#' **Note**: The validation of `codecheck.yml` files happens in function `validate_codecheck_yml()`.
#' 
#' Further test ideas:
#' 
#' - Does the repo have a LICENSE?
#' 
#' @param register A `data.frame` with all required information for the register's view
#' @param from The first register entry to check
#' @param to The last register entry to check
#' 
#' @author Daniel Nüst
#' @importFrom gh gh
#' @export
register_check <- function(register = read.csv("register.csv", as.is = TRUE),
                           from = 1,
                           to = nrow(register)) {
  for (i in seq(from = from, to = to)) {
    cat("Checking", toString(register[i, ]), "\n")
    entry <- register[i, ]
    
    # check certificate IDs if there is a codecheck.yml
    codecheck_yaml <- get_codecheck_yml(entry$Repository)
    if (!is.null(codecheck_yaml)) {
      # validate config file
      validate_codecheck_yml(codecheck_yaml)
      
      # check certificate ID
      if (entry$Certificate != codecheck_yaml$certificate) {
        stop("Certificate mismatch, register: ", entry$Certificate,
             " vs. repo ", codecheck_yaml$certificate)
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
    
    cat("Completed checking registry entry", toString(register[i, "Certificate"]), "\n")
  }
}
