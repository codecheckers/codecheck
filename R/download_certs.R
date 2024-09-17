library(httr)
library(jsonlite)

download_cert_pdf <- function(report_link, cert_id){
  # Obtaining the pdf download link from the report link
  cert_download_url <- get_cert_link(report_link)

  # Checking if the certs dir exist
  cert_pdf_dir <- CONFIG$CERTS_DIR[["certs_pdf"]]
  pdf_path <- paste0(cert_id, "cert.pdf") 

  # Download the PDF file
  download_response <- GET(cert_download_url, write_disk(pdf_path, overwrite = TRUE))

  # Throwing warning messages
  if (status_code(download_response) == 200) {
      message(paste("Cert", cert_id, "downloaded successfully"))
  } 

  else{
      warning(paste("Failed to download the file. No link will be added to the cert", cert_id, ". No link will 
      be added to this cert."))
  }
}

get_cert_link <- function(report_link){
  if (grepl("zenodo", report_link)){
    cert_download_url <- get_zenodo_cert_link(report_link, cert_id) 
  }

  else if (grepl("OSF", report_link, ignore.case = FALSE)) {
    cert_download_url <- get_osf_cert_link(report_link, cert_id)
  }

  return(cert_download_url)
}

get_osf_cert_link <- function(report_link, cert_id){
  # Retrieve the osf_project_id 
  node_id <- basename(report_link)

  # Prepare the API endpoint to access files for a specific node and make the request
  files_url <- paste0(CONFIG$CERT_LINKS[["osf_api"]], "nodes/", node_id, "/files/osfstorage/")
  response <- GET(files_url)

  # Check if the request was successful
  if (status_code(response) == 200) {
      # Manually parse the JSON content
      file_data <- fromJSON(content(response, "text", encoding = "UTF-8"))    
      
      # Accessing the files and finding the correct pdf file based on the extension and the file name
      files_list <- file_data$data

      target_files <- files_list[grepl("\\.pdf$", files_list$attributes$name, ignore.case = TRUE), ]
      
      if (length(nrow(target_files)) > 1){
          warning(paste("Multiple pdf files found in the OSF url. Cannot determine the correct OSF cert file to download. No link will be added to cert", cert_id))
      }

      target_file <- target_files[1, ]
      return (target_file$links$download)
  }

  else {
      warning(paste("Could not access the OSF API. Skipping retrieving cert", cert_id))
  }
}

get_zenodo_cert_link <- function(report_link, cert_id, api_key = "") {
  # Set the base URL for the Zenodo API
  record_id <- gsub("zenodo.", "", basename(report_link))
  record_url <- paste0(CONFIG$CERT_LINKS[["zenodo_api"]], record_id, "/files")
  
  # Make the API request
  response <- GET(record_url, add_headers(Authorization = paste("Bearer", api_key)))
  
  # Check if the request was successful
  if (status_code(response) == 200) {
   # Parse the response
    record_data <- fromJSON(content(response, "text", encoding = "UTF-8"))
    
    files_list <- record_data$entries

    # Check for files in the record
    if (!is.null(files_list)) {
      target_files <- files_list[grepl("\\.pdf$", files_list$key, ignore.case = TRUE), ]
      
      if (length(nrow(target_files)) > 1){
        warning(paste("Multiple pdf files found in the Zenodo url. Cannot determine the correct Zenodo cert file to download. No link will be added to cert", cert_id))
      }

      target_file <- target_files[1, ]
      return (target_file$links$content)
    } 
  } 
  else {
    warning(paste("Could not access the Zenodo API. Skipping retrieving cert", cert_id))
  }
}

get_abstract <- function(register_repo) {
  config_yml <- get_codecheck_yml(register[i, ]$Repo)

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
    warning(paste("No abstract available for DOI", doi))
    return(NULL)
  } 
  else {
    warning(paste("Failed to retrieve data for DOI", doi))
    return(NULL)
  }
}