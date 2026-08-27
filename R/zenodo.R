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

# Pace real Zenodo API calls to stay under its rate limit.
#
# Zenodo's search endpoint (used by getRecordByConceptId(), which both
# is_zenodo_concept_doi() and is_zenodo_latest_version() call below) enforces
# a much stricter limit than the general API - observed empirically as 30
# requests per minute, i.e. one every 2 seconds - rather than the 60/minute
# documented for the API as a whole (see the comment on
# CONFIG$CERT_REQUEST_DELAY in config.R). A register_check() run walks every
# register entry and calls these two functions for each one, so without
# pacing it trips the limit within the first few dozen entries and the whole
# run aborts (register_check() treats a lookup failure here as fatal, not a
# warning). Sleeps only when the last real call was too recent; a fresh R
# session's first call never waits. Not exported: internal to this file.
.zenodo_last_call_time <- new.env(parent = emptyenv())
zenodo_throttle <- function(min_interval = 2.1) {
  last <- .zenodo_last_call_time$t
  if (!is.null(last)) {
    elapsed <- as.numeric(Sys.time() - last, units = "secs")
    if (elapsed < min_interval) {
      Sys.sleep(min_interval - elapsed)
    }
  }
  .zenodo_last_call_time$t <- Sys.time()
  invisible(NULL)
}

# Reuse one ZenodoManager per (url, token presence) for the life of the R
# session, instead of creating a fresh one on every call.
#
# ZenodoManager$new() with a token calls checkUserAuthentication(), an extra
# request against the same rate-limited endpoint; is_zenodo_concept_doi() and
# is_zenodo_latest_version() each created their own manager, so every entry
# paid for two of these on top of the three lookups zenodo_throttle() already
# paces - enough to trip the 30/minute limit even with pacing in place. Not
# exported: internal to this file.
.zenodo_manager_cache <- new.env(parent = emptyenv())
get_shared_zenodo_manager <- function(sandbox = FALSE, logger = NULL) {
  token <- Sys.getenv("ZENODO_TOKEN")
  url <- if (sandbox) "https://sandbox.zenodo.org/api" else "https://zenodo.org/api"
  key <- paste(url, nzchar(token))
  cached <- .zenodo_manager_cache[[key]]
  if (is.null(cached)) {
    zenodo_throttle()
    cached <- ZenodoManager$new(
      url = url,
      token = if (nzchar(token)) token else NULL,
      sandbox = sandbox,
      logger = logger
    )
    .zenodo_manager_cache[[key]] <- cached
  }
  cached
}

# Retry a zen4R call that hit Zenodo's rate limit.
#
# zen4R surfaces an HTTP 429 as a ZenodoException return value rather than an
# R error/condition, so retrying on 429 means inspecting the return value
# rather than catching an error. zenodo_throttle() prevents most 429s, but a
# run that shares the rate limit with other traffic (e.g. a concurrent
# `make zenodo_curate` or another process) can still hit one; retrying after
# a wait recovers the run instead of aborting it. Zenodo reports its limits
# as "N per 1 minute", so wait_seconds needs to be close to that window to
# reliably clear it. Not exported: internal to this file.
zenodo_call_retry <- function(call_fn, max_attempts = 3, wait_seconds = 65) {
  result <- call_fn()
  for (attempt in seq_len(max_attempts - 1)) {
    is_rate_limited <- inherits(result, "ZenodoException") &&
      !is.null(result$status) && isTRUE(result$status == 429)
    if (!is_rate_limited) break
    Sys.sleep(wait_seconds)
    result <- call_fn()
  }
  result
}

##' Check whether a report DOI is a Zenodo "concept DOI"
##'
##' Zenodo assigns every versioned deposit two DOIs: a version-specific DOI
##' (which always resolves to that exact version) and a concept DOI (which
##' always resolves to the *latest* version, see
##' https://zenodo.org/help/versioning). A CODECHECK certificate's `report`
##' field should reference the version-specific DOI so that the certificate
##' points at an immutable record; this function detects the mistake of
##' using the concept DOI instead.
##'
##' @title Check whether a report DOI is a Zenodo concept DOI
##' @param report - string containing the report DOI or URL on Zenodo.
##' @param sandbox connect with the Zenodo Sandbox instead of the real service
##' @param zenodo An object from zen4R to connect with Zenodo (or a mock with
##'   a compatible `getRecordByConceptId()` method, for testing). Defaults to
##'   a new `ZenodoManager` connected to the production (or sandbox) service.
##'   When supplied, `logger` is ignored - configure logging on the object
##'   you pass in instead.
##' @param logger zen4R logger level for the default `ZenodoManager` created
##'   when `zenodo` is not supplied: `NULL` (the default) keeps output to the
##'   single `cli` alert zen4R always prints per request; `"INFO"` or
##'   `"DEBUG"` additionally prints zen4R's own `[zen4R][...]` line for every
##'   request (connect, fetch, record count, ...), useful when diagnosing
##'   rate-limiting or unexpected API responses.
##' @return `TRUE` if `report` is a Zenodo concept DOI, `FALSE` if it is a
##'   version-specific DOI or not a (matchable) Zenodo DOI at all.
##' @author Daniel Nuest
##' @importFrom zen4R ZenodoManager
##' @export
is_zenodo_concept_doi <- function(report, sandbox = FALSE, zenodo = NULL, logger = NULL) {
  id <- get_zenodo_id(report)
  if (is.na(id)) {
    return(FALSE)
  }

  # only pace/retry calls made through a ZenodoManager created here: a
  # caller-supplied `zenodo` (real or a test mock) manages its own pacing
  own_zenodo <- is.null(zenodo)
  if (own_zenodo) {
    # An authenticated request gets a much higher Zenodo rate limit than an
    # anonymous one; use ZENODO_TOKEN when set even though this is a read-only
    # lookup that works without a token too. logger defaults to NULL: zen4R's
    # own methods already emit a cli:: alert for each step (connect, fetch,
    # record count, ...); logger = "INFO"/"DEBUG" additionally prints zen4R's
    # own "[zen4R][...]" line for every one of them, so leave it opt-in
    # rather than doubling console output by default.
    zenodo <- get_shared_zenodo_manager(sandbox = sandbox, logger = logger)
  }

  # A concept ID only resolves via getRecordByConceptId(); a version-specific
  # record ID does not (Zenodo doesn't treat a concept ID as a record itself).
  if (own_zenodo) zenodo_throttle()
  record <- zenodo_call_retry(function() zenodo$getRecordByConceptId(id))

  # On a request failure (e.g. HTTP 429 rate limiting), zen4R's
  # getRecordByConceptId() returns a ZenodoException object rather than NULL
  # or a record, so `!is.null(record)` would wrongly read as "is a concept
  # DOI". Surface the failure instead of misclassifying the DOI.
  if (inherits(record, "ZenodoException")) {
    stop("Could not check whether ", report, " is a Zenodo concept DOI: ",
         record$message, call. = FALSE)
  }

  !is.null(record)
}

##' Check whether a report DOI points to the latest version of a Zenodo record
##'
##' A Zenodo deposit can be updated over time by publishing a new version;
##' each version gets its own version-specific DOI (see
##' https://zenodo.org/help/versioning). A CODECHECK certificate's `report`
##' field should always point at the version that was actually checked *and*
##' still be the latest version of that deposit: if a newer version has since
##' been published, the record's metadata is no longer guaranteed to reflect
##' what the certificate checked, so the certificate should either be updated
##' to reference a fresh check of the current version, or the outdated
##' version should be flagged for transparency rather than silently accepted.
##' This is a separate concern from [is_zenodo_concept_doi()]: a concept DOI
##' is the wrong *kind* of identifier (it is never version-specific), while
##' this function checks that a correctly version-specific DOI has not since
##' been superseded by a newer version of the same record.
##'
##' @title Check whether a report DOI is the latest version of its Zenodo record
##' @param report string containing the report DOI or URL on Zenodo.
##' @param sandbox connect with the Zenodo Sandbox instead of the real service
##' @param zenodo An object from zen4R to connect with Zenodo (or a mock with
##'   a compatible `getRecordById()` method, for testing) whose record carries
##'   a `versions` list with an `is_latest` field, matching the real Zenodo
##'   API. Defaults to a new `ZenodoManager` connected to the production (or
##'   sandbox) service. When supplied, `logger` is ignored - configure
##'   logging on the object you pass in instead.
##' @param logger zen4R logger level for the default `ZenodoManager` created
##'   when `zenodo` is not supplied; see [is_zenodo_concept_doi()] for what
##'   `NULL` (default), `"INFO"` and `"DEBUG"` do.
##' @return `TRUE` if `report` is the latest version of its Zenodo record, or
##'   is not a matchable/resolvable Zenodo DOI (nothing to compare against).
##'   `FALSE` if a more recent version of the record exists.
##' @author Daniel Nuest
##' @importFrom zen4R ZenodoManager
##' @export
is_zenodo_latest_version <- function(report, sandbox = FALSE, zenodo = NULL, logger = NULL) {
  id <- get_zenodo_id(report)
  if (is.na(id)) {
    return(TRUE)
  }

  # see the matching comment in is_zenodo_concept_doi() above
  own_zenodo <- is.null(zenodo)
  if (own_zenodo) {
    zenodo <- get_shared_zenodo_manager(sandbox = sandbox, logger = logger)
  }

  if (own_zenodo) zenodo_throttle()
  record <- zenodo_call_retry(function() zenodo$getRecordById(id))
  if (inherits(record, "ZenodoException")) {
    stop("Could not check whether ", report, " is the latest Zenodo version: ",
         record$message, call. = FALSE)
  }
  if (is.null(record) || is.null(record$versions$is_latest)) {
    # id did not resolve to a version-specific record (e.g. it is itself a
    # concept id, which is_zenodo_concept_doi() flags separately, or an
    # invalid/withdrawn id); nothing to compare against. Note: this used to
    # cross-check via a second getRecordByConceptId() call and compare record
    # ids, but that search-based lookup is not reliably ordered by version -
    # it returned a stale, non-latest record for at least one real register
    # entry (2025-004, zenodo.org/records/15527133) even though that record's
    # own `versions$is_latest` correctly said TRUE. The record's own field is
    # both more reliable and one fewer request against the rate-limited
    # search endpoint.
    return(TRUE)
  }

  isTRUE(record$versions$is_latest)
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
#' @param record the full record as returned by the InvenioRDM API (i.e. the
#'   `record` element of [get_zenodo_record_metadata()]'s return value),
#'   optional; needed for the community membership check, see #20. Community
#'   membership lives outside `metadata` (under `parent$communities`), so this
#'   check is only added when `record` is supplied.
#' @return a data.frame with columns `check`, `status` (one of "pass", "warn",
#'   "fail") and `detail`, one row per policy requirement.
#' @author Daniel Nuest
#' @export
zenodo_policy_check <- function(record_metadata, files = NULL, record = NULL) {
  results <- list()
  add <- function(check, status, detail) {
    results[[length(results) + 1]] <<- data.frame(
      check = check, status = status, detail = detail, stringsAsFactors = FALSE)
  }

  m <- record_metadata

  # Title: must contain "CODECHECK Certificate" (correctly spelled) and the
  # certificate ID (e.g. "2026-023"), see #20
  title <- if (is.character(m$title)) m$title else ""
  has_cert_text <- grepl("CODECHECK Certificate", title, fixed = TRUE)
  has_cert_text_lower <- grepl("CODECHECK certificate", title, fixed = TRUE)
  has_cert_id <- grepl("[0-9]{4}-[0-9]{3}", title)
  if (has_cert_text && has_cert_id) {
    add("title", "pass", title)
  } else if (has_cert_text_lower && has_cert_id) {
    add("title", "warn",
        paste0("'", title, "' - policy spells it \"CODECHECK Certificate\""))
  } else if (has_cert_text || has_cert_text_lower) {
    add("title", "fail",
        paste0("'", title, "' - must contain the certificate ID, e.g. \"2026-023\""))
  } else {
    add("title", "fail",
        paste0("'", title, "' - must contain \"CODECHECK Certificate\" and the certificate ID"))
  }

  # Description with summary
  desc <- if (is.character(m$description)) m$description else ""
  add("description", if (nchar(desc) > 0) "pass" else "fail",
      if (nchar(desc) > 0) "present, must contain the certificate summary"
      else "missing, must contain the certificate summary")

  # License. The certificate PDF must be CC-BY 4.0, but a record may carry
  # further licences for other artefacts it contains (code, data, a source
  # archive), so additional entries alongside CC-BY are correct, not a defect.
  rights_ids <- unlist(lapply(m$rights, function(r) r$id))
  if (length(rights_ids) == 0 && !is.null(m$license$id)) rights_ids <- m$license$id
  others <- setdiff(rights_ids, "cc-by-4.0")
  if ("cc-by-4.0" %in% rights_ids) {
    add("license", "pass",
        if (length(others) > 0)
          paste0("cc-by-4.0 (plus ", paste(others, collapse = ", "),
                 " for other artefacts in the deposit)")
        else "cc-by-4.0")
  } else if (length(rights_ids) == 0) {
    add("license", "fail", "missing - the certificate must be CC-BY 4.0")
  } else {
    add("license", "fail",
        paste0(paste(rights_ids, collapse = ", "),
               " - the certificate must be CC-BY 4.0; other licences may be kept ",
               "alongside it for other artefacts in the deposit"))
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

  # Creators recorded as persons. An organisational creator is not a defect the
  # check can assert either way: a workshop's participants recorded as one
  # entry is correct, a person mistakenly recorded as an organisation is not,
  # and record metadata alone cannot tell the two apart. It is reported as
  # "info" rather than "fail", so it never blocks compliance and is surfaced
  # to a human to judge, instead of being asserted as an error.
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
    add("creators", "info",
        paste0("recorded as organisation: ", paste(orgs, collapse = "; "),
               " - correct for a genuine group, otherwise should be a person"))
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
    # the file must be present, and should specifically be named codecheck.pdf
    # (see #20); a differently-named PDF is a warning, not a failure
    if (length(pdfs) == 0) {
      add("certificate PDF", "fail", "no PDF in the deposit")
    } else if (any(tolower(pdfs) == "codecheck.pdf")) {
      add("certificate PDF", "pass", paste(pdfs, collapse = "; "))
    } else {
      add("certificate PDF", "warn",
          paste0(paste(pdfs, collapse = "; "),
                 " - policy expects the certificate PDF to be named codecheck.pdf"))
    }
    sources <- files[grepl("\\.(Rmd|qmd|docx|odt|md|tex)$", files, ignore.case = TRUE)]
    has_rmd <- any(grepl("\\.Rmd$", sources, ignore.case = TRUE))
    has_qmd <- any(grepl("\\.qmd$", sources, ignore.case = TRUE))
    add("machine-readable certificate",
        if (has_rmd && has_qmd) "fail"
        else if (length(sources) > 0) "pass"
        else "warn",
        if (has_rmd && has_qmd)
          paste0(paste(sources, collapse = "; "),
                 " - both codecheck.Rmd and codecheck.qmd present, remove one ",
                 "so the certificate source is unambiguous")
        else if (length(sources) > 0) paste(sources, collapse = "; ")
        else "deposit should include the certificate source, e.g. codecheck.Rmd")
  }

  # Community membership: the deposit must be part of the Zenodo "codecheck"
  # community, see #20. Only checked when the full record is supplied, since
  # this information is not part of `metadata`.
  if (!is.null(record)) {
    community_ids <- unlist(record$parent$communities$ids)
    in_community <- "codecheck" %in% community_ids
    add("community", if (in_community) "pass" else "fail",
        if (in_community) "member of the codecheck community"
        else "not a member of the Zenodo codecheck community (https://zenodo.org/communities/codecheck/)")
  }

  # Latest version: the checked record must be the current version of its
  # Zenodo deposit, not one a newer version has since superseded (see #36).
  # A certificate's report DOI is meant to be an immutable, permanent
  # reference, but "permanent" here means "always the definitive record of
  # what was checked" - if a newer version now exists, the checked metadata
  # is no longer what a reader lands on, and a certificate that still checks
  # out is preferable to one pointing at a stale record. `versions$is_latest`
  # is only present in the InvenioRDM record representation, not in
  # `metadata`, so this is only checked when the full record is supplied.
  if (!is.null(record) && !is.null(record$versions$is_latest)) {
    is_latest <- isTRUE(record$versions$is_latest)
    add("latest version", if (is_latest) "pass" else "fail",
        if (is_latest) "record is the latest version of its deposit"
        else paste0("a newer version of this record exists on Zenodo - the report DOI ",
                     "should point at the latest version, or a new check against the ",
                     "current version is preferable for transparency"))
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
  result <- zenodo_policy_check(rec$metadata, files = rec$files, record = rec$record)

  for (i in seq_len(nrow(result))) {
    line <- paste0(result$check[i], ": ", result$detail[i])
    switch(result$status[i],
           pass = cli::cli_alert_success(line),
           info = cli::cli_alert_info(line),
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
#' records, but an authenticated request gets a much higher Zenodo rate limit,
#' so ZENODO_TOKEN is sent when set.
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
  token <- Sys.getenv("ZENODO_TOKEN")
  headers <- if (nzchar(token)) {
    httr::add_headers(Accept = "application/vnd.inveniordm.v1+json",
                      Authorization = paste("Bearer", token))
  } else {
    httr::add_headers(Accept = "application/vnd.inveniordm.v1+json")
  }
  response <- httr::GET(paste0(host, "/api/records/", id), headers)
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
#' @param creator_overrides named list keyed by the creator name as currently
#'   recorded, controlling how that creator is handled. Use
#'   `list(organizational = TRUE)` to keep an entry as an organisation (correct
#'   for a group such as "Delft 2024-05 participants"), or
#'   `list(given = "Gabriella", family = "Low Chew Tung")` to give an explicit
#'   split where the last-token heuristic of [split_person_name()] is wrong.
#' @param fields which classes of correction to consider. Defaults to all of
#'   "title", "publisher", "language", "resource_type", "identifiers", "reviews",
#'   "repository" and "creators". The first seven are mechanical: their target
#'   value follows from the certificate ID or from `codecheck.yml`. "creators"
#'   is not: splitting a name into given and family name is wrong for group
#'   entries such as "Delft 2024-05 participants", so exclude it from batch runs
#'   and review those records individually.
#' @return invisibly, a list of the proposed changes
#' @author Daniel Nuest
#' @importFrom cli cli_h1 cli_alert_info cli_alert_success cli_alert_warning
#' @export
curate_zenodo_record <- function(record,
                                 zenodo = NULL,
                                 metadata = NULL,
                                 register_dir = getwd(),
                                 dry_run = TRUE,
                                 record_metadata = NULL,
                                 fields = c("title", "publisher", "language",
                                            "resource_type", "identifiers",
                                            "reviews", "repository", "creators",
                                            "license"),
                                 creator_overrides = list()) {
  fields <- match.arg(fields, several.ok = TRUE)
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
  # only correct the capitalisation of a title that is otherwise as expected;
  # a title carrying extra text (e.g. the paper title) is left to a human
  if ("title" %in% fields && !identical(cm$title, target_title)) {
    if (identical(tolower(cm$title), tolower(target_title))) {
      changes$title <- list(from = cm$title, to = target_title)
    } else {
      changes$title_manual <- list(from = cm$title, to = target_title)
    }
  }

  # Publisher, language and resource type: fixed values from the policy
  if ("publisher" %in% fields &&
      !identical(cm$publisher, "CODECHECK Community on Zenodo")) {
    changes$publisher <- list(from = if (is.null(cm$publisher)) "missing" else cm$publisher,
                              to = "CODECHECK Community on Zenodo")
  }

  if ("language" %in% fields && length(cm$languages) == 0) {
    changes$language <- list(from = "not set", to = "eng")
  }

  # Licence: the certificate must be CC-BY 4.0, so add it when missing. Any
  # other licence already on the record is kept: it may cover code, data or a
  # source archive deposited alongside the certificate.
  current_rights <- unlist(lapply(cm$rights, function(r) r$id))
  if ("license" %in% fields && !("cc-by-4.0" %in% current_rights)) {
    changes$license <- list(
      from = if (length(current_rights) == 0) "missing" else paste(current_rights, collapse = ", "),
      to = paste(c(current_rights, "cc-by-4.0"), collapse = ", "),
      rights = c(current_rights, "cc-by-4.0"))
  }

  current_rt <- if (!is.null(cm$resource_type$id)) cm$resource_type$id else "missing"
  if ("resource_type" %in% fields && !identical(current_rt, "publication-report")) {
    changes$resource_type <- list(from = current_rt, to = "publication-report")
  }

  # Creators recorded as organisations
  creator_targets <- list()
  for (i in if ("creators" %in% fields) seq_along(cm$creators) else integer(0)) {
    poo <- cm$creators[[i]]$person_or_org
    if (identical(poo$type, "organizational")) {
      override <- creator_overrides[[poo$name]]
      if (isTRUE(override$organizational)) {
        # a genuine group, correctly recorded as an organisation
        next
      }
      parts <- if (!is.null(override$family)) {
        list(given = override$given, family = override$family)
      } else {
        split_person_name(poo$name)
      }
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
  if ("reviews" %in% fields && !any(tolower(relations) == "reviews")) {
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

  # Relation to the code/data repository
  repo_relations <- c("issupplementedby", "isderivedfrom", "iscompiledby", "issupplementto")
  if ("repository" %in% fields && !any(tolower(relations) %in% repo_relations)) {
    repo_url <- metadata$repository
    if (is.list(repo_url) && length(repo_url) > 0) repo_url <- repo_url[[1]]
    if (is.character(repo_url) && nchar(repo_url) > 0) {
      repo_url <- gsub("[<>]", "", repo_url)
      if (grepl("github.com/codecheckers|gitlab.com/cdchck", repo_url)) {
        changes$repository <- list(from = "missing",
                                   to = paste0("isSupplementedBy ", repo_url),
                                   identifier = repo_url)
      } else {
        # a repository outside codecheckers/cdchck is not what the policy asks
        # for, so surface it rather than deposit it
        changes$repository_manual <- list(from = "missing", to = repo_url)
      }
    }
  }

  # Alternate identifiers
  alt <- cm$identifiers
  has_scheme <- function(scheme) {
    any(unlist(lapply(alt, function(a)
      tolower(a$scheme) == scheme && grepl("cdchck.science/register/certs/", a$identifier))))
  }
  if ("identifiers" %in% fields && (!has_scheme("url") || !has_scheme("other"))) {
    changes$identifiers <- list(
      from = if (length(alt) == 0) "missing" else
        paste(unlist(lapply(alt, function(a) a$identifier)), collapse = "; "),
      to = paste0("http://cdchck.science/register/certs/", cert,
                  " (url); cdchck.science/register/certs/", cert, " (other)"),
      url = paste0("http://cdchck.science/register/certs/", cert),
      other = paste0("cdchck.science/register/certs/", cert))
  }

  cli::cli_h1(paste0("Curation of Zenodo record ", id, " (certificate ", cert, ")"))
  applicable <- names(changes)[!grepl("_manual$", names(changes))]
  if (length(changes) == 0) {
    cli::cli_alert_success("Nothing to change, the record follows the curation policy.")
    return(invisible(changes))
  }

  for (name in names(changes)) {
    if (grepl("_manual$", name)) {
      cli::cli_alert_warning(paste0(
        sub("_manual$", "", name), ": ", changes[[name]]$from,
        "  ->  needs a human, expected something like: ", changes[[name]]$to))
    } else if (name == "creators") {
      for (ct in changes[["creators"]]) {
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

  if (length(applicable) == 0) {
    cli::cli_alert_warning("Only findings that need a human, nothing written.")
    return(invisible(changes))
  }

  if (is.null(zenodo)) {
    token <- Sys.getenv("ZENODO_TOKEN")
    if (nchar(token) == 0) {
      stop("No Zenodo token: set the ZENODO_TOKEN environment variable or pass `zenodo`")
    }
    zenodo <- zen4R::ZenodoManager$new(token = token, logger = "INFO")
  }

  # NOTE: read `changes` with [["..."]] below, never with $: R partial-matches
  # $ on lists, so changes$title would silently match changes$title_manual and
  # truncate a title that was deliberately routed to a human.
  cli::cli_alert_info("Opening the published record for editing ...")
  draft <- zenodo$editRecord(id)

  # editRecord() does not stop on failure, it returns a non-record (typically
  # on "Permission denied" when the token does not own the record). Without
  # this check the next method call fails with "attempt to apply non-function",
  # which says nothing about the actual cause.
  if (is.null(draft) || !inherits(draft, "ZenodoRecord")) {
    stop("Could not open record ", id, " for editing. The Zenodo token is ",
         "most likely not allowed to edit it - records deposited by another ",
         "user need to be curated by their owner, or the token needs edit ",
         "rights on them.", call. = FALSE)
  }

  if (!is.null(changes[["title"]])) {
    draft$setTitle(changes[["title"]]$to)
  }

  if (!is.null(changes[["publisher"]])) {
    draft$setPublisher(changes[["publisher"]]$to)
  }

  if (!is.null(changes[["language"]])) {
    draft$setLanguage("eng")
  }

  if (!is.null(changes[["resource_type"]])) {
    draft$setResourceType("publication-report")
  }

  if (!is.null(changes[["license"]])) {
    # set the full list explicitly: CC-BY for the certificate plus whatever the
    # record already carried for its other artefacts
    draft$metadata$rights <- lapply(changes[["license"]]$rights,
                                    function(id) list(id = id))
  }

  if (!is.null(changes[["repository"]])) {
    draft$addRelatedIdentifier(identifier = changes[["repository"]]$identifier,
                               scheme = "url",
                               relation_type = "issupplementedby",
                               resource_type = "software")
  }

  if (!is.null(changes[["creators"]])) {
    # rebuild the whole creator list, keeping creators that are already correct
    keep <- draft$metadata$creators
    draft$metadata$creators <- NULL
    for (i in seq_along(keep)) {
      fix <- Filter(function(ct) ct$index == i, changes[["creators"]])
      if (length(fix) == 1) {
        draft$addCreator(firstname = fix[[1]]$given,
                         lastname = fix[[1]]$family,
                         orcid = fix[[1]]$orcid)
      } else {
        draft$metadata$creators[[length(draft$metadata$creators) + 1]] <- keep[[i]]
      }
    }
  }

  if (!is.null(changes[["reviews"]])) {
    draft$addRelatedIdentifier(identifier = changes[["reviews"]]$identifier,
                               scheme = "doi",
                               relation_type = "reviews",
                               resource_type = changes[["reviews"]]$resource_type)
  }

  if (!is.null(changes[["identifiers"]])) {
    draft$metadata$identifiers <- list(
      list(scheme = "url", identifier = changes[["identifiers"]]$url),
      list(scheme = "other", identifier = changes[["identifiers"]]$other))
  }

  draft <- zenodo$depositRecord(draft)
  published <- zenodo$publishRecord(draft$id)
  # the policy check caches record metadata; without this the freshly curated
  # record would keep being reported with its pre-curation findings
  clear_zenodo_policy_cache(id)
  cli::cli_alert_success(paste0("Published metadata update: ", published$links$self_html))

  invisible(changes)
}


#' Drop the cached policy-check metadata of a Zenodo record
#'
#' [check_register_zenodo_policy()] caches record metadata, so a record that was
#' just curated would keep being reported with its pre-curation findings until
#' the whole cache is cleared. Invalidating the single record keeps the rest of
#' the cache warm.
#'
#' @title Drop the cached policy metadata of one Zenodo record
#' @param record_id Zenodo record ID
#' @return TRUE if a cache entry was removed, FALSE otherwise, invisibly
#' @importFrom R.cache findCache
#' @export
clear_zenodo_policy_cache <- function(record_id) {
  removed <- tryCatch({
    path <- R.cache::findCache(key = list(record_id = as.integer(record_id)),
                               dirs = "zenodo-policy")
    if (!is.null(path) && file.exists(path)) file.remove(path) else FALSE
  }, error = function(e) FALSE)
  invisible(isTRUE(removed))
}


#' Check all Zenodo-hosted certificates of a register against the curation policy
#'
#' Runs [zenodo_policy_check()] over every register entry whose report is a
#' Zenodo DOI. Meant to run at the end of a register render as a maintainer
#' signal, so it never fails: an unreachable record, a 404 or a malformed
#' response yields the status "unknown" rather than an error, and entries whose
#' report is not a Zenodo DOI are skipped.
#'
#' Record metadata is cached via [cached_lookup()], which stores conclusive
#' results only, so an outage is retried on the next render instead of being
#' frozen into the cache. Clear it with [register_clear_cache()].
#'
#' @title Check a register's Zenodo records against the CODECHECK curation policy
#' @param register_table a register `data.frame` with the columns `Certificate`
#'   and `Report`
#' @param get_metadata function of one argument (the record ID) returning the
#'   record metadata like [get_zenodo_record_metadata()]; injectable for testing
#' @return a data.frame with one row per checked certificate and the columns
#'   `certificate`, `record_id`, `status` ("compliant", "non-compliant" or
#'   "unknown"), `n_fail`, `n_warn`, `n_info` and `findings`. An "info" finding
#'   (e.g. a creator recorded as an organisation, which is correct for a
#'   genuine group) never makes a record non-compliant
#' @author Daniel Nuest
#' @export
check_register_zenodo_policy <- function(register_table,
                                         get_metadata = get_zenodo_record_metadata) {
  if (is.null(register_table) || nrow(register_table) == 0 ||
      !all(c("Certificate", "Report") %in% names(register_table))) {
    return(empty_zenodo_policy_result())
  }

  rows <- list()
  for (i in seq_len(nrow(register_table))) {
    # after preprocessing the Certificate column holds a markdown link, e.g.
    # "[2026-023](https://codecheck.org.uk/...)", so reduce it to the bare ID
    cert <- as.character(register_table$Certificate[i])
    cert <- sub("^\\[([^]]+)\\].*$", "\\1", cert)
    report <- as.character(register_table$Report[i])
    record_id <- get_zenodo_id(report)

    # entries not archived on Zenodo (OSF, GitLab, ...) are out of scope
    if (is.na(record_id)) next

    result <- tryCatch({
      record <- cached_lookup(
        key = list(record_id = record_id),
        dirs = "zenodo-policy",
        lookup = function() {
          fetched <- tryCatch(get_metadata(record_id),
                              error = function(e) NULL)
          if (is.null(fetched) || is.null(fetched$metadata)) {
            list(status = "failed", value = NULL)
          } else {
            list(status = "found", value = fetched)
          }
        })

      if (is.null(record)) {
        NULL
      } else {
        zenodo_policy_check(record$metadata, files = unlist(record$files), record = record$record)
      }
    }, error = function(e) NULL)

    if (is.null(result)) {
      rows[[length(rows) + 1]] <- data.frame(
        certificate = cert, record_id = record_id, status = "unknown",
        n_fail = NA_integer_, n_warn = NA_integer_, n_info = NA_integer_,
        findings = "record could not be checked (Zenodo unreachable)",
        stringsAsFactors = FALSE)
      next
    }

    fails <- result[result$status == "fail", ]
    warns <- result[result$status == "warn", ]
    infos <- result[result$status == "info", ]
    # guard the zero-row cases: paste0(character(0), ": ", character(0)) recycles
    # the scalar separator and yields ": " rather than an empty vector
    describe <- function(rows) {
      if (nrow(rows) == 0) character(0) else paste0(rows$check, ": ", rows$detail)
    }
    findings <- c(describe(fails), describe(warns), describe(infos))

    rows[[length(rows) + 1]] <- data.frame(
      certificate = cert, record_id = record_id,
      # an "info" finding (e.g. a creator recorded as an organisation) is
      # never a compliance defect, only fails count against it
      status = if (nrow(fails) > 0) "non-compliant" else "compliant",
      n_fail = nrow(fails), n_warn = nrow(warns), n_info = nrow(infos),
      # " | " because individual details already use "; " internally
      findings = paste(findings, collapse = " | "),
      stringsAsFactors = FALSE)
  }

  if (length(rows) == 0) return(empty_zenodo_policy_result())
  do.call(rbind, rows)
}

empty_zenodo_policy_result <- function() {
  data.frame(certificate = character(0), record_id = integer(0),
             status = character(0), n_fail = integer(0), n_warn = integer(0),
             n_info = integer(0), findings = character(0), stringsAsFactors = FALSE)
}


#' Report the register's curation policy findings on the console
#'
#' Prints the result of [check_register_zenodo_policy()] as a `cli` section:
#' a line per certificate with findings, then a tally. Certificates that comply
#' with no findings at all are covered by the tally only; a compliant
#' certificate that has an "info" finding (e.g. a creator recorded as an
#' organisation) is still surfaced, as information rather than as an error.
#'
#' @title Report curation policy findings
#' @param result the data.frame from [check_register_zenodo_policy()]
#' @return the result, invisibly
#' @author Daniel Nuest
#' @importFrom cli cli_h2 cli_alert_danger cli_alert_warning cli_alert_info cli_alert_success
#' @export
report_zenodo_policy_findings <- function(result) {
  if (is.null(result) || nrow(result) == 0) return(invisible(result))

  cli::cli_h2("Zenodo curation policy")

  for (i in seq_len(nrow(result))) {
    row <- result[i, ]
    if (row$status == "unknown") {
      cli::cli_alert_info("{row$certificate}: {row$findings}")
    } else if (row$status == "non-compliant") {
      cli::cli_alert_danger("{row$certificate}: {row$findings}")
    } else if (row$n_warn > 0) {
      cli::cli_alert_warning("{row$certificate}: {row$findings}")
    } else if (row$n_info > 0) {
      cli::cli_alert_info("{row$certificate}: {row$findings}")
    }
  }

  compliant <- sum(result$status == "compliant")
  total <- nrow(result)
  unknown <- sum(result$status == "unknown")
  cli::cli_alert_success(
    "{compliant} of {total} certificate{?s} on Zenodo comply with the curation policy{if (unknown > 0) paste0(', ', unknown, ' could not be checked') else ''}")

  invisible(result)
}


#' Curate all Zenodo records of a register against the curation policy
#'
#' Runs [curate_zenodo_record()] over every register entry whose report is a
#' Zenodo DOI. Intended for the mechanical corrections, whose target values
#' follow from the certificate ID or from `codecheck.yml`; `fields` therefore
#' defaults to everything except "creators", which needs a human because
#' splitting a name is wrong for group entries.
#'
#' One record failing does not stop the run: its error is recorded in the
#' result and the loop continues.
#'
#' @title Curate all Zenodo records of a register
#' @param register_table a register `data.frame` with columns `Certificate`,
#'   `Report` and `Repository`
#' @param zenodo a `zen4R` ZenodoManager, only needed when `dry_run = FALSE`
#' @param fields which classes of correction to consider, see [curate_zenodo_record()]
#' @param dry_run if TRUE (the default) only report what would change
#' @param register_dir directory holding `register.csv`
#' @return a data.frame with one row per record: `certificate`, `record_id`,
#'   `applied` (the corrections), `manual` (findings needing a human), `error`
#' @author Daniel Nuest
#' @importFrom cli cli_h1 cli_alert_info cli_alert_success
#' @export
curate_register_zenodo_records <- function(register_table,
                                           zenodo = NULL,
                                           fields = c("title", "publisher", "language",
                                                      "resource_type", "identifiers",
                                                      "reviews", "repository"),
                                           dry_run = TRUE,
                                           register_dir = getwd()) {
  rows <- list()

  for (i in seq_len(nrow(register_table))) {
    cert <- sub("^\\[([^]]+)\\].*$", "\\1", as.character(register_table$Certificate[i]))
    record_id <- get_zenodo_id(as.character(register_table$Report[i]))
    if (is.na(record_id)) next

    outcome <- tryCatch({
      config <- get_codecheck_yml(as.character(register_table$Repository[i]))
      changes <- curate_zenodo_record(record_id, zenodo = zenodo, metadata = config,
                                      register_dir = register_dir, dry_run = dry_run,
                                      fields = fields)
      names_all <- names(changes)
      list(applied = paste(setdiff(names_all, grep("_manual$", names_all, value = TRUE)),
                           collapse = ", "),
           manual = paste(sub("_manual$", "", grep("_manual$", names_all, value = TRUE)),
                          collapse = ", "),
           error = NA_character_)
    }, error = function(e) {
      list(applied = "", manual = "", error = conditionMessage(e))
    })

    rows[[length(rows) + 1]] <- data.frame(
      certificate = cert, record_id = record_id,
      applied = outcome$applied, manual = outcome$manual, error = outcome$error,
      stringsAsFactors = FALSE)
  }

  result <- if (length(rows) == 0) {
    data.frame(certificate = character(0), record_id = integer(0),
               applied = character(0), manual = character(0),
               error = character(0), stringsAsFactors = FALSE)
  } else do.call(rbind, rows)

  changed <- sum(nchar(result$applied) > 0)
  cli::cli_alert_info(paste0(
    if (dry_run) "Dry run: " else "Applied: ",
    changed, " of ", nrow(result), " records ",
    if (dry_run) "would be corrected" else "corrected",
    ", ", sum(nchar(result$manual) > 0), " have findings needing a human, ",
    sum(!is.na(result$error)), " errored"))

  invisible(result)
}
