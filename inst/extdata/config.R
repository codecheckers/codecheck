CONFIG <- new.env()

# REGISTER TABLE
CONFIG$MD_COLUMNS_WIDTHS <- "|:-------|:--------------------------------|:------------------|:------------------|:---|:--------------------------|:----------|"
CONFIG$REGISTER_COLUMNS <- list("Certificate", "Repository", "Type", "Venue", "Issue", "Report", "Check date")
CONFIG$DIR_TEMP_REGISTER_CODECHECKER <- "docs/temp_register_codechecker.csv"
CONFIG$FILTER_COLUMN_NAMES <- list(
  "venues" = list("Type", "Venue"),
  "codecheckers" = "Codechecker"
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
  "AGILEGIS" = "AGILEGIS",
  "codecheck" = "Codecheck",
  "codecheck NL" = "Codecheck NL",
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