#' Retrieve a codecheck.yml file from a remote repository
#' 
#' @author Daniel Nüst
#' @param x the repo specification
get_codecheck_yml_uncached <- function(x) {
  spec <- parse_repository_spec(x)
  
  result <- switch (spec[["type"]],
    "github" = get_codecheck_yml_github(spec[["repo"]]),
    "osf" = get_codecheck_yml_osf(spec[["repo"]]),
    "gitlab" = get_codecheck_yml_gitlab(spec[["repo"]])
  )
  
  return(result)
}

#' Retrieve a codecheck.yml file from a GitHub repository
#' 
#' @author Daniel Nüst
#' @importFrom gh gh
#' @param x the org/repo to download the file from
get_codecheck_yml_github <- function(x) {
  org_repo <- strsplit(x, "/", fixed = TRUE)[[1]]
  
  if (length(org_repo) != 2) {
    stop("Incomplete repo specification for type 'github', need 'org/repo' but have '", x, "'")
  }
  
  repo_files <- gh::gh("GET /repos/:org/:repo/contents/",
                       org = org_repo[[1]],
                       repo = org_repo[[2]],
                       .accept = "application/vnd.github.VERSION.raw")
  repo_file_names <- sapply(repo_files, "[[", "name")
  
  if ("codecheck.yml" %in% repo_file_names) {
    config_file_response <- gh::gh(
      "GET /repos/:org/:repo/contents/:file",
      org = org_repo[[1]],
      repo = org_repo[[2]],
      file = "codecheck.yml",
      .accept = "application/vnd.github.VERSION.raw")
    config_file <- yaml::read_yaml(text = config_file_response$message)
    return(config_file)
  } else {
    warning("codecheck.yml not found in repository ", x)
    return(NULL)
  }
}

#' Retrieve a codecheck.yml file from an OSF project
#' 
#' @author Daniel Nüst
#' @param x the OSF id (5 characters)
#' @importFrom osfr osf_retrieve_node osf_ls_files osf_download
get_codecheck_yml_osf <- function(x) {
  repo <- osfr::osf_retrieve_node(x)
  repo_files <- osfr::osf_ls_files(repo, pattern = "codecheck.yml")
  
  if (nrow(repo_files) == 1) {
    temp_dir <- tempdir()
    osfr::osf_download(repo_files, path = temp_dir)
    local_file <- file.path(temp_dir, "codecheck.yml")
    config_file <- yaml::read_yaml(file = local_file)
    file.remove(local_file)
    return(config_file)
  } else {
    warning("codecheck.yml not found in repository https://osf.io/", x)
    return(NULL)
  }
}

#' Retrieve a codecheck.yml file from an GitLab.com project
#' 
#' It seems https://statnmap.github.io/gitlabr/ always requires authentication
#' 
#' @author Daniel Nüst
#' @param x the project name on GitLab.com
#' @importFrom httr GET content
#' @importFrom yaml yaml.load
get_codecheck_yml_gitlab <- function(x) {
  link <- paste0("https://gitlab.com/", x, "/-/raw/main/codecheck.yml?inline=false")
  response <- httr::GET(link)
  
  if (response$status == 200) {
    content <- httr::content(response, as = "text", encoding = "UTF-8")
    config_file <- yaml::yaml.load(content)
    return(config_file)
  } else {
    warning("codecheck.yml not found in repository https://gitlab.com/", x)
    return(NULL)
  }
}

#' Parse the repository specification in the column "Repo" in the register CSV file
#' 
#' Based roughly on [`remotes::parse_one_extra`](https://github.com/r-lib/remotes/blob/master/R/deps.R#L519)
#' 
#' Supported variants:
#' 
#' - `osf::ABC12`
#' - `github::codecheckers/Piccolo-2020`
#' - `gitlab::cdchck/Piccolo-2020`
#' 
#' @author Daniel Nüst
#' @param x the repository specification to parse
#' @return a named character vector with the items `type` and `repo`
parse_repository_spec <- function(x) {
  pieces <- strsplit(x, "::", fixed = TRUE)[[1]]
  
  if (length(pieces) == 2) {
    type <- pieces[1]
    repo <- pieces[2]
  } else {
    stop("Malformed repository specification '", x, "'")
  }
  
  if (! type %in% c("github", "osf", "gitlab")) {
    stop("Unsupported repository type '", type, "'")
  }
  
  return(c(type = type, repo = repo))
}

get_codecheck_yml_cached <- R.cache::addMemoization(get_codecheck_yml_uncached)

#' Get the CODECHECK configuration file from a repository
#' 
#' @param x Repository in the codecheckers organisation on GitHub
#' 
#' @author Daniel Nüst
#' @importFrom R.cache addMemoization
#' 
#' @export
get_codecheck_yml <- function(x) {
  configuration <- get_codecheck_yml_cached(x)
  return(configuration)
}

#' Validate a CODECHECK configuration
#' 
#' This functions checks "MUST"-contents only, see https://codecheck.org.uk/spec/config/latest/
#' 
#' @param configuration R object of class `list`, or a path to a file
#' @return `TRUE` if the provided configuration is valid, otherwise the function stops with an error
#' 
#' @author Daniel Nüst
#' @importFrom rorcid check_dois
#' 
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
                                       "but the available ones are: ",
                                       toString(names(codecheck_yml))
                                       )
                          )
  
  # each element of the manifest MUST have a file
  sapply(X = codecheck_yml$manifest, FUN = function(manifest_item) {
    assertthat::assert_that(assertthat::has_name(manifest_item, "file"))
  })
  
  # each author MUST have a name
  sapply(X = codecheck_yml$paper$authors, FUN = function(authors_item) {
    assertthat::assert_that(assertthat::has_name(authors_item, "name"),
                            msg = "All authors must have a 'name'.")
  })
  
  # codechecker MUST have a name
  sapply(X = codecheck_yml$codechecker, FUN = function(codechecker_item) {
    assertthat::assert_that(assertthat::has_name(codechecker_item, "name"),
                            msg = "All codecheckers must have a 'name'.")
  })
  
  # the report MUST be a valid DOI
  assertthat::assert_that(codecheck_yml$report %in% rorcid::check_dois(codecheck_yml$report)$good,
                          msg = paste0(codecheck_yml$report, " is not a valid DOI"))

  # Check if the paper_link contains a valid URL. We only check that it starts with https?://
  url_regex <- "^https?://"
  if (!grepl(url_regex, codecheck_yml$paper$reference)) {
    warning("The paper reference in the codecheck.yml is not a valid URL")
  } 
  
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
  
  # the repository URL should exist
  if(assertthat::has_name(codecheck_yml, "repository")) {
    if(is.vector(codecheck_yml$repository)) {
      for(r in codecheck_yml$repository) {
        assertthat::assert_that(url_exists(r, quiet = TRUE) == TRUE,
                                msg = paste0(r, " - URL does not exist"))  
      }
    } else {
      assertthat::assert_that(url_exists(codecheck_yml$repository, quiet = TRUE) == TRUE,
                              msg = paste0(codecheck_yml$repository, " - URL does not exist"))
    }
  }
  
  return(TRUE)
}

#' From https://stackoverflow.com/a/52915256/261210 by hrbrmstr
#' 
#' @param x a single URL
#' @param non_2xx_return_value what to do if the site exists but the
#'        HTTP status code is not in the `2xx` range. Default is to return `FALSE`.
#' @param quiet if not `FALSE`, then every time the `non_2xx_return_value` condition
#'        arises a warning message will be displayed. Default is `FALSE`.
#' @param ... other params (`timeout()` would be a good one) passed directly
#'        to `httr::HEAD()` and/or `httr::GET()`
#'        
#' @importFrom httr HEAD GET status_code
url_exists <- function(x, non_2xx_return_value = FALSE, quiet = FALSE,...) {
  
  capture_error <- function(code, otherwise = NULL, quiet = TRUE) {
    tryCatch(
      list(result = code, error = NULL),
      error = function(e) {
        if (!quiet)
          message("Error: ", e$message)
        
        list(result = otherwise, error = e)
      },
      interrupt = function(e) {
        stop("Terminated by user", call. = FALSE)
      }
    )
  }
  
  safely <- function(.f, otherwise = NULL, quiet = TRUE) {
    function(...) capture_error(.f(...), otherwise, quiet)
  }
  
  sHEAD <- safely(httr::HEAD)
  sGET <- safely(httr::GET)
  
  # Try HEAD first since it's lightweight
  res <- sHEAD(x, ...)
  
  if (is.null(res$result) || 
      ((httr::status_code(res$result) %/% 200) != 1)) {
    
    res <- sGET(x, ...)
    
    if (is.null(res$result)) return(NA) # or whatever you want to return on "hard" errors
    
    if (((httr::status_code(res$result) %/% 200) != 1)) {
      if (!quiet) warning(sprintf("Requests for [%s] responded but without an HTTP status code in the 200-299 range", x))
      return(non_2xx_return_value)
    }
    
    return(TRUE)
    
  } else {
    return(TRUE)
  }
  
}

