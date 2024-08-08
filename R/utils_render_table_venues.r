#' Renders JSON file of venues.
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the venue names.
render_venues_json <- function(list_venue_reg_tables){
  output_dir <- "docs/venues/"

  table_venues_json <- render_table_venues_json(list_venue_reg_tables)
  jsonlite::write_json(
    table_venues_json,
    path = paste0(output_dir, "index.json"),
    pretty = TRUE
  )
}

#' Renders venues page.
#' Each venue name links to the register table for that specific
#' venue. 
#' 
#' @param list_venue_reg_tables The list of venue register tables. The indices are the venue names.
render_venues_html <- function(list_venue_reg_tables){

  output_dir <- "docs/venues/"
  table_venues <- render_table_venues_html(list_venue_reg_tables)

  # Creating and adjusting the markdown table
  md_table <- load_md_template(CONFIG$MD_TEMPLATE)
  title <- "CODECHECK List of venues"
  md_table <- gsub("\\$title\\$", title, md_table)
  md_table <- gsub("\\$content\\$", paste(table_venues, collapse = "\n"), md_table)

  # Saving the table to a temp md file
  temp_md_path <- paste0(output_dir, "temp.md")
  writeLines(md_table, temp_md_path)

  # Creating the correct html yaml and index files
  create_index_section_files(output_dir, "venues")
  generate_html_document_yml(output_dir)
  yaml_path <- normalizePath(file.path(getwd(), paste0(output_dir, "html_document.yml")))

  # Render index.html from markdown
  rmarkdown::render(
    input = temp_md_path,
    output_file = "index.html",
    output_dir = output_dir,
    output_yaml = yaml_path
  )

  # Deleting the temp file
  file.remove(temp_md_path)

  # Changing the html file so that the path to the libs folder refers to 
  # the libs folder "docs/libs".
  # This is done to remove duplicates of "libs" folders.
  html_file_path <- paste0(output_dir, "index.html")
  edit_html_lib_paths(html_file_path)
  # Deleting the libs folder after changing the html lib path
  unlink(paste0(output_dir, "/libs"), recursive = TRUE)
}

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
  table_venues$`No. of codechecks` <- sapply(
    X = table_venues$`Venue name`,
    FUN = function(venue_name) {
      nrow(list_venue_reg_tables[[venue_name]])
    }
  )

  # Column- venue names
  # Each venue name will be a hyperlink to the register table
  # with all their codechecks
  table_venues$`Venue name` <- mapply(
    FUN = function(venue_name, venue_type){
      if (is.null(CONFIG$DICT_VENUE_NAMES[[venue_name]])) {
        return(NA)  # Handle cases where venue_name is not in CONFIG$DICT_VENUE_NAMES
      }
      paste0("[", CONFIG$DICT_VENUE_NAMES[[venue_name]], "](https://codecheck.org.uk/register/venues/",
            venue_type, "/", determine_venue_name(venue_name, venue_type), "/)")
    },
    venue_name = table_venues$`Venue name`,
    venue_type = table_venues$`Venue type`
  )

  table_venues <- table_venues[, c("Venue type", "Venue name", "No. of codechecks")]

  table_venues <- kable(table_venues)
  return(table_venues)
}
