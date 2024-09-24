
render_cert_htmls <- function(register_table, register, force_download = FALSE){

  # Read template
  html_template <- readLines(CONFIG$CERTS_DIR[["cert_page_template"]])

  # Loop over each cert in the register table
  # for (i in 1:1){
  for (i in 1:nrow(register)){
    # Retrieving report link and cert id
    report_link <- register_table[i, ]$Report
    cert_id <- register_table[i, ]$Certificate

    # Define paths for the certificate PDF and JPEG
    pdf_path <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id, "cert.pdf")
    pdf_exists <- file.exists(pdf_path)
    
    # Download the PDF if it doesn't exist or if force_download is TRUE
    if (!pdf_exists || force_download) {
      download_cert_status <- download_cert_pdf(report_link, cert_id)

      # Failed in downloading cert
      if (download_cert_status == 0){
        next
      }
      convert_cert_pdf_to_jpeg(cert_id)

      # Delaying reqwuests to adhere to request limits
      Sys.sleep(CONFIG$CERT_REQUEST_DELAY)
    }

    create_cert_md(cert_id, register[i, ]$Repo)
    render_cert_html(cert_id)
  }
}

convert_cert_pdf_to_jpeg <- function(cert_id){

  # Checking if the certs dir exist
  cert_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id) 

  # Get the number of pages in the PDF
  cert_pdf_path <- paste0(cert_dir, "cert.pdf")
  num_pages <- pdftools::pdf_info(cert_pdf_path)$pages

  # Create image filenames
  image_filenames <- sapply(1:num_pages, function(page) paste0(cert_dir, "cert_", page, ".png"))
  
  # Read and convert PDF to PNG images
  pdftools::pdf_convert(cert_pdf_path, format = "png", filenames = image_filenames, dpi = CONFIG$CERT_DPI)
}


# Creates a markdown file of the certificate which is then rendered
# to html
create_cert_md <- function(cert_id, repo_link){

  # Loading the template
  md_content <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["md_template"]])

  # Replacing the title
  title <- paste(CONFIG$MD_TITLES[["certs"]], cert_id)
  md_content <- gsub("\\$title\\$", title, md_content)

  # Adding other details from the codecheck.yml
  config_yml <- get_codecheck_yml(repo_link)

  # Formatting the paper title as hyperlink
  paper_title_hyperlink <- paste0("[", config_yml$paper$title, "]", "(", config_yml$paper$reference, ")")
  md_content <- gsub("\\$paper_title\\$", paper_title_hyperlink, md_content)

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

  # Adding the Codechecker name, Date of codecheck, and Codecheck repo
  codechecker_names <- paste(lapply(config_yml$codechecker, function(checker) {
    paste0("[", checker$name, "](", 
    CONFIG$HYPERLINKS["orcid"], checker$ORCID, ")")
    }), collapse = ", ")
  md_content <- gsub("\\$codechecker_name\\$", codechecker_names, md_content)
  
  md_content <- gsub("\\$codecheck_date\\$", config_yml$check_time, md_content)

  # Adjusting the repo link
  md_content <- add_repository_hyperlink(md_content, repo_link)

  # Identifying the number of cert pages 
  cert_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  no_cert_pages <- length(list.files(path = cert_dir, pattern = "^cert_.*\\.png$", full.names = TRUE))

  # Creating a list of images to slide through based on number of cert pages
  list_images <- paste0('"cert_', 1:no_cert_pages, '.png"', collapse = ", ")
  # Replacing the list of images for the slider
  md_content <- gsub("\\$var_images\\$", 
                     paste0("var images = [", list_images, "];"), 
                     md_content)
  
  # Adding the abstract
  abstract <- get_abstract(repo_link)
  md_content <- gsub("\\$abstract\\$", abstract, md_content)

  # Saving the md file
  md_file_path <- file.path(cert_dir, "temp.md")
  writeLines(md_content, md_file_path)
}

render_cert_html <- function(cert_id){

  output_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  temp_md_path <- file.path(output_dir, "temp.md")
  
  # Creating html document yml
  create_cert_page_section_files(paste0(output_dir, "/"))
  generate_html_document_yml(paste0(output_dir, "/"))

  yaml_path <- normalizePath(file.path(getwd(), file.path(output_dir, "html_document.yml", fsep="")))
  # Render HTML from markdown
  rmarkdown::render(
    input = temp_md_path,
    output_file = "index.html",
    output_dir = output_dir,
    output_yaml = yaml_path
  )

  # Removing the temporary md file
  file.remove(temp_md_path)

  # Adjusting the path to the libs folder in the html itself
  # so that the path to the libs folder refers to the libs folder "docs/libs".
  # This is done to remove duplicates of "libs" folders.
  html_file_path <- file.path(output_dir, "index.html")
  edit_html_lib_paths(html_file_path)
  
  # Deleting the libs folder after changing the html lib path
  unlink(file.path(output_dir, "libs"), recursive = TRUE)
}

create_cert_page_section_files <- function(output_dir){

  # Create prefix 
  prefix_template <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["prefix"]], warn = FALSE)
  writeLines(prefix_template, paste0(output_dir, "index_prefix.html"))

  # Create postfix
  postfix_template <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["postfix"]], warn = FALSE)
  writeLines(postfix_template, paste0(output_dir, "index_postfix.html"))

  # Create header
  header_template <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["header"]], warn = FALSE)
  writeLines(header_template, paste0(output_dir, "index_header.html"))
}

add_repository_hyperlink <- function(md_content, repo_link) {
  
  spec <- parse_repository_spec(repo_link)
  if (!any(is.na(spec))) {
    urrl <- "#"

    switch(spec["type"],
      "github" = {
        repo_link <- paste0("https://github.com/", spec[["repo"]])
        paste0("[", spec[["repo"]], "](", repo_link, ")")
      },
      "osf" = {
        repo_link <- paste0("https://osf.io/", spec[["repo"]])
        paste0("[", spec[["repo"]], "](", repo_link, ")")
      },
      "gitlab" = {
        repo_link <- paste0("https://gitlab.com/", spec[["repo"]])
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