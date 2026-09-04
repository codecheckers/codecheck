#' Function for clearing the register cache
#'
#' Removes everything cached below the R.cache root: the codecheck.yml files,
#' the codecheckers table, and the looked up OpenAlex IDs and abstracts. Use it
#' to pick up metadata that has changed at the source, the lookups themselves
#' never cache a failed request.
#'
#' @return 0 for success, 1 for failure, invisibly (see `unlink`)
#'
#' @author Daniel Nuest
#' @importFrom R.cache getCacheRootPath
#' @export
register_clear_cache <- function() {
  path <- R.cache::getCacheRootPath()
  cli::cli_alert_info("Deleting cache path {.path {path}}")
  unlink(path, recursive = TRUE)
  clear_cert_link_cache()
}

#' Fetch a `codecheck.yml` without aborting the whole render
#'
#' The register is rendered from 130+ `codecheck.yml` files spread over
#' GitHub, OSF, GitLab and Zenodo, and every one of them is a chance for a
#' rate limit, an outage or a moved repository. A single such failure must
#' degrade the one entry it concerns, not stop the render of all the others -
#' so every enrichment loop below goes through this wrapper, which turns the
#' error into a warning naming the certificate (`register_render()` collects
#' and reports those at the end) and returns `NULL`, the same value the
#' loops already handle for a repository without a `codecheck.yml`.
#'
#' @param repo The repository specification, i.e. the `Repository` column
#' @param cert_id The certificate identifier, for the warning message
#' @return The parsed `codecheck.yml`, or `NULL` if it could not be retrieved
get_codecheck_yml_or_null <- function(repo, cert_id = NULL) {
  tryCatch(
    get_codecheck_yml(repo),
    error = function(e) {
      warning("Could not retrieve codecheck.yml from ", repo,
              if (!is.null(cert_id)) paste0(" for certificate ", cert_id) else "",
              ": ", conditionMessage(e))
      NULL
    }
  )
}

#' Function for adding clickable links to the paper for each entry in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table
add_paper_links <- function(register_table, register){
  list_hyperlinks <- c()

  # Looping over the entries in the register
  for (i in seq_len(nrow(register))) {
    # Retrieving the link to the paper 
    config_yml <- get_codecheck_yml_or_null(register[i, ]$Repo, register[i, ]$Certificate)

    # Without the configuration there is neither a title nor a link, so the
    # entry keeps its place in the table with an empty cell
    if (is.null(config_yml)) {
      list_hyperlinks <- c(list_hyperlinks, NA_character_)
      next
    }

    paper_link <- config_yml[["paper"]][["reference"]]
    paper_title <- config_yml[["paper"]][["title"]]

    # Removing new lines from paper title and link
    paper_title <- gsub("\n", " ", paper_title)
    paper_link <- gsub("\n$", "", paper_link)
    
    #cat("Adding paper link for ", paper_title, " with link ", paper_link, " for ", register[i, ]$Repo, "\n")
    # Checking if there is a valid url for the paper. If not we just add the title as it is
    url_regex <- "^https?://"
    if (!grepl(url_regex, paper_link)){
      warning("The codecheck_yml's paper reference is not a valid url.")
      list_hyperlinks <- c(list_hyperlinks, paper_title)
    }

    # If we have a valid url we add hyperlink
    else{
      paper_hyperlink <- paste0(
        "[",
        paper_title,
        "](",
        paper_link,
        ")"
      )
      list_hyperlinks <- c(list_hyperlinks, paper_hyperlink)
    }
  }
  # Creating a new "Paper Title" column and moving it next to the "Repository" column
  register_table <- register_table %>% 
    mutate(`Paper Title` = list_hyperlinks) %>%
    relocate(`Paper Title`, .after = Repository)
  return(register_table)
}

#' Function for adding report URLs for each entry in the register table.
#'
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table with Report column containing plain URLs
add_report_links <- function(register_table, register) {

  reports <- c()

  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml_or_null(register[i, ]$Repo, register[i, ]$Certificate)

    report <- NA
    if (!is.null(config_yml)) {
      report <- config_yml$report
    }

    reports <- c(reports, report)
  }
  register_table$Report <- reports
  return(register_table)
}

#' Function for adding clickable links to the issue number of each report in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table
add_issue_number_links <- function(register_table, register) {
  register_table$Issue <- sapply(
    X = register$Issue,
    FUN = function(issue_id) {
      if (!is.na(issue_id)) {
        paste0(
          "[",
          issue_id,
          "](",
          CONFIG$HYPERLINKS[["codecheck_issue"]],
          issue_id, ")"
        )
      } else {
        issue_id
      }
    }
  )
  return(register_table)
}

#' Was a time of day recorded with the check time?
#'
#' `check_time` in a `codecheck.yml` is written with whatever precision the
#' codechecker had at hand: some entries are a bare day, others a full
#' timestamp. Readers only ever see the day (register#219), so the precision
#' matters solely for the machine-readable exports, which keep it.
#'
#' @param x The raw `check_time` value from a codecheck.yml
#' @return TRUE if `x` carries a time of day
#' @keywords internal
check_time_has_time_of_day <- function(x) {
  is_nonempty_string(x) && grepl("[0-9]{1,2}:[0-9]{2}", x)
}

#' The check time as shown to readers: the day, never the time
#'
#' @param x The raw `check_time` value from a codecheck.yml
#' @return `YYYY-MM-DD`, or NA if `x` is missing or unparseable
#' @keywords internal
format_check_date <- function(x) {
  if (!is_nonempty_string(x)) return(NA_character_)
  parsed <- parsedate::parse_date(x)
  if (is.na(parsed)) return(NA_character_)
  format(parsed, "%Y-%m-%d")
}

#' The check time for machine-readable output, at the recorded precision
#'
#' ISO 8601 with the time of day where the codecheck.yml recorded one, the
#' bare day where it did not - a `00:00:00` invented by the parser would
#' claim a precision that was never there.
#'
#' @param x The raw `check_time` value from a codecheck.yml
#' @return An ISO 8601 date or date-time, or NA if `x` is missing or
#'   unparseable
#' @keywords internal
format_check_time_iso <- function(x) {
  if (!is_nonempty_string(x)) return(NA_character_)
  parsed <- parsedate::parse_date(x)
  if (is.na(parsed)) return(NA_character_)
  if (!check_time_has_time_of_day(x)) {
    return(format(parsed, "%Y-%m-%d"))
  }
  # A codecheck.yml usually writes "2020-04-13 10:00:00", a wall clock with no
  # zone; parsedate reads that as UTC, so formatting it back in UTC returns the
  # time as written instead of shifting it. Only a value that named a zone
  # itself gets an offset in the output.
  if (grepl("(Z|[+-][0-9]{2}:?[0-9]{2})$", trimws(x))) {
    parsedate::format_iso_8601(parsed)
  } else {
    format(parsed, "%Y-%m-%dT%H:%M:%S", tz = "UTC")
  }
}

#' Function for adding check time to each report in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table
add_check_time <- function(register_table, register) {
  check_times <- c()

  # Looping over the entries in the register
  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml_or_null(register[i, ]$Repo, register[i, ]$Certificate)

    check_time <- NA
    if (!is.null(config_yml)) {
      check_time <- config_yml$check_time
    }

    check_times <- c(check_times, check_time)
  }
  check_times <- parsedate::parse_date(check_times)
  register_table$`Check date` <- format(check_times, "%Y-%m-%d")

  return(register_table)
}

#' Function for adding codechecker to each report in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table
add_codechecker <- function(register_table, register) {
  codecheckers <- vector("list", length = nrow(register))

  # Looping over the entries in the register
  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml_or_null(register[i, ]$Repo, register[i, ]$Certificate)

    codechecker_ids <- c()
    if (!is.null(config_yml)  && !is.null(config_yml$codechecker)) {

      for (codechecker in config_yml$codechecker) {
        if(is.null(codechecker$name)) {
          stop("Codechecker name is missing in ", config_yml$certificate)
        }

        # Use ORCID as identifier if available
        if (!is.null(codechecker$ORCID) && codechecker$ORCID != "") {
          if (!(codechecker$ORCID %in% names(CONFIG$DICT_ORCID_ID_NAME))) {
            CONFIG$DICT_ORCID_ID_NAME[codechecker$ORCID] <- codechecker$name
          }
          codechecker_ids <- c(codechecker_ids, codechecker$ORCID)
        } else {
          # Fall back to GitHub username for codecheckers without ORCID
          github_username <- get_github_handle_by_name(codechecker$name)

          if (!is.null(github_username)) {
            # Use GitHub username directly as identifier
            if (!(github_username %in% names(CONFIG$DICT_GITHUB_USERNAME_NAME))) {
              CONFIG$DICT_GITHUB_USERNAME_NAME[github_username] <- codechecker$name
            }
            codechecker_ids <- c(codechecker_ids, github_username)
          } else {
            # Use "NA" as identifier for codecheckers without ORCID or GitHub username
            codechecker_ids <- c(codechecker_ids, "NA")
            warning("codechecker ORCID and GitHub username missing for ", codechecker$name, " in ", config_yml$certificate)
          }
        }
      }
    } else {
      warning("codechecker not found in record ", toString(register[i, ]))
    }

    codecheckers[[i]] <- codechecker_ids
  }
  register_table$`Codechecker` <- codecheckers
  return(register_table)
}

#' Function for adding certificate identifier and link as extra columns
#'
#' The `Certificate` column itself is left as the plain identifier - callers
#' that need it as a markdown link (only the md/HTML table rendering does,
#' via [adjust_cert_links_relative()]) build that themselves at render time.
#' Every other consumer (JSON/CSV output, Schema.org generation, Zenodo/
#' ResearchEquals policy checks, ...) can then read `Certificate` directly
#' without having to strip markdown syntax back out of it first.
#'
#' @param register_table The register table to be adjusted.
#' @return The adjusted register table with new columns for certificate identifier and certificate URL
add_cert_links <- function(register_table){
  register_table$`Certificate ID` <- register_table$Certificate
  register_table$`Certificate Link` <- paste0(CONFIG$HYPERLINKS[["certs"]], register_table$Certificate, "/")

  return(register_table)
}

#' Creates a temporary CSV register with a "Codechecker" column.
#' 
#' The function flattens the "Codechecker" column and saves the resulting table 
#' as a temporary CSV file. This tempeorary CSV is needed to filter the registers b
#' by codecheckers.
#' 
#' @param register_table The register table with a "Codechecker" column.
#' 
#' @importFrom utils write.csv
#' 
create_temp_register_with_codechecker <- function(register_table){
  # Flatten the Codechecker column (convert list elements to comma-separated strings)
  # This is done since jsons cannot handle list columns directly
  register_table$Codechecker <- sapply(register_table$Codechecker, function(x) paste(x, collapse = ","))
  write.csv(register_table, CONFIG$DIR_TEMP_REGISTER_CODECHECKER)
}

#' Add OpenAlex work IDs to the register table (addresses register#185)
#'
#' Unlike the per-certificate index.json (rendered via
#' \code{\link{resolve_external_field}}), this table feeds the aggregate
#' outputs (docs/register.json and the venue-filtered json/csv) directly, so
#' it needs the same protection: a lookup that merely failed this run (rate
#' limit, network blip) must fall back to the certificate's existing
#' index.json rather than overwrite a previously-known-good ID with NA - the
#' same regression \code{\link{resolve_external_field}} exists to prevent,
#' just reached through a different render path.
#'
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The register table with added "OpenAlex" column
add_openalex_ids <- function(register_table, register) {
  cli::cli_alert_info("Looking up OpenAlex IDs")
  openalex_ids <- c()
  paper_references <- c()

  for (i in seq_len(nrow(register))) {
    cert_id <- register[i, ]$Certificate
    # A single flaky fetch (of 132+ external repos, across several hosts)
    # must not abort the whole render - same reasoning as the OpenAlex
    # lookup below, just one step earlier.
    config_yml <- get_codecheck_yml_or_null(register[i, ]$Repo, cert_id)
    paper_reference <- config_yml$paper$reference %||% NA_character_
    paper_references <- c(paper_references, paper_reference)
    warn_if_pdf_reference(cert_id, paper_reference)

    lookup <- if (!is.null(config_yml) && !is.null(config_yml$paper$reference)) {
      first_author <- NULL
      if (!is.null(config_yml$paper$authors) && length(config_yml$paper$authors) > 0) {
        first_author <- config_yml$paper$authors[[1]]$name
      }
      tryCatch(
        get_openalex_id_cached_result(
          config_yml$paper$reference,
          paper_title = config_yml$paper$title,
          first_author_name = first_author
        ),
        error = function(e) list(status = "failed", value = NA_character_)
      )
    } else {
      list(status = "failed", value = NA_character_)
    }

    openalex_id <- resolve_external_field(
      cert_id, c("paper", "openalex"), lookup$status, lookup$value,
      empty_value = NA_character_, prune_unavailable = isTRUE(CONFIG$PRUNE_UNAVAILABLE_METADATA)
    )
    openalex_ids <- c(openalex_ids, openalex_id)
  }

  register_table$OpenAlex <- openalex_ids
  n_found <- sum(!is.na(openalex_ids))
  cli::cli_alert_success("Found {n_found}/{nrow(register)} OpenAlex IDs")

  register_table <- add_openalex_work_fields(register_table, paper_references)
  return(register_table)
}

#' Add the publication facts behind each OpenAlex ID (register#50)
#'
#' Part of the same enrichment: an OpenAlex ID is a pointer, and the record it
#' points at is the only place that says which publication a checked work
#' appeared in and when. Both are needed to describe the work as linked data -
#' the register's own `Venue` column names the venue that commissioned the
#' check, which is a different fact and, for a conference running over several
#' years, a different publication.
#'
#' Costs one cached request per work that has an ID, and nothing at all for one
#' that does not.
#'
#' @param register_table The register table, with an `OpenAlex` column
#' @param paper_references Optional character vector, same length and order
#'   as `register_table`'s rows, of each work's `paper.reference` URL from its
#'   `codecheck.yml`. Used only as a fallback (see below); pass NULL/omit to
#'   skip it (e.g. for a per-certificate re-render with a one-row table).
#' @return The register table with added "Paper ISSN", "Paper venue" and
#'   "Work publication date" columns
add_openalex_work_fields <- function(register_table, paper_references = NULL) {
  if (!"OpenAlex" %in% colnames(register_table)) {
    return(register_table)
  }
  cli::cli_alert_info("Looking up the publication of each work")

  fields <- lapply(register_table$OpenAlex, function(id) {
    if (is.na(id)) return(list(issn = NA_character_, venue = NA_character_,
                               publication_date = NA_character_))
    tryCatch(
      get_openalex_work_fields_cached_result(id)$value,
      error = function(e) list(issn = NA_character_, venue = NA_character_,
                               publication_date = NA_character_)
    )
  })

  register_table$`Paper ISSN` <- vapply(fields, function(f) f$issn %||% NA_character_, character(1))
  register_table$`Paper venue` <- vapply(fields, function(f) f$venue %||% NA_character_, character(1))
  publication_dates <- vapply(fields, function(f) f$publication_date %||% NA_character_, character(1))

  # OpenAlex has no record at all for some works (an arXiv preprint, a
  # conference proceedings entry, an institutional repository item, ...) -
  # for those, fall back to reading the date straight off the paper's own
  # reference URL: citation_* meta tags, schema.org JSON-LD, or (for a
  # reference that is itself a PDF) the PDF's own metadata.
  if (!is.null(paper_references) && length(paper_references) == length(publication_dates)) {
    n_from_page <- 0L
    for (i in seq_along(publication_dates)) {
      if (!is.na(publication_dates[i])) next
      reference <- paper_references[i]
      if (is.na(reference) || !nzchar(reference)) next
      page_result <- tryCatch(
        get_page_publication_date_cached_result(reference),
        error = function(e) list(status = "failed", value = NA_character_)
      )
      if (identical(page_result$status, "found") && !is.na(page_result$value)) {
        publication_dates[i] <- page_result$value
        n_from_page <- n_from_page + 1L
      }
    }
    if (n_from_page > 0) {
      cli::cli_alert_success("Found {n_from_page} publication date{?s} directly from the paper's own page (OpenAlex had none)")
    }
  }

  register_table$`Work publication date` <- publication_dates

  cli::cli_alert_success(
    "Found {sum(!is.na(register_table$`Paper ISSN`))} publication ISSN{?s} and {sum(!is.na(register_table$`Work publication date`))} publication date{?s}"
  )
  register_table
}

#' Function for preprocessing the register to create and return the preprocessed register table.
#' 
#' @param register The register.
#' @param filter_by The filter (if applicable).
#' 
#' @return The preprocessed register table
preprocess_register <- function(register, filter_by) {
    register_table <- register

    # The Codechecker column is foundational, not just for the "codecheckers"
    # filter's own output pages: compute_annual_stats() reads it for the main
    # statistics.json and every venue's index.json, and the statistics
    # dashboard reads those. It must be added unconditionally - gating it on
    # "codecheckers" %in% filter_by silently dropped codechecker counts
    # register-wide once register_render()'s default filter_by stopped
    # including "codecheckers" (#123/#150).
    register_table <- add_codechecker(register_table, register)
    register_table <- add_cert_links(register_table)
    register_table <- add_report_links(register_table, register)
    register_table <- add_issue_number_links(register_table, register)
    register_table <- add_check_time(register_table, register)
    register_table <- add_paper_links(register_table, register)
    register_table <- add_openalex_ids(register_table, register)

    if ("works" %in% filter_by){
      register_table <- add_work_key(register_table, register)
    }
    if ("persons" %in% filter_by){
      register_table <- add_person_records(register_table, register)
    }
    # Organisations are derived from the people, so their records need the
    # Person column whether or not the person pages themselves are rendered.
    if ("organisations" %in% filter_by){
      if (!("Person" %in% names(register_table))) {
        register_table <- add_person_records(register_table, register)
      }
      register_table <- add_organisation_records(register_table)
    }

    # Create temp register CSV after all enrichment is complete
    # This ensures the CSV has all enriched columns for codechecker filtering
    if ("codecheckers" %in% filter_by){
      create_temp_register_with_codechecker(register_table)
    }

    return(register_table)
}
