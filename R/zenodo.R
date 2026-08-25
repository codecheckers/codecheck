#' Create a new Zenodo record and automatically update codecheck.yml
#'
#' Run this only once per new codecheck. By default, loads metadata from
#' codecheck.yml in the current working directory.
#'
#' If a Zenodo record already exists (valid Zenodo DOI in report field), retrieves it.
#' If no valid Zenodo DOI exists, creates a new record, submits it to the CODECHECK
#' community on Zenodo, and updates codecheck.yml:
#' - Automatically submits new records to the CODECHECK community (https://zenodo.org/communities/codecheck/)
#' - If report field is empty or contains a placeholder (FIXME, TODO, etc.): Updates automatically
#' - If report field contains a non-placeholder value: Asks user before overwriting (when warn=TRUE)
#'
#' @title Create or retrieve Zenodo record, submit to CODECHECK community, and update codecheck.yml
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

    # Submit to CODECHECK community on Zenodo
    # This creates a review request so the record will be added to the community
    # after publication
    tryCatch({
      message("Submitting record to CODECHECK community on Zenodo...")
      zen$createReviewRequest(my_rec, community = "codecheck")
      zen$submitRecordForReview(my_rec)
      message("\u2713 Record submitted to CODECHECK community for review")
      message("  Once published, the record will be added to: https://zenodo.org/communities/codecheck/")
    }, error = function(e) {
      warning("Could not submit record to CODECHECK community: ", e$message,
              "\nYou can manually submit the published record to the community later.")
    })

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

            message("\u2713 Updated codecheck.yml with Zenodo DOI: ", new_doi_url)
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
  myrec$setTitle(paste("CODECHECK Certificate", metadata$certificate))
  myrec$addLanguage(language = "eng")
  myrec$setLicense("cc-by-4.0")

  # Add creators (codecheckers)
  # zen4R only records a creator as "personal" when BOTH firstname and lastname
  # are given; passing only `name` yields type "organizational", which is wrong
  # for a codechecker. split_person_name() does that split, see below.
  myrec$metadata$creators <- NULL
  num_creators <- length(metadata$codechecker)
  for (i in 1:num_creators) {
    checker <- metadata$codechecker[[i]]
    parts <- split_person_name(checker$name)
    if (is.null(parts$family)) {
      # Single-token name, no sensible split: keep the previous behaviour.
      warning("Could not split codechecker name '", checker$name,
              "' into given and family name, recording it as an organisation. ",
              "Use \"Family, Given\" or \"Given Family\" in codecheck.yml.")
      myrec$addCreator(name = checker$name, orcid = checker$ORCID,
                       affiliations = checker$affiliation)
    } else {
      myrec$addCreator(firstname = parts$given,
                       lastname = parts$family,
                       orcid = checker$ORCID,
                       affiliations = checker$affiliation)
    }
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
      warning("Paper reference is not a DOI: '", paper_ref, "'. The curation ",
              "policy requires a \"reviews\" relation to the checked paper, ",
              "so no policy-compliant related identifier could be added. ",
              "Please set paper$reference in codecheck.yml to the paper DOI.")
    }
  } else {
    warning("No paper reference in the metadata. The curation policy requires ",
            "a \"reviews\" relation to the checked paper; please set ",
            "paper$reference in codecheck.yml.")
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
    # The InvenioRDM record model that Zenodo uses today calls this field
    # "identifiers"; the legacy name "alternate_identifiers" is silently
    # dropped on deposit, which is how certificates ended up published without
    # the certificate ID (see the CODECHECK register issue for 2026-023).
    myrec$metadata$identifiers <- list(
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
#' Upload the CODECHECK certificate PDF to Zenodo as a draft, along with the
#' certificate source file (Rmd or qmd) if found, and any additional files. The
#' certificate is always uploaded first to ensure it becomes the preview file
#' for the record. The source file is automatically detected by looking for a
#' file with the same base name as the certificate but with .Rmd or .qmd extension.
#' If certificate or source files already exist on the Zenodo record, the user is
#' prompted whether to delete the existing files and upload the new ones, or abort
#' the operation. This applies separately to PDF certificates and source files,
#' allowing fine-grained control over what gets replaced.
#'
#' @title Upload the CODECHECK certificate and additional files to Zenodo.
#' @param zenodo - Object from zen4R to interact with Zenodo
#' @param record - either a string/numeric containing the record ID, or a Zenodo
#'   record object. If a record ID is provided, the function will fetch the
#'   record; if a record object is provided, it will be used directly.
#' @param certificate name of the PDF certificate file.
#' @param upload_source logical; if TRUE (default), also uploads the source file
#'   (.Rmd or .qmd) with the same base name as the certificate. The function
#'   first looks for a .Rmd file, then for a .qmd file if no .Rmd is found.
#' @param additional_files character vector of additional file paths to upload
#'   (optional). These files are uploaded after the certificate and source file.
#' @param warn logical; if TRUE (default), prompts user before deleting existing
#'   files. If FALSE, automatically deletes existing files without prompting
#'   (useful for non-interactive/automated contexts).
#' @return list with upload results: certificate result, source result (if uploaded),
#'   and additional_files results
#' @author Stephen Eglen
#' @importFrom utils askYesNo
#' @export
upload_zenodo_certificate <- function(zenodo, record, certificate,
                                       upload_source = TRUE,
                                       additional_files = NULL,
                                       warn = TRUE) {
  # Handle both record ID and record object
  if (inherits(record, c("ZenodoRecord", "list", "environment"))) {
    # Record object provided - use it directly
    draft <- record
  } else {
    # Record ID provided - fetch the record
    draft <- zenodo$getDepositionById(record)
  }

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
          zenodo$deleteFile(draft$id, f$filename)
          message("  \u2713 Deleted: ", f$filename)
        }, error = function(e) {
          warning("Failed to delete file '", f$filename, "': ", e$message)
        })
      }
    }
  }

  # Upload the certificate first (so it becomes the preview file)
  # NOTE: Zenodo uses the first uploaded file as the preview file by default
  message("Uploading certificate: ", basename(certificate))
  cert_result <- zenodo$uploadFile(certificate, draft)
  message("\u2713 Certificate uploaded successfully (will be used as preview)")

  # Upload the source file if requested
  # Automatically detect source file based on certificate filename
  source_result <- NULL
  if (upload_source) {
    # Get the base name without extension from the certificate PDF
    cert_base <- tools::file_path_sans_ext(certificate)

    # Try .Rmd first, then .qmd
    source_file <- NULL
    rmd_path <- paste0(cert_base, ".Rmd")
    qmd_path <- paste0(cert_base, ".qmd")
    if (file.exists(rmd_path)) {
      source_file <- rmd_path
    } else if (file.exists(qmd_path)) {
      source_file <- qmd_path
    }

    if (!is.null(source_file)) {
      # Check if source files already exist on the Zenodo record
      # Need to refresh files list after certificate upload
      draft <- zenodo$getDepositionById(draft$id)
      existing_files <- draft$files

      if (!is.null(existing_files) && length(existing_files) > 0) {
        # Filter for .Rmd and .qmd files
        source_files <- existing_files[grepl("\\.(Rmd|qmd)$", sapply(existing_files, function(f) f$filename), ignore.case = TRUE)]

        if (length(source_files) > 0) {
          # Source file(s) already exist
          if (warn) {
            cat("\nThe following source file(s) already exist on this Zenodo record:\n")
            for (f in source_files) {
              cat("  - ", f$filename, " (", format(f$filesize / 1024, digits = 2), " KB)\n", sep = "")
            }
            cat("\n")

            delete_and_upload_source <- askYesNo(
              "Delete existing source file(s) and upload the new one?",
              default = FALSE
            )

            if (!isTRUE(delete_and_upload_source)) {
              message("Source file upload skipped by user. Existing source file(s) were not modified.")
              source_file <- NULL  # Skip upload
            }
          }

          # Delete existing source files if we're proceeding
          if (!is.null(source_file)) {
            message("Deleting ", length(source_files), " existing source file(s)...")
            for (f in source_files) {
              tryCatch({
                zenodo$deleteFile(draft$id, f$filename)
                message("  \u2713 Deleted: ", f$filename)
              }, error = function(e) {
                warning("Failed to delete source file '", f$filename, "': ", e$message)
              })
            }
          }
        }
      }

      # Upload the new source file if not skipped
      if (!is.null(source_file)) {
        message("Uploading certificate source: ", basename(source_file))
        tryCatch({
          source_result <- zenodo$uploadFile(source_file, draft)
          message("\u2713 Certificate source uploaded successfully")
        }, error = function(e) {
          warning("Failed to upload source file '", source_file, "': ", e$message)
        })
      }
    } else {
      message("Note: No source file (.Rmd or .qmd) found for certificate, skipping upload")
    }
  }

  # Upload additional files if provided
  additional_results <- list()
  if (!is.null(additional_files) && length(additional_files) > 0) {
    message("Uploading ", length(additional_files), " additional file(s)...")
    for (file_path in additional_files) {
      tryCatch({
        file_result <- zenodo$uploadFile(file_path, draft)
        additional_results[[basename(file_path)]] <- file_result
        message("  \u2713 Uploaded: ", basename(file_path))
      }, error = function(e) {
        warning("Failed to upload file '", basename(file_path), "': ", e$message)
        additional_results[[basename(file_path)]] <- NULL
      })
    }
  }

  return(list(
    certificate = cert_result,
    source = source_result,
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


#' Split a person name into given and family name
#'
#' Accepts both "Family, Given" and "Given Middle Family" spellings, which are
#' both in use in the `codechecker` entries of `codecheck.yml` files. When no
#' sensible split is possible (a single token, e.g. a group name), `family` is
#' NULL and the caller should fall back to recording an organisation.
#'
#' @title Split a person name into given and family name
#' @param name a single character string
#' @return list with elements `given` and `family`; `family` is NULL if the name
#'   could not be split.
#' @author Daniel Nuest
#' @export
split_person_name <- function(name) {
  if (is.null(name) || !is.character(name) || nchar(trimws(name)) == 0) {
    return(list(given = NULL, family = NULL))
  }
  name <- trimws(name)

  if (grepl(",", name, fixed = TRUE)) {
    parts <- trimws(strsplit(name, ",", fixed = TRUE)[[1]])
    parts <- parts[nchar(parts) > 0]
    if (length(parts) >= 2) {
      return(list(given = paste(parts[-1], collapse = ", "), family = parts[1]))
    }
    return(list(given = NULL, family = NULL))
  }

  tokens <- strsplit(name, "\\s+")[[1]]
  tokens <- tokens[nchar(tokens) > 0]
  if (length(tokens) < 2) {
    return(list(given = NULL, family = NULL))
  }
  list(given = paste(tokens[-length(tokens)], collapse = " "),
       family = tokens[length(tokens)])
}


#' Check Zenodo record metadata against the CODECHECK curation policy
#'
#' Pure function: it evaluates a record's metadata against the CODECHECK
#' community curation policy, see
#' <https://zenodo.org/communities/codecheck/curation-policy>, and does not
#' touch the network. Pass the `metadata` element of a record as returned by the
#' Zenodo InvenioRDM API (`https://zenodo.org/api/records/<ID>` with the
#' `application/vnd.inveniordm.v1+json` representation) or of a `ZenodoRecord`.
#'
#' @title Check Zenodo record metadata against the CODECHECK curation policy
#' @param record_metadata list of record metadata
#' @param files character vector of file names in the deposit, optional; needed
#'   for the checks on the certificate PDF and the machine-readable source.
#' @return a data.frame with columns `check`, `status` (one of "pass", "warn",
#'   "fail") and `detail`, one row per policy requirement.
#' @author Daniel Nuest
#' @export
zenodo_policy_check <- function(record_metadata, files = NULL) {
  results <- list()
  add <- function(check, status, detail) {
    results[[length(results) + 1]] <<- data.frame(
      check = check, status = status, detail = detail, stringsAsFactors = FALSE)
  }

  m <- record_metadata

  # Title
  title <- if (is.character(m$title)) m$title else ""
  if (grepl("CODECHECK Certificate", title, fixed = TRUE)) {
    add("title", "pass", title)
  } else if (grepl("CODECHECK certificate", title, fixed = TRUE)) {
    add("title", "warn",
        paste0("'", title, "' - policy spells it \"CODECHECK Certificate\""))
  } else {
    add("title", "fail",
        paste0("'", title, "' - must contain \"CODECHECK Certificate\" and the certificate ID"))
  }

  # Description with summary
  desc <- if (is.character(m$description)) m$description else ""
  add("description", if (nchar(desc) > 0) "pass" else "fail",
      if (nchar(desc) > 0) "present, must contain the certificate summary"
      else "missing, must contain the certificate summary")

  # License
  rights_ids <- unlist(lapply(m$rights, function(r) r$id))
  license_id <- if (!is.null(m$license$id)) m$license$id else rights_ids[1]
  if (isTRUE(grepl("^cc-by", license_id))) {
    add("license", "pass", license_id)
  } else if (isTRUE(grepl("^cc", license_id))) {
    add("license", "warn", paste0(license_id, " - CC-BY is preferred"))
  } else {
    add("license", "fail", paste0(if (is.null(license_id)) "missing" else license_id,
                                  " - should be a CC license, preferably CC-BY"))
  }

  # Resource type
  rt <- if (!is.null(m$resource_type$id)) m$resource_type$id else
    paste0(m$resource_type$type, "-", m$resource_type$subtype)
  add("resource type", if (identical(rt, "publication-report")) "pass" else "fail",
      paste0(rt, if (!identical(rt, "publication-report")) " - should be publication-report" else ""))

  # Publisher
  pub <- m$publisher
  add("publisher",
      if (identical(pub, "CODECHECK Community on Zenodo")) "pass" else "fail",
      paste0(if (is.null(pub)) "missing" else pub,
             if (!identical(pub, "CODECHECK Community on Zenodo"))
               " - should be 'CODECHECK Community on Zenodo'" else ""))

  # Language
  # exact matching: m$language would partially match m$languages
  langs <- c(unlist(lapply(m$languages, function(l) l$id)), m[["language"]])
  add("language", if (length(langs) > 0) "pass" else "fail",
      if (length(langs) > 0) paste(langs, collapse = ", ") else "not set")

  # Keywords / subjects
  subjects <- c(unlist(lapply(m$subjects, function(s) s$subject)), m[["keywords"]])
  add("keywords", if (length(subjects) > 0) "pass" else "warn",
      if (length(subjects) > 0) paste(subjects, collapse = ", ") else "none set")

  # Creators recorded as persons
  creator_types <- unlist(lapply(m$creators, function(c) c$person_or_org$type))
  if (length(creator_types) == 0) {
    add("creators", "fail", "no creators")
  } else if (all(creator_types == "personal")) {
    add("creators", "pass", paste(unlist(lapply(m$creators, function(c) c$person_or_org$name)),
                                  collapse = "; "))
  } else {
    orgs <- unlist(lapply(m$creators, function(c) {
      if (identical(c$person_or_org$type, "organizational")) c$person_or_org$name else NULL
    }))
    add("creators", "fail",
        paste0("recorded as organisation, should be a person: ", paste(orgs, collapse = "; ")))
  }

  # Related identifier: reviews -> paper
  relations <- unlist(lapply(m$related_identifiers, function(r) {
    if (!is.null(r$relation_type$id)) r$relation_type$id else r$relation
  }))
  reviews_idx <- which(tolower(relations) == "reviews")
  if (length(reviews_idx) > 0) {
    add("related work: paper", "pass",
        paste0("reviews ", m$related_identifiers[[reviews_idx[1]]]$identifier))
  } else {
    add("related work: paper", "fail",
        "no relation of type \"reviews\" to the checked paper")
  }

  # Related identifier: repository
  repo_relations <- c("issupplementedby", "isderivedfrom", "iscompiledby", "issupplementto")
  repo_idx <- which(tolower(relations) %in% repo_relations)
  if (length(repo_idx) > 0) {
    repo_ids <- unlist(lapply(m$related_identifiers[repo_idx], function(r) r$identifier))
    in_org <- any(grepl("github.com/codecheckers|gitlab.com/cdchck", repo_ids))
    add("related work: repository", if (in_org) "pass" else "warn",
        paste0(paste(repo_ids, collapse = "; "),
               if (!in_org) " - policy asks for a repository in codecheckers/ or cdchck" else ""))
  } else {
    add("related work: repository", "fail", "no relation to a code/data repository")
  }

  # Alternate identifiers (InvenioRDM: metadata$identifiers)
  alt <- m$identifiers
  if (is.null(alt)) alt <- m$alternate_identifiers
  alt_by_scheme <- function(scheme) {
    ids <- unlist(lapply(alt, function(a) if (tolower(a$scheme) == scheme) a$identifier else NULL))
    ids
  }
  url_ids <- alt_by_scheme("url")
  other_ids <- alt_by_scheme("other")
  add("alternate identifier (url)",
      if (any(grepl("cdchck.science/register/certs/", url_ids))) "pass" else "fail",
      if (length(url_ids) > 0) paste(url_ids, collapse = "; ")
      else "missing, expected http://cdchck.science/register/certs/<CERT ID>")
  add("alternate identifier (other)",
      if (any(grepl("cdchck.science/register/certs/", other_ids))) "pass" else "fail",
      if (length(other_ids) > 0) paste(other_ids, collapse = "; ")
      else "missing, expected cdchck.science/register/certs/<CERT ID>")

  # Files
  if (!is.null(files)) {
    pdfs <- files[grepl("\\.pdf$", files, ignore.case = TRUE)]
    add("certificate PDF", if (length(pdfs) > 0) "pass" else "fail",
        if (length(pdfs) > 0) paste(pdfs, collapse = "; ") else "no PDF in the deposit")
    sources <- files[grepl("\\.(Rmd|qmd|docx|odt|md|tex)$", files, ignore.case = TRUE)]
    add("machine-readable certificate", if (length(sources) > 0) "pass" else "warn",
        if (length(sources) > 0) paste(sources, collapse = "; ")
        else "deposit should include the certificate source, e.g. codecheck.Rmd")
  }

  do.call(rbind, results)
}


#' Resolve a certificate ID or Zenodo record reference to a Zenodo record ID
#'
#' Accepts a Zenodo record ID, a Zenodo DOI, or a CODECHECK certificate ID. A
#' certificate ID is resolved via `register.csv` in `register_dir` to the
#' repository spec, and from there via the repository's `codecheck.yml` `report`
#' field to the Zenodo record.
#'
#' @title Resolve a certificate ID or Zenodo reference to a Zenodo record ID
#' @param x certificate ID (e.g. "2026-023"), Zenodo record ID, or Zenodo DOI
#' @param register_dir directory holding `register.csv`, defaults to the working
#'   directory
#' @return the Zenodo record ID as integer
#' @author Daniel Nuest
#' @export
resolve_zenodo_record_id <- function(x, register_dir = getwd()) {
  x <- as.character(x)

  # Zenodo DOI
  id <- get_zenodo_id(x)
  if (!is.na(id)) return(id)

  # plain record ID
  if (grepl("^[0-9]{7,}$", x)) return(as.integer(x))

  # certificate ID
  if (!grepl("^[0-9]{4}-[0-9]{3}$", x)) {
    stop("Cannot interpret '", x, "' as a certificate ID, Zenodo record ID or Zenodo DOI")
  }

  register_file <- file.path(register_dir, "register.csv")
  if (!file.exists(register_file)) {
    stop("Need register.csv in '", register_dir, "' to resolve certificate ", x)
  }
  register <- utils::read.csv(register_file, as.is = TRUE, comment.char = "#")
  row <- register[register$Certificate == x, ]
  if (nrow(row) == 0) {
    stop("Certificate ", x, " is not in ", register_file)
  }

  config <- get_codecheck_yml(row$Repository[1])
  if (is.null(config) || is.null(config$report)) {
    stop("No 'report' field in the codecheck.yml of ", row$Repository[1])
  }
  id <- get_zenodo_id(config$report)
  if (is.na(id)) {
    stop("The report field of ", row$Repository[1], " is not a Zenodo DOI: ", config$report)
  }
  id
}


#' Audit a published Zenodo record against the CODECHECK curation policy
#'
#' Read-only: fetches the record and reports which requirements of the CODECHECK
#' community curation policy it meets, see
#' <https://zenodo.org/communities/codecheck/curation-policy>.
#'
#' @title Audit a Zenodo record against the CODECHECK curation policy
#' @param record certificate ID, Zenodo record ID, or Zenodo DOI
#' @param register_dir directory holding `register.csv`, used to resolve a
#'   certificate ID, defaults to the working directory
#' @return invisibly, the data.frame returned by [zenodo_policy_check()]
#' @author Daniel Nuest
#' @importFrom cli cli_alert_success cli_alert_warning cli_alert_danger cli_h1
#' @export
check_zenodo_record <- function(record, register_dir = getwd()) {
  id <- resolve_zenodo_record_id(record, register_dir = register_dir)
  rec <- get_zenodo_record_metadata(id)

  cli::cli_h1(paste0("Zenodo record ", id, " vs. CODECHECK curation policy"))
  result <- zenodo_policy_check(rec$metadata, files = rec$files)

  for (i in seq_len(nrow(result))) {
    line <- paste0(result$check[i], ": ", result$detail[i])
    switch(result$status[i],
           pass = cli::cli_alert_success(line),
           warn = cli::cli_alert_warning(line),
           fail = cli::cli_alert_danger(line))
  }

  fails <- sum(result$status == "fail")
  warns <- sum(result$status == "warn")
  if (fails == 0 && warns == 0) {
    cli::cli_alert_success("Record complies with the curation policy.")
  } else {
    cli::cli_alert_info(paste0(fails, " requirement(s) not met, ", warns, " warning(s). ",
                               "Run curate_zenodo_record() to see the proposed fixes."))
  }

  invisible(result)
}


#' Fetch the metadata of a published Zenodo record
#'
#' Uses the InvenioRDM representation of the Zenodo REST API, which is the one
#' the curation policy checks apply to. No authentication needed for open
#' records.
#'
#' @title Fetch metadata of a published Zenodo record
#' @param id Zenodo record ID
#' @param sandbox use the Zenodo sandbox instance
#' @return list with elements `metadata` and `files` (file names)
#' @author Daniel Nuest
#' @importFrom httr GET add_headers content stop_for_status
#' @export
get_zenodo_record_metadata <- function(id, sandbox = FALSE) {
  host <- if (sandbox) "https://sandbox.zenodo.org" else "https://zenodo.org"
  response <- httr::GET(
    paste0(host, "/api/records/", id),
    httr::add_headers(Accept = "application/vnd.inveniordm.v1+json"))
  httr::stop_for_status(response)
  record <- httr::content(response, as = "parsed", type = "application/json")

  files <- names(record$files$entries)
  if (is.null(files) && !is.null(record$files)) {
    files <- unlist(lapply(record$files, function(f) f$key))
  }

  list(metadata = record$metadata, files = files, record = record)
}


#' Curate a published Zenodo record to comply with the CODECHECK curation policy
#'
#' Computes the metadata corrections needed to bring a published certificate
#' record in line with the CODECHECK community curation policy, prints them, and
#' - only with `dry_run = FALSE` - applies them by editing the published record
#' and publishing the metadata update. No new file version is created.
#'
#' The target values come from the `codecheck.yml` of the checked repository,
#' which is the source of truth for certificate ID, paper reference and
#' codechecker names.
#'
#' Requires a Zenodo token with write access, see `zen4R::ZenodoManager`.
#'
#' @title Curate a published Zenodo record per the CODECHECK curation policy
#' @param record certificate ID, Zenodo record ID, or Zenodo DOI
#' @param zenodo a `zen4R` ZenodoManager; only needed when `dry_run = FALSE`.
#'   Defaults to a manager built from the `ZENODO_TOKEN` environment variable.
#' @param metadata codecheck metadata (list); defaults to the `codecheck.yml` of
#'   the repository registered for the certificate
#' @param register_dir directory holding `register.csv`, defaults to the working
#'   directory
#' @param dry_run if TRUE (the default) only report what would change
#' @param record_metadata the current record metadata as returned by
#'   [get_zenodo_record_metadata()]; fetched from Zenodo when NULL (the default).
#'   Mainly useful for testing and for auditing a record offline.
#' @return invisibly, a list of the proposed changes
#' @author Daniel Nuest
#' @importFrom cli cli_h1 cli_alert_info cli_alert_success cli_alert_warning
#' @export
curate_zenodo_record <- function(record,
                                 zenodo = NULL,
                                 metadata = NULL,
                                 register_dir = getwd(),
                                 dry_run = TRUE,
                                 record_metadata = NULL) {
  if (is.null(record_metadata)) {
    id <- resolve_zenodo_record_id(record, register_dir = register_dir)
    record_metadata <- get_zenodo_record_metadata(id)
  } else {
    id <- record
  }
  cm <- record_metadata$metadata

  if (is.null(metadata)) {
    register_file <- file.path(register_dir, "register.csv")
    if (grepl("^[0-9]{4}-[0-9]{3}$", as.character(record)) && file.exists(register_file)) {
      register <- utils::read.csv(register_file, as.is = TRUE, comment.char = "#")
      row <- register[register$Certificate == as.character(record), ]
      metadata <- get_codecheck_yml(row$Repository[1])
    } else {
      stop("Provide `metadata` (the codecheck.yml contents) when `record` is not a certificate ID")
    }
  }

  cert <- metadata$certificate
  changes <- list()

  # Title
  target_title <- paste("CODECHECK Certificate", cert)
  if (!identical(cm$title, target_title)) {
    changes$title <- list(from = cm$title, to = target_title)
  }

  # Creators recorded as organisations
  creator_targets <- list()
  for (i in seq_along(cm$creators)) {
    poo <- cm$creators[[i]]$person_or_org
    if (identical(poo$type, "organizational")) {
      parts <- split_person_name(poo$name)
      if (!is.null(parts$family)) {
        creator_targets[[length(creator_targets) + 1]] <- list(
          index = i,
          from = paste0("organizational: ", poo$name),
          to = paste0("personal: ", parts$family, ", ", parts$given),
          given = parts$given, family = parts$family,
          orcid = unlist(lapply(poo$identifiers, function(x)
            if (identical(x$scheme, "orcid")) x$identifier else NULL))[1]
        )
      }
    }
  }
  if (length(creator_targets) > 0) changes$creators <- creator_targets

  # "reviews" relation to the paper
  relations <- unlist(lapply(cm$related_identifiers, function(r) {
    if (!is.null(r$relation_type$id)) r$relation_type$id else r$relation
  }))
  if (!any(tolower(relations) == "reviews")) {
    paper_ref <- metadata$paper$reference
    if (!is.null(paper_ref) && grepl("doi\\.org|^10\\.", paper_ref)) {
      paper_doi <- sub(".*doi\\.org/", "", paper_ref)
      changes$reviews <- list(
        from = "missing",
        to = paste0("reviews ", paper_doi),
        identifier = paper_doi,
        resource_type = if (grepl("10\\.1101/|arxiv|biorxiv|osf\\.io", tolower(paper_ref)))
          "publication-preprint" else "publication-article")
    } else {
      cli::cli_alert_warning(paste0(
        "Cannot add the required \"reviews\" relation: paper$reference in ",
        "codecheck.yml is not a DOI ('", paper_ref, "')"))
    }
  }

  # Alternate identifiers
  alt <- cm$identifiers
  has_scheme <- function(scheme) {
    any(unlist(lapply(alt, function(a)
      tolower(a$scheme) == scheme && grepl("cdchck.science/register/certs/", a$identifier))))
  }
  if (!has_scheme("url") || !has_scheme("other")) {
    changes$identifiers <- list(
      from = if (length(alt) == 0) "missing" else
        paste(unlist(lapply(alt, function(a) a$identifier)), collapse = "; "),
      to = paste0("http://cdchck.science/register/certs/", cert,
                  " (url); cdchck.science/register/certs/", cert, " (other)"),
      url = paste0("http://cdchck.science/register/certs/", cert),
      other = paste0("cdchck.science/register/certs/", cert))
  }

  cli::cli_h1(paste0("Curation of Zenodo record ", id, " (certificate ", cert, ")"))
  if (length(changes) == 0) {
    cli::cli_alert_success("Nothing to change, the record follows the curation policy.")
    return(invisible(changes))
  }

  for (name in names(changes)) {
    if (name == "creators") {
      for (ct in changes$creators) {
        cli::cli_alert_info(paste0("creators[", ct$index, "]: ", ct$from, "  ->  ", ct$to))
      }
    } else {
      cli::cli_alert_info(paste0(name, ": ", changes[[name]]$from, "  ->  ", changes[[name]]$to))
    }
  }

  if (dry_run) {
    cli::cli_alert_warning("Dry run, nothing was written. Call with dry_run = FALSE to apply.")
    return(invisible(changes))
  }

  if (is.null(zenodo)) {
    token <- Sys.getenv("ZENODO_TOKEN")
    if (nchar(token) == 0) {
      stop("No Zenodo token: set the ZENODO_TOKEN environment variable or pass `zenodo`")
    }
    zenodo <- zen4R::ZenodoManager$new(token = token, logger = "INFO")
  }

  cli::cli_alert_info("Opening the published record for editing ...")
  draft <- zenodo$editRecord(id)

  if (!is.null(changes$title)) {
    draft$setTitle(changes$title$to)
  }

  if (!is.null(changes$creators)) {
    # rebuild the whole creator list, keeping creators that are already correct
    keep <- draft$metadata$creators
    draft$metadata$creators <- NULL
    for (i in seq_along(keep)) {
      fix <- Filter(function(ct) ct$index == i, changes$creators)
      if (length(fix) == 1) {
        draft$addCreator(firstname = fix[[1]]$given,
                         lastname = fix[[1]]$family,
                         orcid = fix[[1]]$orcid)
      } else {
        draft$metadata$creators[[length(draft$metadata$creators) + 1]] <- keep[[i]]
      }
    }
  }

  if (!is.null(changes$reviews)) {
    draft$addRelatedIdentifier(identifier = changes$reviews$identifier,
                               scheme = "doi",
                               relation_type = "reviews",
                               resource_type = changes$reviews$resource_type)
  }

  if (!is.null(changes$identifiers)) {
    draft$metadata$identifiers <- list(
      list(scheme = "url", identifier = changes$identifiers$url),
      list(scheme = "other", identifier = changes$identifiers$other))
  }

  draft <- zenodo$depositRecord(draft)
  published <- zenodo$publishRecord(draft$id)
  cli::cli_alert_success(paste0("Published metadata update: ", published$links$self_html))

  invisible(changes)
}
