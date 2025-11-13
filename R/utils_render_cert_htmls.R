#' Generates HTML files for each certificate listed in the given register table. 
#' It checks for the existence of the certificate PDF, downloads it if necessary, and 
#' converts it to JPEG format for embedding. 
#'
#' @param register_table A data frame containing details of each certificate, including repository links and report links.
#' @param force_download Logical; if TRUE, forces the download of certificate PDFs even if they already exist locally. Defaults to FALSE.
render_cert_htmls <- function(register_table, force_download = FALSE){
  # Read template
  html_template <- readLines(CONFIG$CERTS_DIR[["cert_page_template"]])

  # Loop over each cert in the register table
  for (i in 1:nrow(register_table)){
    download_cert_status <- NA
    
    abstract <- get_abstract(register_table[i, ]$Repository)

    # Retrieving report link and cert id
    report_link <- register_table[i, ]$Report
    cert_hyperlink <- register_table[i, ]$Certificate
    cert_id <- sub("\\[(.*)\\]\\(.*\\)", "\\1", cert_hyperlink)

    if(CONFIG$CERT_DOWNLOAD_AND_CONVERT) {
      # Define paths for the certificate PDF and JPEG
      pdf_path <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id, "cert.pdf")
      pdf_exists <- file.exists(pdf_path)
      
      # Download the PDF if it doesn't exist or if force_download is TRUE
      if (!pdf_exists || force_download) {
        download_cert_status <- download_cert_pdf(report_link, cert_id)
        # Successfully downloaded cert
        # Proceeding to convert pdfs to jpegs
        if (download_cert_status == 1){
          convert_cert_pdf_to_png(cert_id)
        }
        
        # Delaying requests to adhere to request limits
        Sys.sleep(CONFIG$CERT_REQUEST_DELAY)
      }
      
      # The pdf exists and force download is False
      else{
        download_cert_status <- 1
      }
    } else {
      # do not display a certificate
      download_cert_status <- 0
    }
    
    # Extract Type and Venue for the certificate
    cert_type <- register_table[i, ]$Type
    cert_venue <- register_table[i, ]$Venue

    render_cert_html(cert_id, register_table[i, ]$Repository, download_cert_status, cert_type, cert_venue)
  }
}

#'
#' Converts each page of a certificate PDF to JPEG format images, saving them in the specified certificate directory. 
#'
#' @importFrom pdftools pdf_info
#' @param cert_id The certificate identifier. This ID is used to locate the PDF and save the resulting images.
convert_cert_pdf_to_png <- function(cert_id){
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
#' @param cert_type A character string containing the venue type (journal, conference, community, institution).
#' @param cert_venue A character string containing the venue name.
render_cert_html <- function(cert_id, repo_link, download_cert_status, cert_type, cert_venue){
  create_cert_md(cert_id, repo_link, download_cert_status, cert_type, cert_venue)

  output_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  temp_md_path <- file.path(output_dir, "temp.md")

  # Creating html document yml with breadcrumbs
  create_cert_page_section_files(output_dir, cert_id, cert_type, cert_venue)
  generate_html_document_yml(output_dir)

  yaml_path <- normalizePath(file.path(getwd(), file.path(output_dir, "html_document.yml")))

  # Render HTML from markdown
  rmarkdown::render(
    input = temp_md_path,
    output_file = "index.html",
    output_dir = output_dir,
    output_yaml = yaml_path
  )

  # Remove temporary files (content already embedded in index.html)
  file.remove(temp_md_path)
  file.remove(file.path(output_dir, "index_header.html"))
  file.remove(file.path(output_dir, "index_prefix.html"))
  file.remove(file.path(output_dir, "index_postfix.html"))
  file.remove(file.path(output_dir, "html_document.yml"))

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
#' @param cert_id The certificate identifier for breadcrumb generation
#' @param cert_type The venue type (journal, conference, community, institution) for breadcrumb generation
#' @param cert_venue The venue name for breadcrumb generation
#' @importFrom whisker whisker.render
create_cert_page_section_files <- function(output_dir, cert_id = NULL, cert_type = NULL, cert_venue = NULL){

  # Create prefix with navigation header and breadcrumbs
  if (!is.null(cert_id) && !is.null(cert_type) && !is.null(cert_venue)) {
    # Generate breadcrumbs for certificate page with venue context
    table_details <- list(
      name = cert_venue,
      subcat = cert_type,
      cert_id = cert_id,
      is_reg_table = TRUE
    )
    base_path <- "../.."  # Certificate pages are always at docs/certs/ID/

    # Generate navigation header (no menu on certificate pages)
    nav_header_html <- generate_navigation_header(filter = "certs", base_path = base_path, table_details = table_details)

    # Generate breadcrumbs
    breadcrumb_html <- generate_breadcrumb(filter = "venues", table_details = table_details, base_path = base_path)

    prefix_content <- paste0(
      nav_header_html,
      '<div style="max-width: 1200px; margin: 1rem auto; padding: 0 1rem;">\n',
      breadcrumb_html,
      '\n</div>\n'
    )
    writeLines(prefix_content, file.path(output_dir, "index_prefix.html"))
  } else {
    # Fallback to template if information not provided
    prefix_template <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["prefix"]], warn = FALSE)
    writeLines(prefix_template, file.path(output_dir, "index_prefix.html"))
  }

  # Create postfix with build metadata
  postfix_template <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["postfix"]], warn = FALSE)

  # Generate footer build info from build metadata
  build_info <- ""
  if (exists("BUILD_METADATA", envir = CONFIG) && !is.null(CONFIG$BUILD_METADATA)) {
    build_info <- generate_footer_build_info(CONFIG$BUILD_METADATA)
  }

  output <- whisker.render(paste(postfix_template, collapse = "\n"), list(build_info = build_info))
  writeLines(output, file.path(output_dir, "index_postfix.html"))

  # Create header with meta generator content
  header_template <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["header"]], warn = FALSE)

  # Generate meta generator content from build metadata
  meta_generator <- ""
  if (exists("BUILD_METADATA", envir = CONFIG) && !is.null(CONFIG$BUILD_METADATA)) {
    meta_generator <- generate_meta_generator_content(CONFIG$BUILD_METADATA)
  }

  # Calculate relative path to docs root (cert pages are always 2 levels deep: docs/certs/ID/)
  # Count directory levels from docs/
  path_components <- strsplit(output_dir, "/")[[1]]
  path_components <- path_components[path_components != "" & path_components != "docs"]
  depth <- length(path_components)

  # Generate relative path
  if (depth == 0) {
    base_path <- ""
  } else {
    base_path <- paste(rep("../", depth), collapse = "")
  }

  output <- whisker.render(paste(header_template, collapse = "\n"),
                          list(meta_generator = meta_generator,
                               base_path = base_path))
  writeLines(output, file.path(output_dir, "index_header.html"))
}
