#' Renders a html containing list of codecheckers
#' Each codechecker name links to the register table for that specific
#' codechecker. 
render_html_list_codecheckers <- function(list_codechecker_reg_tables){

  table_codecheckers <- create_table_codecheckers(list_codechecker_reg_tables)
  output_dir <- "docs/codecheckers/"

  # Creating and adjusting the markdown table
  md_table <- load_md_template(CONFIG$MD_TEMPLATE)
  title <- "CODECHECK List of codecheckers"
  md_table <- gsub("\\$title\\$", title, md_table)
  md_table <- gsub("\\$content\\$", paste(table_codecheckers, collapse = "\n"), md_table)

  # Saving the table to a temp md file
  temp_md_path <- paste0(output_dir, "temp.md")
  writeLines(md_table, temp_md_path)

  # Creating the correct html yaml and index files
  create_index_section_files(output_dir, "codecheckers")
  generate_html_document_yml(output_dir)
  yaml_path <- normalizePath(file.path(getwd(), paste0(output_dir, "html_document.yml")))

  # Render HTML from markdown
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

#' Creates a table with the names of codecheckers
#' Contains 2 columns - codechecker names and their ORCID ID's.
#' The codechecker names link to the codecheck webpage with register table for all
#' their codechecks.
#' The ORCID ID's lead to their orcid webpage
create_table_codecheckers <- function(list_codechecker_reg_tables){

  list_orcid_ids <- names(list_codechecker_reg_tables)
  table_codecheckers <- data.frame(ORCID_ID = list_orcid_ids, stringsAsFactors = FALSE)

  # Creating column with all the codechecker names
  # Each codechecker name will be a hyperlink to the register table
  # with all their codechecks
  table_codecheckers$`Codechecker name` <- sapply(
    X = table_codecheckers$ORCID_ID,
    FUN = function(orcid_id) {
      codechecker_name <- CONFIG$DICT_ORCID_ID_NAME[orcid_id]
      paste0("[", codechecker_name, "](https://codecheck.org.uk/register/codecheckers/",
      orcid_id, "/)")
    }
  )

  # Adding the ORCID ID's with links to the respective orcid pages
  table_codecheckers$ORCID_ID_Link <- sapply(
    X = table_codecheckers$ORCID_ID,
    FUN = function(orcid_id) {
      paste0("[", orcid_id, "](https://orcid.org/", orcid_id, ")")
    }
  )

  # Number of codechecks done by each codechecker
  table_codecheckers$`No. of codechecks` <- sapply(
    X = table_codecheckers$ORCID_ID,
    FUN = function(orcid_id) {
      paste0(nrow(list_codechecker_reg_tables[[orcid_id]]))
    }
  )

  # Drop the original ORCID_ID column and rename ORCID_ID_Link to ORCID_ID
  table_codecheckers <- table_codecheckers[, c("Codechecker name", "ORCID_ID_Link", "No. of codechecks")]
  names(table_codecheckers)[names(table_codecheckers) == "ORCID_ID_Link"] <- "ORCID ID"

  table_codecheckers <- kable(table_codecheckers)
  return(table_codecheckers)
}
