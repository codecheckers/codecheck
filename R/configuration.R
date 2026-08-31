#' Retrieve a codecheck.yml file from a remote repository
#' 
#' @author Daniel Nuest
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

  result <- normalize_person_lists(result)

  return(result)
}

#' Normalize person fields of a codecheck.yml to lists of persons
#'
#' The spec requires `codechecker` and `paper$authors` to be lists of persons,
#' but a single person is often written as a plain mapping, which yaml parses
#' into a named character vector instead of a list of lists. Wrap such cases so
#' consumers can always iterate over persons and use `$name`/`$ORCID`.
#'
#' @param config_yml the parsed codecheck.yml, may be NULL
#' @return the codecheck.yml with normalized person lists
normalize_person_lists <- function(config_yml) {
  if (is.null(config_yml)) {
    return(config_yml)
  }

  as_person_list <- function(persons) {
    # a single person mapping has names ("name", "ORCID", ...), a list of
    # persons does not
    if (!is.null(persons) && !is.null(names(persons))) {
      list(as.list(persons))
    } else {
      persons
    }
  }

  config_yml$codechecker <- as_person_list(config_yml$codechecker)
  if (!is.null(config_yml$paper)) {
    config_yml$paper$authors <- as_person_list(config_yml$paper$authors)
  }

  return(config_yml)
}

#' Retrieve a codecheck.yml file from a GitHub repository
#' 
#' @author Daniel Nuest
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
#' @author Daniel Nuest
#' @param x the OSF id (5 characters)
#' @importFrom osfr osf_retrieve_node osf_ls_files osf_download
get_codecheck_yml_osf <- function(x) {
  # osfr does its own HTTP and parses the response as JSON, so an OSF outage
  # arrives as "lexical error: invalid char in json text" from an HTML error
  # page rather than as a status code. Retry the way codecheck_GET_retry() does
  # for the calls we make ourselves.
  retry_osf <- function(expr, max_attempts = 4, max_wait = 30) {
    wait <- 1
    for (attempt in seq_len(max_attempts)) {
      result <- tryCatch(expr(), error = function(e) e)
      if (!inherits(result, "error")) return(result)
      if (attempt == max_attempts) {
        stop("OSF request failed after ", max_attempts, " attempts: ",
             conditionMessage(result), call. = FALSE)
      }
      Sys.sleep(min(wait, max_wait))
      wait <- wait * 2
    }
  }

  repo <- retry_osf(function() osfr::osf_retrieve_node(x))
  repo_files <- retry_osf(function() osfr::osf_ls_files(repo, pattern = "codecheck.yml"))
  
  if (nrow(repo_files) == 1) {
    temp_dir <- tempdir()
    # The download goes to OSF's file server (WaterButler), which rate limits
    # anonymous requests independently of the API - a whole register render
    # fetches one file per OSF entry, so this is the call most likely to be
    # rejected, and it needs the same retry as the two API calls above.
    retry_osf(function() osfr::osf_download(repo_files, path = temp_dir,
                                            conflicts = "overwrite"))
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
#' @author Daniel Nuest
#' @param x the project name on GitLab.com
#' @importFrom httr GET content
#' @importFrom yaml yaml.load
get_codecheck_yml_gitlab <- function(x) {
  link <- paste0("https://gitlab.com/", x, "/-/raw/main/codecheck.yml?inline=false")
  response <- codecheck_GET(link)
  
  if (response$status == 200) {
    content <- httr::content(response, as = "text", encoding = "UTF-8")
    config_file <- yaml::yaml.load(content)
    return(config_file)
  } else {
    warning("codecheck.yml not found in repository https://gitlab.com/", x)
    return(NULL)
  }
}

#' Split a GitHub repo spec into org, repo and an optional sub-path
#'
#' Repository specs from `register.csv` are `org/repo` or `org/repo|path`
#' (the latter used when the `codecheck.yml` lives in a sub-directory). Repo
#' metadata (archived status, README, license) applies to the whole repo, so
#' callers that only need `org`/`repo` can drop the `path` piece.
#'
#' @param x the `org/repo` or `org/repo|path` spec
#' @return a named list with `org` and `repo`
split_github_repo_spec <- function(x) {
  org_repo <- regmatches(x, regexpr("/", x), invert = TRUE)[[1]]

  if (length(org_repo) != 2) {
    stop("Incomplete repo specification for type 'github', need 'org/repo(|path)' but have '", x, "'")
  }

  repo_path <- strsplit(org_repo[[2]], "|", fixed = TRUE)[[1]]
  list(org = org_repo[[1]], repo = repo_path[[1]])
}

#' Retrieve repository metadata from the GitHub API
#'
#' Thin wrapper around the repo endpoint so callers (and tests, via
#' `with_mocked_codecheck()`) only need to deal with the fields they use, e.g.
#' `archived` and `license`.
#'
#' @author Daniel Nuest
#' @importFrom gh gh
#' @param repo the `org/repo` or `org/repo|path` spec
#' @return the parsed API response, or `NULL` if the repository could not be retrieved
get_github_repo_metadata <- function(repo) {
  org_repo <- split_github_repo_spec(repo)

  tryCatch(
    gh::gh("GET /repos/:org/:repo", org = org_repo$org, repo = org_repo$repo),
    error = function(e) NULL
  )
}

#' Retrieve the rendered README of a GitHub repository, as raw text
#'
#' @author Daniel Nuest
#' @importFrom gh gh
#' @param repo the `org/repo` or `org/repo|path` spec
#' @return the README text, or `NULL` if none was found
get_github_readme_raw <- function(repo) {
  org_repo <- split_github_repo_spec(repo)

  tryCatch(
    gh::gh("GET /repos/:org/:repo/readme",
           org = org_repo$org, repo = org_repo$repo,
           .accept = "application/vnd.github.VERSION.raw"),
    error = function(e) NULL
  )
}

#' Retrieve repository metadata from the GitLab.com API
#'
#' @author Daniel Nuest
#' @importFrom httr GET content status_code
#' @importFrom jsonlite fromJSON
#' @param repo the project path, e.g. `cdchck/Piccolo-2020`
#' @return the parsed API response, or `NULL` if the project could not be retrieved
get_gitlab_project_metadata <- function(repo) {
  # license=true is required for the API to include the `license` field at all
  link <- paste0("https://gitlab.com/api/v4/projects/", utils::URLencode(repo, reserved = TRUE),
                 "?license=true")
  response <- tryCatch(codecheck_GET(link), error = function(e) NULL)

  if (is.null(response) || httr::status_code(response) != 200) {
    return(NULL)
  }

  jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
}

#' Retrieve the README of a GitLab.com project, as raw text
#'
#' Tries the `main` branch first, then falls back to `master`.
#'
#' @author Daniel Nuest
#' @importFrom httr content status_code
#' @param repo the project path, e.g. `cdchck/Piccolo-2020`
#' @return the README text, or `NULL` if none was found
get_gitlab_readme_raw <- function(repo) {
  for (branch in c("main", "master")) {
    link <- paste0("https://gitlab.com/", repo, "/-/raw/", branch, "/README.md?inline=false")
    response <- tryCatch(codecheck_GET(link), error = function(e) NULL)

    if (!is.null(response) && httr::status_code(response) == 200) {
      return(httr::content(response, as = "text", encoding = "UTF-8"))
    }
  }

  NULL
}

#' Retrieve a codecheck.yml file from a Zenodo record
#' 
#' @author Daniel Nuest
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
        response <- codecheck_GET(f$download)
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
#' @author Daniel Nuest
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
#' @author Daniel Nuest
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
#' @author Daniel Nuest
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
#' @author Daniel Nuest
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
#' @author Daniel Nuest
#' @importFrom rorcid check_dois
#' @importFrom httr http_error http_status GET
#'
#' @export
validate_codecheck_yml <- function(configuration) {
  codecheck_yml <- NULL
  is_file <- is.character(configuration) && file.exists(configuration)
  if (is_file) {
    # these two checks need the raw bytes, and must run before read_yaml():
    # an invalid byte inside a quoted scalar makes the YAML parser itself
    # fail with a cryptic scanner error rather than the message below
    lines <- readLines(configuration, warn = FALSE, encoding = "bytes")

    # MUST be UTF-8 encoded
    assertthat::assert_that(all(validUTF8(lines)),
                            msg = paste0(configuration, " is not valid UTF-8 encoded"))

    # MUST start with the YAML document marker '---'
    non_empty <- trimws(lines)
    non_empty <- non_empty[nzchar(non_empty)]
    assertthat::assert_that(length(non_empty) > 0 && identical(non_empty[1], "---"),
                            msg = paste0(configuration,
                                         " must start with the YAML document marker '---'"))

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
  
  # codechecker MUST have at least one entry
  assertthat::assert_that(is.list(codecheck_yml$codechecker) && length(codecheck_yml$codechecker) > 0,
                          msg = "codecheck.yml must have at least one 'codechecker' entry")

  # codechecker MUST have a name
  sapply(X = codecheck_yml$codechecker, FUN = function(codechecker_item) {
    assertthat::assert_that(assertthat::has_name(codechecker_item, "name"),
                            msg = "All codecheckers must have a 'name'.")
  })
  
  # the report MUST be a valid DOI
  assertthat::assert_that(codecheck_yml$report %in% rorcid::check_dois(codecheck_yml$report)$good,
                          msg = paste0(codecheck_yml$report, " is not a valid DOI"))

  # if the report is on Zenodo, it MUST be the version-specific DOI, not the concept DOI, see #36
  if (grepl("zenodo", codecheck_yml$report, ignore.case = TRUE)) {
    assertthat::assert_that(!is_zenodo_concept_doi(codecheck_yml$report),
                            msg = paste0(codecheck_yml$report,
                                         " is a Zenodo concept DOI, which always resolves to the ",
                                         "latest version (see https://zenodo.org/help/versioning). ",
                                         "Use the version-specific DOI for this report instead."))

    # ... and it MUST be the latest version of that record: metadata should
    # always point at the current version, and a newer version having since
    # been published means the checked metadata may no longer be accurate,
    # see #36. A new check against the current version is preferable for
    # transparency to accepting an outdated report DOI.
    assertthat::assert_that(is_zenodo_latest_version(codecheck_yml$report),
                            msg = paste0(codecheck_yml$report,
                                         " is not the latest version of its Zenodo record. ",
                                         "A newer version has since been published; either update ",
                                         "the report DOI to the latest version or check that version ",
                                         "instead, for transparency."))
  }

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
          response <- tryCatch(codecheck_GET(r), error = function(e) NULL)
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
        response <- tryCatch(codecheck_GET(codecheck_yml$repository), error = function(e) NULL)
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

#' Load venues configuration from CSV file
#'
#' Reads a venues.csv file and constructs the CONFIG$DICT_VENUE_NAMES dictionary
#' and stores full venue information including labels.
#'
#' @param venues_file Path to the venues.csv file. If NULL, defaults to
#'   "venues.csv" in the current working directory.
#' @return A data frame with the required columns name, longname, label, plus
#'   whatever optional metadata columns the file carries (e.g. logo_url,
#'   website_url, policy_url, publisher) - passed through unchanged for
#'   consumers like [compute_annual_stats()].
#' @author Daniel Nuest
#' @importFrom utils read.csv
#' @export
load_venues_config <- function(venues_file = NULL) {
  if (is.null(venues_file)) {
    venues_file <- "venues.csv"
  }

  if (!file.exists(venues_file)) {
    stop("Venues configuration file not found: ", venues_file,
         "\nPlease provide a valid path to venues.csv")
  }

  # Read the venues CSV
  venues_data <- read.csv(venues_file, stringsAsFactors = FALSE)

  # Validate required columns
  required_cols <- c("name", "longname", "label")
  missing_cols <- setdiff(required_cols, names(venues_data))
  if (length(missing_cols) > 0) {
    stop("Venues CSV missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  # Construct the venue names dictionary
  venue_dict <- as.list(setNames(venues_data$longname, venues_data$name))

  # Store in CONFIG
  CONFIG$DICT_VENUE_NAMES <- venue_dict

  # Also store the full venue data including labels for later use
  CONFIG$VENUE_DATA <- venues_data

  cli::cli_alert_success("Loaded {nrow(venues_data)} venues from {.path {venues_file}}")

  return(venues_data)
}
