#' Renders codecheckers table in JSON format.
#' 
#' @param list_codechecker_reg_tables The list of codechecker register tables. The indices are the ORCID IDs.
render_table_codecheckers_json <- function(list_codechecker_reg_tables){
  list_orcid_ids <- names(list_codechecker_reg_tables)
  table_codecheckers <- data.frame(matrix(ncol=0, nrow = length(list_orcid_ids)), stringsAsFactors = FALSE)
  
  col_names <- CONFIG$CODECHECKER_TABLE_COL_NAMES

  # Column- codechecker names
  table_codecheckers[[col_names[["codechecker"]]]] <- sapply(
    X = list_orcid_ids,
    FUN = function(orcid_id) {
      paste0(CONFIG$DICT_ORCID_ID_NAME[orcid_id])
    }
  )

  table_codecheckers[[col_names[["orcid"]]]] <- list_orcid_ids

  # Column- No. of codechecks
  table_codecheckers[[col_names[["no_codechecks"]]]] <- sapply(
    X = list_orcid_ids,
    FUN = function(orcid_id) {
      paste0(nrow(list_codechecker_reg_tables[[orcid_id]]))
    }
  )

  return(table_codecheckers)
}

#' Renders codecheckers table in HTML format.
#' Each codechecker name links to the register table for that specific
#' codechecker. The ORCID IDs link to their ORCID pages.
#' 
#' @param list_codechecker_reg_tables The list of codechecker register tables. The indices are the ORCID IDs.
render_table_codecheckers_html <- function(list_codechecker_reg_tables){

  list_orcid_ids <- names(list_codechecker_reg_tables)

  # Initializing a table with rows = no. orcid ids + 1 row (for the headers)
  table_codecheckers <- data.frame(matrix(ncol=0, nrow = length(list_orcid_ids)), stringsAsFactors = FALSE)

  col_names <- CONFIG$CODECHECKER_TABLE_COL_NAMES

  # Column- codechecker names
  # Each codechecker name will be a hyperlink to the register table
  # with all their codechecks
  table_codecheckers[[col_names[["codechecker"]]]] <- sapply(
    X = list_orcid_ids,
    FUN = function(orcid_id) {
      codechecker_name <- CONFIG$DICT_ORCID_ID_NAME[orcid_id]
      paste0("[", codechecker_name, "](https://codecheck.org.uk/register/codecheckers/",
      orcid_id, "/)")
    }
  )

  # Column- ORCID ID 
  table_codecheckers[[col_names[["orcid"]]]] <- sapply(
    X = list_orcid_ids,
    FUN = function(orcid_id) {
      paste0("[", orcid_id, "](https://orcid.org/", orcid_id, ")")
    }
  )
  # Column- No. of codechecks
  # Shown as "no_codechecks (sell all checks)" where "see all checks" links to the checks by 
  # the codechecker
  table_codecheckers[[col_names[["no_codechecks"]]]] <- sapply(
    X = list_orcid_ids,
    FUN = function(orcid_id) {
      no_codechecks <- nrow(list_codechecker_reg_tables[[orcid_id]])
      paste0(nrow(list_codechecker_reg_tables[[orcid_id]])," [(see all checks)](https://codecheck.org.uk/register/codecheckers/",
      orcid_id, "/)")
    }
  )

  return(table_codecheckers)
}

