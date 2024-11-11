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
  
  # Initially checking if a cert is available
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

#' Populates an existing markdown content template with details about the codecheck details.
#'
#' @param md_content A character string containing the Markdown template content with placeholders.
#' @param repo_link A character string containing the repository link associated with the certificate.
#' @return The markdown content, with codecheck details placeholders filled.
add_codecheck_details_md <- function(md_content, repo_link){
  config_yml <- get_codecheck_yml(repo_link)

  # Adding the Codechecker name
  codechecker_names <- paste(lapply(config_yml$codechecker, function(checker) {
    paste0("[", checker$name, "](", 
    CONFIG$HYPERLINKS["orcid"], checker$ORCID, ")")
    }), collapse = ", ")

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
  
  # Adding codecheck date, summary and cert no.
  md_content <- gsub("\\$codecheck_time\\$", config_yml$check_time, md_content)
  md_content <- gsub("\\$codecheck_summary\\$", config_yml$summary, md_content)
  md_content <- gsub("\\$codecheck_cert\\$", config_yml$certificate, md_content)

  # Adjusting the repo and report links
  md_content <- add_repository_hyperlink(md_content, repo_link)
  md_content <- gsub("\\$codecheck_report\\$", config_yml$report, md_content)

  return(md_content)
}