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

#' Validate YAML syntax of a codecheck.yml file
#'
#' This function checks whether a YAML file has valid syntax that can be parsed.
#' It does not validate the content or structure against the CODECHECK specification.
#' Use \code{\link{validate_codecheck_yml}} for full validation.
#'
#' @param yml_file Path to the YAML file to validate
#' @param stop_on_error If TRUE (default), stop execution with an error message if YAML is invalid.
#'   If FALSE, return FALSE on invalid YAML instead of stopping.
#'
#' @return Invisibly returns TRUE if YAML is valid. If stop_on_error is FALSE, returns FALSE
#'   on invalid YAML. If stop_on_error is TRUE, stops execution with an error message.
#'
#' @examples
#' \dontrun{
#' # Validate a codecheck.yml file
#' validate_yaml_syntax("codecheck.yml")
#'
#' # Check without stopping on error
#' is_valid <- validate_yaml_syntax("codecheck.yml", stop_on_error = FALSE)
#' }
#'
#' @author Daniel Nüst
#' @export
validate_yaml_syntax <- function(yml_file, stop_on_error = TRUE) {
  if (!file.exists(yml_file)) {
    stop("File does not exist: ", yml_file)
  }

  result <- tryCatch({
    yaml::read_yaml(yml_file)
    TRUE
  }, error = function(e) {
    error_msg <- paste0("Invalid YAML syntax in '", yml_file, "':\n", e$message)
    if (stop_on_error) {
      stop(error_msg, call. = FALSE)
    } else {
      message(error_msg)
      return(FALSE)
    }
  })

  invisible(result)
}

#' Get certificate identifier from GitHub issues by matching author names
#'
#' This function retrieves open issues from the codecheckers/register repository
#' and attempts to match author names from a codecheck.yml file with issue titles
#' to find the corresponding certificate identifier.
#'
#' Issue titles in the register follow the format: "Author Last, Author First | YYYY-NNN"
#' where YYYY-NNN is the certificate identifier.
#'
#' @param yml_file Path to the codecheck.yml file, or a list with codecheck metadata
#' @param repo GitHub repository in the format "owner/repo". Defaults to "codecheckers/register"
#' @param state Issue state to search. One of "open", "closed", or "all". Defaults to "open"
#' @param max_issues Maximum number of issues to retrieve. Defaults to 100
#'
#' @return A list with the following elements:
#'   \itemize{
#'     \item certificate: The certificate identifier (e.g., "2025-028") if found, otherwise NULL
#'     \item issue_number: The GitHub issue number if found, otherwise NULL
#'     \item issue_title: The full issue title if found, otherwise NULL
#'     \item matched_author: The author name that was matched, otherwise NULL
#'   }
#'
#' @examples
#' \dontrun{
#' # Get certificate ID from open issues
#' result <- get_certificate_from_github_issue("codecheck.yml")
#' if (!is.null(result$certificate)) {
#'   cat("Found certificate:", result$certificate, "in issue", result$issue_number, "\n")
#' }
#'
#' # Search closed issues
#' result <- get_certificate_from_github_issue("codecheck.yml", state = "closed")
#'
#' # Pass metadata directly
#' metadata <- codecheck_metadata(".")
#' result <- get_certificate_from_github_issue(metadata)
#' }
#'
#' @author Daniel Nüst
#' @importFrom gh gh
#' @export
get_certificate_from_github_issue <- function(yml_file,
                                               repo = "codecheckers/register",
                                               state = "open",
                                               max_issues = 100) {

  # Load configuration
  if (is.character(yml_file) && file.exists(yml_file)) {
    config <- yaml::read_yaml(yml_file)
  } else if (inherits(yml_file, "list")) {
    config <- yml_file
  } else {
    stop("yml_file must be a path to a codecheck.yml file or a codecheck metadata list")
  }

  # Extract author names
  if (!assertthat::has_name(config, "paper") ||
      !assertthat::has_name(config$paper, "authors")) {
    stop("codecheck.yml must have paper.authors field")
  }

  authors <- config$paper$authors
  author_names <- sapply(authors, function(a) a$name)

  # Split repo into owner and name
  repo_parts <- strsplit(repo, "/")[[1]]
  if (length(repo_parts) != 2) {
    stop("repo must be in format 'owner/repo'")
  }

  # Retrieve issues from GitHub
  issues <- gh::gh("GET /repos/:owner/:repo/issues",
                   owner = repo_parts[1],
                   repo = repo_parts[2],
                   state = state,
                   per_page = max_issues)

  # Certificate pattern: YYYY-NNN
  cert_pattern <- "\\d{4}-\\d{3}"

  # Try to match each author with issue titles
  for (author_name in author_names) {
    # Split author name into parts (handles "First Last" or "Last, First" formats)
    name_parts <- strsplit(author_name, "[, ]+")[[1]]

    for (issue in issues) {
      issue_title <- issue$title

      # Check if any part of the author name appears in the issue title
      # (case-insensitive matching)
      name_match <- any(sapply(name_parts, function(part) {
        grepl(part, issue_title, ignore.case = TRUE)
      }))

      if (name_match) {
        # Extract certificate identifier from title
        cert_match <- regmatches(issue_title, regexpr(cert_pattern, issue_title))

        if (length(cert_match) > 0) {
          return(list(
            certificate = cert_match[1],
            issue_number = issue$number,
            issue_title = issue_title,
            matched_author = author_name
          ))
        }
      }
    }
  }

  # No match found
  return(list(
    certificate = NULL,
    issue_number = NULL,
    issue_title = NULL,
    matched_author = NULL
  ))
}

#' Validate a CODECHECK configuration
#'
#' This functions checks "MUST"-contents only, see https://codecheck.org.uk/spec/config/latest/
#'
#' @param configuration R object of class `list`, or a path to a file
#' @return `TRUE` if the provided configuration is valid, otherwise the function stops with an error
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
        if(!is.null(r) && nchar(r) > 0) {
          response <- tryCatch(httr::GET(r), error = function(e) NULL)
          if(!is.null(response)) {
            assertthat::assert_that(httr::http_error(response) == FALSE,
                                    msg = paste0(r, " - URL returns error: ",
                                                 toString(httr::http_status(response)))
                                    )
          }
        }
      }
    } else {
      if(!is.null(codecheck_yml$repository) && nchar(codecheck_yml$repository) > 0) {
        response <- tryCatch(httr::GET(codecheck_yml$repository), error = function(e) NULL)
        if(!is.null(response)) {
          assertthat::assert_that(httr::http_error(response) == FALSE,
                                  msg = paste0(codecheck_yml$repository, " - URL returns error: ",
                                               toString(httr::http_status(response)))
          )
        }
      }
    }
  }
  
  return(TRUE)
}
