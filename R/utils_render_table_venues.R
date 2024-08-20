#' Renders venues table in JSON format.
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the venue names.
render_table_venues_json <- function(list_venue_reg_tables){
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues_table"]]
  list_venue_names <- names(list_venue_reg_tables)
  
  # Create initial data frame
  table_venues <- data.frame(
    matrix(ncol=0, nrow = length(list_venue_names)),
    stringsAsFactors = FALSE, 
    check.names = FALSE
  )

  table_venues[[col_names[["venue_name"]]]] <- list_venue_names

  # Column- No. of codechecks
  table_venues[[col_names[["no_codechecks"]]]] <- sapply(
    X = list_venue_names,
    FUN = function(venue_name) {
      paste0(nrow(list_venue_reg_tables[[venue_name]]))
    }
  )

  # Column- Venue type
  table_venues[[col_names[["venue_type"]]]] <- sapply(
    X = table_venues[[col_names[["venue_name"]]]],
    FUN = function(venue_name){
      venue_type <- determine_venue_category(venue_name)
      stringr::str_to_title(venue_type)
    }
  )

  # Column- venue names
  # Using the full names of the venues
  table_venues[[col_names[["venue_name"]]]] <- sapply(
    X = table_venues[[col_names[["venue_name"]]]],
    FUN = function(venue_name){
      CONFIG$DICT_VENUE_NAMES[[venue_name]]
    }
  )

  # Reordering the table
  desired_order_cols <- unlist(col_names)
  table_venues <- table_venues[, desired_order_cols]

  return(table_venues)
}

#' Renders venues table in HTML format.
#' Each venue name links to the register table for that specific
#' venue. The ORCID IDs link to their ORCID pages.
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the ORCID IDs.
render_table_venues_html <- function(list_venue_reg_tables){
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues_table"]]

  list_venue_names <- names(list_venue_reg_tables)
  # Create initial data frame
  table_venues <- data.frame(
    matrix(ncol=0, nrow = length(list_venue_names)),
    stringsAsFactors = FALSE, 
    check.names = FALSE
  )

  table_venues[[col_names[["venue_name"]]]] <- list_venue_names

  # Column- Venue type
  table_venues[[col_names[["venue_type"]]]] <- sapply(
    X = list_venue_names,
    FUN = function(venue_name){
      venue_type <- determine_venue_category(venue_name)
      stringr::str_to_title(venue_type)
    }
  )

  # Column- No. of codechecks
  table_venues[[col_names[["no_codechecks"]]]] <- mapply(
    FUN = function(venue_name, venue_type) {
      no_codechecks <- nrow(list_venue_reg_tables[[venue_name]])
      formatted_venue_type <- stringr::str_to_lower(venue_type)
      formatted_venue_name <-  determine_venue_name(venue_name, venue_type)
      paste0(no_codechecks," [(see all checks)](https://codecheck.org.uk/register/venues/",
      formatted_venue_type, "/", formatted_venue_name, "/)")
    },
    venue_name = table_venues[[col_names[["venue_name"]]]],
    venue_type = table_venues[[col_names[["venue_type"]]]]
  )

  # Column- venue names
  # Each venue name will be a hyperlink to the register table
  # with all their codechecks
  table_venues[[col_names[["venue_name"]]]] <- mapply(
    FUN = function(venue_name, venue_type){
      if (is.null(CONFIG$DICT_VENUE_NAMES[[venue_name]])) {
        return(venue_name)  # Handle cases where venue_name is not in CONFIG$DICT_VENUE_NAMES
      }
      formatted_venue_type <- stringr::str_to_lower(venue_type)
      formatted_venue_name <-  determine_venue_name(venue_name, venue_type)
      paste0("[", CONFIG$DICT_VENUE_NAMES[[venue_name]], "](https://codecheck.org.uk/register/venues/",
            formatted_venue_type, "/", formatted_venue_name, "/)")
    },
    venue_name = table_venues[[col_names[["venue_name"]]]],
    venue_type = table_venues[[col_names[["venue_type"]]]]
  )

  # Reordering the table
  desired_order_cols <- unlist(col_names)
  table_venues <- table_venues[, desired_order_cols]

  return(table_venues)
}
