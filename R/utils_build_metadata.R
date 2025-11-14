#' Get Build Metadata
#'
#' Retrieves metadata about the current build including timestamp, package version,
#' and git commit information from both the register and codecheck package repositories.
#'
#' @param register_repo_path Path to the register repository (default: current directory)
#' @param codecheck_repo_path Optional path to the codecheck package repository (default: NULL, will attempt to find it)
#' @return A list with build metadata including commits from both repositories
#' @importFrom utils packageVersion
#' @importFrom git2r repository commits sha remotes remote_url
#' @export
get_build_metadata <- function(register_repo_path = ".", codecheck_repo_path = NULL) {
  metadata <- list(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    package_version = as.character(packageVersion("codecheck"))
  )

  # Helper function to get git info for a repository
  get_repo_git_info <- function(repo_path, prefix) {
    info <- list()
    tryCatch({
      if (requireNamespace("git2r", quietly = TRUE)) {
        repo <- git2r::repository(repo_path, discover = TRUE)
        commit <- git2r::commits(repo, n = 1)[[1]]
        commit_sha <- git2r::sha(commit)

        info[[paste0(prefix, "_commit")]] <- commit_sha
        info[[paste0(prefix, "_commit_short")]] <- substr(commit_sha, 1, 7)

        # Try to construct GitHub URL
        remotes <- git2r::remotes(repo)
        if ("origin" %in% remotes) {
          remote_url <- git2r::remote_url(repo, "origin")

          if (grepl("github.com", remote_url)) {
            # Extract owner/repo from URL
            if (grepl("git@github.com:", remote_url)) {
              repo_path <- sub("git@github.com:", "", remote_url)
              repo_path <- sub("\\.git$", "", repo_path)
            } else {
              repo_path <- sub("https://github.com/", "", remote_url)
              repo_path <- sub("\\.git$", "", repo_path)
            }
            info[[paste0(prefix, "_commit_url")]] <- paste0("https://github.com/", repo_path, "/commit/", commit_sha)
          }
        }
      }
    }, error = function(e) {
      info[[paste0(prefix, "_commit")]] <- NULL
      info[[paste0(prefix, "_commit_short")]] <- NULL
      info[[paste0(prefix, "_commit_url")]] <- NULL
    })
    return(info)
  }

  # Get register repository git info
  register_info <- get_repo_git_info(register_repo_path, "register")
  metadata <- c(metadata, register_info)

  # Get codecheck package repository git info if path provided
  if (!is.null(codecheck_repo_path) && dir.exists(codecheck_repo_path)) {
    codecheck_info <- get_repo_git_info(codecheck_repo_path, "codecheck")
    metadata <- c(metadata, codecheck_info)
  }

  return(metadata)
}

#' Generate Meta Generator Content
#'
#' Creates the content value for the HTML meta generator tag with build information.
#'
#' @param metadata Build metadata from get_build_metadata()
#' @return String with generator content (without HTML tags)
#' @export
generate_meta_generator_content <- function(metadata) {
  parts <- c(sprintf("codecheck %s", metadata$package_version))

  # Add register commit info
  if (!is.null(metadata$register_commit_short)) {
    parts <- c(parts, sprintf("register commit %s", metadata$register_commit_short))
  }

  # Add codecheck commit info if available
  if (!is.null(metadata$codecheck_commit_short)) {
    parts <- c(parts, sprintf("package commit %s", metadata$codecheck_commit_short))
  }

  return(paste(parts, collapse=", "))
}

#' Generate Footer Build Information HTML
#'
#' Creates HTML content for displaying build information in the footer.
#' Styling should be applied in the template or CSS file.
#'
#' @param metadata Build metadata from get_build_metadata()
#' @return HTML string with build information (without wrapper styling)
#' @export
generate_footer_build_info <- function(metadata) {
  parts <- c()

  # Add timestamp
  parts <- c(parts, sprintf("Built: %s", metadata$timestamp))

  # Add package version
  parts <- c(parts, sprintf("codecheck v%s", metadata$package_version))

  # Add codecheck package git commit with link if available
  if (!is.null(metadata$codecheck_commit_short)) {
    if (!is.null(metadata$codecheck_commit_url)) {
      parts <- c(parts, sprintf('codecheck <a href="%s">%s</a>',
                               metadata$codecheck_commit_url,
                               metadata$codecheck_commit_short))
    } else {
      parts <- c(parts, sprintf("codecheck %s", metadata$codecheck_commit_short))
    }
  }

  # Add register git commit with link if available
  if (!is.null(metadata$register_commit_short)) {
    if (!is.null(metadata$register_commit_url)) {
      parts <- c(parts, sprintf('register <a href="%s">%s</a>',
                               metadata$register_commit_url,
                               metadata$register_commit_short))
    } else {
      parts <- c(parts, sprintf("register %s", metadata$register_commit_short))
    }
  }

  # Return content without styling wrapper
  return(paste(parts, collapse = " | "))
}

#' Write Build Metadata to JSON File
#'
#' Writes build metadata to a .meta.json file in the specified directory.
#'
#' @param metadata Build metadata from get_build_metadata()
#' @param output_path Path where .meta.json should be written (default: current directory)
#' @importFrom jsonlite write_json
#' @export
write_meta_json <- function(metadata, output_path = ".") {
  filepath <- file.path(output_path, ".meta.json")
  jsonlite::write_json(metadata, filepath, pretty = TRUE, auto_unbox = TRUE)
  message("Build metadata written to ", filepath)
}

#' Generate Schema.org JSON-LD for Certificate Page
#'
#' Creates Schema.org JSON-LD metadata representing a CODECHECK certificate as a Review
#' of a ScholarlyArticle. The structure follows schema.org best practices with the
#' certificate (Review) as the main entity and the paper (ScholarlyArticle) nested
#' as the itemReviewed.
#'
#' @param cert_id Certificate ID (e.g., "2025-028")
#' @param config_yml Parsed codecheck.yml configuration
#' @param abstract_data Abstract data from get_abstract() with text and source fields
#' @return JSON-LD string ready to be embedded in HTML <script type="application/ld+json">
#' @importFrom jsonlite toJSON
#' @export
generate_cert_schema_org <- function(cert_id, config_yml, abstract_data = NULL) {

  # Build the ScholarlyArticle (paper being checked)
  paper <- list(
    `@type` = "ScholarlyArticle",
    name = config_yml$paper$title,
    author = lapply(config_yml$paper$authors, function(author) {
      person <- list(
        `@type` = "Person",
        name = author$name
      )
      if (!is.null(author$ORCID) && author$ORCID != "") {
        person$`@id` <- paste0("https://orcid.org/", author$ORCID)
      }
      person
    })
  )

  # Add abstract if available
  if (!is.null(abstract_data) && !is.null(abstract_data$text) && abstract_data$text != "") {
    paper$abstract <- abstract_data$text
  }

  # Add paper URL/DOI
  if (!is.null(config_yml$paper$reference) && config_yml$paper$reference != "") {
    paper$url <- config_yml$paper$reference
    # If it's a DOI, also add sameAs
    if (grepl("doi.org", config_yml$paper$reference)) {
      paper$sameAs <- config_yml$paper$reference
    }
  }

  # Build the Review (CODECHECK certificate)
  cert_url <- paste0("https://codecheck.org.uk/register/certs/", cert_id, "/")

  review <- list(
    `@context` = "https://schema.org",
    `@type` = "Review",
    `@id` = cert_url,
    name = paste("CODECHECK Certificate", config_yml$certificate),
    url = cert_url,
    author = lapply(config_yml$codechecker, function(checker) {
      person <- list(
        `@type` = "Person",
        name = checker$name
      )
      if (!is.null(checker$ORCID) && checker$ORCID != "") {
        person$`@id` <- paste0("https://orcid.org/", checker$ORCID)
      }
      person
    }),
    itemReviewed = paper
  )

  # Add review body (summary) if available
  if ("summary" %in% names(config_yml) && !is.null(config_yml$summary) && config_yml$summary != "") {
    review$reviewBody <- config_yml$summary
  }

  # Add datePublished (check_time)
  if (!is.null(config_yml$check_time) && config_yml$check_time != "") {
    # Parse date and format as ISO 8601 date (YYYY-MM-DD)
    parsed_date <- parsedate::parse_date(config_yml$check_time)
    if (!is.na(parsed_date)) {
      review$datePublished <- format(parsed_date, "%Y-%m-%d")
    }
  }

  # Add associatedMedia (certificate PDF from Zenodo)
  if (!is.null(config_yml$report) && config_yml$report != "") {
    review$associatedMedia <- list(
      `@type` = "MediaObject",
      encodingFormat = "application/pdf",
      url = config_yml$report
    )
  }

  # Convert to JSON with proper formatting
  json_ld <- jsonlite::toJSON(review, pretty = TRUE, auto_unbox = TRUE)

  return(as.character(json_ld))
}

#' Generate Schema.org JSON-LD for codechecker pages
#'
#' Creates structured metadata using @graph to represent the codechecker as a Person
#' and their Reviews (codechecks). Uses the proper Schema.org relationship where
#' each Review has an "author" property pointing to the Person, rather than Person
#' having a "review" property (which doesn't exist in Schema.org).
#' Enables better discoverability by search engines and tools that consume schema.org metadata.
#'
#' @param codechecker_orcid The ORCID identifier of the codechecker
#' @param codechecker_name The name of the codechecker
#' @param codechecker_github Optional GitHub handle of the codechecker
#' @param register_table A data frame containing all codechecks by this codechecker
#'
#' @return JSON-LD string with Schema.org metadata using @graph
#' @export
generate_codechecker_schema_org <- function(codechecker_orcid, codechecker_name,
                                           codechecker_github = NULL, register_table) {

  # Person @id for references
  person_id <- paste0("https://orcid.org/", codechecker_orcid)

  # Build the Person (codechecker) entity
  person <- list(
    `@type` = "Person",
    `@id` = person_id,
    name = codechecker_name
  )

  # Add GitHub profile as sameAs if available
  if (!is.null(codechecker_github) && codechecker_github != "" && codechecker_github != "NA") {
    person$sameAs <- paste0("https://github.com/", codechecker_github)
  }

  # Build array of Review entities (codechecks)
  reviews <- list()

  for (i in 1:nrow(register_table)) {
    cert_id <- register_table$Certificate[i]
    cert_url <- paste0("https://codecheck.org.uk/register/certs/", cert_id, "/")

    # Try to get paper title and reference
    paper_title <- NULL
    paper_url <- NULL

    # Attempt to get codecheck.yml data for this certificate
    tryCatch({
      repo_link <- register_table$Repository[i]
      if (!is.null(repo_link) && repo_link != "" && repo_link != "NA") {
        config_yml <- get_codecheck_yml(repo_link)

        if (!is.null(config_yml$paper$title)) {
          paper_title <- config_yml$paper$title
        }

        if (!is.null(config_yml$paper$reference)) {
          paper_url <- config_yml$paper$reference
        }
      }
    }, error = function(e) {
      # Silently skip if we can't get the config
    })

    # Build the Review (CODECHECK certificate)
    review <- list(
      `@type` = "Review",
      `@id` = cert_url,
      name = paste("CODECHECK Certificate", cert_id),
      url = cert_url,
      # Author points to the Person entity via @id reference
      author = list(`@id` = person_id)
    )

    # Add paper as itemReviewed if we have title or URL
    if (!is.null(paper_title) || !is.null(paper_url)) {
      paper <- list(`@type` = "ScholarlyArticle")

      if (!is.null(paper_title)) {
        paper$name <- paper_title
      }

      if (!is.null(paper_url)) {
        paper$url <- paper_url
        # If it's a DOI, also add sameAs
        if (grepl("doi.org", paper_url)) {
          paper$sameAs <- paper_url
        }
      }

      review$itemReviewed <- paper
    }

    # Add check date if available
    if ("Check date" %in% names(register_table) &&
        !is.null(register_table$`Check date`[i]) &&
        !is.na(register_table$`Check date`[i]) &&
        register_table$`Check date`[i] != "") {
      parsed_date <- parsedate::parse_date(register_table$`Check date`[i])
      if (!is.na(parsed_date)) {
        review$datePublished <- format(parsed_date, "%Y-%m-%d")
      }
    }

    reviews[[i]] <- review
  }

  # Build @graph structure with Person first, then all Reviews
  graph <- c(list(person), reviews)

  # Create final structure with @context and @graph
  schema_org <- list(
    `@context` = "https://schema.org",
    `@graph` = graph
  )

  # Convert to JSON with proper formatting
  json_ld <- jsonlite::toJSON(schema_org, pretty = TRUE, auto_unbox = TRUE)

  return(as.character(json_ld))
}
