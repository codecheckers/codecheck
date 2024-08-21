#' Save a filtered DdataFrame to a CSV File
#' 
#' The output directory is determined based on the filter type, column value, and 
#' an optional subcategory. If the directory does not exist, it is created.
#'
#' @param filtered_register The filtered register DataFrame to be saved.
#' @param filter A string specifying the type of filter applied (e.g., "codecheckers", "venues").
#' @param col_value A string representing the specific value within the filtered column.
#' @param col_subcategory An optional string representing a subcategory within the filter (e.g., venue type). 
#' This is needed for the case where the output dir should be of the form col_subcategory/col_value. Default is NULL.
save_filtered_csv <- function(filtered_register, filter, col_value, col_subcategory = NULL){
  output_dir <- paste0(get_output_dir(filter, col_value, col_subcategory), "register.csv")

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

  for (col_value in unique_col_values){
    mask <- sapply(register$Codechecker, function(x) col_value %in% fromJSON(x))
    filtered_register <- register[mask, ]

    # Only keeping specific columns listed in CONFIG$REGISTER_COLUMNS
    filtered_register <- filtered_register[, names(filtered_register) %in% CONFIG$REGISTER_COLUMNS]

    save_filtered_csv(filtered_register, filter="codecheckers", col_value)
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
    for (col_value in unique_col_values) {
      filtered_register <- register[register[[col_name]]==col_value, ]
      filtered_register <- filtered_register[, names(filtered_register) %in% CONFIG$REGISTER_COLUMNS]

      # When creating the filtered csv for venue name, we determine the venue type
      if (col_name == "Venue"){
        col_subcategory <- filtered_register[["Type"]][1]
      }

      # Saving the filtered csv
      switch(col_name,
        # For the case of venue names we pass col_subcategory (the venue type). 
        # This is needed for the output dir
        "Venue" = save_filtered_csv(filtered_register, filter="venues", col_value, col_subcategory),
        "Type" = save_filtered_csv(filtered_register, filter="venues", col_value)
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

#' Gets the output dir depending on the filter name and the value of the filtered column
#'
#' @param filter The filter name
#' @param column_value The value of the column the filter applies to
#' @return The directory to save files to
get_output_dir <- function(filter, col_value, col_subcategory = NULL) {
  base_dir <- "docs/"
  
  if (filter=="none"){
    return(base_dir)
  }
  
  else if (filter=="venues"){
    # Output dir for each venue name is venue_tpe/venue_name
    if (!is.null(col_subcategory)){
      # Replace white space with "_" in the venue name
      venue_name <- gsub(" ", "_", tolower(col_value))
      return(paste0(base_dir, filter, "/", col_subcategory, "/", venue_name, "/"))  
    }

    # Case where we have venue types
    return(paste0(base_dir, filter, "/", gsub(" ", "_", col_value), "/"))
  }

  else if (filter=="codecheckers"){
    return(paste0(base_dir, filter, "/", gsub(" ", "_", col_value), "/"))
  }

  else{
    return(paste0(base_dir, filter, "/", gsub(" ", "_", tolower(col_value)), "/"))
  }
}
