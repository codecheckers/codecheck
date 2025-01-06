#' Function to add the markdown title based on the specific register table name.
#' 
#' @param table_details List containing details such as the table name, subcat name.
#' @param md_table The markdown table where the title needs to be added
#' @param filter The filter
#'
#' @return The modified markdown table
add_markdown_title <- function(table_details, md_table, filter){
  # The filter is in the CONFIG$MD_TITLES
  title_fn <- NULL
  
  if (is.na(filter)) {
    title_fn <- CONFIG$MD_TITLES[["default"]]
  } else if (filter %in% names(CONFIG$MD_TITLES)) {
    # Loading the title function (if present) and passing the argument
    title_fn <- CONFIG$MD_TITLES[[filter]]
  } else {
    # No filter or no titles provided in the CONFIG file for the filter type
    # Stopping the process
    stop("Invalid filter provided.")
  }

  title <- title_fn(table_details)
  
  md_table <- gsub("\\$title\\$", title, md_table)
  return(md_table)
}

#' Renders register md for a single register_table
#' 
#' @param register_table The register table
#' @param table_details List containing details such as the table name, subcat name.
#' @param filter The filter
render_register_md <- function(register_table, table_details, filter) {
  register_table <- add_venue_hyperlinks_reg(register_table)
  register_table <- add_venue_type_hyperlinks_reg(register_table)

  # Fill in the content
  md_table <- create_md_table(register_table, table_details, filter)
  output_dir <- table_details[["output_dir"]]

  # Saving the md file
  if ("for_html_file" %in% names(table_details)){
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
#' @param table_details List containing details such as the table name, subcat name.
#' @param filter Type of filter (e.g., "venues", "codecheckers").
#'
#' @return The markdown table
create_md_table <- function(register_table, table_details, filter){
  # Loading the template and filling in the content
  md_table <- readLines(CONFIG$TEMPLATE_DIR[["reg"]][["md_template"]])

  md_content <- capture.output(kable(register_table, format = "markdown"))
  md_table <- add_markdown_title(table_details, md_table, filter)
  md_table <- gsub("\\$content\\$", paste(md_content, collapse = "\n"), md_table)

  # Adjusting the column widths
  md_table <- unlist(strsplit(md_table, "\n", fixed = TRUE))
  # Determining which line to add the md column widths in
  alignment_line_index <- grep("^\\|:---", md_table)
  # Selecting filter specific column widths
  if (filter %in% names(CONFIG$MD_TABLE_COLUMN_WIDTHS[["reg"]])){
    md_table[alignment_line_index] <- CONFIG$MD_TABLE_COLUMN_WIDTHS[["reg"]][[filter]]
  }

  # For some filters we can use the "general" column widths
  else{
    md_table[alignment_line_index] <- CONFIG$MD_TABLE_COLUMN_WIDTHS[["reg"]][["general"]]
  }
  return(md_table)
}