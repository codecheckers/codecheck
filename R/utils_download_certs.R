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
    warning(cert_id, " | Failed to download the file. No download link found")
    return(0)
  }

  # Found a cert download url
  else{
    if (grepl("zip", cert_download_url)){
      pdf_cert_retrieval_status <- extract_cert_pdf_from_zip(cert_download_url, cert_sub_dir, cert_id)
      return(pdf_cert_retrieval_status)
    }

    else {
      # Download the PDF file
      pdf_path <- file.path(cert_sub_dir, "cert.pdf")
      download_response <- codecheck_GET(cert_download_url, httr::write_disk(pdf_path, overwrite = TRUE))

      if (httr::status_code(download_response) == 200) {
        cli::cli_alert_success("{cert_id} | Downloaded successfully")
        return(1)
      }
      # Failed to download file
      else{
        warning(cert_id, " | Unsuccessful GET request to download certificate")
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
  # The register is rendered into many tables (main, per venue, per type) and each
  # one resolves the same report links again, which got the requests throttled by
  # the archives. Only successful resolutions are cached, so a transient failure
  # is retried rather than stored for the rest of the session.
  cache_key <- paste0(report_link, "|", cert_id)
  if (!is.null(cert_link_cache[[cache_key]])) {
    return(cert_link_cache[[cache_key]])
  }

  cert_download_url <- get_cert_link_uncached(report_link, cert_id)

  if (!is.null(cert_download_url)) {
    cert_link_cache[[cache_key]] <- cert_download_url
  }

  return(cert_download_url)
}

#' In-session cache of resolved certificate download links, see get_cert_link()
cert_link_cache <- new.env(parent = emptyenv())

#' Clear the in-session cache of resolved certificate download links
clear_cert_link_cache <- function() {
  rm(list = ls(cert_link_cache, all.names = TRUE), envir = cert_link_cache)
}

#' Resolves the download link for a certificate file without caching, see get_cert_link().
#'
#' @param report_link URL of the report to access, either from Zenodo, OSF, or ResearchEquals.
#' @param cert_id ID of the certificate, used for logging and warnings.
#'
#' @return The download link for the certificate file as a string if found; otherwise, NULL.
get_cert_link_uncached <- function(report_link, cert_id){

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
    response <- codecheck_GET_retry(files_url)

    # Check if the request was successful
    if (is.null(response)) {
      stop("Failed to retrieve files: no response from ", files_url)
    }
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
    warning(cert_id, " | No files found for OSF node ", node_id)
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
    warning(cert_id, " | Multiple PDF files found in OSF node. Cannot determine correct cert file")
    return(NULL)
  } else if (length(pdf_files) == 0) {
    warning(cert_id, " | No PDF certs found in OSF node")
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
  response <- codecheck_GET_retry(report_link)
  if (is.null(response)) {
    warning(cert_id, " | Could not resolve report link ", report_link)
    return(NULL)
  }
  final_url <- response$url
  record_id <- basename(final_url)

  # Set the base URL for the Zenodo API
  # record_id <- gsub("zenodo.", "", basename(report_link))
  record_url <- paste0(CONFIG$CERT_LINKS[["zenodo_api"]], record_id, "/files")

  # Make the API request
  response <- codecheck_GET_retry(record_url, httr::add_headers(Authorization = paste("Bearer", api_key)))

  if (is.null(response)) {
    warning(cert_id, " | Could not access Zenodo API")
    return(NULL)
  }

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
          warning(cert_id, " | Multiple PDF files found in Zenodo node. Cannot determine correct cert file")
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

        warning(cert_id, " | No PDF certs found in Zenodo node")
        return(NULL)
      }

      cert_file <- pdf_files[1, ]
      return (cert_file$links$content)
    }
  }
  else {
    warning(cert_id, " | Could not access Zenodo API")
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
  # A ResearchEquals DOI redirects to the page of one version of an output,
  # https://researchequals.com/en-US/versions/<version id>, from where the API
  # gives the key of the deposited file:
  #   GET /api/versions/<version id>  ->  content_s3, content_mediatype
  #   GET /api/files/<content_s3>     ->  the file itself
  # The older /api/modules/main/<DOI suffix> endpoint no longer exists.
  response <- codecheck_GET_retry(report_link)
  if (is.null(response)) {
    warning(cert_id, " | Could not resolve report link ", report_link)
    return(NULL)
  }

  # codecheck_GET_retry() follows redirects, so this is the resolved page; the
  # locale prefix ResearchEquals adds does not affect the trailing version id
  version_id <- basename(response$url)
  api <- CONFIG$CERT_LINKS[["researchequals_api"]]

  version_response <- codecheck_GET_retry(paste0(api, "versions/", version_id))
  if (is.null(version_response) || httr::status_code(version_response) != 200) {
    warning(cert_id, " | Could not access the ResearchEquals API for version ", version_id)
    return(NULL)
  }

  version <- httr::content(version_response, as = "parsed", type = "application/json")
  file_key <- version$content_s3
  if (is.null(file_key)) {
    warning(cert_id, " | ResearchEquals version ", version_id, " has no deposited file")
    return(NULL)
  }
  if (!identical(version$content_mediatype, "application/pdf")) {
    warning(cert_id, " | ResearchEquals version ", version_id, " is not a PDF but ",
            toString(version$content_mediatype))
  }

  return(paste0(api, "files/", file_key))
}


#' Downloads a ZIP file from the given URL, searches for "codecheck.pdf" within its contents,
#' renames it to "cert.pdf," and saves it in the specified directory.
#'
#' @param zip_download_url URL to download the ZIP file from.
#' @param cert_sub_dir Directory to save the extracted certificate PDF.
#' @param cert_id ID of the certificate, used for logging and warnings.
#'
#' @importFrom utils download.file unzip
#'
#' @return 1 if "codecheck.pdf" is found and saved, otherwise 0.
extract_cert_pdf_from_zip <- function(zip_download_url, cert_sub_dir, cert_id){
  zip_dir <- file.path(cert_sub_dir, "content.zip")
  
  # Download the ZIP file
  utils::download.file(zip_download_url, zip_dir)
  
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
      warning(cert_id, " | 'codecheck.pdf' not found in ZIP file")

      # Cleanup: Delete the unzipped temporary directory and all its contents
      unlink(temp_unzip_dir, recursive = TRUE)
      unlink(zip_dir)
      return(0)
    }
}

#' Poppler (via pdftools) reports PDF parsing problems by printing "PDF error: ..."
#' lines directly to R's message connection rather than raising a condition on them,
#' so they bypass ordinary error handling and, uncaptured, flood the console - one
#' line per malformed glyph or object, sometimes hundreds per certificate. This
#' splits captured poppler output into messages that mean the PDF is genuinely
#' broken (unparsable, not really a PDF) versus cosmetic rendering quirks that
#' poppler recovers from on its own (e.g. malformed embedded fonts) and that don't
#' affect the resulting page images.
#'
#' @param lines Character vector of captured message-stream output; only lines
#'   starting with "PDF error" are considered, everything else is ignored.
#' @return A list with `fatal` (unique messages indicating the PDF could not really
#'   be parsed, character(0) if none) and `cosmetic_count` (number of suppressed
#'   non-fatal poppler messages).
classify_poppler_log <- function(lines) {
  pdf_error_lines <- grep("^PDF error", lines, value = TRUE)

  # Substrings that mean poppler could not really make sense of the file, as
  # opposed to a rendering quirk it recovers from on its own.
  fatal_substrings <- c(
    "Couldn't find trailer dictionary",
    "Couldn't read xref table",
    "May not be a PDF file",
    "Illegal character",
    "Damaged PDF file"
  )

  is_fatal <- vapply(pdf_error_lines, function(line) {
    any(vapply(fatal_substrings, grepl, logical(1), x = line, fixed = TRUE))
  }, logical(1))

  list(
    fatal = unique(sub("^PDF error( \\(\\d+\\))?: ", "", pdf_error_lines[is_fatal])),
    cosmetic_count = sum(!is_fatal)
  )
}

#' Converts each page of a certificate PDF to PNG images, saving them in the specified certificate directory.
#'
#' Captures poppler's PDF parsing diagnostics (see [classify_poppler_log()]) instead
#' of letting them print raw to the console, and returns a compact, structured
#' status instead of throwing - so a caller running this inside a parallel worker
#' (where a plain `warning()` never reaches the coordinating process) still gets
#' an accurate, actionable signal back through the ordinary return value.
#'
#' @importFrom pdftools pdf_info pdf_convert
#' @param cert_id The certificate identifier. This ID is used to locate the PDF and save the resulting images.
#' @return A list with `success` (logical), `pages` (page count, `NA` on failure),
#'   `error` (the caught error message, or `NULL`), `fatal` (unique fatal poppler
#'   messages, `character(0)` if none) and `cosmetic_count` (number of suppressed
#'   cosmetic poppler messages).
convert_cert_pdf_to_png <- function(cert_id){
  # Checking if the certs dir exist
  cert_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  cert_pdf_path <- file.path(cert_dir, "cert.pdf")

  poppler_log <- character(0)
  log_con <- textConnection("poppler_log", open = "w", local = TRUE)
  sink(log_con, type = "message")
  outcome <- tryCatch({
    # Get the number of pages in the PDF
    num_pages <- pdftools::pdf_info(cert_pdf_path)$pages

    # Create image filenames
    image_filenames <- sapply(1:num_pages, function(page) file.path(cert_dir, paste0("cert_", page, ".png")))

    # Read and convert PDF to PNG images. verbose = FALSE suppresses the
    # per-page "Converting page X to Y... done!" progress text; callers that
    # want a progress indicator report the page count themselves instead.
    pdftools::pdf_convert(cert_pdf_path, format = "png", filenames = image_filenames,
                          dpi = CONFIG$CERT_DPI, verbose = FALSE)

    list(success = TRUE, pages = num_pages, error = NULL)
  }, error = function(e) {
    list(success = FALSE, pages = NA_integer_, error = conditionMessage(e))
  })
  sink(type = "message")
  close(log_con)

  classified <- classify_poppler_log(poppler_log)

  list(
    success = outcome$success,
    pages = outcome$pages,
    error = outcome$error,
    fatal = classified$fatal,
    cosmetic_count = classified$cosmetic_count
  )
}
