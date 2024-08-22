#' Function for adding repository links in the register table for the creation of the json file.
#' 
#' @param register_table The register table
#' @return Register table with adjusted repository links
add_repository_links_json <- function(register_table) {
  register_table$`Repository Link` <- sapply(
    X = register_table$Repository,
    FUN = function(repository) {
      spec <- parse_repository_spec(repository)
      if (spec[["type"]] == "github") {
        paste0("https://github.com/", spec[["repo"]])
      } else if (spec[["type"]] == "osf") {
        paste0("https://osf.io/", spec[["repo"]])
      } else if (spec[["type"]] == "gitlab") {
        paste0("https://gitlab.com/", spec[["repo"]])
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
#' @param filter The filter
#' @param register_table The register table
#' @param register_table_name The register table name
render_register_json <- function(filter, register_table, register_table_name, filter_subcategory = NULL) {
  register_table <- add_repository_links_json(register_table)

  # Set paper titles and references
  register_table <- set_paper_title_references(register_table)

  output_dir <- get_output_dir(filter, register_table_name, filter_subcategory = )
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = TRUE)
  }

  jsonlite::write_json(
    register_table[, CONFIG$JSON_COLUMNS],
    path = paste0(output_dir, "register.json"),
    pretty = TRUE
  )

  jsonlite::write_json(
    utils::tail(register_table, 10)[, CONFIG$JSON_COLUMNS],
    path = paste0(output_dir, "featured.json"),
    pretty = TRUE
  )

  jsonlite::write_json(
    list(
      source = generate_href(filter, register_table_name, "json", filter_subcategory),
      cert_count = nrow(register_table)
      # TODO count conferences, preprints,
      # journals, etc.
    ),
    auto_unbox = TRUE,
    path = paste0(output_dir, "/stats.json"),
    pretty = TRUE
  )
}

#' Renders register jsons for a list of register tables
#' 
#' @param list_register_table List of register tables
render_register_jsons <- function(list_register_tables){
  for (filter in names(list_register_tables)){
    # For the case of venues we have a nested list
    if (filter == "venues"){
      for (venue_subcat in names(list_register_tables[[filter]])){
        for (venue_name in names(list_register_tables[[filter]][[venue_subcat]])){
          register_table <- list_register_tables[[filter]][[venue_subcat]][[venue_name]]
          render_register_json(filter, register_table, venue_name, venue_subcat)
        }
      }
    }

    else{
      for (register_table_name in names(list_register_tables[[filter]])){
        register_table <- list_register_tables[[filter]][[register_table_name]]
        render_register_json(filter, register_table, register_table_name)
      }
    }
  }
}