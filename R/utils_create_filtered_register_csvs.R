
create_filtered_reg_csvs <- function(register, filter_by){
  for (filter in filter_by){
    if (filter == "codecheckers"){
      # Using the temporary codechecker register
      register <- read.csv(CONFIG$DIR_TEMP_REGISTER_CODECHECKER, as.is = TRUE)
      # Once the temp_register is loaded, we can remove it
      file.remove(CONFIG$DIR_TEMP_REGISTER_CODECHECKER)
    }

    filter_col_name <- CONFIG$FILTER_COLUMN_NAMES[[filter]]
    
    # Creating groups of csvs
    # Not using the nesting functionality since we want to keep the same columns
    grouped_registers <- register %>%
      group_by(across(all_of(filter_col_name))) 

    # Split into a list of data frames
    filtered_register_list <- grouped_registers %>% group_split()

    # Get the group names (keys) based on the filter names
    register_keys <- grouped_registers %>% group_keys()

    # Iterating through each group and generating csv
    for (i in seq_along(filtered_register_list)) {
      # Retrieving the register and its key
      register_key <- register_keys[i, ]
      register <- filtered_register_list[[i]]

      table_details <- generate_table_details(register_key, register, filter)

      json_dir <- paste0(table_details[["output_dir"]], "register.csv")
      print(json_dir)
      write.csv(register, json_dir, row.names=FALSE)
    }
  } 
}
