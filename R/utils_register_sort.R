create_list_venue_sorted_register_tables <- function(register_table) {
    # List of venues
    list_venues <- unique(register_table$Type)

    # Loop over venues. For each venue we create a separate register table
    list_venue_sorted_register_tables <- list()

    for (venue in list_venues) {
        sorted_register_table <- register_table[register_table$`Type`==venue, ]
        list_venue_sorted_register_tables[["venue_" + venue]] <- sorted_register_table
    }     

    return(list_venue_sorted_register_tables)
}