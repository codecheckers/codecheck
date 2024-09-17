
create_cert_pages <- function(register, force_download = FALSE){

  # Read template
  html_template <- readLines(CONFIG$CERTS_DIR[[cert_page]])

  # Loop over each cert in the register table
  for (i in 1:nrow(register)){
    # Retrieving report link and cert id
    report_link <- register[i, ]$Report
    cert_id <- register[i, ]$Certificate

    # Define paths for the certificate PDF and JPEG
    pdf_path <- file.path(CONFIG$CERTS_DIR[["cert_pdf"]], paste0(cert_id, ".pdf"))
    pdf_exists <- file.exists(pdf_path)
    
    # Download the PDF if it doesn't exist or if force_download is TRUE
    if (!pdf_exists || force_download) {
      download_cert_pdf(report_link, cert_id)
      convert_cert_pdf_to_jpeg(cert_id)

      # Delaying reqwuests to adhere to request limits
      Sys.sleep(CONFIG$CERT_REQUEST_DELAY)
    }

    # Retrieve the abstract
    abstract <- get_abstract(register[i, ]$Repo)

    # Add the image tag into the placeholder
    img_tag <- sprintf('<img src="%s" alt="Description">', image_path)
    html_file_path <- paste0(cert_pdf_dir, "index.html")
    html_file <- gsub("<!--placeholder-for-images-->", img_tag, html_template)

    # Write the updated HTML to a file
    writeLines(html_file, html_file_path)
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
