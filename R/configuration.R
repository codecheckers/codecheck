#' @importFrom gh gh
get_codecheck_yml_uncached <- function(repo) {
  repo_files <- gh::gh("GET /repos/codecheckers/:repo/contents/",
                       repo = repo,
                       .accept = "application/vnd.github.VERSION.raw")
  repo_file_names <- sapply(repo_files, "[[", "name")
  
  if ("codecheck.yml" %in% repo_file_names) {
    config_file_response <- gh::gh(
      "GET /repos/codecheckers/:repo/contents/:file",
      repo = repo,
      file = "codecheck.yml",
      .accept = "application/vnd.github.VERSION.raw")
    config_file <- yaml::read_yaml(text = config_file_response$message)
    return(config_file)
  } else {
    return(NULL)
  }
}

get_codecheck_yml_cached <- R.cache::addMemoization(get_codecheck_yml_uncached)

#' Get the CODECHECK configuration file from a repository
#' 
#' @param repo Repository in the codecheckers organisation on GitHub
#' 
#' @importFrom R.cache addMemoization
#' 
#' @export
get_codecheck_yml <- function(repo) {
  configuration <- get_codecheck_yml_cached(repo)
  return(configuration)
}

#' Validate a CODECHECK configuration
#' 
#' This functions checks "MUST"-contents only, see https://codecheck.org.uk/spec/config/latest/
#' 
#' @param configuration R object of class `list`, or a path to a file
#' @return `TRUE` if the provided configuration is valid, otherwise the function stops with an error
#' 
#' @importFrom rorcid check_dois
#' @export
validate_codecheck_yml <- function(configuration) {
  codecheck_yml <- NULL
  if (is.character(configuration) && file.exists(configuration)) {
    # TODO: validate that file encoding is UTF-8, if a file is given
    codecheck_yml <- yaml::read_yaml(configuration)
  } else if (inherits(configuration, "list")) {
    codecheck_yml <- configuration
  } else {
    stop("Could not load codecheck configuration from input '", configuration, "'")
  }
  
  # MUST have manifest
  assertthat::assert_that(assertthat::has_name(codecheck_yml, "manifest"),
                          msg = paste0("codecheck.yml must have a root-level node 'manifest'",
                                       "but the available ones are: ", names(codecheck_yml)))
  
  # each element of the manifest MUST have a file
  sapply(X = codecheck_yml$manifest, FUN = function(manifest_item) {
    assertthat::assert_that(assertthat::has_name(manifest_item, "file"))
  })
  
  # the report MUST be a valid DOI
  assertthat::assert_that(codecheck_yml$report %in% rorcid::check_dois(codecheck_yml$report)$good,
                          msg = paste0(codecheck_yml$report, " is not a valid DOI"))
  
  # if ORCID are used, they must be without URL prefix and valid form, actual checking requires login, see #11
  orcid_regex <- "^(\\d{4}\\-\\d{4}\\-\\d{4}\\-\\d{3}(\\d|X))$"
  if(is.list(codecheck_yml$paper$authors)) {
    for(a in codecheck_yml$paper$authors) {
      if(assertthat::has_name(a, "ORCID")) {
        assertthat::assert_that(grepl(pattern = orcid_regex, x = a$ORCID, perl = TRUE),
                                msg = paste0("ORCIDs must be well-formed and without URL prefix, ",
                                             "but the author's ORCID '", a$ORCID, "' is not"))
      }
    }
  }
  if(is.list(codecheck_yml$codechecker)) {
    for(a in codecheck_yml$codechecker) {
      if(assertthat::has_name(a, "ORCID")) {
        assertthat::assert_that(grepl(pattern = orcid_regex, x = a$ORCID, perl = TRUE),
                                msg = paste0("ORCIDs must be well-formed and without URL prefix, ",
                                             "but the checker's ORCID '", a$ORCID, "' is not"))
      }
    }
  }
  
  return(TRUE)
}
