#' Create Venues Tables
#'
#' Generates tables for all venues and venues categorized by type. 
#' It creates a general venues table and specific venue type tables.
#'
#' @param register_table The original register data.
#'
#' @return A list of tables including the general venues table and venue type-specific tables.
create_venues_tables <- function(register_table){
  list_tables <- list()
  list_tables[["venues"]] <- create_all_venues_table(register_table)

  list_venue_type_tables <- create_venue_type_tables(register_table)

  # Returning the concatenated list of tables
  return(c(list_tables, list_venue_type_tables))
}

#' Add Hyperlinks to Venues Table
#'
#' Adds hyperlinks to the venue names, venue types, and the number of codechecks 
#' in the venues table. If a subcategory is provided, it generates links based on venue types.
#'
#' @param table The data frame containing the venues data.
#' @param subcat An optional string specifying the subcategory (venue type) for the venues.
#'
#' @return The data frame with hyperlinks added to the appropriate columns.
add_venues_hyperlink <- function(table, subcat){
  if (is.null(subcat)){
    return(add_all_venues_hyperlink(table))
  }

  return(add_venue_type_hyperlink(table, venue_type = subcat))
}

#' Create All Venues Table
#'
#' This function generates a table with all unique venues and their corresponding types.
#' It also adds columns for the number of codechecks and a slug for the venue name.
#'
#' @param register_table The data frame containing the original register data.
#'
#' @return A data frame with venues, their types, the number of codechecks, and a slug name.
create_all_venues_table <- function(register_table){
  # Only keeping the Type and Venue column and unique combinations of the two
  new_table <- register_table %>%
    dplyr::select(Type, Venue) %>%
    distinct()

  # Adding no. of codechecks column
  new_table <- new_table %>%
    group_by(Venue) %>%
    mutate(no_codechecks = sum(register_table$Venue == Venue))

  # Adding slug name column. This is needed for the hyperlinks 
  new_table <- new_table %>%
    group_by(Venue) %>%
    mutate(`venue_slug` = gsub(" ", "_", stringr::str_to_lower(Venue)))
  
  # Updating each venue name with the names in CONFIG$DICT_VENUE_NAMES
  # Recode maps each Venue values to the corresponding Venue value in the dict
  new_table <- new_table %>%
    mutate(Venue = recode(Venue, !!!CONFIG$DICT_VENUE_NAMES))

  # Rename the column using the key-value pairs from the CONFIG list
  col_names_dict <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues"]]
  for (key in names(col_names_dict)) {
    colnames(new_table)[colnames(new_table) == key] <- col_names_dict[[key]]
  }

  return(new_table)
}

#' Add Hyperlinks to All Venues Table
#'
#' Adds hyperlinks to the venue names, venue types, and the number of codechecks 
#' in the all venues table. The links point to the venue's page and the venue type's page.
#'
#' @param table The data frame containing data on all venues.
#'
#' @return The data frame with hyperlinks added to the appropriate columns.
add_all_venues_hyperlink <- function(table){
  # Extracting column names from CONFIG
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues"]]

  # !!sym is used to refer to column names defined in the CONFIG$NON_REG_TABLE_COL_NAMES 
  # dynamically
  table <- table %>%

    # NOTE: The order of these mutation must be kept in this order because of
    # dependencies on the links on the column values
    mutate(
      # Generate venue name hyperlink
      !!col_names[["Venue"]] := paste0(
        "[", !!sym(col_names[["Venue"]]), "](",
        "https://codecheck.org.uk/register/venues/", 
        !!sym(col_names[["Type"]]), "/",
        venue_slug, "/)"
      ),

      # Generate no. of codechecks hyperlink
      !!col_names[["no_codechecks"]] := paste0(
        !!sym(col_names[["no_codechecks"]]), 
        " [(see all checks)](https://codecheck.org.uk/register/venues/", 
        !!sym(col_names[["Type"]]), "/",
        venue_slug, "/)"
      ),

      # Generate venue type hyperlink
      !!col_names[["Type"]] := paste0(
        "[", stringr::str_to_title(!!sym(col_names[["Type"]])), 
        "](https://codecheck.org.uk/register/venues/", 
        !!sym(col_names[["Type"]]), "/)"
      )
    )

  # Removing the venue slug column
  table <- table %>% select(-`venue_slug`)
  return(table)
}

#' Create Venue Type-Specific Tables
#'
#' Generates tables for each venue type by filtering the register data. 
#' It adds columns for the venue slug and the number of codechecks for each venue type.
#'
#' @param register_table The data frame containing the original register data.
#'
#' @return A list of tables, one for each venue type.
create_venue_type_tables <- function(register_table){
  list_venue_type_tables <- list()

  # Retrieving the unique types
  venue_types <- unique(register_table[["Type"]])

  for (venue_type in venue_types){
    # For each venue type we filter all venues of that type
    # We use distinct so there is one row for each venue name
    filtered_table <- register_table %>% 
      filter(Type == venue_type) %>% 
      select(Venue) %>%
      distinct()

    # Adding the column venue_slug which is used to generate the hyperlinks
    filtered_table <- filtered_table %>%
      mutate(`venue_slug` = gsub(" ", "_", stringr::str_to_lower(Venue)))

    # Adding no. of codechecks column
    CONFIG$NO_CODECHECKS_VENUE_TYPE[[venue_type]] <- sum(register_table$Type == venue_type)

    filtered_table <- filtered_table %>%
      group_by(Venue) %>%
      mutate(`No. of codechecks` = sum(register_table$Venue == Venue))

    # Updating each venue name with the names in CONFIG$DICT_VENUE_NAMES
    # Recode maps each Venue values to the corresponding Venue value in the dict
    filtered_table <- filtered_table %>%
      mutate(Venue = recode(Venue, !!!CONFIG$DICT_VENUE_NAMES))

    # Renaming the "Venue" column to "{Type} name"
    venue_type_col_name <- paste(stringr::str_to_title(venue_type), "name")
    filtered_table <- filtered_table %>%
      rename(!!sym(venue_type_col_name) := Venue)   

    list_venue_type_tables[[venue_type]] <- filtered_table
  }

  return(list_venue_type_tables)
}

#' Add Hyperlinks to Venue Type-Specific Table
#'
#' Adds hyperlinks to the venue names and the number of codechecks 
#' in the venue type-specific table. The links point to the venue's page for each venue type.
#'
#' @param table The data frame containing the venue type-specific data.
#' @param venue_type A string specifying the venue type.
#'
#' @return The data frame with hyperlinks added to the appropriate columns.
add_venue_type_hyperlink <- function(table, venue_type) {
  table_col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues"]]
  
  venue_col_name <- paste(stringr::str_to_title(venue_type), "name")

  # Ensure slug_name exists (if not, generate it from the Venue column)
  if (!"venue_slug" %in% colnames(table)) {
    table <- table %>%
      mutate(venue_slug = gsub(" ", "_", tolower(Venue)))
  }

  # Add hyperlinks to "{Type} name" and "No. of codechecks" column
  table <- table %>%
    mutate(
      !!sym(venue_col_name) := paste0(
        "[", !!sym(venue_col_name), "](",
        "https://codecheck.org.uk/register/venues/",
        venue_type, "/",
        venue_slug, "/)"
      ),

      # Generate no. of codechecks hyperlink
      !!sym(table_col_names[["no_codechecks"]]) := paste0(
        !!sym(table_col_names[["no_codechecks"]]),
        " [(see all checks)](https://codecheck.org.uk/register/venues/",
        venue_type, "/",
        venue_slug, "/)"
      )
    )

  # Removing the venue slug column
  table <- table %>% select(-`venue_slug`)
  return(table)
}
