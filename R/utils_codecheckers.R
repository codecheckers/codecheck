#' Fetch and cache codecheckers.csv data from GitHub
#'
#' This function downloads the codecheckers registry from the codecheckers/codecheckers
#' repository and caches it for performance.
#'
#' @return A data frame with columns: name, handle, ORCID, contact, fields, languages
#' @importFrom utils read.csv
#' @export
get_codecheckers_data <- function() {
  url <- "https://raw.githubusercontent.com/codecheckers/codecheckers/master/codecheckers.csv"

  tryCatch({
    codecheckers <- read.csv(url, stringsAsFactors = FALSE, strip.white = TRUE)
    return(codecheckers)
  }, error = function(e) {
    warning("Failed to fetch codecheckers.csv: ", e$message)
    return(data.frame(
      name = character(0),
      handle = character(0),
      ORCID = character(0),
      contact = character(0),
      fields = character(0),
      languages = character(0)
    ))
  })
}

# Memoize the function for caching
get_codecheckers_data <- R.cache::addMemoization(get_codecheckers_data)

#' Get codechecker profile information by ORCID
#'
#' Retrieves profile information for a codechecker from the codecheckers registry.
#'
#' @param orcid The ORCID identifier (without URL prefix)
#' @return A list with profile information (name, handle, orcid, fields, languages)
#'         or NULL if not found
#' @export
get_codechecker_profile <- function(orcid) {
  if (is.null(orcid) || is.na(orcid) || orcid == "" || orcid == "0000-0000-0000-0000") {
    return(NULL)
  }

  codecheckers <- get_codecheckers_data()

  if (nrow(codecheckers) == 0) {
    return(NULL)
  }

  # Find the codechecker by ORCID
  match_idx <- which(codecheckers$ORCID == orcid)

  if (length(match_idx) == 0) {
    return(NULL)
  }

  codechecker <- codecheckers[match_idx[1], ]

  # Extract GitHub handle (remove @ prefix if present)
  github_handle <- gsub("^@", "", codechecker$handle)

  profile <- list(
    name = codechecker$name,
    github_handle = if (github_handle != "" && !is.na(github_handle)) github_handle else NULL,
    orcid = codechecker$ORCID,
    fields = codechecker$fields,
    languages = codechecker$languages
  )

  return(profile)
}

#' Generate HTML for codechecker profile links
#'
#' Creates a horizontal list of profile links (ORCID, GitHub) for a codechecker page.
#' Uses a template file to generate the HTML.
#'
#' @param orcid The ORCID identifier
#' @return HTML string with profile links, or empty string if no profile found
#' @importFrom whisker whisker.render
#' @export
generate_codechecker_profile_links <- function(orcid) {
  profile <- get_codechecker_profile(orcid)

  if (is.null(profile)) {
    return("")
  }

  # Prepare data for template
  has_orcid <- !is.null(profile$orcid) && profile$orcid != ""
  has_github <- !is.null(profile$github_handle) && profile$github_handle != ""

  if (!has_orcid && !has_github) {
    return("")
  }

  template_path <- system.file("extdata", "templates/general/codechecker_profile_links.html", package = "codecheck")
  template <- readLines(template_path, warn = FALSE)

  data <- list(
    has_orcid = has_orcid,
    orcid = profile$orcid,
    has_github = has_github,
    github_handle = profile$github_handle,
    has_both = has_orcid && has_github
  )

  html <- whisker.render(paste(template, collapse = "\n"), data)

  return(html)
}
