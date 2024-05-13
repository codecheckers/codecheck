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
                            sort_by = c("venue"),
                            outputs = c("html", "md", "json")) {
  register_table <- preprocess_register(register)

  list_register_tables <- c()
  list_register_tables[["original"]] <- register_table

  # Sorting the tables 
  for (sort in sort_by) {
    if (sort == "venue") {
      list_venue_sorted_register_tables <- create_list_venue_sorted_register_tables(register_table)
      list_register_tables <- c(list_register_tables, list_venue_sorted_register_tables)
    }
  }

  # Rendering files
  md_columns_widths <- "|:-------|:--------------------------------|:------------------|:---|:--------------------------|:----------|"
  if ("md" %in% outputs) render_register_md(list_register_tables, md_columns_widths)
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
    check_certificate_id(codecheck_yaml)
    check_issue_status(entry)
    cat("Completed checking registry entry", toString(register[i, "Certificate"]), "\n")
  }
}
