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

#' Create filtered venue register tables
#'
#' Filters a register based on unique venue names and creates a register table for each venue name.
#' Each filtered table is stored in a nested list structure where the top-level keys are the 
#' venue types and the second-level keys are the venue names.
#'
#' @param register_table The original unfiltered register table.
#'
#' @return A nested list where each top-level key corresponds to a venue type and each second-level key corresponds 
#'         to a specific venue. The value at each key is a DataFrame containing the filtered data for that venue.
#'
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

#' Create filtered codechecker register table
#'
#' Filters a register based on ORCID ID and creates a register table for each ORCID ID
#' Each filtered table is stored in a list structure where the keys are the 
#' ORCID 
#' 
#' @param register_table The original unfiltered register table.
#'
#' @return A list where each key corresponds to a codechecker (identified by ORCID ID) and the value is 
#'         a DataFrame containing the filtered data for that codechecker.
#'
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