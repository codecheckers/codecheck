#' Generates HTML files for each certificate listed in the given register table. 
#' It checks for the existence of the certificate PDF, downloads it if necessary, and 
#' converts it to JPEG format for embedding. 
#'
#' @param register_table A data frame containing details of each certificate, including repository links and report links.
#' @param force_download Logical; if TRUE, forces the download of certificate PDFs even if they already exist locally. Defaults to FALSE.
render_cert_htmls <- function(register_table, force_download = FALSE){
  # Keeping a list of failed cert pages. No hyperlinks will be added for these certs
  CONFIG$LIST_FAILED_CERT_PAGES <- list()
  CONFIG$LIST_FAILED_ABSTRACT <- list()

  # Read template
  html_template <- readLines(CONFIG$CERTS_DIR[["cert_page_template"]])

  # Loop over each cert in the register table
  for (i in 1:nrow(register_table)){
    abstract <- get_abstract(register_table[i, ]$Repository)

    # Retrieving report link and cert id
    report_link <- register_table[i, ]$Report
    cert_hyperlink <- register_table[i, ]$Certificate
    cert_id <- sub("\\[(.*)\\]\\(.*\\)", "\\1", cert_hyperlink)

    # Define paths for the certificate PDF and JPEG
    pdf_path <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id, "cert.pdf")
    pdf_exists <- file.exists(pdf_path)

    # Download the PDF if it doesn't exist or if force_download is TRUE
    if (!pdf_exists || force_download) {
      download_cert_status <- download_cert_pdf(report_link, cert_id)
      # Successfully downloaded cert
      # Proceeding to convert pdfs to jpegs
      if (download_cert_status == 1){
        convert_cert_pdf_to_jpeg(cert_id)
      }

      # Failed in downloading cert
      else{
        CONFIG$LIST_FAILED_CERT_PAGES <- append(CONFIG$LIST_FAILED_CERT_PAGES, cert_id)
        Sys.sleep(CONFIG$CERT_REQUEST_DELAY)
      }
      # Delaying reqwuests to adhere to request limits
      Sys.sleep(CONFIG$CERT_REQUEST_DELAY)
    }

    # The pdf exists and force download is False
    else{
      download_cert_status <- 1
    }

    render_cert_html(cert_id, register_table[i, ]$Repository, download_cert_status)
  }
}

#'
#' Converts each page of a certificate PDF to JPEG format images, saving them in the specified certificate directory. 
#'
#' @param cert_id The certificate identifier. This ID is used to locate the PDF and save the resulting images.
convert_cert_pdf_to_jpeg <- function(cert_id){
  # Checking if the certs dir exist
  cert_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id) 

  # Get the number of pages in the PDF
  cert_pdf_path <- file.path(cert_dir, "cert.pdf")
  num_pages <- pdftools::pdf_info(cert_pdf_path)$pages

  # Create image filenames
  image_filenames <- sapply(1:num_pages, function(page) file.path(cert_dir, paste0("cert_", page, ".png")))
  
  # Read and convert PDF to PNG images
  pdftools::pdf_convert(cert_pdf_path, format = "png", filenames = image_filenames, dpi = CONFIG$CERT_DPI)
}

#' Renders an HTML certificate file from a Markdown template for a specific certificate.
#'
#' @param cert_id A character string representing the unique identifier of the certificate.
#' @param repo_link A character string containing the repository link associated with the certificate.
#' @param download_cert_status An integer (0 or 1) indicating whether the certificate PDF was downloaded (1) or not (0).
render_cert_html <- function(cert_id, repo_link, download_cert_status){
  create_cert_md(cert_id, repo_link, download_cert_status)

  output_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  temp_md_path <- file.path(output_dir, "temp.md")
  
  # Creating html document yml
  create_cert_page_section_files(paste0(output_dir, "/"))
  generate_html_document_yml(paste0(output_dir, "/"))

  yaml_path <- normalizePath(file.path(getwd(), file.path(output_dir, "html_document.yml")))

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

#' Generates section files for a certificate HTML page, including prefix, postfix, and header HTML components.
#'
#' @param output_dir A character string specifying the directory where the section files will be saved.
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
