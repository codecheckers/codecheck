#' Renders table for all venues and venue subcategories in JSON format.
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the venue names.
#' @return Returns list of the json tables with the names of the list being the table names.
render_tables_venues_json <- function(list_venue_reg_tables){
  all_venues_table <- render_table_all_venues_json(list_venue_reg_tables)
  list_venues_subcat_tables <- render_table_venues_subcat(all_venues_table)
  
  list_tables <- list("all_venues" = all_venues_table)
  list_tables <- c(list_tables, list_venues_subcat_tables)
  return(list_tables)
}


#' Renders table for all venues in JSON format.
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the venue names.
#' @return Returns a JSON table for the all venues 
render_table_all_venues_json <- function(list_venue_reg_tables){
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

#' Renders table for all venues and venue subcategories for HTML.
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the venue names.
#' @return Returns list of the html tables with the names of the list being the table names.
render_tables_venues_html <- function(list_venue_reg_tables){
  all_venues_table <- render_table_all_venues_html(list_venue_reg_tables)
  list_venues_subcat_tables <- render_table_venues_subcat(all_venues_table)
  
  list_tables <- list("all_venues" = all_venues_table)
  list_tables <- c(list_tables, list_venues_subcat_tables)
  return(list_tables)
}

#' Renders table for all venues in HTML format.
#' Each venue name links to the register table for that specific
#' venue. The ORCID IDs link to their ORCID pages.
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the ORCID IDs.
#' @return Returns the html table of all the venues.
render_table_all_venues_html <- function(list_venue_reg_tables){
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

#' Renders table for venue subcategories
#' This function can be used for both the html and json table since it works on the
#' table for all venues. If the all_venues table is of html format then this creates
#' a html table and if it is of json format, this creates a json table. 
#' 
#' @param venues_table The table of all venues
#' @return Returns a list of the html tables of venue subcategories. 
#' The names in the list are the names of the subcategories
render_table_venues_subcat <- function(venues_table){
  CONFIG$NO_CODECHECKS_VENUE_SUBCAT <- c()
  list_tables <- c()

  # The venues subcat table will be made from the venues_table.
  # Hence we set the column "venue type" to be NULL as it is redundant for the venues subcategory table
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues_table"]]

  # The "venue name" column is later replaced with "{venue_subcat} name"
  venues_table_venue_name_col <- col_names[["venue_name"]]
  old_venue_name_col <- venues_table_venue_name_col

  for (venue_subcat in CONFIG$FILTER_SUBCATEGORIES[["venues"]]){
    # Filtering and keeping the rows of venue_type == venue_subcat
    table_venue_subcategory <- venues_table[grepl(venue_subcat, venues_table$`Venue type`, ignore.case = TRUE), ]
    # Removing the column showing the row numbers and removing the column "Venue type"
    rownames(table_venue_subcategory) <- NULL
    table_venue_subcategory[col_names[["venue_type"]]] <- NULL

    # Replace the column "Venue name" with "{venue_subcat} name" e.g "Journal/Conference name"
    # Capitalizing the first letter of the subcat name using str_to_title
    new_venue_name_col <- paste(stringr::str_to_title(venue_subcat), "name")
    colnames(table_venue_subcategory)[colnames(table_venue_subcategory) == old_venue_name_col] <- new_venue_name_col
    
    # Extract the numeric part from the "no.of codechecks" column and convert to integers
    list_no_codechecks <- as.numeric(sub(" .*", "", table_venue_subcategory[[col_names[["no_codechecks"]]]]))
    no_codechecks_venue_subcat <- sum(list_no_codechecks)

    # Noting down the number of codechecks for each venue subcategory. This is to be used in the subtext of the
    # html pages
    CONFIG$NO_CODECHECKS_VENUE_SUBCAT[[venue_subcat]] <- no_codechecks_venue_subcat

    list_tables[[venue_subcat]] <- table_venue_subcategory
  }
  return(list_tables)
}