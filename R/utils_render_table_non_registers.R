#' Renders non-register pages such as codecheckers or venues page.
#' 
#' @param list_reg_tables The list of register tables to link to in this html page
render_non_register_htmls <- function(list_reg_tables, page_type){
  output_dir <- paste0("docs/", page_type, "/")

  no_codechecks <- sum(sapply(list_reg_tables, nrow))
  if (page_type == "codecheckers"){
    table <- render_table_codecheckers_html(list_reg_tables)
    # Counting number of codecheckers based of number of codechecker reg tables
    # The table is a kable table and hence we cannot count rows
    no_codecheckers <- length(list_reg_tables)
    subtext <- paste("In total,", no_codecheckers, "codecheckers contributed", no_codechecks, "codechecks")
    generate_html(table, page_type, output_dir, subtext)
  }

  else if (page_type == "venues"){
    table <- render_table_venues_html(list_reg_tables)

    no_venues <- length(list_reg_tables)
    subtext <- paste("In total,", no_codechecks, "codechecks were completed for", no_venues, "venues")
    generate_html(table, page_type, output_dir, subtext)

    # Generating page for each venue subcategory
    for (venue_subcat in CONFIG$VENUE_SUBCATEGORIES){

      table_venue_subcategory <- table[grepl(venue_subcat, table$`Venue type`, ignore.case = TRUE), ]
      no_codechecks <- nrow(table_venue_subcategory)
      
      subtext <- paste("In total,", no_codechecks, "codechecks were completed for", no_venues, venue_subcat)
      output_dir <- paste0("docs/", page_type, "/", venue_subcat, "/")
      generate_html(table_venue_subcategory, page_type, output_dir, subtext)
    }
  }
}

generate_html <- function(table, page_type, output_dir, subtext){
  # Creating and adjusting the markdown table
  md_table <- load_md_template(CONFIG$MD_NON_REG_TEMPLATE)
  title <- paste0("CODECHECK List of ", page_type)
  md_table <- gsub("\\$title\\$", title, md_table)
  md_table <- gsub("\\$subtitle\\$", subtext, md_table)
  md_table <- gsub("\\$content\\$", paste(table, collapse = "\n"), md_table)

  # Saving the table to a temp md file
  temp_md_path <- paste0(output_dir, "temp.md")
  writeLines(md_table, temp_md_path)

  # Creating the correct html yaml and index files
  create_index_section_files(output_dir, page_type)
  generate_html_document_yml(output_dir)
  yaml_path <- normalizePath(file.path(getwd(), paste0(output_dir, "html_document.yml")))

  # Render index.html from markdown
  rmarkdown::render(
    input = temp_md_path,
    output_file = "index.html",
    output_dir = output_dir,
    output_yaml = yaml_path
  )

  # Deleting the temp file
  file.remove(temp_md_path)

  # Changing the html file so that the path to the libs folder refers to 
  # the libs folder "docs/libs".
  # This is done to remove duplicates of "libs" folders.
  html_file_path <- paste0(output_dir, "index.html")
  edit_html_lib_paths(html_file_path)
  # Deleting the libs folder after changing the html lib path
  unlink(paste0(output_dir, "/libs"), recursive = TRUE)
}

#' Renders JSON file of non register tables such as list of venues, list of codecheckers
#' 
#' @param list_reg_tables The list of register tables needed for the information.
render_non_register_jsons <- function(list_reg_tables, page_type){
  output_dir <- paste0("docs/", page_type, "/")

  if (page_type == "codeheckers"){
    table <- render_table_codecheckers_json(list_reg_tables)
  }

  else if (page_type == "venues") {
    table <- render_table_venues_json(list_reg_tables)
  }
  jsonlite::write_json(
    table,
    path = paste0(output_dir, "index.json"),
    pretty = TRUE
  )
}