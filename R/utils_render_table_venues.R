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
#' @param table_details A list containing metadata including output_dir for relative path calculation.
#'
#' @return The data frame with hyperlinks added to the appropriate columns.
add_venues_hyperlinks_non_reg <- function(table, subcat, table_details = NULL){
  if (is.null(subcat)){
    return(add_all_venues_hyperlinks_non_reg(table, table_details))
  }

  return(add_venue_type_hyperlinks_non_reg(table, venue_type = subcat, table_details))
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

  # Ungroup before adding venue label column
  new_table <- new_table %>%
    ungroup()

  # Adding venue label column by looking up in CONFIG$VENUE_DATA
  if (exists("VENUE_DATA", envir = CONFIG) && !is.null(CONFIG$VENUE_DATA)) {
    # Use a vectorized approach with sapply
    new_table <- new_table %>%
      mutate(`venue_label` = sapply(Venue, function(venue_name) {
        match_idx <- which(CONFIG$VENUE_DATA$name == venue_name)
        if (length(match_idx) > 0) {
          return(CONFIG$VENUE_DATA$label[match_idx[1]])
        } else {
          return(NA_character_)
        }
      })
    )
  }

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
#' Uses relative paths for HTML display (absolute URLs used in JSON/CSV).
#'
#' @param table The data frame containing data on all venues.
#' @param table_details A list containing metadata including output_dir for relative path calculation.
#'
#' @return The data frame with hyperlinks added to the appropriate columns.
add_all_venues_hyperlinks_non_reg <- function(table, table_details = NULL){
  # Calculate relative path prefix
  # All venues page is at docs/venues/index.html, so use ./ for venue links
  venues_base <- "./"
  # Extracting column names from CONFIG
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues"]]

  # Ensure venue_label column exists (fill with NA if not present)
  if (!"venue_label" %in% colnames(table)) {
    table$venue_label <- NA_character_
  }

  # !!sym is used to refer to column names defined in the CONFIG$NON_REG_TABLE_COL_NAMES
  # dynamically
  table <- table %>%

    # NOTE: The order of these mutation must be kept in this order because of
    # dependencies on the links on the column values
    mutate(
      # Generate venue name hyperlink with relative path
      !!col_names[["Venue"]] := mapply(
        function(venue_name, venue_type, slug) {
          paste0(
            "[", venue_name, "](",
            venues_base,
            CONFIG$VENUE_SUBCAT_PLURAL[[venue_type]], "/",
            slug, ")"
          )
        },
        !!sym(col_names[["Venue"]]),
        !!sym(col_names[["Type"]]),
        venue_slug,
        SIMPLIFY = TRUE,
        USE.NAMES = FALSE
      ),

      # Generate no. of codechecks hyperlink with "Open checks" link
      !!col_names[["no_codechecks"]] := mapply(
        function(no_checks, venue_type, slug, label) {
          # Base link to see all checks for this venue (relative path)
          base_link <- paste0(
            no_checks,
            " [(see all checks)](",
            venues_base,
            CONFIG$VENUE_SUBCAT_PLURAL[[venue_type]], "/",
            slug, "/)"
          )

          # Add "Open checks" link if label is available
          if (!is.na(label) && nchar(label) > 0) {
            open_checks_link <- paste0(
              " [(open checks)](https://github.com/codecheckers/register/issues?q=is%3Aissue+label%3A%22",
              utils::URLencode(label, reserved = TRUE),
              "%22+is%3Aopen)"
            )
            return(paste0(base_link, open_checks_link))
          } else {
            return(base_link)
          }
        },
        !!sym(col_names[["no_codechecks"]]),
        !!sym(col_names[["Type"]]),
        venue_slug,
        venue_label,
        SIMPLIFY = TRUE,
        USE.NAMES = FALSE
      ),

      # Generate venue type hyperlink with relative path
      !!col_names[["Type"]] := sapply(!!sym(col_names[["Type"]]), function(venue_type) {
        paste0(
          "[", stringr::str_to_title(venue_type),
          "](", venues_base,
          CONFIG$VENUE_SUBCAT_PLURAL[[venue_type]], "/)"
        )
      })
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

    # Adding venue label column by looking up in CONFIG$VENUE_DATA
    # Add venue_label if CONFIG$VENUE_DATA exists
    if (exists("VENUE_DATA", envir = CONFIG) && !is.null(CONFIG$VENUE_DATA)) {
      filtered_table <- filtered_table %>%
        mutate(`venue_label` = sapply(Venue, function(venue_name) {
          match_idx <- which(CONFIG$VENUE_DATA$name == venue_name)
          if (length(match_idx) > 0) {
            return(CONFIG$VENUE_DATA$label[match_idx[1]])
          } else {
            return(NA_character_)
          }
        }))
    }

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
#' Uses relative paths for HTML display (absolute URLs used in JSON/CSV).
#'
#' @param table The data frame containing the venue type-specific data.
#' @param venue_type A string specifying the venue type.
#' @param table_details A list containing metadata including output_dir for relative path calculation.
#'
#' @return The data frame with hyperlinks added to the appropriate columns.
add_venue_type_hyperlinks_non_reg <- function(table, venue_type, table_details = NULL) {
  # Calculate relative path prefix
  # Venue type pages are at docs/venues/journals/index.html, so use ./ for venue links
  venues_base <- "./"
  table_col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["venues"]]

  venue_col_name <- paste(stringr::str_to_title(venue_type), "name")

  # Making the venue type plural for consistency in URL
  venue_type <- CONFIG$VENUE_SUBCAT_PLURAL[[venue_type]]

  # Ensure slug_name exists (if not, generate it from the Venue column)
  if (!"venue_slug" %in% colnames(table)) {
    table <- table %>%
      mutate(venue_slug = gsub(" ", "_", tolower(Venue)))
  }

  # Ensure venue_label column exists (fill with NA if not present)
  if (!"venue_label" %in% colnames(table)) {
    table$venue_label <- NA_character_
  }

  # Add hyperlinks to "{Type} name" and "No. of codechecks" column with relative paths
  table <- table %>%
    mutate(
      !!sym(venue_col_name) := paste0(
        "[", !!sym(venue_col_name), "](",
        venues_base,
        venue_slug, "/)"
      ),

      # Generate no. of codechecks hyperlink with "Open checks" link
      !!sym(table_col_names[["no_codechecks"]]) := mapply(
        function(no_checks, slug, label) {
          # Base link to see all checks for this venue (relative path)
          base_link <- paste0(
            no_checks,
            " [(see all checks)](",
            venues_base,
            slug, "/)"
          )

          # Add "Open checks" link if label is available
          if (!is.na(label) && nchar(label) > 0) {
            open_checks_link <- paste0(
              " [(open checks)](https://github.com/codecheckers/register/issues?q=is%3Aissue+label%3A%22",
              utils::URLencode(label, reserved = TRUE),
              "%22+is%3Aopen)"
            )
            return(paste0(base_link, open_checks_link))
          } else {
            return(base_link)
          }
        },
        !!sym(table_col_names[["no_codechecks"]]),
        venue_slug,
        venue_label,
        SIMPLIFY = TRUE,
        USE.NAMES = FALSE
      )
    )

  # Removing the venue slug column
  table <- table %>% select(-`venue_slug`)
  return(table)
}
