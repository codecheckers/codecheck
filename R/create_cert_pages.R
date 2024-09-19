
render_cert_htmls <- function(register, force_download = FALSE){

  # Read template
  html_template <- readLines(CONFIG$CERTS_DIR[[cert_page_template]])

  # Loop over each cert in the register table
  for (i in 1:nrow(register)){
    # Retrieving report link and cert id
    report_link <- register[i, ]$Report
    cert_id <- register[i, ]$Certificate

    # Define paths for the certificate PDF and JPEG
    pdf_path <- file.path(CONFIG$CERTS_DIR[["cert"]], paste0(cert_id, ".pdf"))
    pdf_exists <- file.exists(pdf_path)
    
    # Download the PDF if it doesn't exist or if force_download is TRUE
    if (!pdf_exists || force_download) {
      download_cert_pdf(report_link, cert_id)
      convert_cert_pdf_to_jpeg(cert_id)

      # Delaying reqwuests to adhere to request limits
      Sys.sleep(CONFIG$CERT_REQUEST_DELAY)
    }

    create_cert_md(cert_id)
    render_cert_html(cert_id)
  }
}

convert_cert_pdf_to_jpeg <- function(cert_id){

  # Checking if the certs dir exist
  cert_pdf_dir <- CONFIG$CERTS_DIR[["certs_pdf"]]
  pdf_path <- paste0(cert_id, "cert.pdf") 

  # Get the number of pages in the PDF
  cert_pdf_path <- paste0(cert_dir, "cert.pdf")
  num_pages <- pdf_info(cert_pdf_path)$pages

  # Create image filenames
  image_filenames <- sapply(1:num_pages, function(page) paste0(cert_dir, "cert_", page, ".png"))
  
  # Read and convert PDF to PNG images
  pdf_convert(cert_pdf_path, format = "png", filenames = image_filenames, dpi = 300)
}


# Creates a markdown file of the certificate which is then rendered
# to html
create_cert_md <- function(cert_id){

  # Loading the template
  md_content <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["md_template"]])

  # Replacing the title
  title <- paste(CONFIG$MD_TITLES[["certs"]], cert_id)
  md_content <- gsub("\\$title\\$", title, md_content)

  # Replacing the list of images for the slider
  # Identifying the number of cert pages 
  no_cert_pages <- length(list.files(path = output_dir, pattern = "^cert_.*\\.jpg$", full.names = TRUE))
  # Creating a list of images to slide through based on number of cert pages
  list_images <- paste0('"cert_', 1:no_cert_pages, '.jpg"', collapse = ", ")

  # Adding the abstract
  abstract <- get_abstract(register[i, ]$Repo)
  md_content <- gsub("\\$abstract\\$", abstract, md_content)

  # Saving the md file
  temp_dir <- paste0(CONFIG$CERTS_DIR[["cert"]], cert_id, "temp.md")
  writeLines(md_table, temp_dir)
}

render_cert_html <- function(cert_id){
  create_cert_md(cert_id)

  output_dir <- paste0(CONFIG$CERTS_DIR[["cert"]], cert_id)
  temp_md_path <- paste0(output_dir, "temp.md")

  # Creating html document yml
  generate_html_document_yml(output_dir)
  yaml_path <- normalizePath(file.path(getwd(), paste0(output_dir, "html_document.yml")))

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
  html_file_path <- paste0(output_dir, "index.html")
  edit_html_lib_paths(html_file_path)
  
  # Deleting the libs folder after changing the html lib path
  unlink(paste0(output_dir, "/libs"), recursive = TRUE)
}

create_cert_page_section_files <- function(output_dir){

  # Create prefix 
  prefix_template <- readLines(CONFIG$TEMPLATE_DIR[["reg"]][["prefix"]], warn = FALSE)
  writeLines(prefix_template, paste0(output_dir, "index_prefix.html"))
}