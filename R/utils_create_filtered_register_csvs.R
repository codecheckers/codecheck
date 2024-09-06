#' Creates filtered CSV files from a register based on specified filters.
#' 
#' The function processes the register by applying filters specified in `filter_by`. 
#' For "codecheckers", a temporary CSV is loaded and processed as the original register.csv
#' does not have the codechecker column. 
#' The register is then grouped by the filter column, and for each group, a CSV file is generated.
#' 
#' @param register The register to be filtered.
#' @param filter_by List of filters to apply (e.g., "venues", "codecheckers").
#' 
create_filtered_reg_csvs <- function(register, filter_by){
  for (filter in filter_by){
    if (filter == "codecheckers"){
      # Using the temporary codechecker register
      register <- read.csv(CONFIG$DIR_TEMP_REGISTER_CODECHECKER, as.is = TRUE)
      # Once the temp_register is loaded, we can remove it
      file.remove(CONFIG$DIR_TEMP_REGISTER_CODECHECKER)

      # Splitting the comma-separated strings into lists
      register$Codechecker <- strsplit(register$Codechecker, ",")
      
      # Unnesting the files
      register <- register %>% tidyr::unnest(Codechecker)
      register$Codechecker <- unlist(register$Codechecker)
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
      register_key <- register_keys[[filter_col_name]][i]
      filtered_register <- filtered_register_list[[i]]
      table_details <- generate_table_details(register_key, filtered_register, filter)
      filtered_register <- filter_and_drop_register_columns(filtered_register, filter)
      output_dir <- paste0(table_details[["output_dir"]], "register.csv")
      write.csv(filtered_register, output_dir, row.names=FALSE)
    }
  } 
}
