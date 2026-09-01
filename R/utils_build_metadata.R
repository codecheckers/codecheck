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
  sprintf("codecheck %s", metadata$package_version)
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
  cli::cli_alert_success("Build metadata written to {.path {filepath}}")
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
#' @param openalex_id Optional pre-resolved OpenAlex ID (see \code{\link{resolve_external_field}}).
#'   `NULL` means "not looked up here" and omits the field, matching the
#'   pre-existing behaviour of this function for callers that don't pass one.
#' @param cert_title Title of the certificate's record on the platform it is
#'   published on, see \code{\link{resolve_cert_title}}; falls back to the
#'   constructed "CODECHECK Certificate <ID>" when not given
#' @return JSON-LD string ready to be embedded in HTML <script type="application/ld+json">
#' @importFrom jsonlite toJSON
#' @export
generate_cert_schema_org <- function(cert_id, config_yml, abstract_data = NULL,
                                     openalex_id = NULL, cert_title = NULL) {

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

  # Add paper URL/DOI and OpenAlex identifier (addresses register#185)
  if (!is.null(config_yml$paper$reference) && config_yml$paper$reference != "") {
    paper$url <- config_yml$paper$reference
    same_as <- c()
    if (grepl("doi.org", config_yml$paper$reference)) {
      same_as <- c(same_as, config_yml$paper$reference)
    }
    # Add OpenAlex identifier
    if (is.null(openalex_id)) {
      openalex_id <- tryCatch(
        get_openalex_id_cached(
          config_yml$paper$reference,
          paper_title = config_yml$paper$title,
          first_author_name = if (length(config_yml$paper$authors) > 0) config_yml$paper$authors[[1]]$name else NULL
        ),
        error = function(e) NA_character_
      )
    }
    if (!is.na(openalex_id)) {
      same_as <- c(same_as, openalex_id)
    }
    if (length(same_as) == 1) {
      paper$sameAs <- same_as
    } else if (length(same_as) > 1) {
      paper$sameAs <- same_as
    }
  }

  # Build the Review (CODECHECK certificate)
  cert_url <- paste0("https://codecheck.org.uk/register/certs/", cert_id, "/")

  review <- list(
    `@context` = "https://schema.org",
    `@type` = "Review",
    `@id` = cert_url,
    name = if (is_nonempty_string(cert_title)) cert_title else default_cert_title(cert_id),
    url = cert_url,
    inLanguage = CONFIG$CERT_LANGUAGE,
    publisher = list(
      `@type` = "Organization",
      name = CONFIG$CERT_PUBLISHER
    ),
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

  # Add the archived record: its DOI identifies the certificate, and the deposit
  # itself is the media object. The archive may be Zenodo, OSF or ResearchEquals.
  if (!is.null(config_yml$report) && config_yml$report != "") {
    doi <- bare_doi(config_yml$report)
    if (!is.null(doi)) {
      review$identifier <- list(
        `@type` = "PropertyValue",
        propertyID = "DOI",
        value = doi
      )
    }

    review$associatedMedia <- list(
      `@type` = "MediaObject",
      encodingFormat = "application/pdf",
      url = config_yml$report
    )
  }

  # The certificate PDF as served from the register itself, alongside the
  # archived copy above
  if (file.exists(file.path(CONFIG$CERTS_DIR[["cert"]], cert_id, "cert.pdf"))) {
    review$encoding <- list(
      `@type` = "MediaObject",
      encodingFormat = "application/pdf",
      contentUrl = paste0(cert_url, "cert.pdf")
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

#' Map a CODECHECK venue type to the closest Schema.org entity type
#'
#' @param venue_type journal/conference/community/institution (register.csv `Type`)
#' @return A Schema.org `@type` string
#' @keywords internal
venue_schema_org_type <- function(venue_type) {
  switch(venue_type,
    journal = "Periodical",
    # A conference recurs across years - EventSeries is schema.org's type
    # for a recurring event, as opposed to one dated Event.
    conference = "EventSeries",
    institution = ,
    community = "Organization",
    "Organization"
  )
}

#' Generate Schema.org JSON-LD for venue pages
#'
#' Creates structured metadata using `@graph` to represent the venue (journal,
#' conference, community or institution) as an appropriately-typed Schema.org
#' entity - a `Periodical` for a journal, an `EventSeries` for a conference,
#' `Organization` otherwise, carrying the same metadata as the venue's landing
#' page panel (name, url, description, logo, identifiers as `PropertyValue`s,
#' via [get_venue_metadata_fields()]) - together with a `Review` per checked
#' paper, whose `itemReviewed` `ScholarlyArticle` links back to the venue via
#' `isPartOf`. Mirrors [generate_codechecker_schema_org()]. Addresses register#183.
#'
#' @param venue_name The venue's name (register.csv `Venue` column / venues.csv `name`)
#' @param venue_type The venue's type (register.csv `Type` column)
#' @param register_table A data frame of all codechecks for this venue, needs
#'   `Certificate`, `Repository` and `Check date` columns
#'
#' @return JSON-LD string with Schema.org metadata using `@graph`
#' @export
generate_venue_schema_org <- function(venue_name, venue_type, register_table) {
  has_value <- function(x) !is.null(x) && !is.na(x) && nzchar(trimws(x))

  venue_row <- lookup_venue_row(venue_name)
  fields <- get_venue_metadata_fields(venue_row, venue_type)

  venue_longname <- if ("longname" %in% names(venue_row) && has_value(venue_row[["longname"]][1])) {
    venue_row[["longname"]][1]
  } else {
    venue_name
  }

  page_url <- NULL
  if (has_value(fields$venue_type) && fields$venue_type %in% names(CONFIG$VENUE_SUBCAT_PLURAL)) {
    # Slug must match generate_table_details()'s lowercased directory name
    # (register#192 - a case-sensitive filesystem would otherwise create a
    # sibling directory instead of linking to the one every other page uses).
    slug <- gsub(" ", "_", tolower(venue_name))
    page_url <- paste0(CONFIG$HYPERLINKS[["venues"]], CONFIG$VENUE_SUBCAT_PLURAL[[fields$venue_type]],
                       "/", slug, "/")
  }

  # Prefer an external persistent identifier (ROR, ISSN Portal, ...) as the
  # entity's @id when available - it is the canonical URI for this venue
  # elsewhere on the web - falling back to the venue's own page.
  venue_id <- NULL
  for (identifier in fields$identifiers) {
    if (!is.null(identifier$link)) {
      venue_id <- identifier$link
      break
    }
  }
  if (is.null(venue_id)) venue_id <- page_url

  venue_entity <- list(`@type` = venue_schema_org_type(fields$venue_type), name = venue_longname)
  if (!is.null(venue_id)) venue_entity$`@id` <- venue_id
  if (!is.null(page_url)) venue_entity$url <- page_url
  if (has_value(fields$website_url)) venue_entity$sameAs <- fields$website_url
  if (has_value(fields$description)) venue_entity$description <- fields$description
  if (has_value(fields$logo_url)) {
    venue_entity$logo <- list(`@type` = "ImageObject", url = fields$logo_url)
  }
  if (length(fields$identifiers) > 0) {
    venue_entity$identifier <- lapply(fields$identifiers, function(i) {
      property_value <- list(`@type` = "PropertyValue", propertyID = i$name, value = i$value)
      if (!is.null(i$link)) property_value$url <- i$link
      property_value
    })
  }

  # Reference the venue by @id where one exists, to avoid repeating the full
  # entity inside every paper's isPartOf.
  venue_ref <- if (!is.null(venue_entity$`@id`)) list(`@id` = venue_entity$`@id`) else venue_entity

  # Build array of Review entities (codechecks); same approach as
  # generate_codechecker_schema_org(), except each paper links back to the
  # venue instead of each review linking back to a codechecker.
  reviews <- list()
  n <- nrow(register_table)
  if (n > 0) {
    for (i in seq_len(n)) {
      cert_id <- register_table$Certificate[i]
      cert_url <- paste0("https://codecheck.org.uk/register/certs/", cert_id, "/")

      paper_title <- NULL
      paper_url <- NULL
      tryCatch({
        repo_link <- register_table$Repository[i]
        if (!is.null(repo_link) && repo_link != "" && repo_link != "NA") {
          config_yml <- get_codecheck_yml(repo_link)
          if (!is.null(config_yml$paper$title)) paper_title <- config_yml$paper$title
          if (!is.null(config_yml$paper$reference)) paper_url <- config_yml$paper$reference
        }
      }, error = function(e) {
        # Silently skip if we can't get the config
      })

      review <- list(
        `@type` = "Review",
        `@id` = cert_url,
        name = paste("CODECHECK Certificate", cert_id),
        url = cert_url
      )

      if (!is.null(paper_title) || !is.null(paper_url)) {
        paper <- list(`@type` = "ScholarlyArticle", isPartOf = venue_ref)
        if (!is.null(paper_title)) paper$name <- paper_title
        if (!is.null(paper_url)) {
          paper$url <- paper_url
          if (grepl("doi.org", paper_url)) paper$sameAs <- paper_url
        }
        review$itemReviewed <- paper
      }

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
  }

  graph <- c(list(venue_entity), reviews)

  schema_org <- list(
    `@context` = "https://schema.org",
    `@graph` = graph
  )

  json_ld <- jsonlite::toJSON(schema_org, pretty = TRUE, auto_unbox = TRUE)

  return(as.character(json_ld))
}

#' Generate Schema.org JSON-LD for a work page (codecheckers/register#150)
#'
#' The `ScholarlyArticle` counterpart of [generate_venue_schema_org()]: the
#' checked paper is the primary `@graph` entity (`@id` its DOI URL), carrying
#' its title, `sameAs` its OpenAlex work ID, and an `author` array of
#' `Person` nodes - `@id`'d by ORCID where known, so a search engine or a
#' data consumer can follow straight from the paper to the person page
#' (mirrors what the paper author links on the certificate page and the
#' work page's own metadata panel already do in HTML - see
#' [generate_work_metadata_html()]). One `Review` per certificate that
#' checked it references the article back via `itemReviewed`.
#'
#' @param doi The work's DOI (`table_details[["name"]]` on a work page).
#' @param register_table A data frame of all certificates for this DOI, needs
#'   `Certificate`, `Repository` and `Check date` columns.
#' @return JSON-LD string with Schema.org metadata using `@graph`.
#' @export
generate_work_schema_org <- function(doi, register_table) {
  fields <- get_work_metadata_fields(doi, register_table)
  article_id <- paste0(CONFIG$HYPERLINKS[["doi"]], doi)

  article <- list(`@type` = "ScholarlyArticle", `@id` = article_id, url = article_id, sameAs = article_id)
  if (!is.na(fields$title) && nzchar(fields$title)) article$name <- fields$title
  if (!is.na(fields$openalex) && nzchar(fields$openalex)) {
    article$sameAs <- c(article_id, fields$openalex)
  }
  if (length(fields$authors) > 0) {
    article$author <- lapply(fields$authors, function(a) {
      person <- list(`@type` = "Person", name = a$name)
      if (!is.null(a$orcid)) person$`@id` <- paste0(CONFIG$HYPERLINKS[["orcid"]], a$orcid)
      person
    })
  }

  article_ref <- list(`@id` = article_id)

  reviews <- list()
  n <- nrow(register_table)
  if (n > 0) {
    for (i in seq_len(n)) {
      cert_id <- register_table$Certificate[i]
      cert_url <- paste0(CONFIG$HYPERLINKS[["certs"]], cert_id, "/")

      review <- list(
        `@type` = "Review",
        `@id` = cert_url,
        name = paste("CODECHECK Certificate", cert_id),
        url = cert_url,
        itemReviewed = article_ref
      )

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
  }

  graph <- c(list(article), reviews)
  schema_org <- list(`@context` = "https://schema.org", `@graph` = graph)
  json_ld <- jsonlite::toJSON(schema_org, pretty = TRUE, auto_unbox = TRUE)
  as.character(json_ld)
}

#' Generate Schema.org JSON-LD for a person page (codecheckers/register#123)
#'
#' Generalises [generate_codechecker_schema_org()] to a person's two
#' possible roles: the `Person` entity still gets a `Review` per certificate
#' they checked (identical to the codechecker version, `author` referencing
#' the person by `@id`), and additionally a `ScholarlyArticle` per paper they
#' authored, each with `author: {"@id": person_id}` pointing back the other
#' way. A person with only one role simply has an empty list for the other.
#'
#' @param orcid The person's ORCID.
#' @param name The person's name.
#' @param github_handle Optional GitHub handle.
#' @param register_table The person's exploded, per-role register rows (see
#'   [explode_person_records()]), needs `Certificate`, `Repository`,
#'   `Check date` and `Role` columns.
#' @return JSON-LD string with Schema.org metadata using `@graph`.
#' @export
generate_person_schema_org <- function(orcid, name, github_handle = NULL, register_table) {
  person_id <- paste0(CONFIG$HYPERLINKS[["orcid"]], orcid)
  person <- list(`@type` = "Person", `@id` = person_id, name = name)
  if (!is.null(github_handle) && nzchar(github_handle) && github_handle != "NA") {
    person$sameAs <- paste0("https://github.com/", github_handle)
  }

  has_role <- "Role" %in% names(register_table)
  checked <- if (has_role) register_table[register_table$Role == "codechecker", , drop = FALSE] else register_table[0, , drop = FALSE]
  authored <- if (has_role) register_table[register_table$Role == "author", , drop = FALSE] else register_table[0, , drop = FALSE]

  # Checks conducted: a Review per certificate, same shape as
  # generate_codechecker_schema_org().
  reviews <- list()
  if (nrow(checked) > 0) {
    for (i in seq_len(nrow(checked))) {
      cert_id <- checked$Certificate[i]
      cert_url <- paste0(CONFIG$HYPERLINKS[["certs"]], cert_id, "/")
      review <- list(
        `@type` = "Review", `@id` = cert_url,
        name = paste("CODECHECK Certificate", cert_id), url = cert_url,
        author = list(`@id` = person_id)
      )
      if ("Check date" %in% names(checked) && !is.na(checked$`Check date`[i]) && checked$`Check date`[i] != "") {
        parsed_date <- parsedate::parse_date(checked$`Check date`[i])
        if (!is.na(parsed_date)) review$datePublished <- format(parsed_date, "%Y-%m-%d")
      }
      reviews[[length(reviews) + 1]] <- review
    }
  }

  # Works authored: one ScholarlyArticle per distinct DOI-keyed work (a
  # certificate row, not a work - several certificates can share a DOI).
  articles <- list()
  if (nrow(authored) > 0 && "Work" %in% names(authored)) {
    dois <- unique(authored$Work[!is.na(authored$Work)])
    for (doi in dois) {
      article <- list(
        `@type` = "ScholarlyArticle",
        `@id` = paste0(CONFIG$HYPERLINKS[["doi"]], doi),
        url = paste0(CONFIG$HYPERLINKS[["doi"]], doi),
        author = list(`@id` = person_id)
      )
      title_row <- authored[authored$Work == doi, , drop = FALSE][1, ]
      if ("Paper Title" %in% names(title_row) && !is.na(title_row[["Paper Title"]])) {
        title_cell <- title_row[["Paper Title"]]
        article$name <- if (grepl("\\[.*\\]\\(.*\\)", title_cell)) sub("\\[(.*)\\]\\(.*\\)", "\\1", title_cell) else title_cell
      }
      articles[[length(articles) + 1]] <- article
    }
  }

  graph <- c(list(person), reviews, articles)
  schema_org <- list(`@context` = "https://schema.org", `@graph` = graph)
  json_ld <- jsonlite::toJSON(schema_org, pretty = TRUE, auto_unbox = TRUE)
  as.character(json_ld)
}

#' Escape a value for use in an HTML attribute
#'
#' The values of `<meta>` tags are HTML attributes, and Google Scholar's
#' indexing guidelines are explicit that they have to be escaped,
#' <https://scholar.google.com/intl/en/scholar/inclusion.html#indexing>.
#' Certificate metadata routinely contains ampersands and quotes, in paper
#' titles as much as in the free text summary of a check.
#'
#' @param x A character value
#' @return The value with `&`, `<`, `>`, `"` and `'` replaced by entities
#' @keywords internal
escape_html_attribute <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  x <- gsub("'", "&#39;", x, fixed = TRUE)
  x
}

#' Is this a usable single non-empty string?
#'
#' @param x A value from a parsed codecheck.yml, which may be NULL, NA or ""
#' @return TRUE if `x` can be rendered into a meta tag
#' @keywords internal
is_nonempty_string <- function(x) {
  is.character(x) && length(x) == 1 && !is.na(x) && nzchar(trimws(x))
}

#' A DOI without its resolver prefix
#'
#' `citation_doi` takes the bare DOI, while the `report` field of a
#' codecheck.yml is usually a DOI URL.
#'
#' @param x A DOI, DOI URL or `doi:` reference
#' @return The bare DOI, or NULL if `x` is not a DOI
#' @keywords internal
bare_doi <- function(x) {
  if (!is_nonempty_string(x)) return(NULL)
  doi <- trimws(x)
  doi <- sub("^https?://(dx\\.)?doi\\.org/", "", doi, ignore.case = TRUE)
  doi <- sub("^doi:", "", doi, ignore.case = TRUE)
  if (grepl("^10\\.[0-9]{4,}/", doi)) doi else NULL
}

#' Generate Highwire citation meta tags for a certificate page
#'
#' Builds the `citation_*` meta tags that make a certificate page citable by
#' Google Scholar and identifiable by Zotero (codecheckers/register#52).
#'
#' The tags describe the **certificate**, not the paper that was checked: the
#' paper has its own landing page at its DOI, and describing it here would make
#' Scholar treat the certificate page as a duplicate of the paper and make
#' Zotero save the wrong item. The link to the checked paper is expressed in the
#' schema.org metadata instead, as the `itemReviewed` of the review, see
#' \code{\link{generate_cert_schema_org}}.
#'
#' Only the Highwire scheme is emitted, not Dublin Core: Google Scholar calls DC
#' a last resort that "works poorly for journal papers", and Zotero's Embedded
#' Metadata translator derives the item type from the Highwire tags -
#' `citation_technical_report_institution` is what makes a certificate a
#' `report` rather than an untyped web page.
#'
#' @param cert_id Certificate ID (e.g. "2020-018")
#' @param config_yml Parsed codecheck.yml configuration
#' @param cert_title Title of the certificate's record on the platform it is
#'   published on, see \code{\link{resolve_cert_title}}; falls back to the
#'   constructed "CODECHECK Certificate <ID>" when not given
#' @param cert_venue Venue name of the certificate, added to the keywords
#' @param has_pdf Whether `cert.pdf` exists next to the page, i.e. whether a
#'   `citation_pdf_url` can be offered
#' @return HTML string of `<meta>` tags, one per line
#' @export
generate_cert_citation_meta <- function(cert_id, config_yml, cert_title = NULL,
                                        cert_venue = NULL, has_pdf = FALSE) {
  tags <- list()
  add <- function(name, value) {
    if (!is_nonempty_string(value)) return(invisible(NULL))
    tags[[length(tags) + 1]] <<- sprintf('<meta name="%s" content="%s">',
                                         name, escape_html_attribute(trimws(value)))
  }

  cert_url <- paste0(CONFIG$HYPERLINKS[["certs"]], cert_id, "/")

  # Required by Google Scholar: without title, author and publication date the
  # page is processed as if it had no meta tags at all
  add("citation_title", if (is_nonempty_string(cert_title)) cert_title else default_cert_title(cert_id))

  for (checker in config_yml$codechecker) {
    add("citation_author", checker$name)
  }

  if (is_nonempty_string(config_yml$check_time)) {
    check_date <- parsedate::parse_date(config_yml$check_time)
    if (!is.na(check_date)) {
      # the format Google Scholar documents, e.g. "2019/2/14"
      add("citation_publication_date", format(check_date, "%Y/%m/%d"))
    }
  }

  # what makes Zotero read the page as a report rather than a web page
  add("citation_technical_report_institution", CONFIG$CERT_PUBLISHER)
  add("citation_technical_report_number", cert_id)
  add("citation_publisher", CONFIG$CERT_PUBLISHER)

  add("citation_doi", bare_doi(config_yml$report))
  add("citation_abstract", config_yml$summary)

  # only offered when the PDF really sits next to the page: Scholar expects an
  # absolute, crawlable URL, and Zotero attaches it as the full text
  if (isTRUE(has_pdf)) {
    add("citation_pdf_url", paste0(cert_url, "cert.pdf"))
  }

  add("citation_fulltext_html_url", cert_url)
  add("citation_public_url", cert_url)
  add("citation_language", CONFIG$CERT_LANGUAGE)

  keywords <- CONFIG$CERT_KEYWORDS
  if (is_nonempty_string(cert_venue)) {
    keywords <- c(keywords, trimws(cert_venue))
  }
  add("citation_keywords", paste(keywords, collapse = "; "))

  paste(unlist(tags), collapse = "\n")
}

#' Generate the OpenGraph and Twitter card tags of a certificate page
#'
#' The shared page header describes the register as a whole, which on a
#' certificate page means every certificate advertised itself as "CODECHECK
#' Register" at the register's own URL. These tags describe the certificate
#' itself, and are read by Zotero's Embedded Metadata translator as well as by
#' the social previews they are named for.
#'
#' @inheritParams generate_cert_citation_meta
#' @param has_preview Whether `cert_1.png`, the first page of the certificate
#'   PDF, exists next to the page and can be used as the preview image
#' @return Named list with `og_title`, `og_url`, `og_description`, `og_type`
#'   and `og_image`, ready to render into the header template
#' @keywords internal
generate_cert_opengraph <- function(cert_id, config_yml, cert_title = NULL,
                                    has_preview = FALSE) {
  cert_url <- paste0(CONFIG$HYPERLINKS[["certs"]], cert_id, "/")

  title <- if (is_nonempty_string(cert_title)) cert_title else default_cert_title(cert_id)

  description <- if (is_nonempty_string(config_yml$summary)) {
    truncate_text(config_yml$summary, 300)
  } else if (is_nonempty_string(config_yml$paper$title)) {
    paste0("CODECHECK of “", config_yml$paper$title, "”")
  } else {
    "CODECHECK is a process for independent execution of computations underlying scholarly research articles."
  }

  list(
    og_title = escape_html_attribute(title),
    og_url = escape_html_attribute(cert_url),
    og_description = escape_html_attribute(description),
    og_type = "article",
    og_image = if (isTRUE(has_preview)) escape_html_attribute(paste0(cert_url, "cert_1.png")) else ""
  )
}

#' Shorten text to a maximum length, at a word boundary
#'
#' @param x The text
#' @param max_chars Maximum number of characters
#' @return The text, shortened and suffixed with a horizontal ellipsis if needed
#' @keywords internal
truncate_text <- function(x, max_chars) {
  x <- trimws(gsub("\\s+", " ", as.character(x)))
  if (nchar(x) <= max_chars) return(x)

  shortened <- substr(x, 1, max_chars)
  last_space <- regexpr("\\s[^\\s]*$", shortened, perl = TRUE)
  if (last_space > 1) {
    shortened <- substr(shortened, 1, last_space - 1)
  }
  paste0(trimws(shortened), "…")
}

#' The page-level metadata of a register page
#'
#' The defaults the shared header template is filled with, describing the
#' register as a whole. Certificate pages override them with
#' \code{\link{generate_cert_opengraph}} and add their citation metadata, see
#' \code{\link{generate_cert_citation_meta}}.
#'
#' @return Named list of template values
#' @keywords internal
register_page_header_data <- function() {
  list(
    page_author = "Stephen Eglen &amp; Daniel Nüst",
    og_title = "CODECHECK Register",
    og_url = CONFIG$HYPERLINKS[["register"]],
    og_description = "CODECHECK is a process for independent execution of computations underlying scholarly research articles.",
    og_type = "website",
    og_image = "",
    citation_meta = ""
  )
}

#' Assemble the values the shared page header template is rendered with
#'
#' The template switches optional blocks on explicit `has_*` flags rather than
#' on the values themselves: whisker treats the empty string as *true*, so a
#' page without an og:image or without Schema.org metadata would otherwise emit
#' an empty `<meta property="og:image" content="">` and an empty
#' `<script type="application/ld+json"></script>` instead of nothing and the
#' generic website metadata.
#'
#' @param page_metadata Page-level values, from
#'   \code{\link{register_page_header_data}} or, for a certificate page,
#'   \code{\link{generate_cert_opengraph}} plus its citation metadata
#' @param meta_generator Content of the generator meta tag
#' @param base_path Relative path from the page to the docs root
#' @param schema_org_jsonld Schema.org JSON-LD, or "" for none
#' @return Named list ready for `whisker.render()`
#' @keywords internal
header_template_data <- function(page_metadata, meta_generator, base_path,
                                 schema_org_jsonld = "") {
  c(page_metadata,
    list(
      meta_generator = meta_generator,
      base_path = base_path,
      schema_org_jsonld = schema_org_jsonld,
      has_schema_org_jsonld = is_nonempty_string(schema_org_jsonld),
      has_og_image = is_nonempty_string(page_metadata$og_image),
      has_citation_meta = is_nonempty_string(page_metadata$citation_meta)
    ))
}
