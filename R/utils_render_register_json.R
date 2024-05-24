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

render_register_json <- function(filter, register_table, register_table_name) {
  register_table <- add_repository_links_json(register_table)

  # Set paper titles and references
  register_table <- set_paper_title_references(register_table)

  output_dir <- get_output_dir(filter, register_table_name)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = TRUE)
  }

  jsonlite::write_json(
    register_table[, c(
      "Certificate",
      "Repository Link",
      "Type",
      "Report",
      "Title",
      "Paper reference",
      "Check date"
    )],
    path = paste0(output_dir, "register.json"),
    pretty = TRUE
  )

  jsonlite::write_json(
    utils::tail(register_table, 10)[, c(
      "Certificate",
      "Repository Link",
      "Type",
      "Report",
      "Title",
      "Paper reference",
      "Check date"
    )],
    path = paste0(output_dir, "featured.json"),
    pretty = TRUE
  )

  jsonlite::write_json(
    list(
      source = set_href(filter, register_table_name, "json"),
      cert_count = nrow(register_table)
      # TODO count conferences, preprints,
      # journals, etc.
    ),
    auto_unbox = TRUE,
    path = paste0(output_dir, "/stats.json"),
    pretty = TRUE
  )
}

render_register_jsons <- function(list_register_tables){
  # Loop over each register table
  for (filter in names(list_register_tables)){
    for (register_table_name in names(list_register_tables[[filter]])) {
      register_table <- list_register_tables[[filter]][[register_table_name]]
      render_register_json(filter, register_table, register_table_name)
    }
  }
}

