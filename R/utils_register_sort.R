#' Function for creating a list of register tables that is sorted by venue. 
#' Each entry in the resulting list uses a key that combines 'venue_' with the venue name, 
#' and maps to a corresponding sorted register table.
#' 
#' @param register_table The register table
#' @return A list of venue sorted register tables. 
create_list_venue_sorted_register_tables <- function(register_table) {
    # List of venues
    list_venues <- unique(register_table$Type)

    # Loop over venues. For each venue we create a separate register table
    list_venue_sorted_register_tables <- list()
    for (venue in list_venues) {
        sorted_register_table <- register_table[register_table$`Type`==venue, ]
        rownames(sorted_register_table) <- NULL  # Reset row names to remove row numbers
        list_venue_sorted_register_tables[[paste("venue", venue, " ")]] <- sorted_register_table
    }    
    return(list_venue_sorted_register_tables)
}