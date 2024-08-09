#' Renders codecheckers table in JSON format.
#' 
#' @param list_codechecker_reg_tables The list of codechecker register tables. The indices are the ORCID IDs.
render_table_codecheckers_json <- function(list_codechecker_reg_tables){
  list_orcid_ids <- names(list_codechecker_reg_tables)
  # Check.names arg is set to FALSE so that column "ORCID ID" has the space
  table_codecheckers <- data.frame(`ORCID ID`= list_orcid_ids, stringsAsFactors = FALSE, check.names = FALSE)
  
  # Column- codechecker names
  table_codecheckers$`Codechecker name` <- sapply(
    X = table_codecheckers$`ORCID ID`,
    FUN = function(orcid_id) {
      paste0(CONFIG$DICT_ORCID_ID_NAME[orcid_id])
    }
  )

  # Column- No. of codechecks
  table_codecheckers$`No. of codechecks` <- sapply(
    X = table_codecheckers$`ORCID ID`,
    FUN = function(orcid_id) {
      paste0(nrow(list_codechecker_reg_tables[[orcid_id]]))
    }
  )

  # Arranging the column names
  table_codecheckers <- table_codecheckers[, c("Codechecker name", "ORCID ID", "No. of codechecks")]

  return(table_codecheckers)
}

#' Renders codecheckers table in HTML format.
#' Each codechecker name links to the register table for that specific
#' codechecker. The ORCID IDs link to their ORCID pages.
#' 
#' @param list_codechecker_reg_tables The list of codechecker register tables. The indices are the ORCID IDs.
render_table_codecheckers_html <- function(list_codechecker_reg_tables){

  list_orcid_ids <- names(list_codechecker_reg_tables)
  table_codecheckers <- data.frame(ORCID_ID = list_orcid_ids, stringsAsFactors = FALSE)

  # Column- codechecker names
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

  # Column- ORCID ID link
  table_codecheckers$ORCID_ID_Link <- sapply(
    X = table_codecheckers$ORCID_ID,
    FUN = function(orcid_id) {
      paste0("[", orcid_id, "](https://orcid.org/", orcid_id, ")")
    }
  )

  # Column- No. of codechecks
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

