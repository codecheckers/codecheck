#' Renders venues table in JSON format.
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the venue names.
render_table_venues_json <- function(list_venue_reg_tables){
  list_venue_names <- names(list_venue_reg_tables)
  # Check.names arg is set to FALSE so that column "Venue name" has the space
  table_venues <- data.frame(`Venue name`= list_venue_names, stringsAsFactors = FALSE, check.names = FALSE)

  # Column- No. of codechecks
  table_venues$`No. of codechecks` <- sapply(
    X = table_venues$`Venue name`,
    FUN = function(venue_name) {
      paste0(nrow(list_venue_reg_tables[[venue_name]]))
    }
  )

  # Column- Venue type
  table_venues$`Venue type` <- sapply(
    X = table_venues$`Venue name`,
    FUN = function(venue_name){
      venue_type <- determine_venue_category(venue_name)
      stringr::str_to_title(venue_type)
    }
  )

  # Column- venue names
  table_venues$`Venue name` <- sapply(
    X = table_venues$`Venue name`,
    FUN = function(venue_name){
      CONFIG$DICT_VENUE_NAMES[[venue_name]]
    }
  )

  return(table_venues)
}

#' Renders venues table in HTML format.
#' Each venue name links to the register table for that specific
#' venue. The ORCID IDs link to their ORCID pages.
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the ORCID IDs.
render_table_venues_html <- function(list_venue_reg_tables){

  list_venue_names <- names(list_venue_reg_tables)
  # Check.names arg is set to FALSE so that column "Venue name" has the space
  table_venues <- data.frame(`Venue name`= list_venue_names, stringsAsFactors = FALSE, check.names = FALSE)

  # Column- Venue type
  table_venues$`Venue type` <- sapply(
    X = table_venues$`Venue name`,
    FUN = function(venue_name){
      venue_type <- determine_venue_category(venue_name)
      stringr::str_to_title(venue_type)
    }
  )

  # Column- No. of codechecks
  table_venues$`No. of codechecks` <- mapply(
    FUN = function(venue_name, venue_type) {
      no_codechecks <- nrow(list_venue_reg_tables[[venue_name]])
      formatted_venue_type <- stringr::str_to_lower(venue_type)
      formatted_venue_name <-  determine_venue_name(venue_name, venue_type)
      paste0(no_codechecks," [(see all checks)](https://codecheck.org.uk/register/venues/",
      formatted_venue_type, "/", formatted_venue_name, "/)")
    },
    venue_name = table_venues$`Venue name`,
    venue_type = table_venues$`Venue type`
  )

  # Column- venue names
  # Each venue name will be a hyperlink to the register table
  # with all their codechecks
  table_venues$`Venue name` <- mapply(
    FUN = function(venue_name, venue_type){
      if (is.null(CONFIG$DICT_VENUE_NAMES[[venue_name]])) {
        return(NA)  # Handle cases where venue_name is not in CONFIG$DICT_VENUE_NAMES
      }
      formatted_venue_type <- stringr::str_to_lower(venue_type)
      formatted_venue_name <-  determine_venue_name(venue_name, venue_type)
      paste0("[", CONFIG$DICT_VENUE_NAMES[[venue_name]], "](https://codecheck.org.uk/register/venues/",
            formatted_venue_type, "/", formatted_venue_name, "/)")
    },
    venue_name = table_venues$`Venue name`,
    venue_type = table_venues$`Venue type`
  )

  table_venues <- table_venues[, c("Venue type", "Venue name", "No. of codechecks")]

  return(table_venues)
}

# render_table_venues_types_html <- function(list_venue_reg_tables){
#   # Take in the table from render_table_venues and then filter 
#   for ((venue_subcat) in CONFIG$VENUE_FILTER_SUBCATEGORIES){
#     table_venue_subcategory <- table_venues[grepl(venue_subcat, table_venues$`Venue type`, ignore.case = TRUE), ]
#     subtext <- paste("In total,", no_codechecks, "codechecks were completed for", no_venues, venue_subcat)
#   }
# }

list_no_codechecks_venue_subcat <- function(list_venue_reg_tables){
  list_no_codechecks_venue_subcat <- list()

  for (venue_subcat in CONFIG$FILTER_SUBCATEGORIES[["venues"]]){
    # Selecting all the tables of the same subcat
    tables_same_subcat <- list_venue_reg_tables[sapply(names(list_venue_reg_tables), function(name) {
      grepl(venue_subcat, name, ignore.case = TRUE)
    })]
    
    no_codechecks <- sum(sapply(tables_same_subcat, nrow))
    list_no_codechecks_venue_subcat[[venue_subcat]] <- no_codechecks
  }

  return(list_no_codechecks_venue_subcat)
}