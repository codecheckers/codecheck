render_non_register_tables_html <- function(list_reg_tables, page_type){

  output <- switch(page_type,
    "codecheckers" = render_table_codecheckers_html(list_reg_tables),
    "venues" = render_tables_venues_html(list_reg_tables),
    stop("Unsupported non-register table page type")
  )

  # Ensuring output is a list, wrapping it if necessary
  # This is needed when the render function returns a single table which is the
  # case when there are not subcategory tables such as the case for codecheckers
  if (is.data.frame(output)){
    output <- list(page_type = output)
  }
  return(output)  
}

#' Renders non-register pages such as codecheckers or venues page.
#' 
#' @param list_reg_tables The list of register tables to link to in this html page
render_non_register_htmls <- function(list_reg_tables, page_type){
  list_tables <- render_non_register_tables_html(list_reg_tables, page_type)

  for (table_name in names(list_tables)){
    table <- list_tables[[table_name]]

    # Case where we are dealing with venue subcategories
    if (page_type == "venues" & table_name != "all_venues"){
      output_dir <- paste0("docs/", page_type, "/", table_name, "/")
    }

    else{
      output_dir <- paste0("docs/", page_type, "/")
    }

    html_header <- generate_html_header(table, page_type, table_name)
    generate_non_reg_html(table, table_name, page_type, html_header, output_dir)
  }
}

generate_non_reg_html <- function(table, table_subcategory, page_type, html_header, output_dir){
  table <- kable(table)

  # Creating and adjusting the markdown table
  md_table <- load_md_template(CONFIG$TEMPLATE_DIR[["non_reg"]][["md_template"]])
  md_table <- gsub("\\$title\\$", html_header[["title"]], md_table)
  md_table <- gsub("\\$subtitle\\$", html_header[["subtext"]], md_table)
  md_table <- gsub("\\$content\\$", paste(table, collapse = "\n"), md_table)
  md_table <- gsub("\\$extra_text\\$", html_header[["extra_text"]], md_table)

  # Saving the table to a temp md file
  temp_md_path <- paste0(output_dir, "temp.md")
  writeLines(md_table, temp_md_path)

  # Creating the correct html yaml and index files
  create_index_section_files(output_dir, page_type, table_subcategory, is_reg_table = FALSE)
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
  if (page_type == "codecheckers"){
    list_tables <- list("codecheckers" = render_table_codecheckers_json(list_reg_tables))
  }

  else if (page_type == "venues") {
    list_tables <- render_tables_venues_json(list_reg_tables)
  }

  for (table_name in names(list_tables)){
    table <- list_tables[[table_name]]
    output_dir <- paste0("docs/", page_type, "/")

    # Case where we are dealing with venue subcategories
    if (page_type == "venues" & table_name != "all_venues"){
      output_dir <- paste0("docs/", page_type, "/", table_name, "/")
    }

    jsonlite::write_json(
      table,
      path = paste0(output_dir, "index.json"),
      pretty = TRUE
    )
  }
}

generate_html_title_non_registers <- function(page_type, table_name){
  title_base <- "CODECHECK List of"

  # Adjusting title for venues subcategory
  if (page_type == "venues" & table_name != "all_venues"){
    # Replacing the word with plural
    plural_subcategory <- switch (table_name,
      "conference" = "conferences",
      "journal" = "journals",
      "community" = "communities"
    )
    title <- paste(title_base, plural_subcategory)
  }

  else{
    # The base title is "CODECHECK List of venues/ codecheckers"
    title <- paste(title_base, page_type)
  }

  return(title)
}

generate_html_extra_text_non_register <- function(page_type){
  extra_text <- ""

  # Extra text to explain why total_codechecks != SUM(no.of codechecks) in the codechecker table
  if (page_type == "codecheckers"){
    extra_text <- "<i>\\*Note that the total codechecks is less than the collective sum of 
    individual codecheckers' number of codechecks. 
    This is because some codechecks involved more than one codechecker.</i>"
  }

  return(extra_text)
}


generate_html_subtext_non_register <- function(table, page_type, table_name){

  # Setting the codecheck word to be plural or singular
  total_codechecks <- CONFIG$NO_CODECHECKS
  codecheck_word <- if (total_codechecks == 1) "codecheck" else "codechecks"
  extra_text <- ""

  if (page_type == "codecheckers"){
    no_codecheckers <- nrow(table)
    # Adding asterik to refer to the extra text at the bottom of the page
    codecheck_word <- paste0(codecheck_word, "*")
    subtext <- paste("In total,", no_codecheckers, "codecheckers contributed", total_codechecks, codecheck_word)
  }

  else if (page_type == "venues"){
    # For the general venues list
    if (table_name == "all_venues"){
      no_venues <- nrow(table)
      subtext <- paste("In total,", total_codechecks, codecheck_word, "were completed for", no_venues, "venues")
    }

    else{
      no_venues_subcat <- nrow(table)
      venue_name_subtext <- table_name
      total_codechecks <- CONFIG$NO_CODECHECKS_VENUE_SUBCAT[[venue_name_subtext]]
      codecheck_word <- if (total_codechecks == 1) "codecheck" else "codechecks"

      if (no_venues_subcat > 1){
        venue_name_subtext <- switch (table_name,
          "conference" = "conferences",
          "journal" = "journals",
          "community" = "communities"
        )
      }
      subtext <- paste("In total,", total_codechecks, codecheck_word, "were completed for", no_venues_subcat, venue_name_subtext)
    }
  }

  return(subtext)
}

generate_html_header <- function(table, page_type, table_name){

  html_header <- list(
    "title" = generate_html_title_non_registers(page_type, table_name),
    "subtext" = generate_html_subtext_non_register(table, page_type, table_name),
    "extra_text" = generate_html_extra_text_non_register(page_type)
  )

  return(html_header)
}