#' Replaces a placeholder in Markdown content with a hyperlink to the repository, based on the repository type (e.g., GitHub, OSF, GitLab). 
#'
#' @param md_content A character string containing Markdown content with a placeholder for the repository link.
#' @param repo_link A character string containing the repository URL to be converted into a hyperlink.
#' @return The modified markdown content.
add_repository_hyperlink <- function(md_content, repo_link) {
  
  spec <- parse_repository_spec(repo_link)
  if (!any(is.na(spec))) {
    urrl <- "#"

    switch(spec["type"],
      "github" = {
        repo_link <- paste0(CONFIG$HYPERLINKS[["github"]], spec[["repo"]])
        paste0("[", spec[["repo"]], "](", repo_link, ")")
      },
      "osf" = {
        repo_link <- paste0(CONFIG$HYPERLINKS[["osf"]], spec[["repo"]])
        paste0("[", spec[["repo"]], "](", repo_link, ")")
      },
      "gitlab" = {
        repo_link <- paste0(CONFIG$HYPERLINKS[["gitlab"]], spec[["repo"]])
        paste0("[", spec[["repo"]], "](", repo_link, ")")
      },
      "zenodo" = {
        repo_link <- paste0(CONFIG$HYPERLINKS[["zenodo"]], spec[["repo"]])
        paste0("[", spec[["repo"]], "](", repo_link, ")")
      },

      # Type is none of the above
      {
        repo_link
      }
    )
  } else {
    repository
  }

  md_content <- gsub("\\$codecheck_repo\\$", repo_link, md_content)

  return(md_content)
}

#' Retrieves the abstract of a research paper from CrossRef or OpenAlex.
#'
#' This function attempts to retrieve a paper's abstract using the OpenAlex. API first.
#' If that fails it then attempts to retrieve from CrossRef
#'
#' @param register_repo URL or path to the repository containing the paper's configuration.
#'
#' @return A list with two elements: `source` (indicating "CrossRef" or "OpenAlex" if found)
#'   and `text` (the abstract text as a string, or NULL if unavailable).
get_abstract <- function(register_repo) {
  # Every certificate is rendered into markdown, HTML and JSON, each of which
  # asks for the abstract again, so this is cached on disk. Only conclusive
  # results are cached, otherwise a rate limited request would remove the
  # abstract from the register until the cache is cleared.
  cached_lookup(
    key = list("abstract", register_repo),
    dirs = c("codecheck", "abstract"),
    lookup = function() get_abstract_result(register_repo)
  )
}

#' Cached version of get_abstract, with the lookup status
#'
#' Same lookup as \code{\link{get_abstract}}, but returns the full
#' `{status, value}` result so a caller can distinguish a confirmed absence
#' from an inconclusive failure, see \code{\link{resolve_external_field}}.
#'
#' @param register_repo URL or path to the repository containing the paper's configuration.
#' @return A list with `status` ("found", "absent" or "failed") and `value`
#' @noRd
get_abstract_cached_result <- function(register_repo) {
  cached_lookup_result(
    key = list("abstract", register_repo),
    dirs = c("codecheck", "abstract"),
    lookup = function() get_abstract_result(register_repo)
  )
}

#' Retrieves the abstract and reports whether the answer is conclusive
#'
#' Same lookup as \code{\link{get_abstract}} without the caching, and with the
#' information needed to decide whether the result may be cached: a paper for
#' which neither API has an abstract is a conclusive answer, a paper whose
#' requests failed is not, see \code{\link{cached_lookup}}.
#'
#' @param register_repo URL or path to the repository containing the paper's configuration.
#' @return A list with `status` ("found", "absent" or "failed") and `value`, the
#'   latter being the `source`/`text` list described in \code{\link{get_abstract}}
get_abstract_result <- function(register_repo) {
  abstract_source <- NULL
  abstract_text <- NULL

  # Try to get the abstract from Crossref first
  crossref <- get_abstract_text_crossref_result(register_repo)
  abstract_text <- crossref$value

  # If Crossref has no abstract, try OpenAlex
  openalex <- NULL
  if (is.null(abstract_text)) {
    openalex <- get_abstract_text_openalex_result(register_repo)
    abstract_text <- openalex$value
    if (!is.null(abstract_text)) {
      abstract_source <- "OpenAlex"
    }
  }
  # Crossref did not fail, adding cross ref as the source
  else {
    abstract_source <- "CrossRef"
  }

  value <- list(source = abstract_source, text = abstract_text)

  if (!is.null(abstract_text)) {
    return(list(status = "found", value = value))
  }

  # without an abstract the result is only conclusive if both APIs answered
  answered <- identical(crossref$status, "absent") &&
    (!is.null(openalex) && identical(openalex$status, "absent"))

  return(list(status = if (answered) "absent" else "failed", value = value))
}

#' Retrieves the abstract of a research paper using the OpenAlex API.
#'
#' @param register_repo URL or path to the repository containing the paper's configuration.
#' @importFrom httr GET status_code content
#'
#' @return The abstract text as a string if available; otherwise, NULL.
get_abstract_text_openalex <- function(register_repo){
  get_abstract_text_openalex_result(register_repo)$value
}

#' Retrieves the abstract from OpenAlex and reports whether the API answered
#'
#' @param register_repo URL or path to the repository containing the paper's configuration.
#' @importFrom httr GET status_code content
#'
#' @return A list with `status` ("found", "absent" or "failed") and `value`, the
#'   abstract text as a string or NULL
get_abstract_text_openalex_result <- function(register_repo){

  abstract <- NULL

  config_yml <- get_codecheck_yml(register_repo)
  doi <- config_yml$paper$reference

  # First, attempt to retrieve the abstract using the DOI directly
  doi_api_url <- paste0(CONFIG$CERT_LINKS[["openalex_api"]], doi)
  # Correcting the api_url if it is malformed
  doi_api_url <- gsub("\\n", "", doi_api_url)
  response <- codecheck_GET_openalex(doi_api_url)

  if (!is.null(response) && httr::status_code(response) != 200){
    # Checking for redirects and retrieving the final doi from there
    redirect_doi <- response$url
    redirect_doi_api_url <- paste0(CONFIG$CERT_LINKS[["openalex_api"]], redirect_doi)
    response <- codecheck_GET_openalex(redirect_doi_api_url)
  }

  if (is.null(response)) {
    return(list(status = "failed", value = NULL))
  }

  # a DOI OpenAlex does not know is an answer, any other error is not
  if (httr::status_code(response) != 200 && httr::status_code(response) != 404) {
    warning("Failed to retrieve abstract from OpenAlex for DOI ", doi)
    return(list(status = "failed", value = NULL))
  }

  if (httr::status_code(response) == 200){
    data <- httr::content(response, "parsed")
    if ("abstract_inverted_index" %in% names(data)){
      # Extract the inverted index from the response
      inverted_index <- data$abstract_inverted_index

      if (is.null(inverted_index)){
        return(list(status = "absent", value = NULL))
      }

      # Initialize an empty character vector to store the words by position
      abstract_vector <- character()

      # Iterate over the inverted index to place each word at its correct position
      for (word in names(inverted_index)) {
        positions <- inverted_index[[word]]
        
        # For each position, assign the word in that position
        for (position in positions) {
          abstract_vector[position + 1] <- word  # +1 to account for R's 1-based indexing
        }
      }
      # Combine the words into a single string to form the abstract
      abstract <- paste(abstract_vector, collapse = " ")
    }
  }

  return(list(status = if (is.null(abstract)) "absent" else "found", value = abstract))
}

#' Look up the OpenAlex work ID for a paper reference URL
#'
#' Queries the OpenAlex API by DOI. If the DOI lookup fails, falls back to
#' a title search filtered by first author name (accepts only a single exact match).
#'
#' @param paper_reference The paper reference URL (typically a DOI URL)
#' @param paper_title Optional paper title for fallback search
#' @param first_author_name Optional first author name for fallback search
#' @return The OpenAlex work URL (e.g., "https://openalex.org/W1234567890") or NA_character_
get_openalex_id <- function(paper_reference, paper_title = NULL, first_author_name = NULL) {
  get_openalex_id_result(paper_reference, paper_title, first_author_name)$value
}

#' Look up the OpenAlex work ID and report whether the answer is conclusive
#'
#' Same lookup as \code{\link{get_openalex_id}}, but distinguishes an ID that
#' OpenAlex does not have from a request that did not succeed, so that only the
#' former is cached, see \code{\link{cached_lookup}}.
#'
#' @param paper_reference The paper reference URL (typically a DOI URL)
#' @param paper_title Optional paper title for fallback search
#' @param first_author_name Optional first author name for fallback search
#' @return A list with `status` ("found", "absent" or "failed") and `value`
get_openalex_id_result <- function(paper_reference, paper_title = NULL, first_author_name = NULL) {
  if (is.null(paper_reference) || is.na(paper_reference) || nchar(paper_reference) == 0) {
    return(list(status = "absent", value = NA_character_))
  }

  # set once an API answered that it has no match, as opposed to not answering
  answered <- FALSE

  # Try DOI-based lookup first
  api_url <- paste0(CONFIG$CERT_LINKS[["openalex_api"]], gsub("\\n", "", paper_reference))
  response <- codecheck_GET_openalex(api_url)

  if (!is.null(response) && httr::status_code(response) != 200) {
    # Follow redirects (some DOIs redirect)
    redirect_url <- response$url
    if (!is.null(redirect_url) && redirect_url != api_url) {
      api_url2 <- paste0(CONFIG$CERT_LINKS[["openalex_api"]], redirect_url)
      response <- codecheck_GET_openalex(api_url2)
    }
  }

  if (!is.null(response)) {
    response_status <- httr::status_code(response)
    if (response_status == 200) {
      data <- httr::content(response, "parsed")
      if (!is.null(data$id)) {
        return(list(status = "found", value = data$id))
      }
      answered <- TRUE
    } else if (response_status == 404) {
      # OpenAlex does not index this DOI, the title search may still find it
      answered <- TRUE
    }
  }

  # Fallback: search by title and first author
  if (!is.null(paper_title) && nchar(paper_title) > 0) {
    search_url <- paste0(
      "https://api.openalex.org/works?filter=title.search:",
      utils::URLencode(paper_title, reserved = TRUE)
    )
    if (!is.null(first_author_name) && nchar(first_author_name) > 0) {
      search_url <- paste0(
        search_url,
        ",authorships.author.display_name:",
        utils::URLencode(first_author_name, reserved = TRUE)
      )
    }
    search_response <- codecheck_GET_openalex(search_url)
    if (!is.null(search_response) && httr::status_code(search_response) == 200) {
      search_data <- httr::content(search_response, "parsed")
      if (!is.null(search_data$meta$count) && search_data$meta$count == 1) {
        return(list(status = "found", value = search_data$results[[1]]$id))
      }
      # the search ran, it just did not return exactly one match
      answered <- TRUE
    } else {
      # the search could have found what the DOI lookup missed, so without it
      # the result is inconclusive regardless of what the DOI lookup said
      answered <- FALSE
    }
  }

  return(list(status = if (answered) "absent" else "failed", value = NA_character_))
}

#' Cached version of get_openalex_id
#'
#' Caches on disk, but only when OpenAlex actually answered, see
#' \code{\link{cached_lookup}}. Cleared by \code{\link{register_clear_cache}}.
#'
#' @inheritParams get_openalex_id_result
#' @return The OpenAlex work URL or NA_character_
#' @noRd
get_openalex_id_cached <- function(paper_reference, paper_title = NULL, first_author_name = NULL) {
  cached_lookup(
    key = list("openalex_id", paper_reference, paper_title, first_author_name),
    dirs = c("codecheck", "openalex_id"),
    lookup = function() {
      get_openalex_id_result(paper_reference, paper_title, first_author_name)
    }
  )
}

#' Cached version of get_openalex_id, with the lookup status
#'
#' Same lookup as \code{\link{get_openalex_id_cached}}, but returns the full
#' `{status, value}` result so a caller can distinguish a confirmed absence
#' from an inconclusive failure, see \code{\link{resolve_external_field}}.
#'
#' @inheritParams get_openalex_id_result
#' @return A list with `status` ("found", "absent" or "failed") and `value`
#' @noRd
get_openalex_id_cached_result <- function(paper_reference, paper_title = NULL, first_author_name = NULL) {
  cached_lookup_result(
    key = list("openalex_id", paper_reference, paper_title, first_author_name),
    dirs = c("codecheck", "openalex_id"),
    lookup = function() {
      get_openalex_id_result(paper_reference, paper_title, first_author_name)
    }
  )
}

#' Extracts the paper DOI from the config_yml of the paper,
#' constructs a CrossRef API request, and returns the abstract text if available.
#'
#' @param register_repo URL or path to the repository containing the paper's configuration.
#' 
#' @importFrom httr GET status_code content
#'
#' @return The abstract text as a string if available; otherwise, NULL.
get_abstract_text_crossref <- function(register_repo) {
  get_abstract_text_crossref_result(register_repo)$value
}

#' Retrieves the abstract from CrossRef and reports whether the API answered
#'
#' @param register_repo URL or path to the repository containing the paper's configuration.
#'
#' @importFrom httr GET status_code content
#'
#' @return A list with `status` ("found", "absent" or "failed") and `value`, the
#'   abstract text as a string or NULL
get_abstract_text_crossref_result <- function(register_repo) {
  config_yml <- get_codecheck_yml(register_repo)

  # Retrieving the paper DOI
  paper_link <- config_yml$paper$reference
  doi <- sub(CONFIG$CERTS_URL_PREFIX, "", paper_link)

  # Construct the URL to access the CrossRef API
  # Make the HTTP GET request
  api_url <- paste0(CONFIG$CERT_LINKS[["crossref_api"]], doi)
  # Correcting the api_url if it is malformed
  api_url <- gsub("\\n", "", api_url)

  response <- codecheck_GET_retry(api_url)

  if (is.null(response)) {
    warning(paste("Failed to retrieve abstract text for DOI", doi))
    return(list(status = "failed", value = NULL))
  }

  # Check if the request was successful
  if (httr::status_code(response) == 200) {
    data <- httr::content(response, "parsed")
    # Retrieve the abstract from the response data, if available
    if (!is.null(data$message$abstract)) {
      return(list(status = "found", value = data$message$abstract))
    }

    # No abstract was found, returning NULL
    warning(paste("No abstract available for DOI", doi))
    return(list(status = "absent", value = NULL))
  }

  # A DOI CrossRef does not know is an answer, any other error is not
  if (httr::status_code(response) == 404) {
    warning(paste("No CrossRef record for DOI", doi))
    return(list(status = "absent", value = NULL))
  }

  # Could not retrieve data for DOI
  warning(paste("Failed to retrieve abstract text for DOI", doi))
  return(list(status = "failed", value = NULL))
}

#' Inserts the abstract text and source link into the Markdown content if an abstract is found for the given repository. 
#' If no abstract is found, an empty string is inserted in place of the abstract content.
#'
#' @param repo_link A character string containing the repository link from which to retrieve the abstract.
#' @param md_content A character string containing the Markdown content with placeholders for abstract details.
#' @param abstract_data Optional pre-resolved abstract (list with `source`/`text`, see
#'   \code{\link{resolve_external_field}}); when `NULL`, looked up here directly.
#' @return The markdown content with filled abstract placeholder
add_abstract <- function(repo_link, md_content, abstract_data = NULL){
  abstract <- if (is.null(abstract_data)) get_abstract(repo_link) else abstract_data

  # No abstract found so we add empty string
  if (is.null(abstract$text)) {  
    md_content <- gsub("\\$abstract_content\\$", "", md_content)
    return(md_content)
  }
  
  # Abstract found- we add the abstract details
  platform_link <- CONFIG$HYPERLINKS[[abstract$source]]
  abstract_source_hyperlink <- paste0("[", abstract$source, "](", platform_link,")")

  md_content <- gsub("\\$abstract_source\\$", abstract_source_hyperlink, md_content)
  md_content <- gsub("\\$abstract_content\\$", abstract$text, md_content)
  return(md_content)
}

#' Generates a Markdown file for a certificate based on a specified template, filling in details about the
#' paper, authors, codecheck information, and the certificate images if available. The resulting Markdown file is later rendered to HTML.
#'
#' @param cert_id A character string representing the unique identifier of the certificate.
#' @param repo_link A character string containing the repository link associated with the certificate.
#' @param download_cert_status An integer (0 or 1) indicating whether the certificate PDF was downloaded (1) or not (0).
#' @param cert_type A character string containing the venue type (journal, conference, community, institution).
#' @param cert_venue A character string containing the venue name.
#' @param openalex_id Optional pre-resolved OpenAlex ID (see \code{\link{resolve_external_field}});
#'   when `NULL`, looked up here directly.
#' @param abstract_data Optional pre-resolved abstract; when `NULL`, looked up here directly.
create_cert_md <- function(cert_id, repo_link, download_cert_status, cert_type, cert_venue,
                           openalex_id = NULL, abstract_data = NULL){
  cert_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  
  # Create the directory if it does not exist (e.g., because no PDFs are downloaded)
  if (!dir.exists(cert_dir)) {
    dir.create(cert_dir, recursive = TRUE) 
  }
  
  # Loading the correct template based on whether cert exists
  if (download_cert_status == 0) {
    template_type <- "md_template_no_cert"
  }

  else{
    template_type <- "md_template_base"
  }

  # Load the template
  md_content <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][[template_type]])
  
  md_file_path <- file.path(cert_dir, "temp.md")
  writeLines(md_content, md_file_path)

  # We add the report link in the subtext when we do not have cert
  if (download_cert_status == 0){
    config_yml <- get_codecheck_yml(repo_link)
    report_hyperlink <- paste0("[link](", config_yml$report, ")")
    md_content <- gsub("\\$codecheck_report_subtext\\$", report_hyperlink, md_content)
  }

  md_content <- add_paper_details_md(md_content, repo_link, openalex_id = openalex_id, abstract_data = abstract_data)
  md_content <- add_codecheck_details_md(md_content, repo_link, cert_type, cert_venue)

  # Inserting the cert 
  if (download_cert_status == 1){
    no_cert_pages <- length(list.files(path = cert_dir, pattern = "^cert_.*\\.png$", full.names = TRUE))
    # Creating a list of images to slide through based on number of cert pages
    list_images <- paste0('"cert_', 1:no_cert_pages, '.png"', collapse = ", ")
    # Replacing the list of images for the slider
    md_content <- gsub("\\$var_images\\$", 
                      paste0("var images = [", list_images, "];"), 
                      md_content)
  }

  # Saving the md file
  md_file_path <- file.path(cert_dir, "temp.md")
  writeLines(md_content, md_file_path)
}

#' Populates an existing markdown content template with details about the codechecked paper.
#'
#' @param md_content A character string containing the Markdown template content with placeholders.
#' @param repo_link A character string containing the repository link associated with the certificate.
#' @param openalex_id Optional pre-resolved OpenAlex ID; when `NULL`, looked up here directly.
#' @param abstract_data Optional pre-resolved abstract; when `NULL`, looked up here directly.
#' @return The markdown content, with paper details placeholders filled.
add_paper_details_md <- function(md_content, repo_link, openalex_id = NULL, abstract_data = NULL){
  config_yml <- get_codecheck_yml(repo_link)

  # Replacing the title
  title <- paste(CONFIG$MD_TITLES[["certs"]], config_yml$certificate)
  md_content <- gsub("\\$title\\$", title, md_content)

  # Formatting the paper title as hyperlink: to its own /works/<DOI>/ landing
  # page (codecheckers/register#150) when the reference is a DOI, since that
  # page shows this certificate alongside any others checking the same
  # paper; falls back to the external reference URL otherwise (no DOI means
  # no work page, per #150).
  work_key <- normalize_work_key(config_yml$paper$reference)
  paper_title_url <- if (!is.na(work_key)) paste0("../../works/", work_key, "/") else config_yml$paper$reference
  paper_title_hyperlink <- paste0("[", config_yml$paper$title, "]", "(", paper_title_url, ")")
  md_content <- gsub("\\$paper_title\\$", paper_title_hyperlink, md_content)
  # md_content <- gsub("\\$paper_link\\$", config_yml$paper$reference, md_content)

  # Formatting the authors list: each ORCID-bearing author's name links to
  # their own /persons/<ORCID>/ page (codecheckers/register#150's "we can
  # link authors ... if we have the ORCID" - #123 gives every ORCID-bearing
  # person a page now, not just codecheckers, so unlike #150's original text
  # this is no longer conditional on also being a codechecker), plus the
  # ORCID icon linking out to the ORCID record itself.
  paper_authors <- paste(lapply(config_yml$paper$authors, function(author) {
    if (!is.null(author$ORCID) && author$ORCID != "") {
      # Certificate pages are at docs/certs/YYYY-NNN/, two levels above persons/
      paste0("[", author$name, "](../../persons/", author$ORCID, "/) ",
      '<a href="', CONFIG$HYPERLINKS[["orcid"]], author$ORCID, '" title="ORCID iD">',
      '<i class="ai ai-orcid orcid-icon-large"></i></a>')
    }

    # If ORCID is missing, just return the name
    else {
      author$name
    }
  }), collapse = ", ")
  md_content <- gsub("\\$paper_authors\\$", paper_authors, md_content)

  # Adjusting the paper author name/ names
  num_authors <- length(config_yml$paper$authors)
  if (num_authors > 1){
    authors_heading <- "Authors"
  }
  
  else{
    authors_heading <- "Author"
  }
  md_content <- gsub("\\$author_names_heading\\$", authors_heading, md_content)

  # Adding abstract
  md_content <- add_abstract(repo_link, md_content, abstract_data = abstract_data)

  # Adding OpenAlex link (addresses register#185)
  if (is.null(openalex_id)) {
    openalex_id <- tryCatch(
      get_openalex_id_cached(
        config_yml$paper$reference,
        paper_title = config_yml$paper$title,
        first_author_name = if (length(config_yml$paper$authors) > 0) config_yml$paper$authors[[1]]$name else NULL
      ),
      error = function(e) NA_character_
    )
  }
  if (!is.na(openalex_id)) {
    # mt-3 matches the top spacing of "Cite this certificate" in the
    # CODECHECK details card - without it, this paragraph (a bare <p>, whose
    # default top margin Bootstrap's reboot zeroes out) sits flush against
    # the abstract box above it.
    openalex_html <- paste0('<p class="mt-3"><strong>OpenAlex</strong>: <a href="', openalex_id, '">', openalex_id, '</a></p>')
  } else {
    openalex_html <- ""
  }
  md_content <- gsub("\\$openalex_link\\$", openalex_html, md_content)

  return(md_content)
}

#' Populates an existing markdown content template with details about the CODECHECK details.
#'
#' @param md_content A character string containing the Markdown template content with placeholders.
#' @param repo_link A character string containing the repository link associated with the certificate.
#' @param cert_type A character string containing the venue type (journal, conference, community, institution).
#' @param cert_venue A character string containing the venue name.
#' @return The markdown content, with CODECHECK details placeholders filled.
add_codecheck_details_md <- function(md_content, repo_link, cert_type, cert_venue){
  config_yml <- get_codecheck_yml(repo_link)

  # Adding the codechecker name
  codechecker_names <- c()

  for (checker in config_yml$codechecker){
    # Creating a hyperlink to the codechecker's person landing page (#123
    # replaces /codecheckers/ with /persons/) if ORCID ID available
    if ("ORCID" %in% names(checker)){
      # Use relative path: certificate pages are at docs/certs/YYYY-NNN/
      # so we need to go up 2 levels to reach persons/
      # The icon links directly to the ORCID profile page.
      codechecker <- paste0("[", checker$name, "](../../persons/", checker$ORCID, "/) ",
      '<a href="', CONFIG$HYPERLINKS[["orcid"]], checker$ORCID, '" title="ORCID iD">',
      '<i class="ai ai-orcid orcid-icon-large"></i></a>')
    }

    else{
      codechecker <- checker$name
    }
    codechecker_names <- append(codechecker_names, codechecker)
  }
  # Concatenate all entries into a single string separated by commas
  codechecker_names <- paste(codechecker_names, collapse = ", ")

  # Adjusting the codechecker name heading 
  # Multiple codecheckers
  if (length(config_yml$codechecker) > 1){
    codechecker_names_heading <- "Codechecker names"
  }
  
  else{
    codechecker_names_heading <- "Codechecker name"
  }
  md_content <- gsub("\\$codechecker_names_heading\\$", codechecker_names_heading, md_content)
  md_content <- gsub("\\$codechecker_names\\$", codechecker_names, md_content)
  
  # Adding check date, summary and cert no.
  md_content <- gsub("\\$codecheck_time\\$", config_yml$check_time, md_content)

  # Adding summary if it exists else adding empty string
  if ("summary" %in% names(config_yml)){
    md_content <- gsub("\\$codecheck_summary\\$", config_yml$summary, md_content)
  }
  else{
    md_content <- gsub("\\$codecheck_summary\\$", "", md_content)
  }

  md_content <- gsub("\\$codecheck_cert\\$", config_yml$certificate, md_content)

  # Adjusting the repo and report links
  md_content <- add_repository_hyperlink(md_content, repo_link)
  md_content <- gsub("\\$codecheck_full_certificate\\$", config_yml$report, md_content)

  # Adding Type and Venue links
  # Create venue slug (lowercase and replace spaces with underscores)
  venue_slug <- gsub(" ", "_", tolower(cert_venue))

  # Get plural form of type from CONFIG
  type_plural <- CONFIG$VENUE_SUBCAT_PLURAL[[cert_type]]

  # Create relative links: certificate pages are at docs/certs/YYYY-NNN/
  # so we need to go up 2 levels to reach venues/
  type_link <- paste0("[", cert_type, "](../../venues/", type_plural, "/)")
  venue_link <- paste0("[", cert_venue, "](../../venues/", type_plural, "/", venue_slug, "/)")

  # Replace placeholders
  md_content <- gsub("\\$codecheck_type\\$", type_link, md_content)
  md_content <- gsub("\\$codecheck_venue\\$", venue_link, md_content)

  return(md_content)
}