#' Fetch and cache codecheckers.csv data from GitHub
#'
#' This function downloads the codecheckers registry from the codecheckers/codecheckers
#' repository and caches it for performance.
#'
#' @param ... Additional arguments passed to the memoization mechanism
#' @param envir Environment for memoization caching (default: parent.frame())
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

#' Get codechecker profile information by GitHub handle
#'
#' Retrieves profile information for a codechecker from the codecheckers registry.
#'
#' @param handle The GitHub handle (without @ prefix)
#' @return A list with profile information (name, handle, orcid, fields, languages)
#'         or NULL if not found
#' @export
get_codechecker_profile_by_handle <- function(handle) {
  if (is.null(handle) || is.na(handle) || handle == "") {
    return(NULL)
  }

  codecheckers <- get_codecheckers_data()

  if (nrow(codecheckers) == 0) {
    return(NULL)
  }

  # Normalize handle (remove @ prefix if present)
  handle <- gsub("^@", "", handle)

  # Find the codechecker by handle (try with and without @ prefix)
  match_idx <- which(codecheckers$handle == handle | codecheckers$handle == paste0("@", handle))

  if (length(match_idx) == 0) {
    return(NULL)
  }

  codechecker <- codecheckers[match_idx[1], ]

  # Extract GitHub handle (remove @ prefix if present)
  github_handle <- gsub("^@", "", codechecker$handle)

  profile <- list(
    name = codechecker$name,
    github_handle = if (github_handle != "" && !is.na(github_handle)) github_handle else NULL,
    orcid = if (!is.na(codechecker$ORCID) && codechecker$ORCID != "") codechecker$ORCID else NULL,
    fields = codechecker$fields,
    languages = codechecker$languages
  )

  return(profile)
}

#' Get GitHub handle for a codechecker by name
#'
#' Looks up the GitHub handle for a codechecker by their name in the codecheckers registry.
#'
#' @param name The full name of the codechecker
#' @return The GitHub handle (without @ prefix) or NULL if not found
#' @export
get_github_handle_by_name <- function(name) {
  if (is.null(name) || is.na(name) || name == "") {
    return(NULL)
  }

  codecheckers <- get_codecheckers_data()

  if (nrow(codecheckers) == 0) {
    return(NULL)
  }

  # Find the codechecker by name
  match_idx <- which(codecheckers$name == name)

  if (length(match_idx) == 0) {
    return(NULL)
  }

  codechecker <- codecheckers[match_idx[1], ]

  # Extract GitHub handle (remove @ prefix if present)
  github_handle <- gsub("^@", "", codechecker$handle)

  if (github_handle == "" || is.na(github_handle)) {
    return(NULL)
  }

  return(github_handle)
}

#' Generate HTML redirect page for codechecker
#'
#' Creates a redirect page at the GitHub handle URL that redirects to the ORCID-based page.
#' This is used for codecheckers who have both ORCID and GitHub handle.
#'
#' @param github_handle The GitHub handle (without @ prefix)
#' @param orcid The ORCID identifier
#' @param name The codechecker's name
#' @return Invisibly returns TRUE if successful, FALSE otherwise
#' @importFrom whisker whisker.render
#' @export
generate_codechecker_redirect <- function(github_handle, orcid, name) {
  if (is.null(github_handle) || is.na(github_handle) || github_handle == "") {
    return(FALSE)
  }

  if (is.null(orcid) || is.na(orcid) || orcid == "") {
    return(FALSE)
  }

  # Create output directory for handle-based page
  handle_dir <- file.path("docs", "codecheckers", github_handle)
  dir.create(handle_dir, recursive = TRUE, showWarnings = FALSE)

  # Generate redirect URL to ORCID-based page
  redirect_url <- paste0(CONFIG$HYPERLINKS[["codecheckers"]], orcid, "/")

  # Load redirect template
  template_path <- system.file("extdata", "templates/general/codechecker_redirect_template.html", package = "codecheck")
  template <- readLines(template_path, warn = FALSE)

  # Render template
  data <- list(
    redirect_url = redirect_url,
    codechecker_name = name
  )

  output <- whisker::whisker.render(paste(template, collapse = "\n"), data)

  # Write redirect page
  redirect_file <- file.path(handle_dir, "index.html")
  writeLines(output, redirect_file)

  message("Created redirect page for ", name, " (", github_handle, " -> ", orcid, ")")
  invisible(TRUE)
}

#' Generate redirect pages for all codecheckers with ORCID
#'
#' Iterates through all codecheckers in the register and creates redirect pages
#' for those who have both ORCID and GitHub handle. The redirect pages are created
#' at the GitHub handle URL and redirect to the ORCID-based URL.
#'
#' @param register_table The preprocessed register table
#' @return Invisibly returns the count of redirect pages created
#' @export
generate_codechecker_redirects <- function(register_table) {
  # Get unique ORCID-based codecheckers from the register
  if (!"Codechecker" %in% names(register_table)) {
    warning("Codechecker column not found in register table")
    return(invisible(0))
  }

  # Unnest and get unique codecheckers
  codecheckers_table <- register_table %>% tidyr::unnest(Codechecker)
  unique_codecheckers <- unique(codecheckers_table$Codechecker)

  # Filter to only ORCID-based codecheckers (not GitHub username-based)
  # ORCID format: NNNN-NNNN-NNNN-NNNX
  orcid_codecheckers <- unique_codecheckers[grepl("^\\d{4}-\\d{4}-\\d{4}-\\d{3}[0-9X]$", unique_codecheckers)]
  orcid_codecheckers <- orcid_codecheckers[!is.na(orcid_codecheckers)]

  redirect_count <- 0

  for (orcid in orcid_codecheckers) {
    # Get profile to check if they have a GitHub handle
    profile <- get_codechecker_profile(orcid)

    if (!is.null(profile) && !is.null(profile$github_handle)) {
      # Generate redirect page
      success <- generate_codechecker_redirect(
        github_handle = profile$github_handle,
        orcid = orcid,
        name = profile$name
      )

      if (success) {
        redirect_count <- redirect_count + 1
      }
    }
  }

  if (redirect_count > 0) {
    message("Generated ", redirect_count, " codechecker redirect pages")
  }

  invisible(redirect_count)
}

#' Generate HTML for codechecker profile links
#'
#' Creates a horizontal list of profile links (ORCID, GitHub) for a codechecker page.
#' Uses a template file to generate the HTML. Supports both ORCID and handle-based identifiers.
#'
#' @param identifier The codechecker identifier (ORCID or "handle:username")
#' @return HTML string with profile links, or empty string if no profile found
#' @importFrom whisker whisker.render
#' @export
generate_codechecker_profile_links <- function(identifier) {
  # Determine if this is an ORCID (format: NNNN-NNNN-NNNN-NNNX) or GitHub username
  is_orcid <- grepl("^\\d{4}-\\d{4}-\\d{4}-\\d{3}[0-9X]$", identifier)

  if (is_orcid) {
    profile <- get_codechecker_profile(identifier)
  } else {
    # GitHub username
    profile <- get_codechecker_profile_by_handle(identifier)
  }

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
