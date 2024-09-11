CONFIG <- new.env()

# REGISTER TABLE

# Specifying the register table column widths
# The names in the list are the filter type
# For filters other than venues we use the general column widths
CONFIG$MD_TABLE_COLUMN_WIDTHS <- list(
  reg = list(
    general = "|:-------|:--------------------------------|:------------------|:------------------|:---|:--------------------------|:----------|",
    venues = "|:-------|:--------------------------------|:---|:--------------------------|:----------|"
  ),

  non_reg = list(
    venues = "|:-----------|:---------------------|:----------|",
    venues_subcat = "|:---------------------|:----------|",
    codecheckers = "|:-----------|:---------------------|:----------|"
  )
)

# These are the columns to keep in the register table
CONFIG$REGISTER_COLUMNS <- list(
  other = c("Certificate", "Paper Title", "Type", "Venue", "Issue", "Report", "Check date"),
  csv = c("Certificate", "Repository", "Type", "Venue", "Issue", "Report", "Check date"),
  json = c("Certificate", "Repository", "Type", "Venue", "Issue", "Report", "Check date")
)

CONFIG$DIR_TEMP_REGISTER_CODECHECKER <- "docs/temp_register_codechecker.csv"
CONFIG$FILTER_COLUMN_NAMES <- list(
  "venues" = "Venue",
  "codecheckers" = "Codechecker"
)

CONFIG$NO_CODECHECKS_VENUE_TYPE <- list()

# Column names to drop for each reg table
CONFIG$FILTER_COLUMN_NAMES_TO_DROP <- list(
  "venues" = list("Venue", "Type"),
  "codecheckers" = "Codechecker"
)

CONFIG$MD_TITLES <- list(
  "none" = function(table_details){
    "CODECHECK Register"
  },

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

# List of hyperlinks
CONFIG$HYPERLINKS <- list(
  venues = "https://codecheck.org.uk/register/venues/",
  register = "https://codecheck.org.uk/register/",
  codecheckers = "https://codecheck.org.uk/register/codecheckers/",
  orcid = "https://orcid.org/",
  osf = "https://osf.io/",
  gitlab = "https://gitlab.com/",
  github = "https://github.com/",
  doi = "https://doi.org/",
  codecheck_issue = "https://github.com/codecheckers/register/issues/",
  zenodo_deposit = "https://zenodo.org/deposit/"
)

# NON-REGISTER_TABLE
CONFIG$NON_REG_TITLE_BASE <- "CODECHECK List of"
CONFIG$NON_REG_TITLE_FNS <- list(
  codecheckers = function(subcat=NULL){
    return("CODECHECK List of codecheckers")
  },

  venues = function(subcat){
    if (is.null(subcat)){
      return("CODECHECK List of venues")
    }

    else{
      # Pluralizing the venue subcat
      plural_subcat <- switch (subcat,
        "conference" = "conferences",
        "journal" = "journals",
        "community" = "communities"
      )
      return(paste("CODECHECK List of", plural_subcat))
    }
  }
)

CONFIG$NON_REG_EXTRA_TEXT <- list(
  codecheckers = "<i>\\*Note that the total number of codechecks is less than 
    the collective sum of individual codecheckers' number of codechecks. 
    This is because some codechecks involved more than one codechecker.</i>"
)

CONFIG$NON_REG_SUBTEXT <- list(
  codecheckers = function(table, subcat=NULL){
    no_codecheckers <- nrow(table)
    return(paste("In total,", no_codecheckers, "codecheckers contributed", CONFIG$NO_CODECHECKS, "codechecks"))
  },

  venues = function(table, subcat = NULL){
    # Case there are no subcategories
    if (is.null(subcat)){
      no_venues <- nrow(table)
      return(paste("In total,", CONFIG$NO_CODECHECKS, "codechecks were completed for", no_venues, "venues"))
    }
    
    # Case we have subcategories
    else{
      no_venues_subcat <- nrow(table)
      total_codechecks <- CONFIG$NO_CODECHECKS_VENUE_TYPE[[subcat]]
      codecheck_word <- if (total_codechecks == 1) "codecheck" else "codechecks"
      venue_name_subtext <- subcat

      # Making the venue_name_subtext plural if necessary
      if (no_venues_subcat > 1){
        venue_name_subtext <- switch (subcat,
          "conference" = "conferences",
          "journal" = "journals",
          "community" = "communities"
        )
      }
      return(paste("In total,", total_codechecks, codecheck_word, "were completed for", no_venues_subcat, venue_name_subtext))
    }
  }
)

# Note that the order of the names in the list will be the order of table columns in html and json
CONFIG$NON_REG_TABLE_COL_NAMES <- list(
  "codecheckers" = c(
    "codechecker_name" = "Codechecker name",
    "Codechecker" = "ORCID ID",
    "no_codechecks" = "No. of codechecks"
  ),

  "venues" = c(
    "Type" = "Venue type", 
    "Venue" = "Venue name",
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
  "preprint" = "Preprint",
  "AUMC" = "Amsterdam UMC"
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
