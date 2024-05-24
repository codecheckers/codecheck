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

    list_1 <- unlist(list_register_tables, recursive = TRUE)
    return(list_register_tables)
}

#' Function for creating a list of register tables that is filtered based on the filter type.
#' Each entry in the resulting list is the filtered register table with index corresponding to unique values in that column.
#'
#' @param register_table The register table
#' @param filter_column The column to filter by
#' @return A list of filtered register tables
create_filtered_register_tables <- function(register_table, filter) {
    list_filtered_register_tables <- list()
    
    column_name <- determine_column_name(filter)
    unique_values <- unique(register_table[[column_name]])
    # Loop over the unique values. We create a sorted table for each value
    for (value in unique_values) {
        filtered_table <- register_table[register_table[[column_name]]==value, ]
        rownames(filtered_table) <- NULL  # Reset row names to remove row numbers
        list_filtered_register_tables[[value]] <- filtered_table
    }    

    print(names(list_filtered_register_tables))
    return(list_filtered_register_tables)
}
