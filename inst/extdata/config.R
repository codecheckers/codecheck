CONFIG <- new.env()

# REGISTER TABLE

# Specifying the register table column widths
# The names in the list are the filter type
CONFIG$MD_TABLE_COLUMN_WIDTHS <- list(
  none = "|:-------|:--------------------------------|:------------------|:------------------|:---|:--------------------------|:----------|",
  venues = "|:-------|:--------------------------------|:---|:--------------------------|:----------|"
)

CONFIG$REGISTER_COLUMNS <- list("Certificate", "Repository", "Type", "Venue", "Issue", "Report", "Check date")
CONFIG$DIR_TEMP_REGISTER_CODECHECKER <- "docs/temp_register_codechecker.csv"
CONFIG$FILTER_COLUMN_NAMES <- list(
  "venues" = "Venue",
  "codecheckers" = "Codechecker"
)

CONFIG$MD_TITLES <- list(
  "none" = "CODECHECK Register",

  "codecheckers" = function(table_details){
    orcid_id <- table_details[["name"]]
    auth_name <- CONFIG$DICT_ORCID_ID_NAME[[orcid_id]]
    paste0("Codechecks by ", auth_name, " (", orcid_id, ")")
  },

  "venues" = function(table_details) {
    venue_type <- table_details[["subcat"]]
    venue_name <- table_details[["name"]]
    paste0("CODECHECK Register for ", venue_type, " (", venue_name, ")")
  }
)

CONFIG$HREF_DETAILS <- list(
  "csv_source" = list(base_url = "https://raw.githubusercontent.com/codecheckers/register/master/", ext = ".csv"),
  "searchable_csv" = list(base_url ="https://github.com/codecheckers/register/blob/master/", ext = ".csv"),
  "json" = list(base_url = "https://codecheck.org.uk/register/", ext = ".json"),
  "md" = list(base_url = "https://codecheck.org.uk/register/", ext = ".md")
)

# NON-REGISTER_TABLE
# Note that the order of the names in the list will be the order of table columns in html and json
CONFIG$NON_REG_TABLE_COL_NAMES <- list(
  "codechecker_table" = list(
    "codechecker" = "Codechecker name",
    "orcid" = "ORCID ID",
    "no_codechecks" = "No. of codechecks"
  ),

  "venues_table" = list(
    "venue_type" = "Venue type", 
    "venue_name" = "Venue name",
    "no_codechecks" = "No. of codechecks"
  )
)

# REGISTER FILTER SUBCATEGORIES
# Each filter can be further divided into each of these subgroups
CONFIG$FILTER_SUBCATEGORIES <- list(
  venues = list("community", "journal", "conference") 
)

# For each filter with subcategories we have a reference to the column
# in the register table that refers to the subcat name
CONFIG$FILTER_SUBCAT_COLUMNS <- list(
  venues = "Type"
)

# OTHERS
CONFIG$DICT_ORCID_ID_NAME <- list()

# DIRECTORIES
CONFIG$TEMPLATE_DIR<- list(
  "non_reg" = list(
    "postfix" = system.file("extdata", "templates/non_reg_tables/index_postfix_template.html", package = "codecheck"),
    "header" = system.file("extdata", "templates/general/index_header_template.html", package = "codecheck"),
    "prefix" = system.file("extdata", "templates/general/index_prefix_template.html", package = "codecheck"),
    "md_template" = system.file("extdata", "templates/non_reg_tables/template.md", package = "codecheck")
  ),
  "reg" = list(
    "postfix" = system.file("extdata", "templates/reg_tables/index_postfix_template.html", package = "codecheck"),
    "header" = system.file("extdata", "templates/general/index_header_template.html", package = "codecheck"),
    "prefix" = system.file("extdata", "templates/general/index_prefix_template.html", package = "codecheck"),
    "md_template" = system.file("extdata", "templates/reg_tables/template.md", package = "codecheck")
  )
)

# DICT OF VENUE NAMES
CONFIG$DICT_VENUE_NAMES <- list(
  "GigaScience" = "GigaScience",
  "J Geogr Syst" = "Journal of Geographical Systems",
  "J Archaeol Sci" = "Journal of Archaeological Science",
  "GigaByte" = "GigaByte",
  "AGILEGIS" = "AGILE Conference on Geographic Information Science",
  "codecheck" = "CODECHECK",
  "codecheck NL" = "CODECHECK NL",
  "in press" = "In press",
  "preprint" = "Preprint"
)

# JSON FILE INFORMATION
# List specifying the columns to keep for JSON files
CONFIG$JSON_COLUMNS <- c(
  "Certificate",
  "Repository Link",
  "Type",
  "Venue",
  "Report",
  "Title",
  "Paper reference",
  "Check date"
)
