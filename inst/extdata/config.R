CONFIG <- new.env()

utils::globalVariables(c("CONFIG"))

# REPOSITORY POLICY

# Organisations/groups a checked repository is allowed to live in, per
# platform, see `check_repository_org()`. "codecheckers" and "cdchck" are the
# project's own org/group; additional trusted orgs (e.g. community-run
# venues that host their own checks) can be added here.
CONFIG$ALLOWED_REPO_ORGS <- list(
  github = c("codecheckers", "reproducible-agile"),
  gitlab = c("cdchck")
)

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
    # Paper Title carries the most content (full titles), Report is just a
    # short DOI/link - it previously had this backwards (register#84 followup).
    venues = "|:--------|:------------|:-------------------------------------------------------|:---------------|",
    # Works filter: Certificate | Report | Venue | Type | Check date. The page's
    # own h1 already names the work, so Paper Title is dropped (like Venue/Type
    # are for venues above) - same as "general" minus that one column.
    works = "|:-------|:--------------------------------------------------|:---------------|:---|:--------------------------|"
  ),

  non_reg = list(
    venues = "|:-----------|:---------------------|:----------|",
    venues_subcat = "|:---------------------|:----------|",
    codecheckers = "|:-----------|:---------------------|:----------|:------|",
    works = "|:---------------------------------------------|:---------------------------|:----------|",
    persons = "|:-----------|:---------------------|:----------|:----------|"
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
    csv = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Type", "Venue", "Check date"),
    json = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Type", "Venue", "Check date")
  ),

  # Venue-specific views (venue and type are redundant in page context)
  venues = list(
    html = c("Certificate", "Report", "Paper Title", "Check date"),
    md = c("Certificate", "Report", "Paper Title", "Check date"),
    csv = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Check date"),
    json = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Check date")
  ),

  # Codechecker-specific views (codechecker is redundant in page context)
  codecheckers = list(
    html = c("Certificate", "Report", "Paper Title", "Venue", "Type", "Check date"),
    md = c("Certificate", "Report", "Paper Title", "Venue", "Type", "Check date"),
    csv = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Venue", "Type", "Check date"),
    json = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Venue", "Type", "Check date")
  ),

  # Work-specific views (Paper Title is redundant - it's the page's own h1).
  # "Repository" is kept in html/json (dropped again before the visible
  # table is built, see create_persons_and_works_md()/render_register_json())
  # purely so generate_work_metadata_html()/schema.org can look up each row's
  # codecheck.yml without needing the un-dropped full_register_table.
  works = list(
    html = c("Certificate", "Report", "Venue", "Type", "Check date", "Repository"),
    md = c("Certificate", "Report", "Venue", "Type", "Check date"),
    csv = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Venue", "Type", "Check date"),
    json = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Venue", "Type", "Check date")
  ),

  # Person-specific views. "Role" (author/codechecker) is what
  # create_persons_md_table() splits the two on-page tables by; every other
  # column is the same set codecheckers uses so both role-tables can share
  # one column subset. No "md" entry: see CONFIG$FILTERS_WITHOUT_MD.
  persons = list(
    html = c("Certificate", "Report", "Paper Title", "Venue", "Type", "Check date", "Role"),
    csv = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Venue", "Type", "Check date", "Role"),
    json = c("Certificate ID", "Certificate Link", "Repository", "Repository Link", "Report", "Title", "Paper reference", "OpenAlex", "Venue", "Type", "Check date", "Role")
  )
)

CONFIG$DIR_TEMP_REGISTER_CODECHECKER <- "docs/temp_register_codechecker.csv"
CONFIG$FILTER_COLUMN_NAMES <- list(
  "venues" = "Venue",
  "codecheckers" = "Codechecker",
  "works" = "Work",
  "persons" = "Person"
)

# register.md is only worth publishing for a page whose main content is one
# table - venues, codecheckers and works all are, but a person page shows
# two (works authored, checks conducted), and a single markdown table can't
# represent that without collapsing the role distinction. Filters listed
# here get every other output (html, json, csv) but no register.md, and the
# HTML footer's "Markdown" link is omitted for them (see
# generate_html_postfix_hrefs_reg()).
CONFIG$FILTERS_WITHOUT_MD <- c("persons")

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
    venue_name <- table_details[["name"]]
    paste0("CODECHECKs for ", venue_name)
  },

  # table_details$title is set by generate_table_details()'s "works" branch,
  # extracted from the group's own "Paper Title" column - the DOI itself
  # (table_details$name) is the fallback for the rare case that column is
  # missing.
  "works" = function(table_details) {
    title <- table_details[["title"]]
    if (is.null(title) || is.na(title) || !nzchar(title)) title <- table_details[["name"]]
    paste0("CODECHECKs of ", title)
  },

  # Bare name, not "Codechecks by X" - #123's person page covers both
  # authoring and checking, so a role-specific title would be wrong for the
  # ~79% of people who only ever appear as an author.
  "persons" = function(table_details) {
    orcid <- table_details[["name"]]
    person_name <- CONFIG$DICT_ORCID_ID_NAME[[orcid]]
    if (is.null(person_name)) person_name <- orcid
    person_name
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
  works = "https://codecheck.org.uk/register/works/",
  persons = "https://codecheck.org.uk/register/persons/",
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

# Stable venue-type -> colour map. The statistics page used to derive these by
# position from the order the types happen to first appear in the data, which
# silently reassigns colours as the register grows; the codecheckers table
# (register#92) and the codechecker donut (register#207) need the same colours
# as that page, so the mapping is pinned here by name. The values are the
# colours the statistics page produced before this was pinned down.
CONFIG$VENUE_TYPE_COLORS <- list(
  journal = "#2c7a4b",
  community = "#3f7fbf",
  conference = "#c97a2c",
  institution = "#8a4fbf"
)

# Used for any venue type not listed above, so a new type is visibly neutral
# rather than borrowing another type's colour.
CONFIG$VENUE_TYPE_COLOR_FALLBACK <- "#8a8a8a"

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
  },

  works = function(subcat = NULL) {
    "All checked works"
  },

  # #123: the overview page's heading is "People", not "codecheckers" - it
  # now covers paper authors as well as codecheckers.
  persons = function(subcat = NULL) {
    "People"
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
    return(paste0("In total, ", no_codecheckers, " codecheckers contributed ", CONFIG$NO_CODECHECKS, " codechecks."))
  },

  venues = function(table, subcat = NULL){
    # Case there are no subcategories
    if (is.null(subcat)){
      no_venues <- nrow(table)
      return(paste0("In total, ", CONFIG$NO_CODECHECKS, " codechecks were completed for ", no_venues, " venues."))
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
      return(paste0("In total, ", total_codechecks, " ", codecheck_word, " were completed for ", no_venues_subcat, " ", venue_name_subtext, "."))
    }
  },

  works = function(table, subcat = NULL) {
    no_works <- nrow(table)
    paste0("In total, ", no_works, " checked works are listed here.")
  },

  persons = function(table, subcat = NULL) {
    no_persons <- nrow(table)
    paste0("In total, ", no_persons, " people have authored or checked a work in the register.")
  }
)

# Note that the order of the names in the list will be the order of table columns in html and json
CONFIG$NON_REG_TABLE_COL_NAMES <- list(
  "codecheckers" = c(
    "codechecker_name" = "Codechecker name",
    "Codechecker" = "ORCID",
    "no_codechecks" = "No. of codechecks",
    "check_types" = "Check types"
  ),

  "venues" = c(
    "Venue" = "Venue name",
    "Type" = "Venue type",
    "no_codechecks" = "No. of codechecks",
    "venue_label" = "Issue label"
  ),

  "works" = c(
    "Title" = "Work title",
    "Work" = "DOI",
    "no_checks" = "No. of checks"
  ),

  "persons" = c(
    "person_name" = "Name",
    "Person" = "ORCID",
    "no_works" = "Works authored",
    "no_checks" = "Checks conducted"
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
  researchequals_api = "https://researchequals.com/api/"
)

CONFIG$CERTS_URL_PREFIX <- "https://doi.org/"

# CITATION METADATA OF CERTIFICATE PAGES
# The publisher of a CODECHECK certificate as a work, used for the Highwire
# citation_publisher/citation_technical_report_institution tags and the
# schema.org publisher of a certificate page. Deliberately *not* the publisher
# the Zenodo curation policy prescribes for the record ("CODECHECK Community on
# Zenodo", see R/zenodo.R): that names one archived copy, while certificates are
# also published on OSF and ResearchEquals.
CONFIG$CERT_PUBLISHER <- "CODECHECK Initiative"

# Keywords every certificate page carries, joined with the certificate's venue
CONFIG$CERT_KEYWORDS <- c("CODECHECK", "reproducibility", "code execution")

# Language of the certificate pages, for citation_language and inLanguage
CONFIG$CERT_LANGUAGE <- "en"
CONFIG$CERT_DPI <- 72

CONFIG$CERT_DOWNLOAD_AND_CONVERT <- TRUE

# DIRECTORIES
CONFIG$CERTS_DIR <- list(
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
  "Certificate PDF",
  "Repository",
  "Repository Link",
  "Report",
  "Title",
  "Paper reference",
  "OpenAlex",
  "Type",
  "Venue",
  "Check date"
)
