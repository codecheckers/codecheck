create_filtered_register_csvs <- function(filter_by, register){

  for (filter in filter_by){
    column_name <- determine_column_name(filter)
    unique_values <- unique(register$column_name)

    for (value in unique_values) {
      filtered_register <- register[register$column_name==value, ]
      output_dir <- get_output_dir(filter, value)

      if (!dir.exists(dirname(output_dir))) {
        dir.create(dirname(output_dir), recursive = TRUE, showWarnings = TRUE)
      }

      write.csv(filtered_register, output_dir, row.names=FALSE)
    }    
  }
}

determine_column_name <- function(filter) {
  result <- switch(filter,
         "venue" = "Type",
         NULL # Default case is set to NULL
         )
  if (is.null(result)) {
    stop(paste("Filter", filter, "is not recognized."))
  }

  return(result)
}

get_output_dir <- function(filter, value) {
  if (filter=="none"){
    return(paste0("docs/"))
  }
  
  else if (filter=="venue"){
    venue_category <- determine_venue_category(value)
    # Removing the venue category to obtain the venue name
    venue_name <- trimws(gsub("[()]", "", gsub(venue_category, "", venue_name)))

    return(paste0("docs/", filter, "/", venue_category, "/", venue_name, "/"))
  }

  else{
    return(paste0("docs/", filter, "/", gsub(" ", "_", tolower(value)), "/"))
  }
}

determine_venue_category <- function(venue_name){
  for (category in list_venue_categories){
    if (grepl(category, venue_name)) {
      return(category)
    }
  }
  # The venue does not belong to the listed categories. Throwing an error
  stop(paste("Register venue does not fall into any of the following venue categories:", toString(list_venue_categories)))
}
