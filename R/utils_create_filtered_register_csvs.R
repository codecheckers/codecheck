#' Creates filtered register csv files
#'
#' Each csv file is saved in the appropriate output_dir.
#'
#' @param filter_by A vector of strings specifying the names of the columns to filter by.
#' @param register A dataframe representing the register data to be filtered.
create_filtered_register_csvs <- function(filter_by, register){

  for (filter in filter_by){
    column_name <- determine_filter_column_name(filter)

    # If filtered by codecheckers we replace the register with the register with codechecker
    # columns
    if (filter == "codecheckers"){
      register <- read.csv(CONFIG$DIR_TEMP_REGISTER_CODECHECKER, as.is = TRUE)
      # Once the temp_register is loaded, we can remove it
      file.remove(CONFIG$DIR_TEMP_REGISTER_CODECHECKER)
    }

    unique_values <- get_unique_values_from_filter(register, column_name)

    # Filtering the register
    for (value in unique_values) {
      # For filtering by codechecker we need to check if unique value is contained
      # in the list which is the row value.
      if (column_name == "Codechecker"){
        mask <- sapply(register$Codechecker, function(x) value %in% fromJSON(x))
        filtered_register <- register[mask, ]

        #! Edit depending on whether they want to keep the column
        # Only keeping the column values specified in CONFIG$REGISTER_COLUMNS
        filtered_register <- filtered_register[, names(filtered_register) %in% CONFIG$REGISTER_COLUMNS]
      }

      # Else we check against the row value itself
      else{
        filtered_register <- register[register[[column_name]]==value, ]
      }
    
      output_dir <- paste0(get_output_dir(filter, value), "register.csv")

      if (!dir.exists(dirname(output_dir))) {
        dir.create(dirname(output_dir), recursive = TRUE, showWarnings = TRUE)
      }

      write.csv(filtered_register, output_dir, row.names=FALSE)
    }    
  }
}

#' Determines the register table's column name to filter the data by.
#'
#' @param filter The filter name
#' @return The column name to filter by
determine_filter_column_name <- function(filter) {
  filter_column_name <- switch(filter,
         "venues" = "Type",
         "codecheckers" = "Codechecker",
         NULL # Default case is set to NULL
         )
  if (is.null(filter_column_name)) {
    stop(paste("Filter", filter, "is not recognized."))
  }

  return(filter_column_name)
}

get_unique_values_from_filter <- function(register_table, filter_column_name){
    # Directly retrieve from DIC_ORCID_ID_NAME
    if (filter_column_name == "Codechecker"){
      unique_values <- names(CONFIG$DICT_ORCID_ID_NAME)
    } 

    else{
        unique_values <- unique(register_table[[filter_column_name]])
    }
    return(unique_values)
}

#' Gets the output dir depending on the filter name and the value of the filtered column
#'
#' @param filter The filter name
#' @param column_value The value of the column the filter applies to
#' @return The directory to save files to
get_output_dir <- function(filter, column_value) {
  if (filter=="none"){
    return(paste0("docs/"))
  }
  
  else if (filter=="venues"){
    venue_category <- determine_venue_category(column_value)
    # In case the venue_category itself has no further subgroups we do not need subgroups
    if (is.null(venue_category)){
      return(paste0("docs/", filter, "/", gsub(" ", "_", column_value), "/"))
    }

    # Removing the venue category to obtain the venue name and replace the brackets
    venue_name <- determine_venue_name(column_value, venue_category)
    return(paste0("docs/", filter, "/", venue_category, "/", venue_name, "/"))  }

  else if (filter=="codecheckers"){
    # The codechecker column is always a list of codecheckers
    for (codechecker in column_value){
      return(paste0("docs/", filter, "/", gsub(" ", "_", codechecker), "/"))
    }
  }

  else{
    return(paste0("docs/", filter, "/", gsub(" ", "_", tolower(column_value)), "/"))
  }
}

#' Determines the venue category based on the venue_name
#'
#' @param venue_name The venue_name obtained from the "Type" column of the register
#' @return The venue category. If the venue does not belong to any category NULL is returned
determine_venue_category <- function(venue_name){
  list_venue_categories <- CONFIG$FILTER_SUB_GROUPS[["venues"]]
  for (category in list_venue_categories){
    if (grepl(category, venue_name, ignore.case=TRUE)) {
      return(category)
    }
  }
  warning(paste("Register venue", venue_name, "does not fall into any of the following venue categories:", toString(list_venue_categories)))
  return(NULL)
}

determine_venue_name <- function(unfiltered_venue_name, venue_category){
  if (is.null(venue_category)){
    return(NULL)
  }

  venue_name <- trimws(gsub("[()]", "", gsub(venue_category, "", unfiltered_venue_name, ignore.case = TRUE)))
  venue_name <- gsub(" ", "_", venue_name)
  return(venue_name)
}
