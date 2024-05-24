create_filtered_register_csvs <- function(filter_by, register, FILTER_SUB_GROUPS){

  for (filter in filter_by){
    column_name <- determine_column_name(filter)
    unique_values <- unique(register[[column_name]])

    for (value in unique_values) {
      filtered_register <- register[register[[column_name]]==value, ]
      output_dir <- paste0(get_output_dir(filter, value), "register.csv")

      if (!dir.exists(dirname(output_dir))) {
        dir.create(dirname(output_dir), recursive = TRUE, showWarnings = TRUE)
      }

      write.csv(filtered_register, output_dir, row.names=FALSE)
    }    
  }
}

determine_column_name <- function(filter) {
  column_name <- switch(filter,
         "venues" = "Type",
         NULL # Default case is set to NULL
         )
  if (is.null(column_name)) {
    stop(paste("Filter", filter, "is not recognized."))
  }

  return(column_name)
}

get_output_dir <- function(filter, value) {
  if (filter=="none"){
    return(paste0("docs/"))
  }
  
  else if (filter=="venues"){
    venue_category <- determine_venue_category(value)
    if (!(venue_category %in% CONFIG$FILTER_SUB_GROUPS[["venues"]])){
      venue_category <- gsub(" ", "_", venue_category)
      return(paste0("docs/", filter, "/", venue_category, "/"))
    }

    # Removing the venue category to obtain the venue name
    venue_name <- trimws(gsub("[()]", "", gsub(venue_category, "", value)))
    venue_name <- gsub(" ", "_", venue_name)
    return(paste0("docs/", filter, "/", venue_category, "/", venue_name, "/"))
  }

  else{
    return(paste0("docs/", filter, "/", gsub(" ", "_", tolower(value)), "/"))
  }
}

determine_venue_category <- function(venue_name){
  list_venue_categories <- CONFIG$FILTER_SUB_GROUPS[["venues"]]
  for (category in list_venue_categories){
    if (grepl(category, venue_name)) {
      return(category)
    }
  }
  # The venue does not belong to the listed categories. 
  warning(paste("Register venue does not fall into any of the following venue categories:", toString(list_venue_categories), "Setting its own name as a"))
  return(venue_name)
}
