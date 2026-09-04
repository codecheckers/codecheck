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

  # The checked work's own item, where Wikidata holds one. The page's JSON
  # already names it, and a consumer reading only the JSON-LD should not have
  # to go and look it up again.
  paper_qid <- wikidata_id_for("paper", config_yml$paper$reference)
  if (!is.null(paper_qid)) {
    paper$sameAs <- c(paper$sameAs, wikidata_entity_url(paper_qid))
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

  # The record exported to Wikidata is the same certificate, said the way
  # Schema.org says it (register#50). The head's describedby link points at the
  # same item as a document; this states the identity.
  cert_qid <- wikidata_id_for("certificate", cert_id)
  if (!is.null(cert_qid)) review$sameAs <- wikidata_entity_url(cert_qid)

  # Add review body (summary) if available
  if ("summary" %in% names(config_yml) && !is.null(config_yml$summary) && config_yml$summary != "") {
    review$reviewBody <- config_yml$summary
  }

  # Add datePublished (check_time), ISO 8601 at the precision the
  # codecheck.yml recorded - the page itself shows the day only, but this is
  # machine-readable and keeps the time of day where there is one (register#219)
  check_time <- format_check_time_iso(config_yml$check_time)
  if (!is.na(check_time)) {
    review$datePublished <- check_time
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
  work_qid <- wikidata_id_for("paper", doi)
  if (!is.null(work_qid)) article$sameAs <- c(article$sameAs, wikidata_entity_url(work_qid))
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
  person_qid <- wikidata_id_for("person", orcid)
  if (!is.null(person_qid)) {
    person$sameAs <- c(person$sameAs, wikidata_entity_url(person_qid))
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

# ---------------------------------------------------------------------------
# FAIR Signposting, codecheckers/register#55
# ---------------------------------------------------------------------------

#' Render a list of typed links as HTML `<link>` elements
#'
#' The register is served by GitHub Pages, which cannot set HTTP response
#' headers, so signposting is expressed entirely through `<link>` elements in
#' the page head. The FAIR Signposting profile explicitly allows this: Level 1
#' asks for the links "in the HTTP header and/or in HTML link elements", and
#' names platforms without header control as the reason for the alternative.
#' What is given up is HEAD-request access to the links, and any signposting on
#' the PDF itself. Level 2 (a link set served as `application/linkset+json`) is
#' out of reach on GitHub Pages, which derives media types from file extensions
#' and has none registered for that type.
#'
#' @param links List of `list(rel, href, type)` entries; `type` may be NULL.
#'   Entries without a `href` are dropped, so callers can pass conditional
#'   values straight through.
#' @return HTML string of `<link>` elements, one per line, or `""` for none
#' @keywords internal
signposting_link_tags <- function(links) {
  tags <- character(0)
  for (link in links) {
    if (is.null(link) || !is_nonempty_string(link$href)) next
    tag <- sprintf('<link rel="%s" href="%s"', link$rel,
                   escape_html_attribute(trimws(link$href)))
    if (is_nonempty_string(link$type)) {
      tag <- paste0(tag, sprintf(' type="%s"', escape_html_attribute(link$type)))
    }
    tags <- c(tags, paste0(tag, ">"))
  }
  paste(tags, collapse = "\n")
}

#' Write a page's Schema.org metadata as a standalone JSON-LD document
#'
#' The same JSON-LD is inlined in the page's `<script>` element; writing it to
#' `index.jsonld` next to the page gives the signposting `describedby` link a
#' real target. The extension matters: GitHub Pages derives media types from
#' file extensions and serves `.jsonld` as `application/ld+json`, so the
#' document arrives correctly typed without any header control.
#'
#' @param schema_org_jsonld The JSON-LD string, or `""` for a page that has none
#' @param output_dir Directory of the page
#' @return `TRUE` if a document was written, `FALSE` otherwise
#' @keywords internal
write_schema_org_jsonld <- function(schema_org_jsonld, output_dir) {
  if (!is_nonempty_string(schema_org_jsonld)) return(FALSE)
  writeLines(schema_org_jsonld, file.path(output_dir, "index.jsonld"))
  TRUE
}

#' Signposting links for a certificate page
#'
#' A certificate page is a scholarly object's landing page, so it carries the
#' full FAIR Signposting Level 1 link set. `cite-as` is the certificate's own
#' archived DOI, never the checked paper's: the paper has its own landing page
#' at its own PID, and it is linked as `itemReviewed` in the Schema.org
#' metadata instead, for the same reason the Highwire tags describe the
#' certificate only, see \code{\link{generate_cert_citation_meta}}.
#'
#' Relations that cannot be stated truthfully are omitted rather than guessed:
#' `cite-as` has cardinality 1 and is dropped when the certificate has no
#' report DOI, and `item` is dropped when no PDF sits next to the page.
#'
#' @inheritParams generate_cert_citation_meta
#' @param has_jsonld Whether `index.jsonld`, the Schema.org metadata as a
#'   standalone document, was written next to the page
#' @return HTML string of `<link>` elements, one per line
#' @export
generate_cert_signposting <- function(cert_id, config_yml, has_pdf = FALSE,
                                      has_jsonld = FALSE) {
  doi <- bare_doi(config_yml$report)

  authors <- lapply(config_yml$codechecker, function(checker) {
    if (is.null(checker$ORCID) || !is_nonempty_string(checker$ORCID)) return(NULL)
    list(rel = "author", href = paste0(CONFIG$HYPERLINKS[["orcid"]], checker$ORCID))
  })

  links <- c(
    list(
      list(rel = "cite-as", href = if (!is.null(doi)) paste0(CONFIG$HYPERLINKS[["doi"]], doi) else NULL),
      # the schema.org class of the described object, plus the class of this
      # page itself, as the profile requires (cardinality 2)
      list(rel = "type", href = "https://schema.org/Review"),
      list(rel = "type", href = "https://schema.org/AboutPage")
    ),
    authors,
    list(
      list(rel = "describedby", href = "index.json", type = "application/json"),
      list(rel = "describedby", href = if (isTRUE(has_jsonld)) "index.jsonld" else NULL,
           type = "application/ld+json")
    ),
    wikidata_signposting_links(wikidata_id_for("certificate", cert_id)),
    list(
      list(rel = "item", href = if (isTRUE(has_pdf)) "cert.pdf" else NULL,
           type = "application/pdf"),
      list(rel = "license", href = CONFIG$LICENSE_CERT)
    )
  )

  signposting_link_tags(links)
}

#' Signposting links for a work page
#'
#' A work page is about a checked paper, which has a DOI, so it is the one
#' non-certificate page that can carry a `cite-as`. The register is a third
#' party to that paper - `cite-as` here states the PID of the thing the page
#' describes, which is what an aggregator landing page is expected to do, and
#' does not claim to be the publisher's landing page.
#'
#' @param doi The work's DOI (`table_details[["name"]]` on a work page)
#' @param register_table See \code{\link{get_work_metadata_fields}}
#' @param has_jsonld Whether `index.jsonld` was written next to the page
#' @return HTML string of `<link>` elements, one per line
#' @export
generate_work_signposting <- function(doi, register_table, has_jsonld = FALSE) {
  fields <- get_work_metadata_fields(doi, register_table)

  authors <- lapply(fields$authors, function(author) {
    if (is.null(author$orcid) || !is_nonempty_string(author$orcid)) return(NULL)
    list(rel = "author", href = paste0(CONFIG$HYPERLINKS[["orcid"]], author$orcid))
  })

  links <- c(
    list(
      list(rel = "cite-as", href = paste0(CONFIG$HYPERLINKS[["doi"]], doi)),
      list(rel = "type", href = "https://schema.org/ScholarlyArticle"),
      list(rel = "type", href = "https://schema.org/AboutPage")
    ),
    authors,
    list(
      list(rel = "describedby", href = "index.json", type = "application/json"),
      list(rel = "describedby", href = if (isTRUE(has_jsonld)) "index.jsonld" else NULL,
           type = "application/ld+json")
    ),
    wikidata_signposting_links(wikidata_id_for("paper", doi)),
    list(
      list(rel = "alternate", href = "register.json", type = "application/json"),
      list(rel = "alternate", href = "register.md", type = "text/markdown"),
      list(rel = "license", href = CONFIG$LICENSE_REGISTER)
    )
  )

  signposting_link_tags(links)
}

#' Signposting links for a person page
#'
#' `ProfilePage` is Schema.org's type for exactly this page, and an ORCID is a
#' persistent identifier for the person the page is about, so a person page can
#' carry a `cite-as` as well. No `author`: the person authors the checks listed
#' on the page, not the page.
#'
#' @param orcid The person's ORCID
#' @param has_jsonld Whether `index.jsonld` was written next to the page
#' @return HTML string of `<link>` elements, one per line
#' @export
generate_person_signposting <- function(orcid, has_jsonld = FALSE) {
  links <- c(list(
    list(rel = "cite-as", href = if (is_nonempty_string(orcid)) paste0(CONFIG$HYPERLINKS[["orcid"]], orcid) else NULL),
    list(rel = "type", href = "https://schema.org/ProfilePage"),
    list(rel = "type", href = "https://schema.org/AboutPage"),
    list(rel = "describedby", href = if (isTRUE(has_jsonld)) "index.jsonld" else NULL,
         type = "application/ld+json")),
    wikidata_signposting_links(wikidata_id_for("person", orcid)),
    list(
    list(rel = "alternate", href = "register.json", type = "application/json"),
    list(rel = "alternate", href = "stats.json", type = "application/json"),
    list(rel = "license", href = CONFIG$LICENSE_REGISTER))
  )

  signposting_link_tags(links)
}

#' Signposting links for a venue page
#'
#' Venues have persistent identifiers too: `venues.csv` carries a `wikidata`
#' column, and a Wikidata entity URI is the one PID that exists for every venue
#' type, which is what `cite-as` needs given its cardinality of 1. The ISSNs in
#' the `identifiers` column stay where they are, in the Schema.org `sameAs`.
#' A venue without a Wikidata item simply gets no `cite-as`.
#'
#' Some rows of `venues.csv` are not venues but publication states - "preprint",
#' "in press" - and their `wikidata` value is a class item the Wikidata data
#' model types checked works with (Q580922, "preprint"), not an identifier of
#' the venue. Those get no `cite-as` either: `cite-as` states the PID *of the
#' thing the page is about*, and a class shared across the register is not it.
#' They are recognised by looking the value up in [WIKIDATA_ITEMS].
#'
#' @param venue_name The venue's name (`venues.csv` `name` column)
#' @param venue_type The venue's type, mapped to a Schema.org class by
#'   \code{\link{venue_schema_org_type}}
#' @param has_jsonld Whether `index.jsonld` was written next to the page
#' @return HTML string of `<link>` elements, one per line
#' @export
generate_venue_signposting <- function(venue_name, venue_type, has_jsonld = FALSE) {
  wikidata_id <- NULL
  if (exists("VENUE_DATA", envir = CONFIG) && !is.null(CONFIG$VENUE_DATA) &&
      "wikidata" %in% names(CONFIG$VENUE_DATA)) {
    venue_row <- CONFIG$VENUE_DATA[CONFIG$VENUE_DATA$name == venue_name, , drop = FALSE]
    if (nrow(venue_row) > 0 && is_nonempty_string(venue_row$wikidata[1])) {
      candidate <- trimws(venue_row$wikidata[1])
      if (!candidate %in% unlist(WIKIDATA_ITEMS)) wikidata_id <- candidate
    }
  }

  schema_type <- if (is_nonempty_string(venue_type)) venue_schema_org_type(venue_type) else "Organization"

  links <- list(
    list(rel = "cite-as", href = if (!is.null(wikidata_id)) paste0(CONFIG$HYPERLINKS[["wikidata"]], wikidata_id) else NULL),
    list(rel = "type", href = paste0("https://schema.org/", schema_type)),
    list(rel = "type", href = "https://schema.org/AboutPage"),
    list(rel = "describedby", href = "index.json", type = "application/json"),
    list(rel = "describedby", href = if (isTRUE(has_jsonld)) "index.jsonld" else NULL,
         type = "application/ld+json"),
    list(rel = "alternate", href = "register.json", type = "application/json"),
    list(rel = "alternate", href = "register.csv", type = "text/csv"),
    list(rel = "alternate", href = "register.md", type = "text/markdown"),
    list(rel = "license", href = CONFIG$LICENSE_REGISTER)
  )

  signposting_link_tags(links)
}

#' Signposting links for a listing or overview page
#'
#' Listing pages are not scholarly objects, so they are outside the FAIR
#' Signposting profile and carry no `cite-as`. They do get the same vocabulary
#' of typed links, which is what makes the register's JSON and CSV exports
#' discoverable from the HTML rather than only from the documentation.
#'
#' They deliberately carry no `item` links to their member certificates:
#' `item` means a content resource of the described object - on a certificate
#' page, the PDF - and reusing it for list membership would make those links
#' ambiguous. Enumerating members is what a Level 2 link set is for, which
#' GitHub Pages cannot serve conformantly, see
#' \code{\link{signposting_link_tags}}.
#'
#' @param is_main_register Whether this is the unfiltered register page, which
#'   is the only one with the full CSV and JSON exports next to it
#' @param has_register_files Whether `register.json` and `register.md` sit next
#'   to the page; false for the overview pages that only list subpages
#' @param has_index_json Whether `index.json` sits next to the page, which is
#'   the case for the overview pages but not for the main register page
#' @return HTML string of `<link>` elements, one per line
#' @export
generate_list_signposting <- function(is_main_register = FALSE,
                                      has_register_files = TRUE,
                                      has_index_json = FALSE) {
  links <- list(
    list(rel = "type", href = "https://schema.org/CollectionPage"),
    list(rel = "describedby", href = if (isTRUE(has_index_json)) "index.json" else NULL,
         type = "application/json"),
    list(rel = "alternate", href = if (isTRUE(has_register_files)) "register.json" else NULL,
         type = "application/json"),
    list(rel = "alternate", href = if (isTRUE(has_register_files)) "register.md" else NULL,
         type = "text/markdown"),
    list(rel = "alternate", href = if (isTRUE(is_main_register)) "register-full.json" else NULL,
         type = "application/json"),
    list(rel = "alternate", href = if (isTRUE(is_main_register)) "register-full.csv" else NULL,
         type = "text/csv"),
    list(rel = "license", href = CONFIG$LICENSE_REGISTER)
  )

  signposting_link_tags(links)
}

#' Signposting links for any non-certificate register page
#'
#' Dispatches on the same `filter`/`table_details` pair the Schema.org
#' generation in \code{\link{render_html}} already switches on, so the two
#' descriptions of a page cannot drift apart.
#'
#' @param filter The filter name (`NA` for the main register, else "venues",
#'   "works", "persons", "codecheckers", ...)
#' @param table_details List containing details such as the table name and
#'   subcat name
#' @param register_table The page's register rows, needed for a work page's
#'   author ORCIDs
#' @param has_jsonld Whether `index.jsonld` was written next to the page
#' @return HTML string of `<link>` elements, one per line
#' @export
generate_page_signposting <- function(filter, table_details,
                                      register_table = NULL, has_jsonld = FALSE) {
  is_detail <- !is.na(filter) && isTRUE(table_details[["is_reg_table"]]) &&
    !is.null(table_details[["name"]]) && !is.na(table_details[["name"]])

  if (is_detail && filter == "venues") {
    return(generate_venue_signposting(table_details[["name"]], table_details[["subcat"]],
                                      has_jsonld = has_jsonld))
  }
  if (is_detail && filter == "works") {
    return(generate_work_signposting(table_details[["name"]], register_table,
                                     has_jsonld = has_jsonld))
  }
  # codecheckers pages redirect to the person page of the same ORCID, and both
  # describe the same person
  if (is_detail && filter %in% c("persons", "codecheckers")) {
    return(generate_person_signposting(table_details[["name"]], has_jsonld = has_jsonld))
  }
  if (is_detail && filter == "organisations") {
    return(generate_organisation_signposting(table_details[["name"]], has_jsonld = has_jsonld))
  }

  # A filtered listing page (all venues, all works, ...) lists subpages and has
  # no register.json of its own; the main register page has the full exports.
  generate_list_signposting(
    is_main_register = is.na(filter),
    has_register_files = is.na(filter) || isTRUE(table_details[["is_reg_table"]]),
    has_index_json = !is.na(filter) && !isTRUE(table_details[["is_reg_table"]])
  )
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
    citation_meta = "",
    signposting = ""
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
      has_citation_meta = is_nonempty_string(page_metadata$citation_meta),
      has_signposting = is_nonempty_string(page_metadata$signposting)
    ))
}

#' Signposting links for an organisation page
#'
#' The ROR is the organisation's persistent identifier, so it is what
#' `cite-as` names - the analogue of the ORCID on a person page.
#'
#' @param ror The organisation's ROR id.
#' @param has_jsonld Whether an `index.jsonld` was written next to the page.
#' @return The `<link>` elements as an HTML string.
#' @keywords internal
generate_organisation_signposting <- function(ror, has_jsonld = FALSE) {
  links <- list(
    list(rel = "cite-as", href = if (is_nonempty_string(ror)) paste0("https://ror.org/", ror) else NULL),
    list(rel = "type", href = "https://schema.org/AboutPage"),
    list(rel = "type", href = "https://schema.org/Organization"),
    list(rel = "describedby", href = if (isTRUE(has_jsonld)) "index.jsonld" else NULL,
         type = "application/ld+json"),
    list(rel = "alternate", href = "register.json", type = "application/json"),
    list(rel = "alternate", href = "stats.json", type = "application/json"),
    list(rel = "license", href = CONFIG$LICENSE_REGISTER)
  )

  signposting_link_tags(links)
}

#' Schema.org metadata for an organisation page
#'
#' An `Organization` identified by its ROR, with the checked works its people
#' authored and the certificates its people produced, mirroring
#' [generate_person_schema_org()] - the organisation is the `affiliation` of
#' the people the register knows, so the works and reviews it lists are theirs
#' (register#53).
#'
#' @param ror The organisation's ROR id.
#' @param register_table The organisation's exploded register rows.
#' @return The JSON-LD as a string.
#' @keywords internal
generate_organisation_schema_org <- function(ror, register_table) {
  fields <- get_organisation_metadata(ror)
  organisation_id <- paste0("https://ror.org/", ror)

  organisation <- list(
    `@context` = "https://schema.org",
    `@type` = "Organization",
    `@id` = organisation_id,
    name = fields$name,
    identifier = organisation_id,
    url = paste0(CONFIG$HYPERLINKS[["organisations"]], ror, "/")
  )
  if (!is.na(fields$website_url)) organisation$sameAs <- fields$website_url
  if (!is.na(fields$city) || !is.na(fields$country)) {
    organisation$location <- list(
      `@type` = "Place",
      address = paste(stats::na.omit(c(fields$city, fields$country)), collapse = ", ")
    )
  }

  has_role <- "Role" %in% names(register_table)
  checked <- if (has_role) register_table[register_table$Role == "codechecker", , drop = FALSE] else register_table[0, , drop = FALSE]

  # The certificates this organisation's people produced, as Reviews - the
  # same shape a person page uses, without repeating a certificate that two
  # of its people worked on.
  reviews <- list()
  for (cert_id in unique(checked$Certificate)) {
    if (is.na(cert_id)) next
    cert_url <- paste0(CONFIG$HYPERLINKS[["certs"]], cert_id, "/")
    reviews[[length(reviews) + 1]] <- list(
      `@type` = "Review", `@id` = cert_url,
      name = paste("CODECHECK Certificate", cert_id), url = cert_url
    )
  }
  if (length(reviews) > 0) organisation$subjectOf <- reviews

  jsonlite::toJSON(organisation, auto_unbox = TRUE, pretty = TRUE, null = "null")
}
