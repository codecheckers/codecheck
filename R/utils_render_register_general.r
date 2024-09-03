
generate_table_details <- function(nested_register_tables, i, filter){
  table_details <- list()
  filter_col_name <- CONFIG$FILTER_COLUMN_NAMES[[filter]]

  nested_table <- nested_register_tables[["data"]][[i]]

  table_details[["name"]] <- nested_register_tables[[filter_col_name]][[i]]
  table_details[["slug_name"]] <- tolower(gsub(" ", "_", table_details[["name"]]))
  table_details[["outpur_dir"]] <- get_output_dir(table_details, filter)

  if (filter %in% names(CONFIG$FILTER_SUBCAT_COLUMNS)){
    subcat_col <- CONFIG$FILTER_SUBCAT_COLUMNS[[filter]]
    table_details[["subcat"]] <- nested_table[[subcat_col]][1]
  }

  return(table_details)
}

render_register <- function(register_table, table_details, filter, output_type){
  switch(output_type,
    "md" = render_register_md(`register_table, table_details, filter),
    "html" = render_register_html(register_table, table_details, filter),
    "json" = render_register_json(register_table, table_details, filter)
  )
}

#' Get Output Directory Path
#'
#' Determines the directory path for saving files based on info in the register table
#' and the filter name
#'
#' @param table_details List containing details such as the table name, subcat name.
#' @param filter The filter name (e.g., "venues", "codecheckers").
#'
#' @return A string representing the directory path for saving files.
get_output_dir <- function(table_details, filter) {
  base_dir <- "docs/"
  table_name <- table_details[["slug_name"]]
  
  if (filter=="none"){
    output_dir <- base_dir
  }

  # The table belongs to a subcat so we need a nested folder
  if ("subcat" %in% names(table_details)){
    output_dir <- paste0(base_dir, filter, "/", table_details[["subcat"]], "/", table_name, "/")
  }

  # The table does not belong to a subcat
  else{
    output_dir <- paste0(base_dir, filter, "/", table_name, "/")
  }

  # Creating the output dir if it does not already exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = TRUE)
  }
  return(output_dir)
}