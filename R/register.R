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
#' @importFrom utils capture.output read.csv tail
#' @import     jsonlite
#'
#' @export
register_render <- function(register = read.csv("register.csv", as.is = TRUE),
                            outputs = c("html", "md", "json")) {
  register_table <- preprocess_register(register)

  md_columns_widths <- "|:-------|:--------------------------------|:------------------|:---|:--------------------------|:----------|"

  if ("md" %in% outputs) render_register_md(register_table, md_columns_widths)
  if ("html" %in% outputs) render_register_html(register_table, register, md_columns_widths)
  if ("json" %in% outputs) render_register_json(register_table, register)

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
        stop(
          "Certificate mismatch, register: ", entry$Certificate,
          " vs. repo ", codecheck_yaml$certificate
        )
      }
    } else {
      warning(entry$Certificate, " does not have a codecheck.yml file")
    }

    # check issue status
    if (!is.na(entry$Issue)) {
      # get the status and labels from an issue
      issue <- gh::gh("GET /repos/codecheckers/:repo/issues/:issue",
        repo = "register",
        issue = entry$Issue
      )
      issue$state
      issue$labels
      if (issue$state != "closed") {
        warning(
          entry$Certificate, " issue is still open: ",
          "<https://github.com/codecheckers/register/issues/",
          entry$Issue, ">"
        )
      }
    }

    cat("Completed checking registry entry", toString(register[i, "Certificate"]), "\n")
  }
}
