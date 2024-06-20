#' Function for adding filtered register tables to a list based on specified filters.
#' Each entry in the resulting list is a filtered register table by the filter type provided.
#'
#' @param list_register_tables A list to store the filtered tables
#' @param register_table The register table to filter
#' @param filter_by A vector of strings specifying the filter types
#' @return A list of filtered register tables
add_filtered_register_tables <- function(list_register_tables, register_table, filter_by) {

    for (filter in filter_by){
        list_register_tables[[filter]] <- create_filtered_register_tables(register_table, filter)
    }

    return(list_register_tables)
}

#' Function for creating a list of register tables that is filtered based on the filter type.
#' Each entry in the resulting list is the filtered register table with index corresponding to unique values in that column.
#'
#' @param register_table The register table
#' @param filter The filter name
#' @return A list of filtered register tables
create_filtered_register_tables <- function(register_table, filter) {
    list_filtered_register_tables <- list()
    
    filter_column_name <- determine_filter_column_name(filter)
    unique_values <- get_unique_values_from_filter(register_table, filter_column_name)
    
    # Loop over the unique values. We create a filtered table for each value
    # For filter by codechecker the table indices in the list will be the orcid ID. 
    for (value in unique_values) {
        # For filtering by codechecker we need to check if unique value is contained
        # in the list which is the row value
        if (filter_column_name == "Codechecker"){
            mask <- sapply(register_table$Codechecker, function(x) value %in% x)
            filtered_table <- register_table[mask, ]
        }

        else{
            filtered_table <- register_table[register_table[[filter_column_name]]==value, ]
        }

        #! Edit depending on whether they want to keep the column
        # Dropping columns not specificied in CONFIG$REGISTER_COLUMNS
        filtered_table <- filtered_table[, names(register_table) %in% CONFIG$REGISTER_COLUMNS]

        rownames(filtered_table) <- NULL  # Reset row names to remove row numbers
        list_filtered_register_tables[[value]] <- filtered_table
    }    

    return(list_filtered_register_tables)
}
