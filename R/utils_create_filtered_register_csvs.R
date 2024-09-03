
create_filtered_reg_csv <- function(register, filter_by){
  for (filter in filter_by){
    if (filter == "codecheckers"){
      # Using the temporary codechecker register
      register <- read.csv(CONFIG$DIR_TEMP_REGISTER_CODECHECKER, as.is = TRUE)
      # Once the temp_register is loaded, we can remove it
      file.remove(CONFIG$DIR_TEMP_REGISTER_CODECHECKER)
    }

    filter_col_names <- CONFIG$FILTER_COLUMN_NAMES[[filter]]
    
    # Creating groups of csvs
    # Not using the nesting functionality since we want to keep the same columns
    grouped_registers <- register %>%
      group_by(across(all_of(filter_col_names))) 

    # Split into a list of data frames
    grouped_list <- grouped_registers %>% group_split()

    # Get the group names (keys) based on the filter names
    group_keys <- grouped_registers %>% group_keys()

    # Iterating through each group and generating csv
    for (i in seq_along(grouped_list)) {
      group_name <- group_keys[i, ]
      group_data <- grouped_list[[i]]

      table_details <- generate_register_csv_table_details(group_name, group_data, filter)

      json_dir <- paste0(table_details[["output_dir"]], "register.csv")
      print(json_dir)
      write.csv(group_data, json_dir, row.names=FALSE)
    }
  } 
}

generate_register_csv_table_details <- function(group_name, group_data, filter){
  table_details <- list()

  # Setting the table name
  table_details[["name"]] <- group_name
  table_details[["slug_name"]] <- tolower(gsub(" ", "_", table_details[["name"]]))
  
  # Checking if the filter has a subcategory
  if (filter %in% names(CONFIG$FILTER_SUBCAT_COLUMNS)){
    subcat_col <- CONFIG$FILTER_SUBCAT_COLUMNS[[filter]]
    table_details[["subcat"]] <- group_data[[subcat_col]][1]
  }

  # Generating the output dir once here instead of multiple times
  table_details[["output_dir"]] <- generate_output_dir(filter, table_details)

  return(table_details)
}
