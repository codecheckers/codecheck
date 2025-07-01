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
  # Initialize the abstract source and text
  abstract_source <- NULL
  abstract_text <- NULL

  # Try to get the abstract from Crossref first
  abstract_text <- get_abstract_text_crossref(register_repo)

  # If Crossref fails, try OpenAlex
  if (is.null(abstract_text)) {
    abstract_text <- get_abstract_text_openalex(register_repo)
    if (!is.null(abstract_text)) {
      abstract_source <- "OpenAlex"
    }
  } 
  # Crossref did not fail, adding cross ref as the source
  else {
    abstract_source <- "CrossRef"
  }

  # Return both the source and the abstract text as a list
  return(list(
    source = abstract_source,
    text = abstract_text
  ))
}

#' Retrieves the abstract of a research paper using the OpenAlex API.
#'
#' @param register_repo URL or path to the repository containing the paper's configuration.
#' @importFrom httr GET status_code content
#'
#' @return The abstract text as a string if available; otherwise, NULL.
get_abstract_text_openalex <- function(register_repo){

  abstract <- NULL

  config_yml <- get_codecheck_yml(register_repo)
  doi <- config_yml$paper$reference

  # First, attempt to retrieve the abstract using the DOI directly
  doi_api_url <- paste0(CONFIG$CERT_LINKS[["openalex_api"]], doi)
  # Correcting the api_url if it is malformed
  doi_api_url <- gsub("\\n", "", doi_api_url)
  response <- httr::GET(doi_api_url)

  if (httr::status_code(response) != 200){
    # Checking for redirects and retrieving the final doi from there
    redirect_doi <- response$url 
    redirect_doi_api_url <- paste0(CONFIG$CERT_LINKS[["openalex_api"]], redirect_doi)
    response <- httr::GET(redirect_doi_api_url)
  }

  if (httr::status_code(response) == 200){
    data <- httr::content(response, "parsed")
    if ("abstract_inverted_index" %in% names(data)){
      # Extract the inverted index from the response
      inverted_index <- data$abstract_inverted_index

      if (is.null(inverted_index)){
        return(NULL)
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
  return(abstract)
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
  config_yml <- get_codecheck_yml(register_repo)

  # Retrieving the paper DOI
  paper_link <- config_yml$paper$referenc
  doi <- sub(CONFIG$CERTS_URL_PREFIX, "", paper_link)

  # Construct the URL to access the CrossRef API
  # Make the HTTP GET request
  api_url <- paste0(CONFIG$CERT_LINKS[["crossref_api"]], doi)
  # Correcting the api_url if it is malformed
  api_url <- gsub("\\n", "", api_url)

  response <- httr::GET(api_url)
  
  # Check if the request was successful
  if (httr::status_code(response) == 200) {
    data <- httr::content(response, "parsed")
    # Retrieve the abstract from the response data, if available
    if (!is.null(data$message$abstract)) {
      return(data$message$abstract)
    } 

    # No abstract was found, returning NULL
    warning(paste("No abstract available for DOI", doi))
    return(NULL)
  } 

  # Could not retrieve data for DOI
  else {
    warning(paste("Failed to retrieve abstract text for DOI", doi))
    return(NULL)
  }
}

#' Inserts the abstract text and source link into the Markdown content if an abstract is found for the given repository. 
#' If no abstract is found, an empty string is inserted in place of the abstract content.
#'
#' @param repo_link A character string containing the repository link from which to retrieve the abstract.
#' @param md_content A character string containing the Markdown content with placeholders for abstract details.
#' @return The markdown content with filled abstract placeholder
add_abstract <- function(repo_link, md_content){
  abstract <- get_abstract(repo_link)
  
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
create_cert_md <- function(cert_id, repo_link, download_cert_status){
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

  md_content <- add_paper_details_md(md_content, repo_link)
  md_content <- add_codecheck_details_md(md_content, repo_link)

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
#' @param download_cert_status An integer (0 or 1) indicating whether the certificate PDF was downloaded (1) or not (0).
#' @return The markdown content, with paper details placeholders filled.
add_paper_details_md <- function(md_content, repo_link, download_cert_status){
  config_yml <- get_codecheck_yml(repo_link)

  # Replacing the title
  title <- paste(CONFIG$MD_TITLES[["certs"]], config_yml$certificate)
  md_content <- gsub("\\$title\\$", title, md_content)

  # Formatting the paper title as hyperlink
  paper_title_hyperlink <- paste0("[", config_yml$paper$title, "]", "(", config_yml$paper$reference, ")")
  md_content <- gsub("\\$paper_title\\$", paper_title_hyperlink, md_content)
  # md_content <- gsub("\\$paper_link\\$", config_yml$paper$reference, md_content)

  # Formatting the authors list
  paper_authors <- paste(lapply(config_yml$paper$authors, function(author) {
    if (!is.null(author$ORCID) && author$ORCID != "") {
      # If ORCID exists, create a hyperlink
      paste0("[", author$name, "](", 
      CONFIG$HYPERLINKS["orcid"], author$ORCID, ")")
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
  md_content <- add_abstract(repo_link, md_content)

  return(md_content)
}

#' Populates an existing markdown content template with details about the CODECHECK details.
#'
#' @param md_content A character string containing the Markdown template content with placeholders.
#' @param repo_link A character string containing the repository link associated with the certificate.
#' @return The markdown content, with CODECHECK details placeholders filled.
add_codecheck_details_md <- function(md_content, repo_link){
  config_yml <- get_codecheck_yml(repo_link)

  # Adding the codechecker name
  codechecker_names <- c()

  for (checker in config_yml$codechecker){
    # Creating a hyperlink if the ORCID ID available
    if ("ORCID" %in% names(checker)){
      codechecker <- paste0("[", checker$name, "](", CONFIG$HYPERLINKS["orcid"], checker$ORCID, ")")
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

  return(md_content)
}