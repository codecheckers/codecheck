#' Renders non-register pages such as codecheckers or venues page.
#' 
#' @param list_reg_tables The list of register tables to link to in this html page
render_non_register_htmls <- function(list_reg_tables, page_type){
  output_dir <- paste0("docs/", page_type, "/")

  if (page_type == "codecheckers"){
    table <- render_table_codecheckers_html(list_reg_tables)
    table <- kable(table)
    # Counting number of codecheckers based of number of codechecker reg tables
    # The table is a kable table and hence we cannot count rows
    no_codecheckers <- length(list_reg_tables)
    # Using number of codechecks from CONFIG instead of "no. of codechecks" column to avoid double count
    subtext <- paste("In total,", no_codecheckers, "codecheckers contributed", CONFIG$NO_CODECHECKS, "codechecks*")
    
    # Extra text to explain why total_codechecks != SUM(no.of codechecks)
    extra_text <- "<i>\\*Note that the total codechecks is less than the collective sum of 
    individual codecheckers' no. of codechecks. 
    This is because some codechecks involved more than one codechecker.</i>"
  }

  else{
    return()
  }
  # Creating and adjusting the markdown table
  md_table <- load_md_template(CONFIG$TEMPLATE_DIR[["non_reg"]][["md_template"]])
  title <- paste0("CODECHECK List of ", page_type)
  md_table <- gsub("\\$title\\$", title, md_table)
  md_table <- gsub("\\$subtitle\\$", subtext, md_table)
  md_table <- gsub("\\$content\\$", paste(table, collapse = "\n"), md_table)
  md_table <- gsub("\\$extra_text\\$", extra_text, md_table)

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

  else{
    return()
  }
  jsonlite::write_json(
    table,
    path = paste0(output_dir, "index.json"),
    pretty = TRUE
  )
}