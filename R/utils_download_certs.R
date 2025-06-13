#' Downloads a certificate PDF from a report link and saves it locally. 
#' If the download link is a ZIP file, it extracts the PDF from 
#' the archive. Returns status based on success.
#'
#' @param report_link URL of the report from which to download the certificate.
#' @param cert_id ID of the certificate, used for directory naming and logging.
#' @importFrom httr status_code GET write_disk
#'
#' @return 1 if the certificate is successfully downloaded and saved; otherwise, 0.
download_cert_pdf <- function(report_link, cert_id){
  # Checking if the certs dir exist
  cert_dir <- CONFIG$CERTS_DIR[["cert"]]
  cert_sub_dir <- file.path(cert_dir, cert_id)

  if (!dir.exists(cert_sub_dir)) {
    dir.create(cert_sub_dir, recursive = TRUE)
  }

  # Obtaining the pdf download link from the report link
  cert_download_url <- get_cert_link(report_link, cert_id)

  # Could not find a cert download url
  if (is.null(cert_download_url)){
    warning(paste("Failed to download the file. No link will be added to the cert", cert_id, ". No link will 
    be added to this cert."))
    return(0)
  }

  # Found a cert download url
  else{
    if (grepl("zip", cert_download_url)){
      pdf_cert_retrieval_status <- extract_cert_pdf_from_zip(cert_download_url, cert_sub_dir)
      return(pdf_cert_retrieval_status)
    }

    else {
      # Download the PDF file
      pdf_path <- file.path(cert_sub_dir, "cert.pdf") 
      download_response <- httr::GET(cert_download_url, httr::write_disk(pdf_path, overwrite = TRUE))
      
      if (httr::status_code(download_response) == 200) {
        message(paste("Cert", cert_id, "downloaded successfully"))
        return(1)
      } 
      # Failed to download file
      else{
        warning(paste("Unsuccessful GET request to download certificate", cert_id, ". No link will 
        be added to this cert."))
        return(0)
      }
    }
  }
}

#' Retrieves the download link for a certificate file from Zenodo, OSF, or ResearchEquals.
#'
#' @param report_link URL of the report to access, either from Zenodo, OSF, or ResearchEquals.
#' @param cert_id ID of the certificate, used for logging and warnings.
#'
#' @return The download link for the certificate file as a string if found; otherwise, NULL.
get_cert_link <- function(report_link, cert_id){

  if (grepl("zenodo", report_link, ignore.case = TRUE)){
    cert_download_url <- get_zenodo_cert_link(report_link, cert_id)
  }

  else if (grepl("OSF", report_link, ignore.case = TRUE)) {
    cert_download_url <- get_osf_cert_link(report_link, cert_id)
  }
  
  # use issuer prefix for LibSci, see https://web.archive.org/web/20250504015818/https://www.libscie.org/blog/working-openly-1/minting-dois-for-research-modules-147/
  else if (grepl("10.53962", report_link, ignore.case = TRUE)) {
    cert_download_url <- get_researchequals_cert_link(report_link, cert_id)
  }

  else(
    return(NULL)
  )

  return(cert_download_url)
}

#' Retrieves the link to a certificate PDF file from an OSF project node. It retrieves its files, 
#' and searches for a single PDF certificate file within the node. If multiple or no PDF 
#' files are found, it returns NULL with a warning.
#'
#' @param report_link URL of the OSF report to access.
#' @param cert_id ID of the certificate, used for logging and warnings.
#' @importFrom httr status_code content
#' @return The download link for the certificate file as a string if a single PDF is found; otherwise, NULL.
get_osf_cert_link <- function(report_link, cert_id){
  # Retrieve the OSF project node ID 
  node_id <- basename(report_link)
  # Prepare the API endpoint to access files for a specific node
  files_url <- paste0(CONFIG$CERT_LINKS[["osf_api"]], "nodes/", node_id, "/files/osfstorage/")

  # Initializing a list of all files (to handle pagination)
  all_files <- list()

  # Continue making requests while there is a 'next' page
  while (!is.null(files_url)) {
    response <- httr::GET(files_url)
    
    # Check if the request was successful
    if (httr::status_code(response) != 200) {
      stop("Failed to retrieve files: ", status_code(response))
    }
    
    # Parse the response content
    response_content <- httr::content(response, as = "parsed", type = "application/json")
    
    # Add the files from the current page to the list of all files
    all_files <- c(all_files, response_content$data)
    
    # Check if there is a 'next' link to retrieve the next page of files
    files_url <- response_content$links[["next"]]
  }

  # If no files were retrieved, warn and return NULL
  if (length(all_files) == 0) {
    warning(paste("No files found for node", node_id))
    return(NULL)
  }

  # Filter the files to find PDF files based on their extension in the name attribute
  pdf_files <- lapply(all_files, function(file) {
    if (grepl("\\.pdf$", file$attributes$name, ignore.case = TRUE)) {
      return(file)
    }
    return(NULL)
  })

  # Remove NULL entries
  pdf_files <- Filter(Negate(is.null), pdf_files)

  # If multiple or no PDF files are found, return a warning
  if (length(pdf_files) > 1) {
    warning(paste("Multiple PDF files found in the OSF node. Cannot determine the correct cert file to download for cert", cert_id))
    return(NULL)
  } else if (length(pdf_files) == 0) {
    warning(paste("No PDF certs found for certificate with id", cert_id))
    return(NULL)
  }

  # Extract the download link for the target PDF file
  cert_file <- pdf_files[[1]]
  return(cert_file$links$download)
}

#' Accesses a codecheck's Zenodo record via its report link, retrieves the record ID, 
#' and searches for a certificate PDF or ZIP file within the record's files using the Zenodo API.
#'
#' @param report_link URL of the Zenodo report to access.
#' @param cert_id ID of the certificate, used for logging and warnings.
#' @param api_key (Optional) API key for Zenodo authentication if required.
#' 
#' @importFrom httr GET status_code content
#' @importFrom jsonlite fromJSON
#'
#' @return The download link for the certificate file as a string if found; otherwise, NULL.
get_zenodo_cert_link <- function(report_link, cert_id, api_key = "") {
  # Checking for redirects and retrieving the record_id from there
  response <- httr::GET(report_link)
  final_url <- response$url 
  record_id <- basename(final_url)

  # Set the base URL for the Zenodo API
  # record_id <- gsub("zenodo.", "", basename(report_link))
  record_url <- paste0(CONFIG$CERT_LINKS[["zenodo_api"]], record_id, "/files")
  
  # Make the API request
  response <- httr::GET(record_url, httr::add_headers(Authorization = paste("Bearer", api_key)))
  
  # Check if the request was successful
  if (httr::status_code(response) == 200) {
    
    # Parse the response
    record_data <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))
    
    files_list <- record_data$entries

    # Check for files in the record
    if (!is.null(files_list)) {
      pdf_files <- files_list[grepl("\\.pdf$", files_list$key, ignore.case = TRUE), ]
      if (nrow(pdf_files) > 1) {
        # Check if there's a file named "codecheck.pdf". Generally this is the name of the
        # cert file
        codecheck_file <- pdf_files[pdf_files$key == "codecheck.pdf", ]
        # If the file "codecheck.pdf" exists, return it
        if (nrow(codecheck_file) == 1) {
          return (codecheck_file$links$content)
        }

        else{
          warning(paste("Multiple PDF files found in the Zenodo node. Cannot determine the correct cert file to download for cert", cert_id))
          return(NULL)
        }
      } 
      else if (nrow(pdf_files) == 0) {
        # Check for ZIP files if no PDF is found
        zip_files <- files_list[grepl("\\.zip$", files_list$key, ignore.case = TRUE), ]
        
        if (nrow(zip_files) == 1) {
          # Download the ZIP file
          zip_file_url <- zip_files$links$content
          return(zip_file_url)
        }

        warning(paste("No PDF certs found for certificate with id", cert_id))
        return(NULL)
      }

      cert_file <- pdf_files[1, ]
      return (cert_file$links$content)
    } 
  } 
  else {
    warning(paste("Could not access the Zenodo API. Skipping retrieving cert", cert_id))
    return(NULL)
  }
}


#' Accesses a codecheck's ResearchEquals record via its report link and download the main file of the module
#'
#' @param report_link URL of the ResearchEquals report to access.
#' @param cert_id ID of the certificate, used for logging and warnings.
#' 
#' @importFrom httr GET status_code content
#' @importFrom jsonlite fromJSON
#'
#' @return The download link for the certificate file as a string if found; otherwise, NULL.
get_researchequals_cert_link <- function(report_link, cert_id) {
  # Download link example: https://www.researchequals.com/api/modules/main/wxh7-8yjd
  # Let's guess the ID from the report_link
  
  # Checking for redirects and retrieving the record_id from there
  response <- httr::GET(report_link)
  final_url <- response$url
  record_id <- basename(final_url)
  
  # Set the base URL for the ResearchEquals API
  record_url <- paste0(CONFIG$CERT_LINKS[["researchequals_api"]], record_id)
  
  return (record_url)
}


#' Downloads a ZIP file from the given URL, searches for "codecheck.pdf" within its contents,
#' renames it to "cert.pdf," and saves it in the specified directory. 
#'
#' @param zip_download_url URL to download the ZIP file from.
#' @param cert_sub_dir Directory to save the extracted certificate PDF.
#'
#' @return 1 if "codecheck.pdf" is found and saved, otherwise 0.
extract_cert_pdf_from_zip <- function(zip_download_url, cert_sub_dir){
  zip_dir <- file.path(cert_sub_dir, "content.zip")
  
  # Download the ZIP file
  download.file(zip_download_url, zip_dir)
  
  # Create a temporary unzip directory inside cert_sub_dir
  temp_unzip_dir <- file.path(cert_sub_dir, "temp_unzip")
  dir.create(temp_unzip_dir)  # Create the directory if it doesn't exist
  
  # Unzip the contents into the temp_unzip_dir
  unzip(zip_dir, exdir = temp_unzip_dir)

  # Find the "codecheck.pdf" in the unzipped directory (including subdirectories)
  codecheck_path <- list.files(temp_unzip_dir, pattern = "codecheck\\.pdf$", recursive = TRUE, full.names = TRUE)
  
  # If "codecheck.pdf" exists, move it to the cert_sub_dir
    if (length(codecheck_path) == 1) {
      file.rename(codecheck_path, file.path(cert_sub_dir, "cert.pdf"))
      
      # Delete the unzipped temporary directory and all its contents
      unlink(temp_unzip_dir, recursive = TRUE)
      unlink(zip_dir)
      return(1) 
    } 
    else {
      warning("'codecheck.pdf' not found in the ZIP file")
      
      # Cleanup: Delete the unzipped temporary directory and all its contents
      unlink(temp_unzip_dir, recursive = TRUE)
      unlink(zip_dir)
      return(0)
    }
}

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
