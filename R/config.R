CONFIG <- new.env()

# REGISTER TABLE
CONFIG$MD_COLUMNS_WIDTHS <- "|:-------|:--------------------------------|:------------------|:---|:--------------------------|:----------|"
CONFIG$REGISTER_COLUMNS <- list("Certificate", "Repository", "Type", "Issue", "Report", "Check date")
CONFIG$DIR_TEMP_REGISTER_CODECHECKER <- "docs/temp_register_codechecker.csv"

# NON-REGISTER_TABLE
CONFIG$NON_REG_TABLE_COL_NAMES <- list(
  "codechecker_table" = {
    "codechecker" = "Codechecker name",
    "orcid" = "ORCID ID",
    "no_codechecks" = "No. of codechecks"
  }
)

# REGISTER FILTER SUBCATEGORIES
# Each filter can be further divided into each of these subgroups
CONFIG$FILTER_SUBCATEGORIES <- list(
  venues = list("community", "journal", "conference") 
)

# OTHERS
CONFIG$DICT_ORCID_ID_NAME <- list()

# DIRECTORIES
CONFIG$DIR_INDEX_TEMPLATE<- list(
  "non_reg" = list(
    "postfix" = "/docs/templates/codecheckers_venues_list/index_postfix_template.html",
  ),
  "reg" = list(
    "postfix" = "/docs/templates/reg_tables/index_postfix_template.html"
  )
)
