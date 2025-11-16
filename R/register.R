#' Function for rendering the register into different view
#'
#' NOTE: You should put a GitHub API token in the environment variable `GITHUB_PAT` to fix rate limits. Acquire one at see https://github.com/settings/tokens.
#'
#' - `.html`
#' - `.md``
#'
#' @param register A `data.frame` with all required information for the register's view
#' @param filter_by The filter or list o filters (if applicable)
#' @param outputs The output formats to create
#' @param config A list of configuration files to be sourced at the beginning of the rending process
#' @param venues_file Path to the venues.csv file containing venue names and labels
#' @param codecheck_repo_path Optional path to the codecheck package repository for build metadata (default: NULL)
#' @param from The first register entry to check
#' @param to The last register entry to check
#' @param parallel Logical; if TRUE, renders certificates in parallel using multiple cores. Defaults to FALSE.
#' @param ncores Integer; number of CPU cores to use for parallel rendering. If NULL, automatically detects available cores minus 1. Defaults to NULL.
#'
#' @return A `data.frame` of the register enriched with information from the configuration files of respective CODECHECKs from the online repositories
#'
#' @author Daniel Nuest
#' @importFrom parsedate parse_date
#' @importFrom rmarkdown render
#' @importFrom knitr kable
#' @importFrom utils capture.output read.csv tail packageVersion
#' @import     jsonlite
#' @import     dplyr
#'
#' @export
register_render <- function(register = read.csv("register.csv", as.is = TRUE, comment.char = '#'),
                            filter_by = c("venues", "codecheckers"),
                            outputs = c("html", "md", "json"),
                            config = c(system.file("extdata", "config.R", package = "codecheck")),
                            venues_file = "venues.csv",
                            codecheck_repo_path = NULL,
                            from = 1,
                            to = nrow(register),
                            parallel = FALSE,
                            ncores = NULL) {
  message("Rendering register using codecheck version ", utils::packageVersion("codecheck"), " from ", from, " to ", to)

  # Loading config.R files
  for (i in seq(length(config))) {
    source(config[i])
  }

  # Load venues configuration
  load_venues_config(venues_file)

  # Setup external libraries locally (Bootstrap, Font Awesome, Academicons, etc.)
  setup_external_libraries()

  # Copy package JavaScript files (citation.js, cert-utils.js, etc.)
  copy_package_javascript()

  message("Using cache path ", R.cache::getCacheRootPath())

  # Get build metadata for footer and meta tags
  build_metadata <- get_build_metadata(".", codecheck_repo_path)
  CONFIG$BUILD_METADATA <- build_metadata

  register <- register[(from:to),]

  register_table <- preprocess_register(register, filter_by)
  # Setting number of codechecks now for later use. This is done to avoid double counting codechecks
  # done by multiple authors.
  CONFIG$NO_CODECHECKS <- nrow(register_table)

  if("html" %in% outputs) {
    render_cert_htmls(register_table, force_download = FALSE, parallel = parallel, ncores = ncores)
  }

  create_filtered_reg_csvs(register_table, filter_by)
  create_register_files(register_table, filter_by, outputs)
  create_non_register_files(register_table, filter_by)

  # Generate redirect pages for codecheckers with ORCID
  if ("codecheckers" %in% filter_by) {
    generate_codechecker_redirects(register_table)
  }

  # Write build metadata JSON file
  write_meta_json(build_metadata, "docs")

  # Generate SEO files (sitemap.xml and robots.txt)
  generate_sitemap(register_table, filter_by, output_dir = "docs")
  generate_robots_txt(output_dir = "docs")

  return(register_table)
}

#' Function for checking all entries in the register
#'
#' This functions starts of a `data.frame` read from the local register file.
#'
#' **Note**: The validation of `codecheck.yml` files happens in function `validate_codecheck_yml()`.
#'
#' Further test ideas:
#'
#' - Does the repo have a LICENSE?
#'
#' @param register A `data.frame` with all required information for the register's view
#' @param from The first register entry to check
#' @param to The last register entry to check
#'
#' @author Daniel Nuest
#' @importFrom R.cache getCacheRootPath
#' @importFrom utils packageVersion
#' @importFrom gh gh
#' @export
register_check <- function(register = read.csv("register.csv", as.is = TRUE, comment.char = '#'),
                           from = 1,
                           to = nrow(register)) {
  message("Checking register using codecheck version ", utils::packageVersion("codecheck"), " from ", from, " to ", to)
  
  # Loading config.R file
  source(system.file("extdata", "config.R", package = "codecheck"))
  
  message("Using cache path ", R.cache::getCacheRootPath())
  
  for (i in seq(from = from, to = to)) {
    cat("Checking", toString(register[i, ]), "\n")
    entry <- register[i, ]

    # check certificate IDs if there is a codecheck.yml
    codecheck_yaml <- get_codecheck_yml(entry$Repository)
    check_certificate_id(entry, codecheck_yaml)
    check_issue_status(entry)
    cat("Completed checking registry entry", toString(register[i, "Certificate"]), "\n")
  }
}
