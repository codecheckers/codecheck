create_register_files_original <- function(register_table, outputs){
  filter <- "none"
  for (output_type in outputs){
    table_details <- list(
      output_dir = generate_output_dir(filter),
      is_reg_table = TRUE
    )
    register_table <- filter_and_drop_register_columns(register_table, filter)
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
  create_register_files_original(register_table, outputs)
  
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

        # Dropping columns that are redundant
        filtered_table <- filter_and_drop_register_columns(filtered_table, filter)
        render_register(filtered_table, table_details, filter, output_type)
      }
    }
  }
}

filter_and_drop_register_columns <- function(register_table, filter) {
  
  # Step 1: Columns that we want to keep
  columns_to_keep <- CONFIG$REGISTER_COLUMNS
  
  # Initialize final columns to columns_to_keep in case no filter is applied
  final_columns <- intersect(columns_to_keep, names(register_table))
  
  # Step 2: Check if the filter exists in CONFIG and drop columns if necessary
  if (filter %in% names(CONFIG$FILTER_COLUMN_NAMES_TO_DROP)) {
    columns_to_drop <- CONFIG$FILTER_COLUMN_NAMES_TO_DROP[[filter]]
    
    # Ensure we only keep valid columns that aren't in columns_to_drop
    final_columns <- setdiff(final_columns, columns_to_drop)
  }
  final_columns <- as.character(final_columns) 

  # Step 3: Subset the register table to keep only the final columns
  register_table <- register_table[, final_columns, drop = FALSE]
  return(register_table)
}

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

render_register <- function(register_table, table_details, filter, output_type){
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
    if (filter=="none"){
      output_dir <- base_dir
    }

    # We have filtered register tables
    else{
      table_name <- table_details[["slug_name"]]

      # The table belongs to a subcat so we need a nested folder
      if ("subcat" %in% names(table_details)){
        output_dir <- paste0(base_dir, filter, "/", table_details[["subcat"]], "/", table_name, "/")
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
      output_dir <- paste0(base_dir, filter, "/", table_details[["subcat"]], "/")
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