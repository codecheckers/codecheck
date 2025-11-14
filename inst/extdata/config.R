CONFIG <- new.env()

utils::globalVariables(c("CONFIG"))

# REGISTER TABLE

# Specifying the register table column widths
# The names in the list are the filter type
# For filters other than venues we use the general column widths
# Column widths: Paper Title doubled, Report reduced significantly
CONFIG$MD_TABLE_COLUMN_WIDTHS <- list(
  reg = list(
    # Main register and codecheckers: Certificate | Report | Paper Title | Venue | Type | Check date
    general = "|:-------|:--------------------------------------------------|:----------------------------------|:---------------|:---|:--------------------------|",
    # Venues filter: Certificate | Report | Paper Title | Check date
    venues = "|:-------|:--------------------------------------------------|:------|:--------------------------|"
  ),

  non_reg = list(
    venues = "|:-----------|:---------------------|:----------|",
    venues_subcat = "|:---------------------|:----------|",
    codecheckers = "|:-----------|:---------------------|:----------|"
  )
)

# Column configuration for register tables
# Hierarchical structure: filter -> file_type -> columns
# Special filter "default" is used for the main register and as fallback
# Per-filter configurations can override default for specific views
CONFIG$REGISTER_COLUMNS <- list(
  # Default configuration (main register, unfiltered)
  # Order per issue #101: Certificate, Report, Title, Venue, Type, Check date
  default = list(
    html = c("Certificate", "Report", "Paper Title", "Venue", "Type", "Check date"),
    md = c("Certificate", "Report", "Paper Title", "Venue", "Type", "Check date"),
    csv = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "Type", "Venue", "Check date"),
    json = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "Type", "Venue", "Check date")
  ),

  # Venue-specific views (venue and type are redundant in page context)
  venues = list(
    html = c("Certificate", "Report", "Paper Title", "Check date"),
    md = c("Certificate", "Report", "Paper Title", "Check date"),
    csv = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "Check date"),
    json = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "Check date")
  ),

  # Codechecker-specific views (codechecker is redundant in page context)
  codecheckers = list(
    html = c("Certificate", "Report", "Paper Title", "Venue", "Type", "Check date"),
    md = c("Certificate", "Report", "Paper Title", "Venue", "Type", "Check date"),
    csv = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "Venue", "Type", "Check date"),
    json = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "Venue", "Type", "Check date")
  )
)

CONFIG$DIR_TEMP_REGISTER_CODECHECKER <- "docs/temp_register_codechecker.csv"
CONFIG$FILTER_COLUMN_NAMES <- list(
  "venues" = "Venue",
  "codecheckers" = "Codechecker"
)

CONFIG$NO_CODECHECKS_VENUE_TYPE <- list()

CONFIG$MD_TITLES <- list(
  "default" = function(table_details){
    "CODECHECK Register"
  },

  "codecheckers" = function(table_details){
    identifier <- table_details[["name"]]
    # Check if it's an ORCID (format: NNNN-NNNN-NNNN-NNNX) or GitHub username
    if (grepl("^\\d{4}-\\d{4}-\\d{4}-\\d{3}[0-9X]$", identifier)) {
      # ORCID format
      auth_name <- CONFIG$DICT_ORCID_ID_NAME[[identifier]]
    } else {
      # GitHub username
      auth_name <- CONFIG$DICT_GITHUB_USERNAME_NAME[[identifier]]
    }
    paste0("Codechecks by ", auth_name)
  },

  "venues" = function(table_details) {
    venue_type <- table_details[["subcat"]]
    venue_name <- table_details[["name"]]
    paste0("CODECHECK Register for ", venue_name, " (", venue_type, ")")
  },

  "certs" = "CODECHECK Certificate"
)

CONFIG$HREF_DETAILS <- list(
  "csv_source" = list(base_url = "https://raw.githubusercontent.com/codecheckers/register/master/", ext = ".csv"),
  "searchable_csv" = list(base_url ="https://github.com/codecheckers/register/blob/master/", ext = ".csv"),
  "json" = list(base_url = "https://codecheck.org.uk/register/", ext = ".json"),
  "md" = list(base_url = "https://codecheck.org.uk/register/", ext = ".md")
)

# List of hyperlinks
CONFIG$HYPERLINKS <- list(
  certs = "https://codecheck.org.uk/register/certs/",
  venues = "https://codecheck.org.uk/register/venues/",
  register = "https://codecheck.org.uk/register/",
  codecheckers = "https://codecheck.org.uk/register/codecheckers/",
  orcid = "https://orcid.org/",
  osf = "https://osf.io/",
  gitlab = "https://gitlab.com/",
  github = "https://github.com/",
  doi = "https://doi.org/",
  codecheck_issue = "https://github.com/codecheckers/register/issues/",
  zenodo_deposit = "https://zenodo.org/deposit/",
  zenodo_community = "https://zenodo.org/communities/codecheck/",
  CrossRef = "https://www.crossref.org",
  OpenAlex = "https://openalex.org",
  zenodo = "https://zenodo.org/records/"
)

# Plural of venue subcategories 
CONFIG$VENUE_SUBCAT_PLURAL <- list(
  conference = "conferences",
  journal = "journals",
  community = "communities",
  institution = "institutions"
)

# NON-REGISTER_TABLE
CONFIG$NON_REG_TITLE_BASE <- "CODECHECK List of"
CONFIG$NON_REG_TITLE_FNS <- list(
  codecheckers = function(subcat=NULL){
    return("All codecheckers")
  },

  venues = function(subcat){
    if (is.null(subcat)){
      return("All CODECHECK venues")
    }

    else{
      # Pluralizing the venue subcat
      plural_subcat <- switch (subcat,
        "conference" = "conferences",
        "journal" = "journals",
        "community" = "communities",
        "institution" = "institutions"
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
        venue_name_subtext <- CONFIG$VENUE_SUBCAT_PLURAL[[subcat]]
      }
      return(paste("In total,", total_codechecks, codecheck_word, "were completed for", no_venues_subcat, venue_name_subtext))
    }
  }
)

# Note that the order of the names in the list will be the order of table columns in html and json
CONFIG$NON_REG_TABLE_COL_NAMES <- list(
  "codecheckers" = c(
    "codechecker_name" = "Codechecker name",
    "Codechecker" = "ORCID",
    "no_codechecks" = "No. of codechecks"
  ),

  "venues" = c(
    "Venue" = "Venue name",
    "Type" = "Venue type",
    "no_codechecks" = "No. of codechecks",
    "venue_label" = "Issue label"
  )
)

# REGISTER FILTER SUBCATEGORIES
# Each filter can be further divided into each of these subgroups
CONFIG$FILTER_SUBCATEGORIES <- list(
  venues = list("community", "journal", "conference", "institution") 
)

# For each filter with subcategories we have a reference to the column
# in the register table that refers to the subcat name
CONFIG$FILTER_SUBCAT_COLUMNS <- list(
  venues = "Type"
)

# OTHERS
CONFIG$DICT_ORCID_ID_NAME <- list()
CONFIG$DICT_GITHUB_USERNAME_NAME <- list()  # Maps GitHub usernames to codechecker names

# Delaying requests by 1 second to adhere to the rate limit of 60 requests/minute for Zenodo
CONFIG$CERT_REQUEST_DELAY <- 1

# Number of items in the featured lists of certificates
CONFIG$FEATURED_COUNT <- 10

# CERT LINKS
CONFIG$CERT_LINKS <- list(
  osf_api = "https://api.osf.io/v2/",
  zenodo_api = "https://zenodo.org/api/records/",
  crossref_api = "https://api.crossref.org/works/",
  openalex_api = "https://api.openalex.org/works/",
  researchequals_api = "https://www.researchequals.com/api/modules/main/"
)

CONFIG$CERTS_URL_PREFIX <- "https://doi.org/"
CONFIG$CERT_DPI <- 800

CONFIG$CERT_DOWNLOAD_AND_CONVERT <- TRUE

# DIRECTORIES
CONFIG$CERTS_DIR <- list(
  cert_page_template = system.file("extdata", "templates/cert/template_cert_page.html", package = "codecheck"),
  cert = "docs/certs"
)

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
  ),
  "cert" = list(
    "postfix" = system.file("extdata", "templates/cert/index_postfix_template.html", package = "codecheck"),
    "header" = system.file("extdata", "templates/general/index_header_template.html", package = "codecheck"),
    "prefix" = system.file("extdata", "templates/general/index_prefix_template.html", package = "codecheck"),
    md_template_base = system.file("extdata", "templates/cert/template_base.md", package = "codecheck"),
    md_template_no_cert = system.file("extdata", "templates/cert/template_no_cert.md", package = "codecheck")
  )
)

# DICT OF VENUE NAMES
# This is loaded dynamically from venues.csv by load_venues_config()
# Initialize as empty list for compatibility
CONFIG$DICT_VENUE_NAMES <- list()

# JSON FILE INFORMATION
# List specifying the columns to keep for JSON files
# This is used by render_register_json() to filter columns
CONFIG$JSON_COLUMNS <- c(
  "Certificate ID",
  "Certificate Link",
  "Repository",
  "Repository Link",
  "Report",
  "Title",
  "Paper reference",
  "Type",
  "Venue",
  "Check date"
)
