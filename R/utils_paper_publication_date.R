#' Parse a partial or full publication date string into an ISO date
#'
#' Publication-date metadata found in the wild is often partial: a bare year
#' ("2022"), a year and month ("2022/6", separators "/" or "-"), a full date
#' ("2025/07/04", "2025-07-04"), or a full ISO 8601 timestamp
#' ("2025-12-11T15:19:52+0100", schema.org's `datePublished`). The statistics
#' dashboard's interval calculations need one concrete calendar day per work,
#' so a partial date is filled in at its most likely midpoint (day 15 of a
#' known month, July 2 of a bare year) rather than defaulted to the 1st -
#' which would systematically bias every partial date toward "early in the
#' period" - or left as NA, which would silently drop the work from the
#' interval statistics entirely.
#'
#' @param date_str A date string in one of the formats above, or NA/NULL
#' @return An ISO "YYYY-MM-DD" string, or NA_character_ if unparseable
#' @keywords internal
parse_partial_publication_date <- function(date_str) {
  if (is.null(date_str) || length(date_str) != 1 || is.na(date_str) || !nzchar(trimws(date_str))) {
    return(NA_character_)
  }
  s <- trimws(date_str)

  # Full ISO 8601 timestamp (schema.org datePublished, with a time and
  # timezone offset) - only the calendar date part is used.
  if (grepl("^\\d{4}-\\d{2}-\\d{2}T", s)) {
    d <- tryCatch(as.Date(substr(s, 1, 10)), error = function(e) NA)
    return(if (length(d) != 1 || is.na(d)) NA_character_ else format(d, "%Y-%m-%d"))
  }

  # Full date, "/" or "-" separated: YYYY/MM/DD or YYYY-MM-DD
  if (grepl("^\\d{4}[/-]\\d{1,2}[/-]\\d{1,2}$", s)) {
    d <- tryCatch(as.Date(gsub("/", "-", s)), error = function(e) NA)
    return(if (length(d) != 1 || is.na(d)) NA_character_ else format(d, "%Y-%m-%d"))
  }

  # Year and month only, "/" or "-" separated: YYYY/MM or YYYY-MM (e.g.
  # ACL Anthology's "2022/6")
  if (grepl("^\\d{4}[/-]\\d{1,2}$", s)) {
    parts <- strsplit(s, "[/-]")[[1]]
    year <- suppressWarnings(as.integer(parts[1]))
    month <- suppressWarnings(as.integer(parts[2]))
    if (is.na(year) || is.na(month) || month < 1 || month > 12) return(NA_character_)
    return(sprintf("%04d-%02d-15", year, month))
  }

  # Bare year
  if (grepl("^\\d{4}$", s)) {
    return(sprintf("%s-07-02", s))
  }

  NA_character_
}

#' Warn when a certificate's paper reference is a plain PDF link
#'
#' A direct PDF link (no DOI, no publisher/repository landing page) carries no
#' machine-readable publication metadata for the OpenAlex/page-scrape lookups
#' to read, and such links are also prone to rotting (see register#219 and the
#' 2020-008/2020-009 CMMID reports, both 404 as of writing). Surfaced during
#' every render as a nudge to fix the source `codecheck.yml`, per the
#' guidance added to the community workflow spec: prefer a DOI or landing
#' page, and if a PDF is genuinely the only option, use a
#' https://web.archive.org/ snapshot URL rather than the live one.
#'
#' @param cert_id The certificate ID, for the warning message
#' @param paper_reference The paper reference URL, or NA
#' @return Invisibly TRUE if a warning was issued, FALSE otherwise
#' @keywords internal
warn_if_pdf_reference <- function(cert_id, paper_reference) {
  if (is.na(paper_reference) || !nzchar(paper_reference)) {
    return(invisible(FALSE))
  }
  is_pdf <- grepl("\\.pdf($|\\?)", paper_reference, ignore.case = TRUE)
  if (!is_pdf) {
    return(invisible(FALSE))
  }
  is_archived <- grepl("^https?://web\\.archive\\.org/", paper_reference, ignore.case = TRUE)
  if (is_archived) {
    return(invisible(FALSE))
  }
  cli::cli_alert_warning(
    "{cert_id} | paper.reference is a plain PDF link ({paper_reference}) - prefer a DOI or landing page; if none exists, use a web.archive.org snapshot URL instead (it carries publication metadata and is less likely to 404)"
  )
  invisible(TRUE)
}

#' Extract a citation_* publication-date meta tag from an HTML page
#'
#' Checks, in priority order, `citation_online_date` (the earliest date a
#' work was made public - preprints, early view), `citation_publication_date`
#' and `citation_date`: the Highwire Press / Google Scholar metadata tags
#' academic publisher and repository platforms embed (arXiv, TU/e's Pure
#' repository, ACL Anthology, Copernicus journals, ...).
#'
#' @param html_text The page's HTML source
#' @return The tag's raw `content` string, or NA_character_ if none present
#' @keywords internal
extract_citation_meta_date <- function(html_text) {
  doc <- tryCatch(xml2::read_html(html_text), error = function(e) NULL)
  if (is.null(doc)) return(NA_character_)

  for (tag in c("citation_online_date", "citation_publication_date", "citation_date")) {
    nodes <- xml2::xml_find_all(doc, sprintf("//meta[@name='%s']", tag))
    if (length(nodes) > 0) {
      content <- xml2::xml_attr(nodes[[1]], "content")
      if (!is.na(content) && nzchar(content)) return(content)
    }
  }
  NA_character_
}

#' Extract a schema.org `datePublished` from a page's JSON-LD
#'
#' Reads every `<script type="application/ld+json">` block and returns the
#' first `datePublished` found, at the top level or inside a `@graph` array
#' (the shape some publishing platforms, e.g. IIEP-UNESCO, use).
#'
#' @param html_text The page's HTML source
#' @return A date string (typically ISO 8601), or NA_character_ if none present
#' @keywords internal
extract_schema_org_date_published <- function(html_text) {
  doc <- tryCatch(xml2::read_html(html_text), error = function(e) NULL)
  if (is.null(doc)) return(NA_character_)

  nodes <- xml2::xml_find_all(doc, "//script[@type='application/ld+json']")
  for (node in nodes) {
    json_text <- xml2::xml_text(node)
    parsed <- tryCatch(jsonlite::fromJSON(json_text, simplifyVector = FALSE), error = function(e) NULL)
    if (is.null(parsed)) next

    candidates <- if (!is.null(parsed$datePublished)) list(parsed) else parsed$`@graph`
    for (item in candidates) {
      if (!is.null(item$datePublished) && nzchar(item$datePublished)) {
        return(item$datePublished)
      }
    }
  }
  NA_character_
}

#' Look up a work's publication date directly from its own landing page
#'
#' Fallback for when OpenAlex has no record for a work at all (an arXiv
#' preprint, a conference proceedings entry, an institutional repository
#' item, ...): tries, in order, HTML `citation_*` meta tags, schema.org
#' `datePublished` JSON-LD, and - for a reference that is itself a PDF with
#' no separate landing page - the PDF's own `Created` metadata via
#' `pdftools::pdf_info()`.
#'
#' @param url The paper reference URL (typically the same URL used for the
#'   OpenAlex lookup)
#' @return A list with `status` ("found", "absent" or "failed") and `value`,
#'   an ISO "YYYY-MM-DD" string or NA_character_
#' @keywords internal
get_page_publication_date_result <- function(url) {
  if (is.null(url) || is.na(url) || !nzchar(url)) {
    return(list(status = "absent", value = NA_character_))
  }

  response <- codecheck_GET_retry(url)
  if (is.null(response)) {
    return(list(status = "failed", value = NA_character_))
  }
  status <- httr::status_code(response)
  if (status != 200) {
    return(list(status = if (status == 404) "absent" else "failed", value = NA_character_))
  }

  content_type <- httr::headers(response)[["content-type"]] %||% ""
  is_pdf <- grepl("application/pdf", content_type, fixed = TRUE) ||
    grepl("\\.pdf($|\\?)", url, ignore.case = TRUE)

  if (is_pdf) {
    tmp <- tempfile(fileext = ".pdf")
    on.exit(unlink(tmp), add = TRUE)
    body <- tryCatch(httr::content(response, "raw"), error = function(e) NULL)
    if (is.null(body)) {
      return(list(status = "failed", value = NA_character_))
    }
    writeBin(body, tmp)
    created <- tryCatch(pdftools::pdf_info(tmp)$created, error = function(e) NULL)
    if (is.null(created) || length(created) != 1 || is.na(created)) {
      return(list(status = "absent", value = NA_character_))
    }
    return(list(status = "found", value = format(as.Date(created), "%Y-%m-%d")))
  }

  html_text <- tryCatch(httr::content(response, "text", encoding = "UTF-8"), error = function(e) NA_character_)
  if (length(html_text) != 1 || is.na(html_text)) {
    return(list(status = "failed", value = NA_character_))
  }

  raw_date <- extract_citation_meta_date(html_text)
  if (is.na(raw_date)) {
    raw_date <- extract_schema_org_date_published(html_text)
  }
  if (is.na(raw_date)) {
    return(list(status = "absent", value = NA_character_))
  }

  parsed <- parse_partial_publication_date(raw_date)
  if (is.na(parsed)) {
    return(list(status = "absent", value = NA_character_))
  }
  list(status = "found", value = parsed)
}

#' Cached version of get_page_publication_date_result
#'
#' Keyed on the URL, so a work whose landing page was already scraped costs
#' nothing on a later render. Cleared by \code{\link{register_clear_cache}}.
#'
#' @inheritParams get_page_publication_date_result
#' @noRd
get_page_publication_date_cached_result <- function(url) {
  cached_lookup_result(
    key = list("page_publication_date", url),
    dirs = c("codecheck", "page_publication_date"),
    lookup = function() get_page_publication_date_result(url)
  )
}

#' The publication date of a DOI's own record
#'
#' Asked before the landing page when OpenAlex has no date for a work, or a
#' date that belongs to another work: the registration agency holds what the
#' depositor registered, and for a preprint that is the day it was posted.
#' Landing pages are less reliable for exactly the works that need this - the
#' bioRxiv page of 2023-011 gives `citation_publication_date` 2023/01/01, and a
#' Copernicus discussion page shows the date of the final article.
#'
#' CrossRef's `posted` date comes first, as the date of posted content, then
#' the dates of publication online, in print and of issue. DataCite records the
#' versions of an arXiv preprint as `Submitted` dates, and the earliest full
#' date among `Submitted`, `Available` and `Issued` is the first public
#' version; the bare `publicationYear` is the last resort.
#'
#' @param reference The paper reference; anything that is not a DOI is absent
#' @return A list with `status` ("found", "absent" or "failed") and `value`,
#'   an ISO "YYYY-MM-DD" string or NA_character_
#' @keywords internal
get_registry_publication_date_result <- function(reference) {
  registry_date_result(get_registry_record_result(reference))
}

#' The publication date in a registry record lookup, as a date lookup result
#'
#' @param record A result of [get_registry_record_result()]
#' @return A list with `status` and `value`, see
#'   [get_registry_publication_date_result()]
#' @keywords internal
registry_date_result <- function(record) {
  if (!identical(record$status, "found")) {
    return(list(status = record$status, value = NA_character_))
  }
  parsed <- parse_partial_publication_date(record$value$publication_date)
  if (is.na(parsed)) list(status = "absent", value = NA_character_)
  else list(status = "found", value = parsed)
}

#' What a DOI's registration agency records about the work
#'
#' One request to doi.org for the agency, one to Crossref or DataCite for the
#' record. The record answers more than one question - when the work was made
#' public (see [get_registry_publication_date_result()]) and what type of work
#' it is (see [get_reference_type()]) - so it is fetched, and cached, once.
#'
#' @param reference The paper reference; anything that is not a DOI is absent
#' @return A list with `status` ("found", "absent" or "failed") and `value`,
#'   a list with `agency`, `publication_date` (as the record states it, see
#'   [crossref_publication_date()]) and `type` (see
#'   [crossref_reference_type()]), or `NULL`
#' @keywords internal
get_registry_record_result <- function(reference) {
  absent <- list(status = "absent", value = NULL)
  failed <- list(status = "failed", value = NULL)
  doi <- tolower(wikidata_transform(reference %||% NA_character_, "doi"))
  if (is.na(doi)) return(absent)

  agency <- lookup_registration_agency(doi)
  if (is.null(agency)) return(failed)
  # a DOI that does not exist is as absent as one without a record, and stays so
  if (is.na(agency)) return(absent)
  encoded <- utils::URLencode(doi, reserved = TRUE)
  url <- switch(agency,
    Crossref = paste0("https://api.crossref.org/works/", encoded),
    DataCite = paste0("https://api.datacite.org/dois/", encoded),
    return(absent))

  response <- tryCatch(codecheck_GET(url), error = function(e) NULL)
  if (is.null(response)) return(failed)
  if (httr::status_code(response) != 200) {
    return(if (httr::status_code(response) == 404) absent else failed)
  }
  body <- tryCatch(jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"),
                                      simplifyVector = FALSE),
                   error = function(e) NULL)
  if (is.null(body)) return(failed)

  crossref <- agency == "Crossref"
  record <- if (crossref) body$message else body$data$attributes
  list(status = "found", value = list(
    agency = agency,
    publication_date = (if (crossref) crossref_publication_date else datacite_publication_date)(record),
    type = (if (crossref) crossref_reference_type else datacite_reference_type)(record),
    # for an item of a further reference, which the register knows nothing else
    # about: its title and authors may differ from those of the checked work
    title = registry_title(if (crossref) record$title else
                             lapply(record$titles, function(t) t$title)),
    authors = registry_authors(if (crossref) record$author else record$creators)))
}

#' The first title of a registry record, without markup and surplus space
#'
#' @param titles a list of title strings
#' @return a string, or `NA`
#' @keywords internal
registry_title <- function(titles) {
  titles <- unlist(titles)
  if (length(titles) == 0 || is.na(titles[1])) return(NA_character_)
  title <- trimws(gsub("\\s+", " ", gsub("<[^>]+>", "", titles[1])))
  if (nzchar(title)) title else NA_character_
}

#' The author names of a registry record, "Given Family" where it has both
#'
#' @param people the `author` list of a Crossref record or the `creators` of a
#'   DataCite one
#' @return a character vector
#' @keywords internal
registry_authors <- function(people) {
  names <- vapply(people %||% list(), function(person) {
    given <- person$given %||% person$givenName
    family <- person$family %||% person$familyName
    name <- if (!is.null(given) && !is.null(family)) paste(given, family) else
      person$name %||% family %||% NA_character_
    as.character(name)[1]
  }, character(1))
  names[!is.na(names) & nzchar(trimws(names))]
}

#' Cached version of get_registry_record_result
#'
#' Keyed on the lowercased DOI. Cleared by \code{\link{register_clear_cache}}.
#'
#' @inheritParams get_registry_record_result
#' @noRd
get_registry_record_cached_result <- function(reference) {
  doi <- tolower(wikidata_transform(reference %||% NA_character_, "doi"))
  if (is.na(doi)) return(list(status = "absent", value = NULL))
  cached_lookup_result(
    # the record holds the display label of the type, so a change to
    # crossref_reference_type()/datacite_reference_type() bumps the version;
    # v2 added the title and authors
    key = list("registry_record", doi, "v2"),
    dirs = c("codecheck", "registry_record"),
    lookup = function() get_registry_record_result(reference)
  )
}

#' The date a CrossRef record says the work was made public
#'
#' @param message the `message` of a CrossRef works response
#' @return the date as "Y-M-D", "Y-M" or "Y", or `NA`
#' @keywords internal
crossref_publication_date <- function(message) {
  for (field in c("posted", "published-online", "published-print", "issued")) {
    parts <- suppressWarnings(as.integer(unlist(message[[field]]$`date-parts`[[1]])))
    parts <- parts[!is.na(parts)]
    if (length(parts) > 0) return(paste(parts, collapse = "-"))
  }
  NA_character_
}

#' The date a DataCite record says the work was made public
#'
#' @param attributes the `data$attributes` of a DataCite DOI response
#' @return the date as "YYYY-MM-DD" or a partial date, or `NA`
#' @keywords internal
datacite_publication_date <- function(attributes) {
  dates <- Filter(function(d) isTRUE(d$dateType %in% c("Submitted", "Available", "Issued")),
                  attributes$dates %||% list())
  values <- vapply(dates, function(d) as.character(d$date %||% NA_character_), character(1))
  full <- sort(substr(values[grepl("^\\d{4}-\\d{2}-\\d{2}", values)], 1, 10))
  if (length(full) > 0) return(full[1])
  partial <- sort(values[!is.na(values)])
  if (length(partial) > 0) return(partial[1])
  if (is.null(attributes$publicationYear)) NA_character_ else as.character(attributes$publicationYear)
}

#' Cached version of get_registry_publication_date_result
#'
#' Shares the cached registry record with [get_reference_type()]. Cleared by
#' \code{\link{register_clear_cache}}.
#'
#' @inheritParams get_registry_publication_date_result
#' @noRd
get_registry_publication_date_cached_result <- function(reference) {
  registry_date_result(get_registry_record_cached_result(reference))
}

#' A work's publication date when OpenAlex has none of its own
#'
#' The registry first, then the landing page, see
#' [get_registry_publication_date_result()].
#'
#' @param reference The paper reference
#' @return A list with `status`, `value` and `source` ("registry" or "page")
#' @keywords internal
get_fallback_publication_date <- function(reference) {
  for (source in c("registry", "page")) {
    lookup <- if (source == "registry") get_registry_publication_date_cached_result
              else get_page_publication_date_cached_result
    result <- tryCatch(lookup(reference),
                       error = function(e) list(status = "failed", value = NA_character_))
    if (identical(result$status, "found") && !is.na(result$value)) {
      return(c(result, source = source))
    }
  }
  list(status = "absent", value = NA_character_, source = NA_character_)
}
