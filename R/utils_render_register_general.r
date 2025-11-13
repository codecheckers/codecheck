#' Function for adding clickable links to the codecheck venue pages for each entry in the register table.
#' 
#' @param register_table The register table
#' @return The adjusted register table
add_venue_hyperlinks_reg <- function(register_table){
  if (!("Venue" %in% names(register_table))) {
    return(register_table)
  }

  list_hyperlinks <- c()
  venue_hyperlink_base <- CONFIG$HYPERLINKS[["venues"]]

  # Looping over the entries in the register
  for (i in seq_len(nrow(register_table))) {
    venue_name <- register_table[i, ]$Venue

    # Retrieving the venue type which is needed for url construction
    venue_type <- register_table[i, ]$Type
    venue_type_plural <- CONFIG$VENUE_SUBCAT_PLURAL[[venue_type]]
    
    # Generating the venue slug for the hyperlink
    venue_slug <- gsub(" ", "_", stringr::str_to_lower(venue_name))
    venue_hyperlink <- paste0("[", venue_name,"](",venue_hyperlink_base, venue_type_plural, "/", venue_slug, ")")
    list_hyperlinks <- c(list_hyperlinks, venue_hyperlink)
  }

  # Replace the "Venue" column with the hyperlinks
  register_table$Venue <- list_hyperlinks
  return(register_table)
}

#' Function for adding clickable links to the codecheck venue type pages for each entry in the register table.
#' 
#' @param register_table The register table
#' @return The adjusted register table
add_venue_type_hyperlinks_reg <- function(register_table){
  if (!("Type" %in% names(register_table))) {
    return(register_table)
  }

  list_hyperlinks <- c()
  venue_hyperlink_base <- CONFIG$HYPERLINKS[["venues"]]

  # Looping over the entries in the register
  for (i in seq_len(nrow(register_table))) {
    venue_type <- register_table[i, ]$Type
    venue_type_plural <- CONFIG$VENUE_SUBCAT_PLURAL[[venue_type]]
    
    venue_type_hyperlink <- paste0("[", stringr::str_to_title(venue_type), "](", venue_hyperlink_base, venue_type_plural, ")")
    list_hyperlinks <- c(list_hyperlinks, venue_type_hyperlink)
  }

  # Replace the "Type" column with the hyperlinks
  register_table$Type <- list_hyperlinks
  return(register_table)
}

#' Generates original register files in various output formats.
#' 
#' @param register_table The register table.
#' @param outputs List of the output types (e.g., "csv", "json").
#' 
#' The function iterates through the provided output types, generates an output directory,
#' filters and adjusts the register table, and renders the original register files based on the specified formats.
create_original_register_files <- function(register_table, outputs){
  filter <- NA
  for (output_type in outputs){
    table_details <- list(is_reg_table = TRUE)
    table_details[["output_dir"]] <- generate_output_dir(filter, table_details)
    render_register(register_table, table_details, filter, output_type)
  }
}

#' Create Register Files
#'
#' This function processes the register table based on different filter types and output formats.
#' It groups the register data by the specified filters, generates nested tables, and then 
#' creates markdown, HTML, and JSON files for each individual table.
#'
#' @param register_table The original register table
#' @param filter_by A list specifying the filters to be applied (e.g., "venues", "codecheckers").
#' @param outputs A list specifying the output formats to generate (e.g., "md", "html", "json").
#'
#' @return None. The function generates files in the specified formats.
create_register_files <- function(register_table, filter_by, outputs){

  # Creating the original register file
  create_original_register_files(register_table, outputs)
  # Generating filtered register table files
  # For each filter type we created the nested register tables first
  for (filter in filter_by){

    # Checking if the filter is of a known type
    if (!(filter %in% names(CONFIG$FILTER_COLUMN_NAMES))){
      stop(paste("Unknown filter type:", filter))
    }

    # For filter by codecheckers we need to unnest the column "codechecker"
    # As a result of unnesting, a row of data with multiple codecheckers will now
    # be split into multiple rows, one for each codechecker
    if (filter == "codecheckers"){
      register_table <- register_table %>% tidyr::unnest(Codechecker)
      register_table$Codechecker <- unlist(register_table$Codechecker)

      # Filter out NA codecheckers
      register_table <- register_table %>% filter(!is.na(Codechecker) & Codechecker != "NA")
    }

    # Group the register_table by the filter column and nest the resulting groups
    filter_col_name <- CONFIG$FILTER_COLUMN_NAMES[[filter]]
    grouped_registers <- register_table %>%
      group_by(across(all_of(filter_col_name))) 

    # Split into a list of data frames
    filtered_register_list <- grouped_registers %>% group_split()

    # Get the group names (keys) based on the filter names
    register_keys <- grouped_registers %>% group_keys()
    # Looping over each of the output types
    for (output_type in outputs){
      for (i in seq_along(filtered_register_list)) {
        # Retrieving the register and its key
        register_key <- register_keys[[filter_col_name]][i]
        filtered_table <- filtered_register_list[[i]]

        table_details <- generate_table_details(register_key, filtered_table, filter)

        render_register(filtered_table, table_details, filter, output_type)
      }
    }
  }
}

#' Filter and Drop Columns from Register Table
#'
#' This function filters and drops columns from the register table based on the
#' specified filter type. Uses hierarchical column configuration from
#' CONFIG$REGISTER_COLUMNS with filter-specific overrides.
#'
#' @param register_table The register table
#' @param filter A string specifying the filter to apply (e.g., "venues", "codecheckers").
#'        Use NA for the default/main register.
#' @param file_type The type of file we need to render the register for.
#'        The columns to keep depend on the file type and filter
#'
#' @return The filtered register table with only the necessary columns retained and ordered.
filter_and_drop_register_columns <- function(register_table, filter, file_type) {

  # Step 1: Determine which filter configuration to use
  # If filter is NA or not configured, use "default"
  filter_key <- if (is.na(filter) || !(filter %in% names(CONFIG$REGISTER_COLUMNS))) {
    "default"
  } else {
    filter
  }

  # Step 2: Get columns for this filter and file type
  # Try filter-specific config first, fall back to default if not found
  columns_to_keep <- NULL

  if (filter_key %in% names(CONFIG$REGISTER_COLUMNS)) {
    filter_config <- CONFIG$REGISTER_COLUMNS[[filter_key]]
    if (file_type %in% names(filter_config)) {
      columns_to_keep <- filter_config[[file_type]]
    }
  }

  # Fall back to default if filter-specific config not found
  if (is.null(columns_to_keep)) {
    if ("default" %in% names(CONFIG$REGISTER_COLUMNS)) {
      default_config <- CONFIG$REGISTER_COLUMNS[["default"]]
      if (file_type %in% names(default_config)) {
        columns_to_keep <- default_config[[file_type]]
      }
    }
  }

  # If still no config found, return table as-is with warning
  if (is.null(columns_to_keep)) {
    warning("No column configuration found for filter '", filter_key, "' and file type '", file_type, "'")
    return(register_table)
  }

  # Step 3: Keep only columns that exist in the table (in the specified order)
  final_columns <- intersect(columns_to_keep, names(register_table))

  # Step 4: Subset and reorder the register table
  register_table <- register_table[, final_columns, drop = FALSE]
  return(register_table)
}

#' Generate Table Details
#'
#' This function generates metadata and details for a specific table, including 
#' the table name, slugified name, subcategory (if applicable), and the output directory. 
#' It is used when rendering tables in different formats.
#'
#' @param table_key The key (name) of the table being processed.
#' @param table The data frame containing the table data.
#' @param filter A string specifying the filter applied to the table data.
#' @param is_reg_table A boolean indicating whether the table is a register table (default is TRUE).
#'
#' @return A list of table details including name, slugified name, subcategory (if applicable), and output directory.
generate_table_details <- function(table_key, table, filter, is_reg_table = TRUE){
  table_details <- list()
  # This information is needed when creating the html index section files
  table_details[["is_reg_table"]] <- is_reg_table

  # Setting the table name
  table_details[["name"]] <- table_key
  table_details[["slug_name"]] <- tolower(gsub(" ", "_", table_details[["name"]]))
  
  # Checking if the filter has a subcategory
  if (filter %in% names(CONFIG$FILTER_SUBCAT_COLUMNS)){
    subcat_col <- CONFIG$FILTER_SUBCAT_COLUMNS[[filter]]
    table_details[["subcat"]] <- table[[subcat_col]][1]
  }

  # Generating the output dir once here instead of multiple times
  table_details[["output_dir"]] <- generate_output_dir(filter, table_details)

  return(table_details)
}

#' Render Register in Specified Output Format
#'
#' This function renders the register table into different output formats based on the specified type.
#' It supports rendering the table as Markdown, HTML, or JSON.
#'
#' @param register_table The register table that needs to be rendered into different files.
#' @param table_details A list of details related to the table (e.g., output directory, metadata).
#' @param filter A string specifying the filter applied to the register data.
#' @param output_type A string specifying the desired output format "json" for JSON, 
#'        "csv" for CSVs, "md" for MD and "html" for HTMLs.
#'
#' @return None. The function generates a file in the specified format.
render_register <- function(register_table, table_details, filter = NA, output_type){
  register_table <- filter_and_drop_register_columns(register_table, filter, output_type)
  
  switch(output_type,
    "md" = render_register_md(register_table, table_details, filter),
    "html" = render_html(register_table, table_details, filter),
    "json" = render_register_json(register_table, table_details, filter)
  )
}

#' Generate Output Directory Path
#'
#' Generates the directory path for saving files based on info in the register table
#' and the filter name. Creates the output directory if it does not already exist
#'
#' @param filter The filter name (e.g., "venues", "codecheckers").
#' @param table_details List containing details such as the table name, subcat name.
#'
#' @return A string representing the directory path for saving files.
generate_output_dir <- function(filter, table_details = list()) {
  base_dir <- "docs/"

  # We have register tables
  if (table_details[["is_reg_table"]]){
    # We have the original register table
    if (is.na(filter)){
      output_dir <- base_dir
    }

    # We have filtered register tables
    else{
      table_name <- table_details[["slug_name"]]
      
      # The table belongs to a subcat so we need a nested folder
      if ("subcat" %in% names(table_details)){
        plural_subcat <- CONFIG$VENUE_SUBCAT_PLURAL[[table_details[["subcat"]]]]
        output_dir <- paste0(base_dir, filter, "/", plural_subcat, "/", table_name, "/")
      }

      # The table does not belong to a subcat
      else{
        output_dir <- paste0(base_dir, filter, "/", table_name, "/")
      }
    }
  }

  # We have non register tables
  else{
    if ("subcat" %in% names(table_details)){
      plural_subcat <- CONFIG$VENUE_SUBCAT_PLURAL[[table_details[["subcat"]]]]
      output_dir <- paste0(base_dir, filter, "/", plural_subcat, "/")
    }

    else{
      output_dir <- paste0(base_dir, filter, "/")
    }
  }

  # Creating the output dir if it does not already exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = TRUE)
  }
  return(output_dir)
}