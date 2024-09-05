#' Create Codecheckers Table
#'
#' Processes the register table to create a new table of distinct codecheckers. 
#' The resulting table has codechecker name, codechecker ID and no. of codechecks column
#'
#' @param register_table The register table
#'
#' @return A list with a single element, the codechecker table
create_all_codecheckers_table <- function(register_table){
  # Unlisting the table to split codechecks with multiple codecheckers
  # into multiple separate rows
  register_table <- register_table %>% tidyr::unnest(Codechecker)
  register_table$Codechecker <- unlist(register_table$Codechecker)

  # Only keeping the Codechecker column and distinct values
  new_table <- register_table %>% 
    select(Codechecker) %>% 
    distinct()

  # Adding the codechecker name column
  new_table <- new_table %>%
    mutate(`codechecker_name` = recode(Codechecker, !!!CONFIG$DICT_ORCID_ID_NAME))

  # Adding no. of codechecks column
  new_table <- new_table %>%
    group_by(Codechecker) %>%
    mutate(`no_codechecks` = sum(register_table$Codechecker == Codechecker))

  # Rename the column using the key-value pairs from the CONFIG list
  col_names_dict <- CONFIG$NON_REG_TABLE_COL_NAMES[["codecheckers"]]
  for (key in names(col_names_dict)) {
    colnames(new_table)[colnames(new_table) == key] <- col_names_dict[[key]]
  }

  # Rearrange columns to the order in the col_names_dict
  new_table <- new_table[, unname(col_names_dict)]

  # Returning as a list for consistency with create_table_venues
  return(list(codecheckers = new_table)) 
}

#' Add Hyperlinks to Codecheckers Table
#'
#' Adds hyperlinks to the codecheckers table by modifying the codechecker names, 
#' number of codechecks, and ORCID IDs into clickable links.
#'
#' @param table The codecheckers table
#'
#' @return The data frame with added hyperlinks in the specified columns.
add_all_codecheckers_hyperlink <- function(table){
  # Extracting column names from CONFIG
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["codecheckers"]]

  # !!sym is used to refer to column names defined in the CONFIG$NON_REG_TABLE_COL_NAMES 
  # dynamically
  table <- table %>%

    # NOTE: The order of these mutation must be kept in this order because of
    # dependencies on the links on the column values
    mutate(
      # Generate codechecker table hyperlink
      !!col_names[["codechecker_name"]] := paste0(
        "[", !!sym(col_names[["codechecker_name"]]), 
        "](https://codecheck.org.uk/register/codecheckers/",
        !!sym(col_names[["Codechecker"]]), "/)"
      ),


      # Generate no. of codechecks hyperlink
      !!col_names[["no_codechecks"]] := paste0(
        !!sym(col_names[["no_codechecks"]]), 
        " [(see all checks)](https://codecheck.org.uk/register/codecheckers/", 
        !!sym(col_names[["Codechecker"]]), "/)"
      ),

      # Generate ORCID ID hyperlink
      !!col_names[["Codechecker"]] := paste0(
        "[", !!sym(col_names[["Codechecker"]]), "](https://orcid.org/", 
        !!sym(col_names[["Codechecker"]]), ")"
      )
    )

  # Only keeping columns specified in the CONFIG
  table <- table[, unname(col_names)]
  return(table)
}