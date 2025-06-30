#' Retrieve a codecheck.yml file from a remote repository
#' 
#' @author Daniel Nüst
#' @param x the repo specification
get_codecheck_yml_uncached <- function(x) {
  spec <- parse_repository_spec(x)
  
  result <- switch (spec[["type"]],
    "github" = get_codecheck_yml_github(spec[["repo"]]),
    "osf" = get_codecheck_yml_osf(spec[["repo"]]),
    "gitlab" = get_codecheck_yml_gitlab(spec[["repo"]]),
    "zenodo" = get_codecheck_yml_zenodo(spec[["repo"]]),
    "zenodo-sandbox" = get_codecheck_yml_zenodo(spec[["repo"]], sandbox = TRUE),
  )
  
  return(result)
}

#' Retrieve a codecheck.yml file from a GitHub repository
#' 
#' @author Daniel Nüst
#' @importFrom gh gh
#' @param x the org/repo to download the file from
get_codecheck_yml_github <- function(x) {
  org_repo <- regmatches(x, regexpr("/", x), invert =TRUE)[[1]]
  
  if (length(org_repo) != 2) {
    stop("Incomplete repo specification for type 'github', need 'org/repo(|path)' but have '", x, "'")
  }
  
  repo_path <- strsplit(org_repo[[2]], "|", fixed = TRUE)[[1]]
  path <- ""
  if (length(repo_path) == 2) {
    org_repo[[2]] <- repo_path[[1]]
    path <- repo_path[[2]]
  }
  
  repo_files <- gh::gh("GET /repos/:org/:repo/contents/:path",
                       org = org_repo[[1]],
                       repo = org_repo[[2]],
                       path = path,
                       .accept = "application/vnd.github.VERSION.raw")
  repo_file_names <- sapply(repo_files, "[[", "name")
  
  if ("codecheck.yml" %in% repo_file_names) {
    config_file_response <- gh::gh(
      "GET /repos/:org/:repo/contents/:file",
      org = org_repo[[1]],
      repo = org_repo[[2]],
      file = ifelse(path == "", "codecheck.yml", paste0(path, "/codecheck.yml")),
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

#' Retrieve a codecheck.yml file from a Zenodo record
#' 
#' @author Daniel Nüst
#' @param x the record ID on Zenodo
#' @param sandbox connect with the Zenodo Sandbox instead of the real service
#' @importFrom httr GET content
#' @importFrom yaml yaml.load
#' @importFrom zen4R ZenodoManager
get_codecheck_yml_zenodo <- function(x, sandbox = FALSE) {
  zenodo <- ZenodoManager$new(
    url = "https://zenodo.org/api",
    sandbox = sandbox,
    logger = "INFO"
  )
  
  record <- zenodo$getRecordById(x)
  
  if(!is.null(record)) {
    files <- record$files
    for(f in files) {
      if(f$filename == "codecheck.yml") {
        response <- httr::GET(f$download)
        content <- httr::content(response, as = "text", encoding = "UTF-8")
        config_file <- yaml::yaml.load(content)
        return(config_file)
      }
    }
  }
  
  # record is null, or no file with the required name was in the list of files
  warning("codecheck.yml not found in record ", x, " (sandbox? ", sandbox, ")")
  return(NULL)
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
  
  supported_repos <- c("github", "osf", "gitlab", "zenodo", "zenodo-sandbox")
  if (! type %in% supported_repos) {
    stop("Unsupported repository type '", type, "' - must be one of ", toString(supported_repos))
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
#' @importFrom httr http_error http_status GET
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
  
  # MUST have a non-empty certificate identifier matching the pattern NNNN-NNN
  assertthat::assert_that(isTRUE(grepl("^\\d{4}-\\d{3}$", codecheck_yml$certificate)), # if certificate is missing, grepl returns a logical(0)
                          msg = paste0("The certificate identifier '",
                                       codecheck_yml$certificate,
                                       "' is missing or invalid")
                          )
  
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
  assertthat::assert_that(grepl(url_regex, codecheck_yml$paper$reference),
                          msg = paste0(codecheck_yml$paper$reference, " is not a valid URL"))
  
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
        assertthat::assert_that(httr::http_error(r) == FALSE,
                                msg = paste0(r, " - URL returns error: ",
                                             toString(httr::http_status(httr::GET(r))))
                                )
      }
    } else {
      assertthat::assert_that(httr::http_error(codecheck_yml$repository) == FALSE,
                              msg = paste0(codecheck_yml$repository, " - URL returns error: ",
                                           toString(httr::http_status(httr::GET(r))))
      )  
    }
  }
  
  return(TRUE)
}
