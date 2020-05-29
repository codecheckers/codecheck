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
#' For each entry in the registry we can do some basic checks, e.g. like
#' - checking the certificate numbers match
#' - checking the yaml exists?
#' - linting the yaml?
#' 
#' @param configuration R object of class `yaml`
#' @return `TRUE` if the provided configuration is valid, `FALSE` otherwise.
#' 
#' @export
validate_codecheck_yml <- function(configuration) {
  codecheck_yml <- NULL
  if (is.character(configuration) && file.exists(configuration)) {
    # TODO: validate that file encoding is UTF-8, if a file is given
    # TODO: check the 
    stop("File checking not yet implemented.")
    # read file to YAML, continue
  }
  
  codecheck_yml <- configuration
  
  # MUST have manifest
  assertthat::assert_that(assertthat::has_name(codecheck_yml, "manifest"))
  
  # manifest must not be named
  assertthat::assert_that(codecheck_yml$manifest, NULL)
  
  # each element of the manifest MUST have a file
  sapply(X = codecheck_yml$manifest, FUN = function(manifest_item) {
    assertthat::assert_that(assertthat::has_name(manifest_item, "file"))
  }  )
}
