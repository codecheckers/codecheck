#' Function for adding repository links in the register table for the creation of the json file.
#' 
#' @param register_table The register table
#' @return Register table with adjusted repository links
add_repository_links_json <- function(register_table) {
  register_table$`Repository Link` <- sapply(
    X = register_table$Repository,
    FUN = function(repository) {
      # ! Needs refactoring
      spec <- parse_repository_spec(repository)
      if (spec[["type"]] == "github") {
        paste0(CONFIG$HYPERLINKS[["github"]], spec[["repo"]])
      } else if (spec[["type"]] == "osf") {
        paste0(CONFIG$HYPERLINKS[["osf"]], spec[["repo"]])
      } else if (spec[["type"]] == "gitlab") {
        paste0(CONFIG$HYPERLINKS[["gitlab"]], spec[["repo"]])
      } else if (spec[["type"]] == "zenodo") {
        paste0(CONFIG$HYPERLINKS[["zenodo"]], spec[["repo"]])
      } else {
        repository
      }
    }
  )
  return(register_table)
}

#' Set "Title" and "Paper reference" columns and values to the register_table
#' 
#' @param register_table The register table
#' @return Updated register table including "Title" and "Paper reference" columns
set_paper_title_references <- function(register_table){
  titles <- c()
  references <- c()
  for (i in seq_len(nrow(register_table))) {
    config_yml <- get_codecheck_yml(register_table[i, ]$Repository)

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

  return(register_table)
}

#' Renders register json for a single register_table
#'
#' @param register_table The register table
#' @param table_details List containing details such as the table name, subcat name.
#' @param filter The filter
render_register_json <- function(register_table, table_details, filter) {
  register_table_json <- add_repository_links_json(register_table)

  # Set paper titles and references
  register_table_json <- set_paper_title_references(register_table_json)

  output_dir <- table_details[["output_dir"]]

  # Keeping only those columns that are mentioned in the json columns and those that
  # register table already has
  columns_to_keep <- intersect(CONFIG$JSON_COLUMNS, names(register_table_json))

  # Main register.json: sorted by certificate identifier (done in render_register())
  jsonlite::write_json(
    register_table_json[, columns_to_keep],
    path = file.path(output_dir, "register.json"),
    pretty = TRUE
  )

  # featured.json: sorted by check date (most recent first)
  # (addresses codecheckers/register#160)
  featured_table <- register_table_json
  if ("Check date" %in% names(featured_table)) {
    featured_table <- featured_table %>% arrange(desc(`Check date`))
  }
  jsonlite::write_json(
    utils::head(featured_table, CONFIG$FEATURED_COUNT)[, columns_to_keep],
    path = file.path(output_dir, "featured.json"),
    pretty = TRUE
  )

  jsonlite::write_json(
    list(
      source = generate_href(filter, table_details, "json"),
      cert_count = nrow(register_table_json)
      # TODO count conferences, preprints,
      # journals, etc.
    ),
    auto_unbox = TRUE,
    path = file.path(output_dir, "stats.json"),
    pretty = TRUE
  )
}
