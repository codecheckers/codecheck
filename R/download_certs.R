library(httr)
library(jsonlite)

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
}

get_cert_link <- function(report_link, cert_id){

  if (grepl("zenodo", report_link, ignore.case = TRUE)){
    cert_download_url <- get_zenodo_cert_link(report_link, cert_id)
  }

  else if (grepl("OSF", report_link, ignore.case = TRUE)) {
  }

  else(
    return(NULL)
  )

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


get_zenodo_cert_link <- function(report_link, cert_id, api_key = "") {
  # Checking for redirects and retrieving the record_id from there
  response <- GET(report_link)
  final_url <- response$url 
  record_id <- basename(final_url)

  # Set the base URL for the Zenodo API
  # record_id <- gsub("zenodo.", "", basename(report_link))
  record_url <- paste0(CONFIG$CERT_LINKS[["zenodo_api"]], record_id, "/files")
  
  # Make the API request
  response <- GET(record_url, httr::add_headers(Authorization = paste("Bearer", api_key)))
  
  # Check if the request was successful
  if (status_code(response) == 200) {
    
    # Parse the response
    record_data <- fromJSON(content(response, "text", encoding = "UTF-8"))
    
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

get_abstract_text_openalex <- function(register_repo){

  abstract <- NULL

  config_yml <- get_codecheck_yml(register_repo)
  doi <- config_yml$paper$reference

  # First, attempt to retrieve the abstract using the DOI directly
  doi_api_url <- paste0(CONFIG$CERT_LINKS[["openalex_api"]], doi)
  # Correcting the api_url if it is malformed
  doi_api_url <- gsub("\\n", "", doi_api_url)
  response <- httr::GET(doi_api_url)

  if (status_code(response) != 200){
    # Checking for redirects and retrieving the final doi from there
    redirect_doi <- response$url 
    redirect_doi_api_url <- paste0(CONFIG$CERT_LINKS[["openalex_api"]], redirect_doi)
    response <- httr::GET(redirect_doi_api_url)
  }

  if (status_code(response) == 200){
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
