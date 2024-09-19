library(httr)
library(jsonlite)

download_cert_pdf <- function(report_link, cert_id){
  # Checking if the certs dir exist
  cert_dir <- CONFIG$CERTS_DIR[["cert"]]
  cert_sub_dir <- paste0(cert_dir, cert_id, "/")

  if (!dir.exists(cert_sub_dir)) {
    dir.create(cert_sub_dir, recursive = TRUE)
  }

  # Download the PDF file
  pdf_path <- paste0(cert_sub_dir, "/cert.pdf") 

  # Obtaining the pdf download link from the report link
  cert_download_url <- get_cert_link(report_link, cert_id)

  # Could not find a cert download url
  if (is.na(cert_download_url)){
    warning(paste("Failed to download the file. No link will be added to the cert", cert_id, ". No link will 
    be added to this cert."))
    return(0)
  }

  # Found a cert download url
  else{
    download_response <- GET(cert_download_url, httr::write_disk(pdf_path, overwrite = TRUE))

    if (status_code(download_response) == 200) {
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

get_cert_link <- function(report_link, cert_id){
  if (grepl("zenodo", report_link)){
    cert_download_url <- get_zenodo_cert_link(report_link, cert_id) 
  }

  else if (grepl("OSF", report_link, ignore.case = FALSE)) {
    cert_download_url <- get_osf_cert_link(report_link, cert_id)
  }
  # print(report_link)
  return(cert_download_url)
}
get_osf_cert_link <- function(report_link, cert_id){
  # Retrieve the OSF project node ID 
  node_id <- basename(report_link)

  # Prepare the API endpoint to access files for a specific node
  files_url <- paste0(CONFIG$CERT_LINKS[["osf_api"]], "nodes/", node_id, "/files/osfstorage/")

  # Initializing a list of all files (to handle pagination)
  all_files <- list()

  # Continue making requests while there is a 'next' page
  while (!is.null(files_url)) {
    response <- GET(files_url)
    
    # Check if the request was successful
    if (status_code(response) != 200) {
      stop("Failed to retrieve files: ", status_code(response))
    }
    
    # Parse the response content
    response_content <- content(response, as = "parsed", type = "application/json")
    
    # Add the files from the current page to the list of all files
    all_files <- c(all_files, response_content$data)
    
    # Check if there is a 'next' link to retrieve the next page of files
    files_url <- response_content$links[["next"]]
  }

  # If no files were retrieved, warn and return NA
  if (length(all_files) == 0) {
    warning(paste("No files found for node", node_id))
    return(NA)
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
    return(NA)
  } else if (length(pdf_files) == 0) {
    warning(paste("No PDF certs found for certificate with id", cert_id))
    return(NA)
  }

  # Extract the download link for the target PDF file
  cert_file <- pdf_files[[1]]
  return(cert_file$links$download)
}


get_zenodo_cert_link <- function(report_link, cert_id, api_key = "") {
  # Set the base URL for the Zenodo API
  record_id <- gsub("zenodo.", "", basename(report_link))
  record_url <- paste0(CONFIG$CERT_LINKS[["zenodo_api"]], record_id, "/files")
  
  # Make the API request
  response <- GET(record_url, httr::add_headers(Authorization = paste("Bearer", api_key)))
  
  # Check if the request was successful
  if (status_code(response) == 200) {
    
    # Parse the response
    record_data <- fromJSON(content(response, "text", encoding = "UTF-8"))
    
    files_list <- record_data$entries
    # print("List of files")
    # print(files_list)

    # print(nrow(files_list))
    # print(files_list$key)
    # Check for files in the record
    if (!is.null(files_list)) {
      pdf_files <- files_list[grepl("\\.pdf$", files_list$key, ignore.case = TRUE), ]
      # print("The pdf files")
      # print(pdf_files)
      if (nrow(pdf_files) > 1) {
        warning(paste("Multiple PDF files found in the Zenodo node. Cannot determine the correct cert file to download for cert", cert_id))
        return(NA)
      } else if (nrow(pdf_files) == 0) {
        warning(paste("No PDF certs found for certificate with id", cert_id))
        return(NA)
      }

      cert_file <- pdf_files[1, ]
      return (cert_file$links$content)
    } 
  } 
  else {
    warning(paste("Could not access the Zenodo API. Skipping retrieving cert", cert_id))
  }
}

get_abstract <- function(register_repo) {
  config_yml <- get_codecheck_yml(register_repo)

  # Retrieving the paper DOI
  paper_link <- config_yml$paper$reference
  doi <- sub(CONFIG$CERTS_URL_PREFIX, "", paper_link)

  # Construct the URL to access the CrossRef API
  # Make the HTTP GET request
  api_url <- paste0(CONFIG$CERT_LINKS[["crossref_api"]], doi)
  response <- GET(api_url)
  
  # Check if the request was successful
  if (status_code(response) == 200) {
    data <- content(response, "parsed")
    
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
    warning(paste("Failed to retrieve data for DOI", doi))
    return(NULL)
  }
}