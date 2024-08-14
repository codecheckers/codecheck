CONFIG <- new.env()
# Registers can be further divided into filter subgroups
# For cases where an entry does not fall into any subgroup, it's rendered files
# are stored in a folder with its own name
CONFIG$FILTER_SUB_GROUPS <- list(
  venues = list("community", "journal", "conference") 
)
CONFIG$MD_COLUMNS_WIDTHS <- "|:-------|:--------------------------------|:------------------|:---|:--------------------------|:----------|"
CONFIG$REGISTER_COLUMNS <- list("Certificate", "Repository", "Type", "Issue", "Report", "Check date")
CONFIG$DICT_ORCID_ID_NAME <- list()
CONFIG$DIR_TEMP_REGISTER_CODECHECKER <- "docs/temp_register_codechecker.csv"
CONFIG$DICT_VENUE_NAMES <- list(
  "journal (GigaScience)" = "GigaScience",
  "journal (J Geogr Syst)" = "Journal of Geographical Systems",
  "journal (J Archaeol Sci)" = "Journal of Archaeological Science",
  "journal (GigaByte)" = "GigaByte",
  "conference (AGILEGIS)" = "AGILEGIS",
  "community (codecheck)" = "Codecheck",
  "community (codecheck NL)" = "Codecheck NL",
  "community (in press)" = "In press",
  "community (preprint)" = "Preprint"
)


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
                            filter_by = c("venues", "codecheckers"),
                            outputs = c("html", "md", "json")) {
  CONFIG$MD_REG_TEMPLATE <- system.file("extdata", "templates/template_register.md", package = "codecheck")
  CONFIG$MD_NON_REG_TEMPLATE <- system.file("extdata", "templates/template_non_register.md", package = "codecheck")

  register_table <- preprocess_register(register, filter_by)

  # Creating list of of register tables with indices being the filter types
  list_register_tables <- c()
  
  # Adding the original register table. We drop the columns that are not in CONFIG$REGISTER_COLUMNS as
  # some of them may have added in the preprocessing for the sake of filtering
  og_register_table <- register_table[, names(register_table) %in% CONFIG$REGISTER_COLUMNS]
  list_register_tables[["none"]] <- list("original"= og_register_table)

  if (length(filter_by)!=0){
    create_filtered_register_csvs(filter_by, register)
    # Creating and adding filtered registered tables to list of tables
    list_register_tables <- add_filtered_register_tables(list_register_tables, register_table, filter_by)
  }

  # Rendering files
  # if ("md" %in% outputs) render_register_mds(list_register_tables)
  if ("html" %in% outputs) {
    render_register_htmls(list_register_tables)

    for (filter in filter_by){
      render_non_register_htmls(list_register_tables[[filter]], page_type = filter)
    }
  }
  if ("json" %in% outputs) {
    # render_register_jsons(list_register_tables)
    for (filter in filter_by){
      render_non_register_jsons(list_register_tables[[filter]], page_type = filter)
    }

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
    check_certificate_id(entry, codecheck_yaml)
    check_issue_status(entry)
    cat("Completed checking registry entry", toString(register[i, "Certificate"]), "\n")
  }
}
