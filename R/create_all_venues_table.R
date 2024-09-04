create_all_venues_table <- function(register_table){
  # Only keeping the Type and Venue column and unique combinations of the two
  new_table <- register_table %>%
    dplyr::select(Type, Venue) %>%
    distinct()

  # Adding no. of codechecks column
  new_table <- new_table %>%
    group_by(Venue) %>%
    mutate(`no_codechecks` = sum(register_table$Venue == Venue))

  # Adding slug name column. This is needed for the hyperlinks 
  new_table <- new_table %>%
    group_by(Venue) %>%
    mutate(`venue_slug` = gsub(" ", "_", stringr::str_to_lower(Venue)))
  
  # Updating each venue name with the names in CONFIG$DICT_VENUE_NAMES
  # Recode maps each Venue values to the corresponding Venue value in the dict
  new_table <- new_table %>%
    mutate(Venue = recode(Venue, !!!CONFIG$DICT_VENUE_NAMES))

  # Rename the column using the key-value pairs from the CONFIG list
  col_names_dict <- CONFIG$NON_REG_TABLE_COL_NAMES$venues_table
  for (key in names(col_names_dict)) {
    colnames(new_table)[colnames(new_table) == key] <- col_names_dict[[key]]
  }
  
  return(new_table)
}

add_all_venues_hyperlink <- function(table){
  # Extracting column names from CONFIG
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues_table"]]

  # !!sym is used to refer to column names defined in the CONFIG$NON_REG_TABLE_COL_NAMES 
  # dynamically
  table <- table %>%

    # NOTE: The order of these mutation must be kept in this order because of
    # dependencies on the links on the column values
    mutate(
      # Generate venue name hyperlink
      !!col_names[["Venue"]] := paste0(
        "[", !!sym(col_names[["Venue"]]), "](",
        "https://codecheck.org.uk/register/venues/", !!sym(col_names[["Type"]]), "/",
        venue_slug, "/)"
      ),

      # Generate no. of codechecks hyperlink
      !!col_names[["no_codechecks"]] := paste0(
        !!sym(col_names[["no_codechecks"]]), " [(see all checks)](",
        "https://codecheck.org.uk/register/venues/", !!sym(col_names[["Type"]]), "/",
        venue_slug, "/)"
      ),

      # Generate venue type hyperlink
      !!col_names[["Type"]] := paste0(
        "[", stringr::str_to_title(!!sym(col_names[["Type"]])), "](",
        "https://codecheck.org.uk/register/venues/", !!sym(col_names[["Type"]]), "/)"
      )
    )

  table <- table[, unname(col_names)]
  return(table)
}