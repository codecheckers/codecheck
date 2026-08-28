# The title a certificate carries on the platform it is published on.
#
# Certificates are not all archived on Zenodo - OSF and ResearchEquals are used
# as well - and the title of the record differs between them: the Zenodo
# curation policy prescribes "CODECHECK Certificate <ID>", while a module on
# ResearchEquals or a project on OSF may be titled differently. The citation
# metadata of a certificate page (see generate_cert_citation_meta()) must show
# the title the record actually has, so it is read from the platform rather
# than constructed from the certificate ID.
#
# The platform dispatch mirrors get_cert_link_uncached() in
# R/utils_download_certs.R, which resolves the certificate PDF from the same
# three platforms and the same `report` field of codecheck.yml.

#' The title of a certificate's record on its publication platform
#'
#' Reads the record title from Zenodo, OSF or ResearchEquals, whichever the
#' `report` link of the certificate points at. Cached on disk, because every
#' certificate is rendered into markdown, HTML and JSON and each of those asks
#' for the title again; only conclusive results are cached, so a rate limited
#' request is retried on the next render instead of persisting a gap, see
#' \code{\link{cached_lookup}}.
#'
#' @param report_link The `report` field of the certificate's codecheck.yml, a
#'   DOI or platform URL
#' @param cert_id Certificate identifier, used for logging and warnings
#' @return The record title as a string, or `NULL` when there is none to be had
#' @keywords internal
get_cert_record_title <- function(report_link, cert_id) {
  get_cert_record_title_cached_result(report_link, cert_id)$value
}

#' Cached version of get_cert_record_title, with the lookup status
#'
#' Same lookup as \code{\link{get_cert_record_title}}, but returns the full
#' `{status, value}` result so a caller can tell a platform that conclusively
#' has no title apart from one that could not be reached, see
#' \code{\link{resolve_external_field}}.
#'
#' @inheritParams get_cert_record_title
#' @return A list with `status` ("found", "absent" or "failed") and `value`
#' @keywords internal
get_cert_record_title_cached_result <- function(report_link, cert_id) {
  cached_lookup_result(
    key = list("cert_title", report_link),
    dirs = c("codecheck", "cert_title"),
    lookup = function() get_cert_record_title_result(report_link, cert_id)
  )
}

#' Read a record title and report whether the answer is conclusive
#'
#' Same lookup as \code{\link{get_cert_record_title}} without the caching, and
#' with the information needed to decide whether the result may be cached: a
#' report link on a platform the register cannot query is a conclusive "no
#' title" and is cached, a platform that could not be reached is not.
#'
#' @inheritParams get_cert_record_title
#' @return A list with `status` ("found", "absent" or "failed") and `value`
#' @keywords internal
get_cert_record_title_result <- function(report_link, cert_id) {
  report_link <- as.character(report_link)

  if (length(report_link) != 1 || is.na(report_link) || !nzchar(report_link)) {
    return(list(status = "absent", value = NULL))
  }

  # same order as get_cert_link_uncached(), so a certificate's title and its PDF
  # are always read from the same platform
  fetch <- if (grepl("zenodo", report_link, ignore.case = TRUE)) {
    get_zenodo_record_title
  } else if (grepl("OSF", report_link, ignore.case = TRUE)) {
    get_osf_record_title
  } else if (is_researchequals_report(report_link)) {
    get_researchequals_record_title
  } else {
    # a platform the register does not know how to query: there is no record
    # title to be read, now or on a later render, so this is conclusive
    return(list(status = "absent", value = NULL))
  }

  # the platform readers signal a platform they could not reach with an error,
  # and a record that simply carries no title with NULL
  fetched <- tryCatch(
    list(reached = TRUE, title = fetch(report_link)),
    error = function(e) {
      warning(cert_id, " | Could not read the record title from ", report_link,
              ": ", conditionMessage(e))
      list(reached = FALSE)
    }
  )

  if (!isTRUE(fetched$reached)) {
    return(list(status = "failed", value = NULL))
  }

  title <- fetched$title
  if (is.character(title) && length(title) == 1 && !is.na(title) && nzchar(trimws(title))) {
    list(status = "found", value = trimws(title))
  } else {
    list(status = "absent", value = NULL)
  }
}

#' The title of a Zenodo record
#'
#' @param report_link A Zenodo DOI, DOI URL or record URL
#' @return The record title, or `NULL` if the record carries none
#' @keywords internal
get_zenodo_record_title <- function(report_link) {
  # the sandbox instance mints under its own DOI prefix and is a separate host
  sandbox <- grepl("10.5072/zenodo.", report_link, fixed = TRUE) ||
    grepl("sandbox.zenodo.org", report_link, fixed = TRUE)

  id <- get_zenodo_id(report_link)
  if (is.na(id)) {
    # not a zenodo.org DOI but a sandbox DOI or a record URL, both of which
    # carry the record ID as their last numeric segment
    id <- sub("^.*[./]", "", sub("/$", "", report_link))
  }

  # errors on anything but a successful response, which is what marks the
  # lookup inconclusive rather than conclusively title-less
  record <- get_zenodo_record_metadata(id, sandbox = sandbox)
  record$metadata$title
}

#' The title of an OSF project node
#'
#' @param report_link An OSF project URL, whose last segment is the node ID
#' @return The node title, or `NULL` if the node carries none
#' @importFrom httr status_code content
#' @keywords internal
get_osf_record_title <- function(report_link) {
  node_id <- basename(sub("/$", "", report_link))
  node_url <- paste0(CONFIG$CERT_LINKS[["osf_api"]], "nodes/", node_id, "/")

  response <- codecheck_GET_retry(node_url)
  if (is.null(response) || httr::status_code(response) != 200) {
    stop("Could not access the OSF API for node ", node_id)
  }

  node <- httr::content(response, as = "parsed", type = "application/json")
  node$data$attributes$title
}

#' The title of a ResearchEquals module version
#'
#' Only the version metadata is fetched, not the deposited file that
#' [get_researchequals_version_metadata()] additionally resolves.
#'
#' @param report_link A ResearchEquals DOI, DOI URL, version URL or version ID
#' @return The version title, or `NULL` if the version carries none
#' @importFrom httr status_code content
#' @keywords internal
get_researchequals_record_title <- function(report_link) {
  version_id <- get_researchequals_version_id(report_link)
  if (is.null(version_id)) {
    stop("Could not resolve ", report_link, " to a ResearchEquals version")
  }

  version_url <- paste0(CONFIG$CERT_LINKS[["researchequals_api"]], "versions/", version_id)
  response <- codecheck_GET_retry(version_url)
  if (is.null(response) || httr::status_code(response) != 200) {
    stop("Could not access the ResearchEquals API for version ", version_id)
  }

  version <- httr::content(response, as = "parsed", type = "application/json")
  version$title
}

#' The title to show for a certificate, protected from transient failures
#'
#' Resolves this render's platform lookup against what the certificate's
#' existing `index.json` already says, so a Zenodo outage or a rate limited
#' render cannot silently replace every record title with the constructed
#' fallback, see \code{\link{resolve_external_field}}.
#'
#' @param cert_id Certificate identifier, e.g. "2020-018"
#' @param report_link The `report` field of the certificate's codecheck.yml
#' @param prune_unavailable Passed to \code{\link{resolve_external_field}}
#' @return The record title, or "CODECHECK Certificate <ID>" when none is known
#' @keywords internal
resolve_cert_title <- function(cert_id, report_link, prune_unavailable = FALSE) {
  lookup <- get_cert_record_title_cached_result(report_link, cert_id)

  resolve_external_field(
    cert_id = cert_id,
    json_key_path = c("certificate", "title"),
    status = lookup$status,
    value = lookup$value,
    empty_value = default_cert_title(cert_id),
    prune_unavailable = prune_unavailable
  )
}

#' The title a certificate is given when its record's own title is unknown
#'
#' The form the Zenodo curation policy prescribes,
#' <https://zenodo.org/communities/codecheck/curation-policy>.
#'
#' @param cert_id Certificate identifier, e.g. "2020-018"
#' @return The constructed title
#' @keywords internal
default_cert_title <- function(cert_id) {
  paste("CODECHECK Certificate", cert_id)
}
