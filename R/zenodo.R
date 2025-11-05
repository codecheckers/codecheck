#' Create a new Zenodo record and automatically update codecheck.yml
#'
#' Run this only once per new codecheck. By default, loads metadata from
#' codecheck.yml in the current working directory.
#'
#' If a Zenodo record already exists (valid Zenodo DOI in report field), retrieves it.
#' If no valid Zenodo DOI exists, creates a new record and updates codecheck.yml:
#' - If report field is empty or contains a placeholder (FIXME, TODO, etc.): Updates automatically
#' - If report field contains a non-placeholder value: Asks user before overwriting (when warn=TRUE)
#'
#' @title Create or retrieve Zenodo record and update codecheck.yml
#' @param zen Object from zen4R to interact with Zenodo
#' @param metadata codecheck.yml metadata (list). Defaults to loading from
#'   codecheck.yml in the current working directory using \code{codecheck_metadata(getwd())}.
#' @param warn Logical. If TRUE (default), asks for user confirmation before creating
#'   a new record or overwriting an existing non-placeholder DOI. If FALSE, skips
#'   interactive prompts (useful for non-interactive contexts).
#' @param yml_file Path to the codecheck.yml file to update. Defaults to "codecheck.yml"
#'   in the current directory.
#' @return Zenodo record object (ZenodoRecord)
#' @author Stephen Eglen
#' @importFrom zen4R ZenodoRecord
#' @importFrom utils askYesNo
#' @importFrom yaml read_yaml write_yaml
#'
#' @export
get_or_create_zenodo_record <- function(zen, metadata = codecheck_metadata(getwd()), warn=TRUE, yml_file = "codecheck.yml") {
  id <- get_zenodo_id(metadata$report)

  if (!is.na(id)) {
    # Record exists, retrieve it
    my_rec <- zen$getDepositionById(id)
  } else {
    # No valid Zenodo ID, need to create a new record
    if(warn) {
      proceed <- askYesNo("You do not have a Zenodo record yet; I can create one and update your codecheck.yml file. Proceed?")
      if (!isTRUE(proceed)) {
        stop("User cancelled record creation", call. = FALSE)
      }
    }

    # Create new record
    my_rec <- zen$createEmptyRecord()

    # Get the prereserved DOI from the new record
    if (!is.null(my_rec$metadata$prereserve_doi$doi)) {
      new_doi <- my_rec$metadata$prereserve_doi$doi
      new_doi_url <- paste0("https://doi.org/", new_doi)

      # Determine if we should update the YAML file
      should_update <- FALSE
      current_report <- metadata$report

      # Check if current report is empty, NULL, or a placeholder using shared helper
      if (is_doi_placeholder(current_report)) {
        # Empty or placeholder - safe to update
        should_update <- TRUE
        is_empty <- is.null(current_report) || current_report == ""
        message("Current report field is ", if(is_empty) "empty" else "a placeholder",
                ". Updating with new Zenodo DOI: ", new_doi_url)
      } else {
        # Has a value that's not a placeholder - ask user
        if (warn) {
          cat("Current report field value: ", current_report, "\n")
          cat("New Zenodo DOI: ", new_doi_url, "\n")
          overwrite <- askYesNo("The report field already contains a value. Overwrite with new Zenodo DOI?")
          should_update <- isTRUE(overwrite)
        } else {
          # Not in interactive mode, don't overwrite
          warning("Report field already contains a non-placeholder value. Not updating automatically. ",
                  "Please manually update codecheck.yml with: ", new_doi_url)
          should_update <- FALSE
        }
      }

      # Update the YAML file if we should
      if (should_update) {
        # Find the YAML file
        yml_path <- yml_file
        if (!file.exists(yml_path)) {
          # Try in current directory
          yml_path <- file.path(getwd(), yml_file)
        }

        if (file.exists(yml_path)) {
          tryCatch({
            # Read current YAML
            yaml_data <- yaml::read_yaml(yml_path)

            # Update report field
            yaml_data$report <- new_doi_url

            # Write back to file
            yaml::write_yaml(yaml_data, yml_path)

            message("✓ Updated codecheck.yml with Zenodo DOI: ", new_doi_url)
            message("  Remember to reload metadata after this change if needed")
          }, error = function(e) {
            warning("Could not update codecheck.yml: ", e$message,
                   "\nPlease manually add this DOI to the report field: ", new_doi_url)
          })
        } else {
          warning("Could not find codecheck.yml file at: ", yml_path,
                 "\nPlease manually add this DOI to the report field: ", new_doi_url)
        }
      }
    } else {
      warning("New Zenodo record was created but prereserved DOI is not available. ",
              "Please check the record online and manually update codecheck.yml")
    }
  }

  my_rec
}


##   myrec <- zen$createEmptyRecord()
##   this_doi = myrec$metadata$prereserve_doi$doi
##   cat("The following URL is your Zenodo DOI.\n")
##   cat("Please add this to codecheck.yml in report: field\n")
##   print(paste0(CONFIG$HYPERLINKS[["doi"]], this_doi))
##   cat("Remember to reload the yaml file after editing it.\n")
##   get_zenodo_record(this_doi)
## }




##' Extract the Zenodo record number from the report URL
##'
##' The report paramater should contain a URL like:
##' http://doi.org/10.5281/zenodo.3750741 where the final part of the
##' URL is zenodo.X where X is a number containing at least 7 digits.
##' X is returned.  If we cannot extract the number X, we return an
##' error, in which case the function create_zenodo_record() can be
##' run to create a new record.  Alternatively, the report URL is
##' pre-assigned a DOI when manually creating the record.
##'
##' @title Extract the Zenodo record number from the report URL
##' @param report - string containing the report URL on Zenodo.
##' @return the Zenodo record number (a number with at least 7 digits).
##' @author Stephen Eglen
##' @importFrom stringr str_match
##' @export
get_zenodo_id <- function(report) {
  result = str_match(report, "10\\.5281/zenodo\\.([0-9]{7,})")[2]
  as.integer(result)
}

#' Get the full Zenodo record from the metadata
#'
#' Retrieve the Zenodo record, if one exists. By default, loads metadata from
#' codecheck.yml in the current working directory.
#' If no record number is currently listed in the metadata (i.e. the "FIXME" tag is still there)
#' then the code returns NULL and an empty record should be created.
#' @title Get the full zenodo record using the record number stored in the metadata.
#' @param zenodo An object from zen4R to connect with Zenodo
#' @param metadata A codecheck configuration (list). Defaults to loading from
#'   codecheck.yml in the current working directory using \code{codecheck_metadata(getwd())}.
#' @return The Zenodo record, or NULL.
#' @author Stephen Eglen
#' @export
get_zenodo_record <- function(zenodo, metadata = codecheck_metadata(getwd())) {
  id <- get_zenodo_id(metadata$report)
  if (is.na(id)) {
    NULL
  } else {
    zenodo$getDepositionById(id)
  }
}

#' Upload codecheck metadata to Zenodo.
#'
#' The contents of codecheck.yml are uploaded to Zenodo using this function.
#' By default, loads metadata from codecheck.yml in the current working directory.
#'
#' This function complies with the CODECHECK Zenodo community curation policy:
#' https://zenodo.org/communities/codecheck/curation-policy
#'
#' Requirements:
#' - Description must include the certificate summary
#' - Publisher must be "CODECHECK Community on Zenodo"
#' - Resource type must be "publication-report"
#' - Related identifiers for paper (reviews) and repository (isSupplementedBy)
#' - Alternate identifiers for certificate ID (URL and Other schemas)
#'
#' @title Upload metadata to Zenodo
#' @param zenodo object from zen4R to connect with Zenodo
#' @param myrec a Zenodo record object
#' @param metadata codecheck metadata (list). Defaults to loading from
#'   codecheck.yml in the current working directory using \code{codecheck_metadata(getwd())}.
#' @param resource_types named list to override default resource types for related identifiers.
#'   Supported names: "paper" (default: "publication-article"), "repository" (default: auto-detected).
#'   Example: \code{list(paper = "publication-preprint")}
#' @return rec -- the updated record.
#' @author Stephen Eglen
#' @export
upload_zenodo_metadata <- function(zenodo, myrec, metadata = codecheck_metadata(getwd()),
                                   resource_types = list()) {

  # Validate required fields
  if (is.null(metadata$certificate) || metadata$certificate == "") {
    stop("Certificate ID is required but missing from metadata")
  }

  if (is.null(metadata$summary) || metadata$summary == "") {
    warning("Certificate summary is missing. The Zenodo curation policy requires a summary in the description.")
  }

  # Helper function to detect repository type
  detect_repo_type <- function(url) {
    if (is.null(url) || !is.character(url) || nchar(url) == 0) {
      return(list(type = NULL, confidence = "unknown"))
    }

    url_lower <- tolower(url)

    # Check for code repository platforms
    code_platforms <- c("github.com", "gitlab.com", "codeberg.org", "bitbucket.org",
                       "git.sr.ht", "gitea.com", "gitee.com")
    for (platform in code_platforms) {
      if (grepl(platform, url_lower, fixed = TRUE)) {
        return(list(type = "software", confidence = "high"))
      }
    }

    # Check for DataCite DOI (datasets)
    if (grepl("^(https?://)?doi\\.org/10\\.", url_lower) || grepl("^10\\.", url_lower)) {
      # Try to detect if it's a DataCite DOI
      # DataCite DOIs often (but not always) use specific registrants
      if (grepl("zenodo|figshare|dryad|osf\\.io|dataverse", url_lower)) {
        return(list(type = "dataset", confidence = "medium"))
      }
      # Could be dataset or other, unclear
      return(list(type = "dataset", confidence = "low"))
    }

    # Check for OSF (could be code or data)
    if (grepl("osf\\.io", url_lower)) {
      return(list(type = "software", confidence = "medium"))
    }

    # Unknown
    return(list(type = "software", confidence = "low"))
  }

  # Clear existing metadata and set basic fields
  myrec$metadata <- NULL
  myrec$setTitle(paste("CODECHECK certificate", metadata$certificate))
  myrec$addLanguage(language = "eng")
  myrec$setLicense("cc-by-4.0")

  # Add creators (codecheckers)
  myrec$metadata$creators <- NULL
  num_creators <- length(metadata$codechecker)
  for (i in 1:num_creators) {
    myrec$addCreator(
            name  = metadata$codechecker[[i]]$name,
            orcid = metadata$codechecker[[i]]$ORCID)
  }

  # Set publication date and publisher (POLICY REQUIREMENT)
  myrec$setPublicationDate(substring(metadata$check_time, 1, 10))
  myrec$setPublisher("CODECHECK Community on Zenodo")

  # Set resource type to "publication-report" (POLICY REQUIREMENT)
  # Zenodo expects format: upload_type-publication_type
  myrec$setResourceType("publication-report")

  # Build description with summary (POLICY REQUIREMENT)
  description_parts <- character(0)

  # Add summary if available (required by policy)
  if (!is.null(metadata$summary) && nchar(metadata$summary) > 0) {
    description_parts <- c(description_parts,
                          paste0("<p><strong>Summary:</strong> ", metadata$summary, "</p>"))
  }

  # Add paper title
  description_parts <- c(description_parts,
                        paste0("<p><strong>Paper:</strong> ", metadata$paper$title, "</p>"))

  # Add repository link
  repo_url <- NULL
  if (!is.null(metadata$repository) && length(metadata$repository) > 0) {
    if (is.list(metadata$repository)) {
      repo_url <- metadata$repository[[1]]
    } else if (is.character(metadata$repository) && nchar(metadata$repository) > 0) {
      repo_url <- gsub("[<>]", "", metadata$repository)
    }
  }

  if (!is.null(repo_url) && nchar(repo_url) > 0) {
    description_parts <- c(description_parts,
                          paste0('<p><strong>Repository:</strong> <a href="', repo_url, '">', repo_url, '</a></p>'))
  }

  description_text <- paste(description_parts, collapse = "\n")
  myrec$setDescription(description_text)

  # Set subjects/keywords
  myrec$setSubjects(subjects = c("CODECHECK"))

  # Set notes
  myrec$setNotes(notes = c("See file LICENSE for license of the contained code. The report document codecheck.pdf is published under CC-BY 4.0 International."))

  # Add related identifier for original paper (POLICY REQUIREMENT)
  if (!is.null(metadata$paper$reference) && nchar(metadata$paper$reference) > 0) {
    paper_ref <- metadata$paper$reference

    # Check if reference is a DOI (starts with 10. or contains doi.org)
    is_doi <- grepl("^10\\.", paper_ref) || grepl("doi\\.org", paper_ref)

    if (is_doi) {
      # Extract clean DOI if it's a URL
      if (grepl("doi\\.org", paper_ref)) {
        paper_ref <- sub(".*doi\\.org/", "", paper_ref)
        # Ensure it starts with 10.
        if (!grepl("^10\\.", paper_ref)) {
          paper_ref <- paste0("10.", paper_ref)
        }
      }

      # Add with "reviews" relation as per policy
      # Default resource type: publication-article
      paper_resource_type <- if (!is.null(resource_types$paper)) {
        resource_types$paper
      } else {
        "publication-article"
      }

      tryCatch({
        myrec$addRelatedIdentifier(
          identifier = paper_ref,
          scheme = "doi",
          relation_type = "reviews",
          resource_type = paper_resource_type
        )
        message("Added related identifier for paper: ", paper_ref,
                " (resource_type: ", paper_resource_type, ")")
      }, error = function(e) {
        warning("Could not add related identifier for paper: ", e$message)
      })
    } else {
      message("Paper reference is not a DOI, skipping related identifier: ", paper_ref)
    }
  }

  # Add related identifier for code repository (POLICY REQUIREMENT)
  if (!is.null(repo_url) && nchar(repo_url) > 0) {
    # Determine resource type: use override if provided, otherwise auto-detect
    if (!is.null(resource_types$repository)) {
      repo_resource_type <- resource_types$repository
      repo_confidence <- "user-specified"
    } else {
      detection <- detect_repo_type(repo_url)
      repo_resource_type <- detection$type
      repo_confidence <- detection$confidence
    }

    # Inform user if confidence is low
    if (repo_confidence %in% c("low", "medium")) {
      message("Auto-detected repository resource type as '", repo_resource_type,
              "' with ", repo_confidence, " confidence. ",
              "Please verify this is correct for: ", repo_url)
    }

    tryCatch({
      myrec$addRelatedIdentifier(
        identifier = repo_url,
        scheme = "url",
        relation_type = "issupplementedby",
        resource_type = repo_resource_type
      )
      message("Added related identifier for repository: ", repo_url,
              " (resource_type: ", repo_resource_type, ")")
    }, error = function(e) {
      warning("Could not add related identifier for repository: ", e$message)
    })
  }

  # Add alternate identifiers for certificate ID (POLICY REQUIREMENT)
  # The curation policy requires TWO alternate identifier entries:
  # 1. URL schema: http://cdchck.science/register/certs/<CERT ID>
  # 2. Other schema: cdchck.science/register/certs/<CERT ID>
  cert_id_url <- paste0("http://cdchck.science/register/certs/", metadata$certificate)
  cert_id_other <- paste0("cdchck.science/register/certs/", metadata$certificate)

  tryCatch({
    # Set alternate_identifiers directly in metadata
    # This field expects a list of lists, each with 'scheme' and 'identifier'
    myrec$metadata$alternate_identifiers <- list(
      list(scheme = "url", identifier = cert_id_url),
      list(scheme = "other", identifier = cert_id_other)
    )
    message("Added alternate identifiers for certificate:")
    message("  - URL: ", cert_id_url)
    message("  - Other: ", cert_id_other)
  }, error = function(e) {
    warning("Could not add alternate identifiers for certificate: ", e$message)
  })

  cat(paste0("Check your record online at ",  myrec$links$self_html, "\n"))
  myrec <- zenodo$depositRecord(myrec)

  return(myrec)
}


#' Upload the CODECHECK certificate and optional additional files to Zenodo.
#'
#' Upload the CODECHECK certificate PDF to Zenodo as a draft, along with any
#' additional files. The certificate is always uploaded first to ensure it
#' becomes the preview file for the record. If certificate files already exist
#' on the Zenodo record, the user is prompted whether to delete the existing
#' files and upload the new ones, or abort the operation.
#'
#' @title Upload the CODECHECK certificate and additional files to Zenodo.
#' @param zen - Object from zen4R to interact with Zenodo
#' @param record - string containing the report URL on Zenodo.
#' @param certificate name of the PDF certificate file.
#' @param additional_files character vector of additional file paths to upload
#'   (optional). These files are uploaded after the certificate.
#' @param warn logical; if TRUE (default), prompts user before deleting existing
#'   files. If FALSE, automatically deletes existing files without prompting
#'   (useful for non-interactive/automated contexts).
#' @return list with upload results: certificate result and additional_files results
#' @author Stephen Eglen
#' @importFrom utils askYesNo
#' @export
upload_zenodo_certificate <- function(zen, record, certificate, additional_files = NULL, warn = TRUE) {
  draft <- zen$getDepositionById(record)

  # Verify local certificate file exists
  if (!file.exists(certificate)) {
    stop("Certificate file not found: ", certificate)
  }

  # Verify additional files exist
  if (!is.null(additional_files)) {
    missing_files <- additional_files[!file.exists(additional_files)]
    if (length(missing_files) > 0) {
      stop("Additional file(s) not found: ", paste(missing_files, collapse = ", "))
    }
  }

  # Check if files already exist on the Zenodo record
  existing_files <- draft$files

  if (!is.null(existing_files) && length(existing_files) > 0) {
    # Filter for PDF files (likely certificates)
    pdf_files <- existing_files[grepl("\\.pdf$", sapply(existing_files, function(f) f$filename), ignore.case = TRUE)]

    if (length(pdf_files) > 0) {
      # Certificate file(s) already exist
      if (warn) {
        cat("\nThe following certificate file(s) already exist on this Zenodo record:\n")
        for (f in pdf_files) {
          cat("  - ", f$filename, " (", format(f$filesize / 1024, digits = 2), " KB)\n", sep = "")
        }
        cat("\n")

        delete_and_upload <- askYesNo(
          "Delete existing certificate file(s) and upload the new one?",
          default = FALSE
        )

        if (!isTRUE(delete_and_upload)) {
          message("Upload aborted by user. Existing certificate file(s) were not modified.")
          return(invisible(NULL))
        }
      }

      # Delete existing PDF files
      message("Deleting ", length(pdf_files), " existing certificate file(s)...")
      for (f in pdf_files) {
        tryCatch({
          zen$deleteFile(draft$id, f$filename)
          message("  ✓ Deleted: ", f$filename)
        }, error = function(e) {
          warning("Failed to delete file '", f$filename, "': ", e$message)
        })
      }
    }
  }

  # Upload the certificate first (so it becomes the preview file)
  message("Uploading certificate: ", basename(certificate))
  cert_result <- zen$uploadFile(certificate, draft)
  message("✓ Certificate uploaded successfully (will be used as preview)")

  # Upload additional files if provided
  additional_results <- list()
  if (!is.null(additional_files) && length(additional_files) > 0) {
    message("Uploading ", length(additional_files), " additional file(s)...")
    for (file_path in additional_files) {
      tryCatch({
        file_result <- zen$uploadFile(file_path, draft)
        additional_results[[basename(file_path)]] <- file_result
        message("  ✓ Uploaded: ", basename(file_path))
      }, error = function(e) {
        warning("Failed to upload file '", basename(file_path), "': ", e$message)
        additional_results[[basename(file_path)]] <- NULL
      })
    }
  }

  return(list(
    certificate = cert_result,
    additional_files = if (length(additional_results) > 0) additional_results else NULL
  ))
}

#' @rdname upload_zenodo_certificate
#' @export
set_zenodo_certificate <- upload_zenodo_certificate

## We deliberately do not provide a function to publish the certificate.
## You should go check it yourself.


## Helper functions
add_id_to_yml <- function(id, yml_file) {
  ## Add id to the yaml file.
  data1 <- readLines(yml_file)
  data2 <- gsub(pattern = "zenodo.FIXME$",
                replacement = paste0("zenodo.",id),
                x = data1)
  writeLines(data2, yml_file)
}
