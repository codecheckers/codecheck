#' Create Non-Register Files
#'
#' Processes the register table to create non-register files such as venues and codecheckers.
#' It applies filters to split the data into separate tables and generates corresponding HTML and JSON files.
#'
#' @param register_table The original register data.
#' @param filter_by A list specifying the filters to apply (e.g., "venues", "codecheckers").
create_non_register_files <- function(register_table, filter_by){
  for (filter in filter_by){
    list_tables <- create_tables_non_register(register_table, filter)

    for (table_name in names(list_tables)){
      table <- list_tables[[table_name]]

      # Table does not belong to a subcategory. Setting subcat to NULL
      if (table_name %in% list("venues", "codecheckers")){
        subcat <- NULL
      }

      # Table belongs to a subcategory
      else{subcat <- table_name}
      table_details <- generate_table_details_non_reg(table, filter, subcat)

      render_html(table, table_details, filter)

      # Removing the unnecessary columns before creating html and json
      if (filter == "venues"){
        # Rename venue_label to its display name before output
        col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues"]]
        if ("venue_label" %in% colnames(table)) {
          table <- table %>%
            rename(!!sym(col_names[["venue_label"]]) := venue_label)
        }
        # Remove slug column
        table <- table %>% select(-`venue_slug`)
      }

      # Saving the json file
      jsonlite::write_json(
        table,
        path = paste0(table_details[["output_dir"]], "index.json"),
        pretty = TRUE
      )
    }
  }
}

#' Create Non-Register Tables
#'
#' Generates tables based on the filter type provided, such as venues or codecheckers.
#' It creates tables for further processing and rendering into different formats.
#'
#' @param register_table The original register data.
#' @param filter A string specifying the filter to apply (e.g., "venues", "codecheckers").
#'
#' @return A list of tables generated based on the specified filter. The keys are the table
#' names and the values are the tables themselves.
create_tables_non_register <- function(register_table, filter){
  list_tables <- switch(filter,
    "venues" = create_venues_tables(register_table),
    "codecheckers" = create_all_codecheckers_table(register_table)
  )
  return(list_tables)
}

#' Generate Table Details for Non-Register Files
#'
#' Generates metadata for non-register tables, including subcategory, title, subtext, 
#' extra text, and output directory. It is used to prepare the table for rendering.
#'
#' @param table The data frame containing the filtered table.
#' @param filter A string specifying the filter applied to the table.
#' @param subcat An optional string for the subcategory (if applicable).
#'
#' @return A list containing metadata such as title, subtext, and output directory for the table.
generate_table_details_non_reg <- function(table, filter, subcat = NULL){
  table_details <- list()
  table_details[["subcat"]] <- subcat
  table_details[["title"]] <- generate_html_title_non_registers(filter, subcat)
  table_details[["subtext"]] <- generate_html_subtext_non_register(table, filter, subcat)
  table_details[["extra_text"]] <- generate_html_extra_text_non_register(filter)
  table_details[["is_reg_table"]] <- FALSE
  table_details[["output_dir"]] <- generate_output_dir(filter, table_details)
  return(table_details)
}

#' Generates postfix hrefs for the venues/ codecheckers list pages
#' 
#' @param filter The filter being used such as "venues" or "codecheckers"
#' @param table_details A list of metadata about the table (e.g., title, subtext, extra text).
#' @return A list of the hrefs.
generate_html_postfix_hrefs_non_reg <- function(filter, table_details){  
  # Case we do not have subcat
  if ("subcat" %in% names(table_details)){
    subcat <- table_details[["subcat"]]
    # If subcat is venue type, we pluralize the venue names
    if (subcat %in% names(CONFIG$VENUE_SUBCAT_PLURAL)){
      subcat <- CONFIG$VENUE_SUBCAT_PLURAL[[subcat]]
    }
    hrefs <- list(
      json_href = paste0(CONFIG$HYPERLINKS[["register"]], filter, "/", subcat,"/index.json")
    )
  }

  # Case with subcat
  else{
    hrefs <- list(
      json_href = paste0(CONFIG$HYPERLINKS[["register"]], filter, "/index.json")
    )
  }

  return(hrefs)
}

#' Render Non-Register Markdown Table
#'
#' Renders the table in Markdown format, including adding hyperlinks to the relevant
#' columns. It adjusts column widths and saves the output as a Markdown file.
#'
#' @param table The data frame containing the filtered table.
#' @param table_details A list of metadata about the table (e.g., title, subtext, extra text).
#' @param filter A string specifying the filter applied (e.g., "venues", "codecheckers").
render_non_register_md <- function(table, table_details, filter){
  # Add hyperlinks
  table <- switch(filter,
    "venues" = add_venues_hyperlinks_non_reg(table, table_details[["subcat"]]),
    "codecheckers" = add_all_codecheckers_hyperlink(table)
  )

  table <- kable(table)
  # Creating and adjusting the markdown table
  md_table <- readLines(CONFIG$TEMPLATE_DIR[["non_reg"]][["md_template"]])
  md_table <- gsub("\\$title\\$", table_details[["title"]], md_table)
  md_table <- gsub("\\$subtitle\\$", table_details[["subtext"]], md_table)
  md_table <- gsub("\\$content\\$", paste(table, collapse = "\n"), md_table)
  md_table <- gsub("\\$extra_text\\$", table_details[["extra_text"]], md_table)

  # Add profile links (empty for non-register summary pages)
  md_table <- gsub("\\$profile_links\\$", "", md_table)

  # Adjusting the column widths
  md_table <- unlist(strsplit(md_table, "\n", fixed = TRUE))
  # Determining which line to add the md column widths in
  alignment_line_index <- grep("^\\|:---", md_table)

  # Selecting filter specific column widths
  if (filter %in% names(CONFIG$MD_TABLE_COLUMN_WIDTHS[["non_reg"]])){
    if (filter == "venues" && !is.null(table_details[["subcat"]])){
      md_table[alignment_line_index] <- CONFIG$MD_TABLE_COLUMN_WIDTHS[["non_reg"]][["venues_subcat"]]
    }

    else{
      md_table[alignment_line_index] <- CONFIG$MD_TABLE_COLUMN_WIDTHS[["non_reg"]][[filter]]
    }
  }

  # Saving the table to a temp md file
  temp_md_path <- paste0(table_details[["output_dir"]], "temp.md")
  writeLines(md_table, temp_md_path)
}

#' Generate HTML Title for Non-Register Pages
#'
#' Generates the title for the HTML page based on the filter and subcategory.
#' The title is used for rendering the non-register HTML files such as venues or codecheckers pages.
#'
#' @param filter A string specifying the filter applied (e.g., "venues", "codecheckers").
#' @param subcat An optional string for the subcategory (if applicable).
#'
#' @return A string containing the generated HTML title.
generate_html_title_non_registers <- function(filter, subcat){
  if (filter %in% names(CONFIG$NON_REG_TITLE_FNS)){
    title_fn <- CONFIG$NON_REG_TITLE_FNS[[filter]]
    title <- title_fn(subcat)
    return(title)
  }
  return(paste(CONFIG$NON_REG_TITLE_BASE, filter))
}

#' Generates the extra text of the HTML pages for non registers.
#' This extra text is to be placed under the table.
#' There is only extra text for the codecheckers HTML page to explain
#' the reason for discrepancy between total_codechecks != SUM(no.of codechecks)
#' 
#' @param filter A string specifying the filter applied (e.g., "venues", "codecheckers").
#' @return The extra text to place under the table
generate_html_extra_text_non_register <- function(filter){
  extra_text <- ""

  if (filter %in% names(CONFIG$NON_REG_EXTRA_TEXT)){
    extra_text <- CONFIG$NON_REG_EXTRA_TEXT[[filter]]
  }

  return(extra_text)
}

#' Generates the subtext of the HTML pages for non registers with a summary of
#' the number of codechecks and number of codechecks/ venues etc.
#' 
#' @param table The table to showcase in the html
#' @param filter A string specifying the filter applied (e.g., "venues", "codecheckers").
#' @param subcat An optional string for the subcategory (if applicable).
#' @return The subtext to put under the html title
generate_html_subtext_non_register <- function(table, filter, subcat = NULL){
  # The filter is in the CONFIG$NON_REG_SUBTEXT
  if (filter %in% names(CONFIG$NON_REG_SUBTEXT)) {
    # Loading the subtext function (if present) and passing the argument
    subtext_fn <- CONFIG$NON_REG_SUBTEXT[[filter]]
    return(subtext_fn(table, subcat))
  } 

  else{
    stop("Filter not found")
  }
}
