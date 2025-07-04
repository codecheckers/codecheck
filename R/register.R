#' Function for rendering the register into different view
#'
#' NOTE: You should put a GitHub API token in the environment variable `GITHUB_PAT` to fix rate limits. Acquire one at see https://github.com/settings/tokens.
#'
#' - `.html`
#' - `.md``
#'
#' @param register A `data.frame` with all required information for the register's view
#' @param filter_by The filter or list o filters (if applicable)
#' @param outputs The output formats to create
#' @param config A list of configuration files to be sourced at the beginning of the rending process
#' @param from The first register entry to check
#' @param to The last register entry to check
#'
#' @return A `data.frame` of the register enriched with information from the configuration files of respective CODECHECKs from the online repositories
#'
#' @author Daniel Nüst
#' @importFrom parsedate parse_date
#' @importFrom rmarkdown render
#' @importFrom knitr kable
#' @importFrom utils capture.output read.csv tail packageVersion
#' @import     jsonlite
#' @import     dplyr
#'
#' @export
register_render <- function(register = read.csv("register.csv", as.is = TRUE, comment.char = '#'),
                            filter_by = c("venues", "codecheckers"),
                            outputs = c("html", "md", "json"),
                            config = c(system.file("extdata", "config.R", package = "codecheck")),
                            from = 1,
                            to = nrow(register)) {
  message("Rendering register using codecheck version ", utils::packageVersion("codecheck"), " from ", from, " to ", to)
  
  # Loading config.R files
  for (i in seq(length(config))) {
    source(config[i])
  }
  
  message("Using cache path ", R.cache::getCacheRootPath())
  
  register <- register[(from:to),]

  register_table <- preprocess_register(register, filter_by)
  # Setting number of codechecks now for later use. This is done to avoid double counting codechecks
  # done by multiple authors.
  CONFIG$NO_CODECHECKS <- nrow(register_table)
  
  if("html" %in% outputs) {
    render_cert_htmls(register_table, force_download = FALSE)
  }
  
  create_filtered_reg_csvs(register, filter_by)
  create_register_files(register_table, filter_by, outputs)
  create_non_register_files(register_table, filter_by)

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
#' @importFrom R.cache getCacheRootPath
#' @importFrom utils packageVersion
#' @importFrom gh gh
#' @export
register_check <- function(register = read.csv("register.csv", as.is = TRUE, comment.char = '#'),
                           from = 1,
                           to = nrow(register)) {
  message("Checking register using codecheck version ", utils::packageVersion("codecheck"), " from ", from, " to ", to)
  
  # Loading config.R file
  source(system.file("extdata", "config.R", package = "codecheck"))
  
  message("Using cache path ", R.cache::getCacheRootPath())
  
  for (i in seq(from = from, to = to)) {
    cat("Checking", toString(register[i, ]), "\n")
    entry <- register[i, ]

    # check certificate IDs if there is a codecheck.yml
    codecheck_yaml <- get_codecheck_yml(entry$Repository)
    check_certificate_id(entry, codecheck_yaml)
    check_issue_status(entry)
    cat("Completed checking registry entry", toString(register[i, "Certificate"]), "\n")
  }
}
