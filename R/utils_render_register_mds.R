#' Function to add the markdown title based on the specific register table name.
#' 
#' @param markdown_table The markdown template where the title needs to be added
#' @param register_table_name The name of the register table
#'
#' @return The modified markdown table
add_markdown_title <- function(filter, md_table, register_table_name, filter_subcat=NULL){
  if (filter == "none"){
    title <- "CODECHECK Register"
  }
  
  # For codechecker filtered registers we show the name and the ORCID ID
  else if (filter == "codecheckers") {
    author_name <- CONFIG$DICT_ORCID_ID_NAME[register_table_name]
    orcid_id <- register_table_name
    title <- paste0("Codechecks by ", author_name, " (", orcid_id,")")
  }
  
  # For venue filtered registers we display the venue name in the title.
  else if (filter == "venues"){
    title <- paste0("CODECHECK Register for ", filter_subcat, " (", register_table_name, ")")
  }

  md_table <- gsub("\\$title\\$", title, md_table)
  return(md_table)
}

#' Function for adding repository links in the register table for the creation of the markdown file.
#' 
#' @param register_table The register table
#' @return Register table with adjusted repository links
add_repository_links_md <- function(register_table) {
  register_table$Repository <- sapply(
    X = register_table$Repository,
    FUN = function(repository) {
      spec <- parse_repository_spec(repository)
      if (!any(is.na(spec))) {
        urrl <- "#"

        switch(spec["type"],
          "github" = {
            urrl <- paste0("https://github.com/", spec[["repo"]])
            paste0("[", spec[["repo"]], "](", urrl, ")")
          },
          "osf" = {
            urrl <- paste0("https://osf.io/", spec[["repo"]])
            paste0("[", spec[["repo"]], "](", urrl, ")")
          },
          "gitlab" = {
            urrl <- paste0("https://gitlab.com/", spec[["repo"]])
            paste0("[", spec[["repo"]], "](", urrl, ")")
          },

          # Type is none of the above
          {
            repository
          }
        )
      } else {
        repository
      }
    }
  )
  return(register_table)
}

#' Renders register md for a single register_table
#' 
#' @param filter The filter
#' @param register_table The register table
#' @param register_table_name The register table name
#' @param filter_subcategory The name of the filter subcategory. Only needed in case of venues which has subcategories. Defaults to NULL
#' @param for_html_file Flag for whether we are rendering register md for html file.
#' Set to FALSE by default. If TRUE, no repo links are added to the repository table.
render_register_md <- function(filter, register_table, register_table_name, filter_subcategory = NULL, for_html_file=FALSE) {
  
  # Add appropriate repo links based on whether we are rendering the md for html or not
  register_table <- if (for_html_file) {
    add_repository_links_html(register_table)
  } else {
    add_repository_links_md(register_table)
  }

  # Fill in the content
  md_table <- create_md_table(register_table, register_table_name, filter, filter_subcategory)
  save_md_table(md_table, filter, register_table_name, filter_subcategory, for_html_file)
}

#' Renders register mds for a list of register tables
#' 
#' @param list_register_table List of register tables
render_register_mds <- function(list_register_tables){
  for (filter in names(list_register_tables)){
    # For the case of venues we have a nested list
    if (filter == "venues"){
      for (venue_subcat in names(list_register_tables[[filter]])){
        for (venue_name in names(list_register_tables[[filter]][[venue_subcat]])){
          register_table <- list_register_tables[[filter]][[venue_subcat]][[venue_name]]
          render_register_md(filter, register_table, venue_name, venue_subcat)
        }
      }
    }

    else{
      for (register_table_name in names(list_register_tables[[filter]])){
        register_table <- list_register_tables[[filter]][[register_table_name]]
        render_register_md(filter, register_table, register_table_name)
      }
    }
  }
}

#' Save markdown table to a file
#'
#' The output directory is determined based on the filter type, register table name, and an optional subcategory. 
#' The file is saved as either a temporary file (`temp.md`) or as `register.md` depending on 
#' whether it is being rendered for an HTML file.
#'
#' @param md_table The markdown table to be saved.
#' @param filter The filter applied (e.g., "venues", "codecheckers").
#' @param register_table_name The name of the register table.
#' @param filter_subcategory An optional string representing a subcategory within the filter 
#'        (e.g., venue type). Default is NULL.
#' @param for_html_file A logical flag indicating whether the markdown is being rendered for an HTML file. 
#'        If TRUE, the file is saved as `temp.md`. Default is FALSE.
save_md_table <- function(md_table, filter, register_table_name, filter_subcategory, for_html_file){
  output_dir <- get_output_dir(filter, register_table_name, filter_subcategory)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = TRUE)
  }

  # If rendering md for html file we create a temp file
  if (for_html_file){
    output_dir <- paste0(output_dir, "temp.md")
  }

  else{
    output_dir <- paste0(output_dir, "register.md")
  }

  writeLines(md_table, output_dir)
}

#' Creates a markdown table from a register template
#' Adds title to the markdown and adjusts the column widths of the table 
#' before returning it.
#'
#' @param register_table DataFrame of the register data.
#' @param register_table_name Name of the register table.
#' @param filter Type of filter (e.g., "venues", "codecheckers").
#' @param filter_subcat Optional subcategory within the filter. Default is NULL.
#'
#' @return The markdown table
create_md_table <- function(register_table, register_table_name, filter, filter_subcat=NULL){
  # Fill in the content
  md_table <- readLines(CONFIG$TEMPLATE_DIR[["reg"]][["md_template"]])

  markdown_content <- capture.output(kable(register_table, format = "markdown"))
  md_table <- add_markdown_title(filter, md_table, register_table_name, filter_subcat)
  md_table <- gsub("\\$content\\$", paste(markdown_content, collapse = "\n"), md_table)

  # Adjusting the column widths
  md_table <- unlist(strsplit(md_table, "\n", fixed = TRUE))
  # Determining which line to add the md column widths in
  alignment_line_index <- grep("^\\|:---", md_table)
  md_table[alignment_line_index] <- CONFIG$MD_COLUMNS_WIDTHS

  return(md_table)
}