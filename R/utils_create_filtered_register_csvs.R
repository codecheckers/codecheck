#' Save Filtered DataFrame to CSV
#'
#' Saves a filtered DataFrame to a CSV file in an output directory determined by the filter type, 
#' table name, and an optional subcategory. Creates the directory if it doesn't exist.
#'
#' @param filtered_register DataFrame to be saved.
#' @param filter Type of filter applied (e.g., "codecheckers", "venues").
#' @param table_name Name of the table or filtered item.
#' @param filter_subcategory Optional subcategory for the output directory structure (e.g., venue type). Default is NULL.
save_filtered_csv <- function(filtered_register, filter, table_name, filter_subcategory = NULL){
  output_dir <- paste0(get_output_dir(filter, table_name, filter_subcategory), "register.csv")

  # Create the output directory if it doesnt exist
  if (!dir.exists(dirname(output_dir))) {
    dir.create(dirname(output_dir), recursive = TRUE, showWarnings = TRUE)
  }

  write.csv(filtered_register, output_dir, row.names=FALSE)
}

#' Creates filtered codecheckers register CSV file
#'
#' This function reads a temporary codechecker register, filters the data based on 
#' ORCID IDs, and saves the filtered registers as CSV files. Each CSV file is saved 
#' in a directory named after the corresponding ORCID ID.
create_codechecker_filtered_reg_csv <- function(){
  # Using the temporary codechecker register
  register <- read.csv(CONFIG$DIR_TEMP_REGISTER_CODECHECKER, as.is = TRUE)
  # Once the temp_register is loaded, we can remove it
  file.remove(CONFIG$DIR_TEMP_REGISTER_CODECHECKER)

  # Using the ORCID IDs to filter the register by
  unique_col_values <- names(CONFIG$DICT_ORCID_ID_NAME)

  for (table_name in unique_col_values){
    mask <- sapply(register$Codechecker, function(x) table_name %in% fromJSON(x))
    filtered_register <- register[mask, ]

    # Only keeping specific columns listed in CONFIG$REGISTER_COLUMNS
    filtered_register <- filtered_register[, names(filtered_register) %in% CONFIG$REGISTER_COLUMNS]

    save_filtered_csv(filtered_register, filter="codecheckers", table_name)
  }
}

#' Create Filtered Venue Register CSV Files
#'
#' This function filters a register DataFrame based on venue-related columns ("Type" and "Venue"). 
#' It saves filtered CSV files for each unique value within these columns. 
#' For venue names, the corresponding venue type is also passed to determine the appropriate output directory.
#'
#' @param register A DataFrame representing the complete register data to be filtered.
create_venue_filtered_reg_csv <- function(register){

  filter_col_names <- CONFIG$FILTER_COLUMN_NAMES[["venues"]]

  for (col_name in filter_col_names){
    unique_col_values <- unique(register[[col_name]])

    # Filtering the register
    for (table_name in unique_col_values) {
      filtered_register <- register[register[[col_name]]==table_name, ]
      filtered_register <- filtered_register[, names(filtered_register) %in% CONFIG$REGISTER_COLUMNS]

      # When creating the filtered csv for venue name, we determine the venue type
      if (col_name == "Venue"){
        filter_subcategory <- filtered_register[["Type"]][1]
      }

      # Saving the filtered csv
      switch(col_name,
        # For the case of venue names we pass col_subcategory (the venue type). 
        # This is needed for the output dir
        "Venue" = save_filtered_csv(filtered_register, filter="venues", table_name, filter_subcategory),
        "Type" = save_filtered_csv(filtered_register, filter="venues", table_name)
      )
    }
  }
}

#' Creates filtered register csv files
#'
#' Each csv file is saved in the appropriate output_dir.
#'
#' @param filter_by A vector of strings specifying the names of the columns to filter by.
#' @param register A dataframe representing the register data to be filtered.
create_filtered_register_csvs <- function(filter_by, register){

  for (filter in filter_by){
    switch (filter,
      "codecheckers" = create_codechecker_filtered_reg_csv(),
      "venues" = create_venue_filtered_reg_csv(register),
    )
  }
}

#' Get Output Directory Path
#'
#' Determines the directory path for saving files based on the filter, table name, 
#' and an optional subcategory.
#'
#' @param filter The filter name (e.g., "venues", "codecheckers").
#' @param table_name The name of the table or item being filtered.
#' @param filter_subcategory Optional subcategory for more specific filtering (e.g., venue type). Default is NULL.
#'
#' @return A string representing the directory path for saving files.
get_output_dir <- function(filter, table_name, filter_subcategory = NULL) {
  base_dir <- "docs/"
  
  if (filter=="none"){
    return(base_dir)
  }
  
  # Case where we have specific venue name (filter_subcategory is not NULL)
  else if (filter=="venues" && !is.null(filter_subcategory)){
    # Replace white space with "_" in the venue name
    venue_name <- gsub(" ", "_", tolower(table_name))
    return(paste0(base_dir, filter, "/", filter_subcategory, "/", venue_name, "/"))  
  }

  else{
    return(paste0(base_dir, filter, "/", gsub(" ", "_", table_name), "/"))
  }
}
