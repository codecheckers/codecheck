#' Function for creating a list of register tables that is filtered based on the filter type.
#' Each entry in the resulting list is the filtered register table with index corresponding to unique values in that column.
#'
#' @param register_table The register table
#' @param filter The filter name
#' @return A list of filtered register tables
create_filtered_register_tables <- function(register_table, filter_by) {
    list_filtered_register_tables <- list()

    for (filter in filter_by){
        list_filtered_register_tables[[filter]] <- switch(filter, 
            "venues" = create_venues_filtered_register_tables(register_table),
            "codecheckers" = create_codecheckers_filtered_register_tables(register_table)
        )
    }
    return(list_filtered_register_tables)
}

create_venues_filtered_register_tables <- function(register_table){
    list_venue_filtered_tables <- list()
    unique_col_values <- unique(register_table[["Venue"]])

    for (col_value in unique_col_values){
        filtered_table <- register_table[register_table[["Venue"]]==col_value, ]

        # Only keeping the column names specified in CONFIG$REGISTER_COLUMNS
        filtered_table <- filtered_table[, names(filtered_table) %in% CONFIG$REGISTER_COLUMNS]
        rownames(filtered_table) <- NULL  # Reset row names to remove row numbers

        col_subcategory <- filtered_table[["Type"]][1]
        list_venue_filtered_tables[[col_subcategory]][[col_value]] <- filtered_table
    }

    return(list_venue_filtered_tables)
}

create_codecheckers_filtered_register_tables <- function(register_table){
    list_codechecker_filtered_tables <- list()

    list_codecheckers <- names(CONFIG$DICT_ORCID_ID_NAME)

    for (codechecker in list_codecheckers){
        # Applying mask to only keep rows of data with the matching codechecker name
        mask <- sapply(register_table[["Codechecker"]], function(x) codechecker %in% x)
        filtered_table <- register_table[mask, ]
        
        # Only keeping the column names specified in CONFIG$REGISTER_COLUMNS
        filtered_table <- filtered_table[, names(register_table) %in% CONFIG$REGISTER_COLUMNS]
        rownames(filtered_table) <- NULL  # Reset row names to remove row numbers

        list_codechecker_filtered_tables[[codechecker]] <- filtered_table
    }

    return(list_codechecker_filtered_tables)
}