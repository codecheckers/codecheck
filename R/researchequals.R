# Checks for certificates published on ResearchEquals, the counterpart of the
# Zenodo curation policy checks in R/zenodo.R. The CODECHECK collection on
# ResearchEquals plays the role the Zenodo "codecheck" community plays there:
# https://researchequals.com/collections/720ac28c-07a1-40c3-a098-c77443e5de96

# The API base, the collection and the vocabulary identifiers ResearchEquals
# uses are policy constants, not display settings, and the functions here can be
# called without CONFIG (config.R) having been sourced, so they live in the
# package rather than in inst/extdata/config.R.
RESEARCHEQUALS_API <- "https://researchequals.com/api/"

# The collections a certificate published on ResearchEquals must be part of. A
# collection is addressed by its ID, the issues within it by their own ID, and
# it is the issue that carries the list of submissions, i.e. the membership; the
# editor URL of the CODECHECK issue is
# https://researchequals.com/collections/418426de-e3c3-4f4d-b66d-81381cc1c5b9/edit
# `venues` restricts a collection to the register venues it applies to; NULL
# means every certificate must be part of it.
RESEARCHEQUALS_COLLECTIONS <- list(
  list(name = "CODECHECK",
       id = "720ac28c-07a1-40c3-a098-c77443e5de96",
       issue_id = "418426de-e3c3-4f4d-b66d-81381cc1c5b9",
       venues = NULL),
  list(name = "Reproducible AGILE",
       id = "aad8e6af-bd94-47f3-b215-c68d31687c74",
       issue_id = "1bb9dfbe-e027-481b-92af-126479cf2075",
       venues = "AGILEGIS")
)

#' The public URL of a ResearchEquals collection
#'
#' @param id the collection ID
#' @return the collection URL
#' @keywords internal
researchequals_collection_url <- function(id) {
  paste0("https://researchequals.com/collections/", id)
}


#' The short name of a ResearchEquals collection
#'
#' The name from [RESEARCHEQUALS_COLLECTIONS] if the issue is one of the
#' collections the policy requires, otherwise the part of the collection title
#' before the en dash, e.g. "CODECHECK" out of "CODECHECK - CODECHECK
#' Certificates and Reproducibility Reports".
#'
#' @param issue a collection issue as returned by [get_researchequals_collection()]
#' @return the short name as a string
#' @keywords internal
collection_name <- function(issue) {
  definition <- collection_definition(issue)
  if (!is.null(definition)) return(definition$name)
  trimws(strsplit(as.character(issue$title), "\u2013", fixed = TRUE)[[1]][1])
}


#' The policy definition of a ResearchEquals collection
#'
#' @param issue a collection issue as returned by [get_researchequals_collection()]
#' @return the matching entry of [RESEARCHEQUALS_COLLECTIONS], or NULL for a
#'   collection the policy does not know
#' @keywords internal
collection_definition <- function(issue) {
  for (definition in RESEARCHEQUALS_COLLECTIONS) {
    if (identical(issue$id, definition$issue_id)) return(definition)
  }
  NULL
}


#' Does a collection apply to a certificate from this venue?
#'
#' A collection without a `venues` restriction applies to every certificate. One
#' with a restriction, like Reproducible AGILE, applies only to the venues it
#' names, and cannot be judged at all when the venue is unknown.
#'
#' @param issue a collection issue as returned by [get_researchequals_collection()]
#' @param venue the register venue of the certificate, may be NULL
#' @return TRUE if membership in the collection is required
#' @keywords internal
collection_applies <- function(issue, venue) {
  definition <- collection_definition(issue)
  venues <- if (is.null(definition)) NULL else definition$venues
  if (length(venues) == 0) return(TRUE)
  if (is.null(venue) || length(venue) == 0 || is.na(venue) || !nzchar(venue)) return(FALSE)
  tolower(venue) %in% tolower(venues)
}

# ResearchEquals describes module type and licence with Wikidata identifiers
RESEARCHEQUALS_TYPE_REPRODUCIBILITY_REPORT <- "Q116740071"
RESEARCHEQUALS_LICENSE_CC_BY_4 <- "Q20007257"

# The DOI prefix ResearchEquals mints under
RESEARCHEQUALS_DOI_PREFIX <- "10.53962"


#' Is a report reference published on ResearchEquals?
#'
#' @param x a DOI, DOI URL or ResearchEquals URL
#' @return TRUE if `x` points at ResearchEquals
#' @keywords internal
is_researchequals_report <- function(x) {
  x <- as.character(x)
  if (length(x) != 1 || is.na(x) || !nzchar(x)) return(FALSE)
  grepl(RESEARCHEQUALS_DOI_PREFIX, x, fixed = TRUE) ||
    grepl("researchequals.com", x, fixed = TRUE)
}


#' Resolve a ResearchEquals report reference to a version ID
#'
#' A ResearchEquals DOI redirects to the page of one version of an output,
#' `https://researchequals.com/en-US/versions/<version id>`, and the API is keyed
#' by that version ID, see [get_researchequals_cert_link()].
#'
#' @param report_link a ResearchEquals DOI, DOI URL, version URL or version ID
#' @return the version ID as a string, or NULL if it cannot be resolved
#' @keywords internal
get_researchequals_version_id <- function(report_link) {
  report_link <- as.character(report_link)
  if (length(report_link) != 1 || is.na(report_link) || !nzchar(report_link)) {
    return(NULL)
  }

  # a bare version ID (UUID) needs no resolution
  if (grepl("^[0-9a-f-]{36}$", report_link)) return(report_link)

  if (grepl("^10\\.", report_link)) report_link <- paste0("https://doi.org/", report_link)

  response <- codecheck_GET_retry(report_link)
  if (is.null(response) || httr::status_code(response) != 200) return(NULL)

  # the redirect target is .../versions/<version id>, with a locale prefix that
  # does not affect the trailing ID
  version_id <- basename(response$url)
  if (!grepl("^[0-9a-f-]{36}$", version_id)) return(NULL)
  version_id
}


#' The file a ResearchEquals module version actually offers for download
#'
#' A module's main file is usually the deposited file itself, `content_s3` with
#' the media type `content_mediatype`. It can also be a document written in
#' ResearchEquals' own editor, `application/x-blocknote`, which is a JSON array
#' of blocks that may *contain* the certificate PDF rather than be it, as for
#' certificate 2026-014:
#'
#' ```
#' [{"type":"pdf","props":{"url":".../api/files/<key>","name":"...pdf"},"children":[]}]
#' ```
#'
#' Returning the BlockNote document as the certificate download means saving
#' that JSON as `cert.pdf`, so this resolves one level further and returns the
#' embedded PDF. Blocks nest, so the document is walked recursively.
#'
#' Needs the network only for a BlockNote main file; when that fetch fails the
#' unresolved main file is returned, which is what the caller would have used
#' anyway.
#'
#' @param version version metadata as returned by the ResearchEquals API
#' @param cert_id ID of the certificate, used for warnings, optional
#' @return a list with `url`, `mediatype` and `name` (NULL unless the file came
#'   from a BlockNote block), or NULL when the version has no main file
#' @keywords internal
researchequals_main_file <- function(version, cert_id = NULL) {
  file_key <- version$content_s3
  if (is.null(file_key) || !nzchar(file_key)) return(NULL)

  main_file <- list(url = paste0(RESEARCHEQUALS_API, "files/", file_key),
                    mediatype = version$content_mediatype,
                    name = NULL)

  if (!identical(version$content_mediatype, "application/x-blocknote")) {
    return(main_file)
  }

  response <- codecheck_GET_retry(main_file$url)
  if (is.null(response) || httr::status_code(response) != 200) {
    warning(cert_id, " | Could not read the ResearchEquals text document of version ",
            version$id)
    return(main_file)
  }

  document <- tryCatch(
    httr::content(response, as = "parsed", type = "application/json"),
    error = function(e) NULL)
  if (is.null(document)) {
    warning(cert_id, " | Could not parse the ResearchEquals text document of version ",
            version$id)
    return(main_file)
  }

  pdfs <- blocknote_pdf_blocks(document)
  if (length(pdfs) == 0) return(main_file)

  # a certificate deposited under its policy name wins over any other PDF the
  # document embeds, e.g. a figure or the checked paper
  named <- vapply(pdfs, function(p) if (is.null(p$name)) "" else p$name, character(1))
  preferred <- which(grepl("codecheck", named, ignore.case = TRUE))
  chosen <- pdfs[[if (length(preferred) > 0) preferred[1] else 1]]

  list(url = chosen$url, mediatype = "application/pdf", name = chosen$name)
}


#' The PDF blocks of a BlockNote document
#'
#' Walks the blocks recursively, `children` included, and returns those that
#' carry a downloadable PDF.
#'
#' @param blocks a parsed BlockNote document, or the `children` of one block
#' @return a list of lists with `url` and `name`
#' @keywords internal
blocknote_pdf_blocks <- function(blocks) {
  found <- list()
  if (!is.list(blocks)) return(found)

  for (block in blocks) {
    if (!is.list(block)) next

    url <- block$props$url
    name <- block$props$name
    is_pdf <- identical(block$type, "pdf") ||
      (identical(block$type, "file") &&
         (grepl("\\.pdf$", if (is.null(name)) "" else name, ignore.case = TRUE) ||
            grepl("\\.pdf$", if (is.null(url)) "" else url, ignore.case = TRUE)))

    if (is_pdf && !is.null(url) && nzchar(url)) {
      found[[length(found) + 1]] <- list(url = url, name = name)
    }

    found <- c(found, blocknote_pdf_blocks(block$children))
  }

  found
}


#' Retrieve the metadata of a ResearchEquals module version
#'
#' The main file is resolved with [researchequals_main_file()] and added as the
#' element `main_file`, so that [researchequals_policy_check()] can judge the
#' deposited certificate without doing any network access of its own.
#'
#' @title Retrieve a ResearchEquals version's metadata
#' @param version_id the ResearchEquals version ID
#' @return the parsed API response as a list, plus the element `main_file`
#' @author Daniel Nuest
#' @importFrom httr content stop_for_status
#' @export
get_researchequals_version_metadata <- function(version_id) {
  response <- codecheck_GET_retry(paste0(RESEARCHEQUALS_API, "versions/", version_id))
  if (is.null(response)) {
    stop("Could not access the ResearchEquals API for version ", version_id)
  }
  httr::stop_for_status(response)
  version <- httr::content(response, as = "parsed", type = "application/json")

  version$main_file <- researchequals_main_file(version)
  version
}


#' Retrieve a collection from ResearchEquals
#'
#' Fetches the issue of a collection, including the list of submissions that
#' constitutes its membership.
#'
#' @title Retrieve a collection on ResearchEquals
#' @param issue_id the collection issue ID, defaults to the current CODECHECK issue
#' @return the parsed API response as a list, with the element `submissions`
#' @author Daniel Nuest
#' @importFrom httr content stop_for_status
#' @export
get_researchequals_collection <- function(issue_id = RESEARCHEQUALS_COLLECTIONS[[1]]$issue_id) {
  response <- codecheck_GET_retry(paste0(RESEARCHEQUALS_API, "issues/", issue_id))
  if (is.null(response)) {
    stop("Could not access the ResearchEquals API for collection issue ", issue_id)
  }
  httr::stop_for_status(response)
  httr::content(response, as = "parsed", type = "application/json")
}


#' Retrieve the collections a CODECHECK certificate must be part of
#'
#' Fetches every collection in `definitions`, by default the CODECHECK
#' collection, <https://researchequals.com/collections/720ac28c-07a1-40c3-a098-c77443e5de96>,
#' which every certificate must be part of, and the Reproducible AGILE
#' collection, <https://researchequals.com/collections/aad8e6af-bd94-47f3-b215-c68d31687c74>,
#' which only certificates for papers of the AGILEGIS venue must be part of.
#'
#' A collection that cannot be fetched is skipped with a warning rather than
#' aborting the whole audit: [researchequals_policy_check()] then does not
#' report on it, which is preferable to reporting every certificate as missing
#' from a collection that merely could not be read.
#'
#' @title Retrieve the collections a certificate must be part of
#' @param definitions list of collection definitions, each a list with `name`,
#'   `id`, `issue_id` and `venues`; defaults to `RESEARCHEQUALS_COLLECTIONS`
#' @return a named list of collection issues, the names being the collections'
#'   short names, with the collection `id` kept as the attribute
#'   `collection_id` on each element
#' @author Daniel Nuest
#' @export
get_researchequals_collections <- function(definitions = RESEARCHEQUALS_COLLECTIONS) {
  collections <- list()
  for (definition in definitions) {
    issue <- tryCatch(get_researchequals_collection(definition$issue_id),
                      error = function(e) {
                        warning("Could not fetch the ", definition$name,
                                " collection on ResearchEquals: ", conditionMessage(e))
                        NULL
                      })
    if (is.null(issue)) next
    attr(issue, "collection_id") <- definition$id
    collections[[definition$name]] <- issue
  }
  collections
}


#' Reduce a DOI, DOI URL or ResearchEquals PID to the bare DOI
#'
#' @param x a DOI in any of the forms used across the API ("doi:10.53962/x",
#'   "https://doi.org/10.53962/x", "10.53962/x")
#' @return the lowercase bare DOI, or NA
#' @keywords internal
normalize_doi <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- sub("^https?://(dx\\.)?doi\\.org/", "", x)
  x <- sub("^doi:", "", x)
  x[!nzchar(x)] <- NA_character_
  x
}


#' Check a ResearchEquals module against the CODECHECK curation policy
#'
#' Pure function: it evaluates the metadata of a ResearchEquals module version
#' against the CODECHECK curation policy, see
#' <https://zenodo.org/communities/codecheck/curation-policy>, whose
#' requirements apply to certificates on any platform, and does not touch the
#' network. Pass a version as returned by the ResearchEquals API
#' (`https://researchequals.com/api/versions/<version id>`).
#'
#' The counterpart of the Zenodo community membership requirement is membership
#' in the collections a certificate must be part of on ResearchEquals, see
#' [get_researchequals_collections()]. Every certificate must be in the
#' CODECHECK collection; the Reproducible AGILE collection is only required for
#' certificates of the AGILEGIS venue, so it is checked only when `venue` says
#' the certificate belongs to it. Membership is not part of the version
#' metadata, so a collection is only checked when it is passed in
#' `collections`, and each one is reported as its own row, `collection: <name>`.
#'
#' @title Check a ResearchEquals module against the CODECHECK curation policy
#' @param version list of version metadata as returned by the ResearchEquals API
#' @param collections named list of collection issues as returned by
#'   [get_researchequals_collections()], optional; needed for the collection
#'   membership checks. A single collection issue is accepted as well.
#' @param venue the register venue of the certificate, e.g. "AGILEGIS",
#'   optional; a venue-specific collection is skipped when the venue is unknown
#' @return a data.frame with columns `check`, `status` (one of "pass", "warn",
#'   "info", "fail") and `detail`, one row per policy requirement.
#' @author Daniel Nuest
#' @export
researchequals_policy_check <- function(version, collections = NULL, venue = NULL) {
  results <- list()
  add <- function(check, status, detail) {
    results[[length(results) + 1]] <<- data.frame(
      check = check, status = status, detail = detail, stringsAsFactors = FALSE)
  }

  # Title: must contain "CODECHECK Certificate" (correctly spelled) and the
  # certificate ID (e.g. "2026-023"), as for Zenodo records. Reports titled
  # "Reproducibility review of: <paper>" predate that convention and are
  # reported as a warning, not a failure.
  title <- if (is.character(version$title)) version$title else ""
  has_cert_text <- grepl("CODECHECK Certificate", title, fixed = TRUE)
  has_cert_text_lower <- grepl("CODECHECK certificate", title, fixed = TRUE)
  has_cert_id <- grepl("[0-9]{4}-[0-9]{3}", title)
  if (has_cert_text && has_cert_id) {
    add("title", "pass", title)
  } else if (has_cert_text_lower && has_cert_id) {
    add("title", "warn",
        paste0("'", title, "' - policy spells it \"CODECHECK Certificate\""))
  } else if (grepl("^Reproducibility review of", title)) {
    add("title", "warn",
        paste0("'", title, "' - policy asks for \"CODECHECK Certificate <ID>\""))
  } else {
    add("title", "fail",
        paste0("'", title, "' - must contain \"CODECHECK Certificate\" and the certificate ID"))
  }

  # Description with summary
  desc <- if (is.character(version$description)) version$description else ""
  add("description", if (nchar(desc) > 0) "pass" else "fail",
      if (nchar(desc) > 0) "present, must contain the certificate summary"
      else "missing, must contain the certificate summary")

  # Licence: the certificate must be CC-BY 4.0
  license <- version$license_id
  add("license",
      if (identical(license, RESEARCHEQUALS_LICENSE_CC_BY_4)) "pass" else "fail",
      if (identical(license, RESEARCHEQUALS_LICENSE_CC_BY_4)) "CC BY 4.0"
      else paste0(if (is.null(license)) "missing" else license,
                  " - the certificate must be CC BY 4.0 (", RESEARCHEQUALS_LICENSE_CC_BY_4, ")"))

  # Module type, the ResearchEquals counterpart of Zenodo's resource type
  type <- version$type_id
  add("module type",
      if (identical(type, RESEARCHEQUALS_TYPE_REPRODUCIBILITY_REPORT)) "pass" else "fail",
      if (identical(type, RESEARCHEQUALS_TYPE_REPRODUCIBILITY_REPORT)) "Reproducibility Report"
      else paste0(if (is.null(type)) "missing" else type,
                  " - should be Reproducibility Report (",
                  RESEARCHEQUALS_TYPE_REPRODUCIBILITY_REPORT, ")"))

  # Language
  lang <- version$language
  add("language", if (!is.null(lang) && nzchar(lang)) "pass" else "fail",
      if (!is.null(lang) && nzchar(lang)) lang else "not set")

  # Contributors: at least one, and identified by ORCID. ResearchEquals records
  # contributors as persons by construction, so unlike on Zenodo there is no
  # organisation-vs-person ambiguity to report.
  contributors <- version$contributors
  if (length(contributors) == 0) {
    add("contributors", "fail", "no contributors")
  } else {
    names_of <- function(c) trimws(paste(c$given_name, c$surname))
    all_names <- unlist(lapply(contributors, names_of))
    without_orcid <- unlist(lapply(contributors, function(c) {
      if (is.null(c$orcid) || !nzchar(c$orcid)) names_of(c) else NULL
    }))
    if (length(without_orcid) == 0) {
      add("contributors", "pass", paste(all_names, collapse = "; "))
    } else {
      add("contributors", "warn",
          paste0(paste(all_names, collapse = "; "), " - no ORCID for ",
                 paste(without_orcid, collapse = "; ")))
    }
  }

  # Published: a draft is not a citable certificate
  add("published", if (isTRUE(version$published)) "pass" else "fail",
      if (isTRUE(version$published)) "published"
      else "the module is not published, so the certificate is not publicly available")

  # The certificate itself. ResearchEquals modules can hold a PDF, or text
  # written in its own editor - which may in turn embed the certificate PDF, see
  # researchequals_main_file(); the policy asks for the certificate PDF, so a
  # text-only certificate is a warning rather than a failure. The resolved main
  # file is used when the caller supplied it, so that this stays a pure function.
  main_file <- version$main_file
  mediatype <- if (!is.null(main_file)) main_file$mediatype else version$content_mediatype
  if (identical(mediatype, "application/pdf")) {
    add("certificate PDF", "pass",
        if (!is.null(main_file$name))
          paste0("application/pdf, embedded in the module text as ", main_file$name)
        else "application/pdf")
  } else if (is.null(mediatype) || !nzchar(mediatype)) {
    add("certificate PDF", "fail", "no main file deposited")
  } else {
    add("certificate PDF", "warn",
        paste0(mediatype, " - policy expects the certificate as a PDF"))
  }

  # Related work: the checked paper. ResearchEquals keeps related work in a flat
  # list of references without relation types, so the check can only assert that
  # the module points at something. Unlike on Zenodo, where the same requirement
  # is a failure because the metadata of a published record can still be edited,
  # this is only a warning: ResearchEquals references cannot be changed after
  # publication, so a certificate missing them cannot be brought into line
  # retroactively. They have to be set when the record is created.
  refs <- unlist(version$refs)
  add("related work: paper", if (length(refs) > 0) "pass" else "warn",
      if (length(refs) > 0) paste(refs, collapse = "; ")
      else paste0("no reference to the checked paper - references cannot be added ",
                  "after publication, they must be set when the record is created"))

  # Collection membership: the module must be part of each collection listed in
  # RESEARCHEQUALS_COLLECTIONS that applies to it, the counterpart of the Zenodo
  # codecheck community. Membership lives on the collection, not on the version,
  # so a collection is only checked when it is supplied, and a venue-specific
  # one - Reproducible AGILE - only for the venues it covers.
  if (!is.null(collections)) {
    # a single collection issue, as returned by get_researchequals_collection(),
    # is accepted in place of the named list of them
    if (!is.null(collections$submissions)) {
      collections <- list(collections)
      names(collections) <- collection_name(collections[[1]])
    }

    dois <- normalize_doi(unlist(version$pids))

    for (name in names(collections)) {
      collection <- collections[[name]]
      if (!collection_applies(collection, venue)) next
      check <- paste0("collection: ", name)
      submitted <- unlist(lapply(collection$submissions, function(s) {
        if (any(normalize_doi(s$link_url) %in% dois)) s$status else NULL
      }))

      if (length(submitted) == 0) {
        add(check, "fail",
            paste0("not part of the ", name, " collection on ResearchEquals (",
                   researchequals_collection_url(
                     if (!is.null(collection$collection_id)) collection$collection_id
                     else attr(collection, "collection_id")), ")"))
      } else if (any(submitted == "accepted")) {
        add(check, "pass", paste0("part of the ", name, " collection"))
      } else if (any(submitted == "pending")) {
        add(check, "warn",
            paste0("submitted to the ", name,
                   " collection, but the submission is still pending"))
      } else {
        add(check, "fail",
            paste0("submission to the ", name, " collection has the status ",
                   paste(unique(submitted), collapse = ", ")))
      }
    }
  }

  # Latest version: the report DOI should point at the current version of the
  # module, not one a newer version has since superseded, see #36 for the same
  # requirement on Zenodo.
  versions <- unlist(lapply(version$version_history, function(v) v$version))
  if (length(versions) > 0 && !is.null(version$version)) {
    is_latest <- version$version >= max(versions)
    add("latest version", if (is_latest) "pass" else "fail",
        if (is_latest) "module version is the latest one"
        else paste0("a newer version of this module exists (version ", max(versions),
                    ") - the report DOI should point at the latest version"))
  }

  do.call(rbind, results)
}


#' Resolve a certificate ID or ResearchEquals reference to a version ID
#'
#' Accepts a ResearchEquals version ID, a ResearchEquals DOI or URL, or a
#' CODECHECK certificate ID. A certificate ID is resolved via `register.csv` in
#' `register_dir` to the repository spec, and from there via the repository's
#' `codecheck.yml` `report` field to the ResearchEquals module.
#'
#' @title Resolve a certificate ID or ResearchEquals reference to a version ID
#' @param x certificate ID (e.g. "2026-023"), ResearchEquals version ID, DOI or URL
#' @param register_dir directory holding `register.csv`, defaults to the working
#'   directory
#' @return the ResearchEquals version ID as a string
#' @author Daniel Nuest
#' @importFrom utils read.csv
#' @export
resolve_researchequals_version_id <- function(x, register_dir = getwd()) {
  x <- as.character(x)

  if (!grepl("^[0-9]{4}-[0-9]{3}$", x)) {
    version_id <- get_researchequals_version_id(x)
    if (is.null(version_id)) {
      stop("Cannot resolve '", x,
           "' to a ResearchEquals version, expected a certificate ID, version ID, DOI or URL")
    }
    return(version_id)
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
  if (!is_researchequals_report(config$report)) {
    stop("The report field of ", row$Repository[1],
         " is not a ResearchEquals DOI: ", config$report)
  }

  version_id <- get_researchequals_version_id(config$report)
  if (is.null(version_id)) {
    stop("Could not resolve the report ", config$report, " of certificate ", x)
  }
  version_id
}


#' The venue of a certificate as recorded in the register
#'
#' @param record a certificate ID; anything else yields NULL, the venue of a
#'   module referenced by DOI cannot be looked up
#' @param register_dir directory holding `register.csv`
#' @return the venue as a string, or NULL when it cannot be determined
#' @importFrom utils read.csv
#' @keywords internal
lookup_register_venue <- function(record, register_dir) {
  record <- as.character(record)
  if (length(record) != 1 || !grepl("^[0-9]{4}-[0-9]{3}$", record)) return(NULL)

  register_file <- file.path(register_dir, "register.csv")
  if (!file.exists(register_file)) return(NULL)

  register <- tryCatch(
    utils::read.csv(register_file, as.is = TRUE, comment.char = "#"),
    error = function(e) NULL)
  if (is.null(register) || !"Venue" %in% names(register)) return(NULL)

  row <- register[register$Certificate == record, ]
  if (nrow(row) == 0) return(NULL)
  as.character(row$Venue[1])
}


#' Audit a published ResearchEquals module against the CODECHECK curation policy
#'
#' Read-only: fetches the module version and the collections a certificate must
#' be part of, and reports which requirements of the CODECHECK curation policy
#' the certificate meets, including its membership in those collections, see
#' [get_researchequals_collections()].
#'
#' @title Audit a ResearchEquals certificate against the CODECHECK curation policy
#' @param record certificate ID, ResearchEquals version ID, DOI or URL
#' @param register_dir directory holding `register.csv`, used to resolve a
#'   certificate ID and its venue, defaults to the working directory
#' @param venue the register venue of the certificate, e.g. "AGILEGIS"; looked
#'   up in `register.csv` when `record` is a certificate ID. Without it a
#'   venue-specific collection, i.e. Reproducible AGILE, is not checked.
#' @return invisibly, the data.frame returned by [researchequals_policy_check()]
#' @author Daniel Nuest
#' @importFrom cli cli_alert_success cli_alert_warning cli_alert_danger cli_alert_info cli_h1
#' @export
check_researchequals_record <- function(record, register_dir = getwd(), venue = NULL) {
  version_id <- resolve_researchequals_version_id(record, register_dir = register_dir)
  if (is.null(venue)) venue <- lookup_register_venue(record, register_dir)
  version <- get_researchequals_version_metadata(version_id)
  collections <- tryCatch(get_researchequals_collections(), error = function(e) {
    cli::cli_alert_info("Could not fetch the collections: {conditionMessage(e)}")
    NULL
  })

  cli::cli_h1(paste0("ResearchEquals version ", version_id, " vs. CODECHECK curation policy"))
  result <- researchequals_policy_check(version, collections = collections, venue = venue)

  for (i in seq_len(nrow(result))) {
    line <- paste0(result$check[i], ": ", result$detail[i])
    switch(result$status[i],
           pass = cli::cli_alert_success(line),
           info = cli::cli_alert_info(line),
           warn = cli::cli_alert_warning(line),
           fail = cli::cli_alert_danger(line))
  }

  invisible(result)
}


#' Drop the cached policy metadata of one ResearchEquals module
#'
#' [check_register_researchequals_policy()] caches version metadata, so a module
#' that was just corrected would keep being reported with its earlier findings
#' until the whole cache is cleared. Invalidating the single version keeps the
#' rest of the cache warm.
#'
#' @title Drop the cached policy metadata of one ResearchEquals module
#' @param version_id ResearchEquals version ID
#' @return TRUE if a cache entry was removed, FALSE otherwise, invisibly
#' @importFrom R.cache findCache
#' @export
clear_researchequals_policy_cache <- function(version_id) {
  removed <- tryCatch({
    path <- R.cache::findCache(key = list(version_id = as.character(version_id)),
                               dirs = "researchequals-policy")
    if (!is.null(path) && file.exists(path)) file.remove(path) else FALSE
  }, error = function(e) FALSE)
  invisible(isTRUE(removed))
}


#' Check all ResearchEquals certificates of a register against the curation policy
#'
#' Runs [researchequals_policy_check()] over every register entry whose report is
#' a ResearchEquals DOI. Meant to run at the end of a register render as a
#' maintainer signal, so it never fails: an unreachable module, a 404 or a
#' malformed response yields the status "unknown" rather than an error, and
#' entries whose report is not on ResearchEquals are skipped.
#'
#' The collections are fetched once for the whole run; one that cannot be
#' fetched is skipped rather than reported as a failure for every certificate.
#'
#' Version metadata is cached via [cached_lookup()], which stores conclusive
#' results only, so an outage is retried on the next render instead of being
#' frozen into the cache. Clear it with [register_clear_cache()].
#'
#' @title Check a register's ResearchEquals certificates against the CODECHECK curation policy
#' @param register_table a register `data.frame` with the columns `Certificate`
#'   and `Report`, and optionally `Venue`, without which the venue-specific
#'   Reproducible AGILE collection is not checked
#' @param get_metadata function of one argument (the version ID) returning the
#'   version metadata like [get_researchequals_version_metadata()]; injectable
#'   for testing
#' @param get_collections function of no arguments returning the collections a
#'   certificate must be part of, like [get_researchequals_collections()];
#'   injectable for testing
#' @return a data.frame with one row per checked certificate and the columns
#'   `certificate`, `version_id`, `status` ("compliant", "non-compliant" or
#'   "unknown"), `n_fail`, `n_warn`, `n_info` and `findings`
#' @author Daniel Nuest
#' @export
check_register_researchequals_policy <- function(
    register_table,
    get_metadata = get_researchequals_version_metadata,
    get_collections = get_researchequals_collections) {
  if (is.null(register_table) || nrow(register_table) == 0 ||
      !all(c("Certificate", "Report") %in% names(register_table))) {
    return(empty_researchequals_policy_result())
  }

  reports <- as.character(register_table$Report)
  if (!any(vapply(reports, is_researchequals_report, logical(1)))) {
    return(empty_researchequals_policy_result())
  }

  # one fetch for the whole run; a collection missing from it is not checked
  collections <- tryCatch(get_collections(), error = function(e) NULL)

  venues <- if ("Venue" %in% names(register_table)) {
    as.character(register_table$Venue)
  } else {
    rep(NA_character_, nrow(register_table))
  }

  rows <- list()
  for (i in seq_len(nrow(register_table))) {
    # after preprocessing the Certificate column holds a markdown link, e.g.
    # "[2026-023](https://codecheck.org.uk/...)", so reduce it to the bare ID
    cert <- as.character(register_table$Certificate[i])
    cert <- sub("^\\[([^]]+)\\].*$", "\\1", cert)
    report <- reports[i]

    # entries not published on ResearchEquals (Zenodo, OSF, ...) are out of scope
    if (!is_researchequals_report(report)) next

    version_id <- tryCatch(get_researchequals_version_id(report), error = function(e) NULL)

    result <- if (is.null(version_id)) NULL else tryCatch({
      version <- cached_lookup(
        key = list(version_id = version_id),
        dirs = "researchequals-policy",
        lookup = function() {
          fetched <- tryCatch(get_metadata(version_id), error = function(e) NULL)
          if (is.null(fetched) || is.null(fetched$title)) {
            list(status = "failed", value = NULL)
          } else {
            list(status = "found", value = fetched)
          }
        })

      if (is.null(version)) NULL
      else researchequals_policy_check(version, collections = collections,
                                       venue = venues[i])
    }, error = function(e) NULL)

    if (is.null(result)) {
      rows[[length(rows) + 1]] <- data.frame(
        certificate = cert,
        version_id = if (is.null(version_id)) NA_character_ else version_id,
        status = "unknown",
        n_fail = NA_integer_, n_warn = NA_integer_, n_info = NA_integer_,
        findings = "module could not be checked (ResearchEquals unreachable)",
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
      certificate = cert, version_id = version_id,
      status = if (nrow(fails) > 0) "non-compliant" else "compliant",
      n_fail = nrow(fails), n_warn = nrow(warns), n_info = nrow(infos),
      # " | " because individual details already use "; " internally
      findings = paste(findings, collapse = " | "),
      stringsAsFactors = FALSE)
  }

  if (length(rows) == 0) return(empty_researchequals_policy_result())
  do.call(rbind, rows)
}

empty_researchequals_policy_result <- function() {
  data.frame(certificate = character(0), version_id = character(0),
             status = character(0), n_fail = integer(0), n_warn = integer(0),
             n_info = integer(0), findings = character(0), stringsAsFactors = FALSE)
}


#' Report the register's ResearchEquals policy findings on the console
#'
#' Prints the result of [check_register_researchequals_policy()] as a `cli`
#' section: a line per certificate with findings, then a tally. Certificates
#' that comply with no findings at all are covered by the tally only.
#'
#' @title Report ResearchEquals curation policy findings
#' @param result the data.frame from [check_register_researchequals_policy()]
#' @return the result, invisibly
#' @author Daniel Nuest
#' @importFrom cli cli_h2 cli_alert_danger cli_alert_warning cli_alert_info cli_alert_success
#' @export
report_researchequals_policy_findings <- function(result) {
  if (is.null(result) || nrow(result) == 0) return(invisible(result))

  cli::cli_h2("ResearchEquals curation policy")

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
    "{compliant} of {total} certificate{?s} on ResearchEquals comply with the curation policy{if (unknown > 0) paste0(', ', unknown, ' could not be checked') else ''}")

  invisible(result)
}
