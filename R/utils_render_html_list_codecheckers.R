#' Renders a html containing list of codecheckers
#' Each codechecker name links to the register table for that specific
#' codechecker. 
render_html_list_codecheckers <- function(list_orcid_ids){

  table_codecheckers <- create_table_codecheckers(list_orcid_ids)
  output_dir <- "docs/codecheckers/"

  title <- "List of codecheckers"
  md_table <- load_md_template(CONFIG$MD_TEMPLATE)
  md_table <- gsub("\\$title\\$", title, md_table)
  md_table <- gsub("\\$content\\$", paste(table_codecheckers, collapse = "\n"), md_table)

  # Saving the table to a temp md file
  temp_md_path <- paste0(output_dir, "temp.md")
  writeLines(md_table, temp_md_path)

  # Render HTML from markdown
  rmarkdown::render(
    input = temp_md_file_path,
    output_file = "index.html",
    output_dir = output_dir,
    output_yaml = yaml_path
  )

  # Deleting the temp file
  file.remove(temp_md_path)
}

#' Creates a table with the names of codecheckers
#' Contains 2 columns - codechecker names and their ORCID ID's.
#' The codechecker names link to the codecheck webpage with register table for all
#' their codechecks.
#' The ORCID ID's lead to their orcid webpage
create_table_codecheckers <- function(list_orcid_ids){

  table_codecheckers <- data.frame(ORCID_ID = list_orcid_ids, stringsAsFactors = FALSE)

  # Adding the ORCID ID's with links to the respective orcid pages
  table_codecheckers$ORCID_ID <- sapply(
    X = table_codecheckers$ORCID_ID,
    FUN = function(orcid_id) {
      paste0("[", orcid_id, "](https://orcid.org/", orcid_id, ")")
    }
  )

  # Creating column with all the codechecker names
  # Each codechecker name will be a hyperlink to the register table
  # with all their codechecks
  table_codecheckers$Codechecker  <- sapply(
    X = table_codecheckers$ORCID_ID,
    FUN = function(orcid_id) {
      codechecker_name <- CONFIG$DICT_ORCID_ID_NAME[orcid_id]
      paste0("[", codechecker_name, "](https://codecheck.org.uk/register/codecheckers/",
      orcid_id, "/)")
    }
  )

  return(table_codecheckers)
}
