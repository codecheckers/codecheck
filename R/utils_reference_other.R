#' A paper's further references, from `paper.reference-other`
#'
#' The configuration specification 2.0 lets a `codecheck.yml` list further
#' references to the checked work, such as a preprint or the version of record,
#' next to the one `reference` that identifies it. Validation reports anything
#' malformed (rules `CC-CFG-029`, `CC-CFG-030`); rendering only needs to stay
#' on its feet, so an entry that is neither a DOI nor a web address is left out
#' with a warning naming the certificate, and nothing unvalidated reaches a
#' public page.
#'
#' The YAML parser reads a single scalar and a one-item sequence alike, so a
#' bare URL is simply used as a one-item list here.
#'
#' Entries that repeat the paper's own `reference`, or each other, are dropped:
#' DOIs compare case-insensitively and in any of their spellings
#' (`https://doi.org/`, `dx.doi.org`, `doi:`), see [normalize_work_key()].
#'
#' The warnings are given where the register is first read, see [add_work_key()]
#' and [register_check()], which pass `cert_id`; the page renderers read the
#' field again without it, and quietly.
#'
#' @param config_yml The parsed `codecheck.yml`
#' @param cert_id The certificate identifier; without it, nothing left out is
#'   reported
#' @return A data frame with one row per usable entry and the columns `url`
#'   (the DOI as a `https://doi.org/` URL, or the web address as given) and
#'   `doi` (the lowercased bare DOI, `NA` for a web address)
#' @keywords internal
get_reference_other <- function(config_yml, cert_id = NULL) {
  empty <- data.frame(url = character(0), doi = character(0), stringsAsFactors = FALSE)
  other <- config_yml$paper[["reference-other"]]
  if (is.null(other) || length(other) == 0) {
    return(empty)
  }
  # The message carries text from the codecheck.yml, which may hold "{...}":
  # passed as a value, never as cli's glue template, which would evaluate it.
  warn <- function(message) {
    if (!is.null(cert_id) && !is.na(cert_id)) cli::cli_alert_warning("{cert_id} | {message}")
  }

  if (!is.null(names(other))) {
    warn("reference-other is a map, not a list of references; not rendered")
    return(empty)
  }

  urls <- character(0)
  dois <- character(0)
  for (entry in as.list(other)) {
    if (!is.character(entry) || length(entry) != 1 || is.na(entry)) {
      warn(paste("reference-other entry that is not a single URL left out:", format(entry)))
      next
    }
    entry <- trimws(entry)
    doi <- normalize_work_key(entry)
    if (is.na(doi) && !is_bare_url(entry)) {
      warn(paste("reference-other entry that is not a URL left out:", entry))
      next
    }
    urls <- c(urls, if (is.na(doi)) entry else paste0(CONFIG$HYPERLINKS[["doi"]], doi))
    dois <- c(dois, doi)
  }

  key <- reference_key(urls)
  keep <- !duplicated(key) & key != reference_key(config_yml$paper$reference %||% "")
  data.frame(url = urls[keep], doi = dois[keep], stringsAsFactors = FALSE)
}

#' What makes two references the same: the DOI, in any spelling, or else the
#' address as written
#'
#' Shared by rendering ([get_reference_other()]) and rule `CC-CFG-033`, so that
#' both count the same entries as repeats.
#'
#' @param x Character vector of references
#' @return The lowercased bare DOI of each, or the trimmed reference
#' @keywords internal
reference_key <- function(x) {
  x <- trimws(x)
  doi <- vapply(x, normalize_work_key, character(1), USE.NAMES = FALSE)
  ifelse(is.na(doi), x, doi)
}

#' A paper's further references with the type of each, see [get_reference_type()]
#'
#' @inheritParams get_reference_other
#' @return The data frame of [get_reference_other()] with `type` and `agency`
#'   columns, `NA` for a web address or an unknown type
#' @keywords internal
typed_reference_other <- function(config_yml) {
  add_reference_types(get_reference_other(config_yml))
}

#' Add the `type` and `agency` of each DOI to a data frame of references
#'
#' @param refs A data frame with `url` and `doi` columns
#' @return `refs` with `type` and `agency` columns
#' @keywords internal
add_reference_types <- function(refs) {
  types <- lapply(refs$url, get_reference_type)
  refs$type <- vapply(types, function(t) t$type, character(1))
  refs$agency <- vapply(types, function(t) t$agency, character(1))
  refs
}

#' The type of work a DOI's registry record states, e.g. "Preprint"
#'
#' Read from the record at the DOI's registration agency, which is the one
#' source that types a preprint as such: OpenAlex merges a preprint into its
#' published version, so looking up the preprint's DOI there answers with the
#' journal article's record (see [openalex_record_is_work()]).
#'
#' @param reference A paper reference; anything that is not a DOI has no type
#' @return A list with `type` (a display label, `NA` when unknown) and
#'   `agency` ("Crossref", "DataCite" or `NA`)
#' @keywords internal
get_reference_type <- function(reference) {
  unknown <- list(type = NA_character_, agency = NA_character_)
  if (is.null(reference) || length(reference) != 1 || is.na(reference) ||
      is.na(normalize_work_key(reference))) {
    return(unknown)
  }
  record <- tryCatch(get_registry_record_cached_result(reference),
                     error = function(e) NULL)
  if (is.null(record) || !identical(record$status, "found")) {
    return(unknown)
  }
  list(type = record$value$type %||% NA_character_,
       agency = record$value$agency %||% NA_character_)
}

#' The type label of a Crossref record
#'
#' Crossref types a preprint as posted content of subtype preprint, which is
#' what a bioRxiv, medRxiv or OSF preprint is.
#'
#' @param message The `message` of a Crossref works response
#' @return A display label, or `NA` for a type not shown on the register
#' @keywords internal
crossref_reference_type <- function(message) {
  type <- message$type %||% NA_character_
  if (identical(type, "posted-content")) {
    return(if (identical(message$subtype, "preprint")) "Preprint" else NA_character_)
  }
  labels <- c(
    "journal-article" = "Journal article",
    "proceedings-article" = "Conference paper",
    "book-chapter" = "Book chapter",
    "book" = "Book",
    "monograph" = "Book",
    "edited-book" = "Book",
    "dataset" = "Dataset",
    "report" = "Report",
    "dissertation" = "Thesis"
  )
  unname(labels[type])
}

#' The type label of a DataCite record
#'
#' arXiv registers its preprints at DataCite as `Text`/`Article`, not as
#' `Preprint`, so its records are recognised by their publisher and DOI prefix.
#'
#' @param attributes The `data$attributes` of a DataCite DOI response
#' @return A display label, or `NA` for a type not shown on the register
#' @keywords internal
datacite_reference_type <- function(attributes) {
  publisher <- attributes$publisher
  if (is.list(publisher)) publisher <- publisher$name
  doi <- tolower(attributes$doi %||% "")
  if (identical(publisher, "arXiv") || startsWith(doi, "10.48550/")) {
    return("Preprint")
  }
  type <- attributes$types$resourceTypeGeneral %||% NA_character_
  labels <- c(
    "Preprint" = "Preprint",
    "JournalArticle" = "Journal article",
    "ConferencePaper" = "Conference paper",
    "BookChapter" = "Book chapter",
    "Book" = "Book",
    "Dataset" = "Dataset",
    "Software" = "Software",
    "Report" = "Report",
    "Dissertation" = "Thesis"
  )
  unname(labels[type])
}

#' A template of the package, as one string
#'
#' @param path Path below `extdata/templates/`
#' @keywords internal
template_text <- function(path) {
  template_path <- system.file("extdata", "templates", path, package = "codecheck")
  paste(readLines(template_path, warn = FALSE), collapse = "\n")
}

#' The partials the reference templates include: `reference_type`, the type label
#'
#' @return A list for the `partials` of [whisker::whisker.render()]
#' @keywords internal
reference_partials <- function() {
  list(reference_type = template_text("general/reference_type.html"))
}

#' A reference's type as whisker data, `NULL` when unknown so that a section
#' over it is left out
#'
#' @param type,agency See [get_reference_type()]
#' @keywords internal
reference_type_data <- function(type, agency) {
  if (is.null(type) || is.na(type)) NULL else list(type = type, agency = agency)
}

#' A reference's type label as HTML, or `""` when the type is unknown
#'
#' For the certificate page's title, which is filled into a Markdown template
#' rather than a whisker one.
#'
#' @param type_info A list with `type` and `agency`, see [get_reference_type()]
#' @return An HTML string
#' @keywords internal
reference_type_html <- function(type_info) {
  data <- reference_type_data(type_info$type, type_info$agency)
  if (is.null(data)) "" else whisker::whisker.render(reference_partials()$reference_type, data)
}

#' The works that are one work, from the references of all certificates
#'
#' A certificate's `reference` and its `reference-other` DOIs are references to
#' the same work, so their work pages link to each other. Two certificates that
#' share any DOI join their groups, including across several steps: A's
#' reference lists X as another reference, and B's reference is X with Y as
#' another reference, makes A's DOI, X and Y one work.
#'
#' Web addresses that are not DOIs have no work page, but are shown on the
#' work pages of the group the certificate belongs to.
#'
#' @param certs Character vector of certificate IDs
#' @param work_keys Character vector of each certificate's normalized
#'   reference DOI (see [normalize_work_key()]), `NA` where it is not a DOI
#' @param other_refs List of data frames, each certificate's further
#'   references (see [get_reference_other()])
#' @return A named list, one element per DOI, each a data frame of the other
#'   references of that work with the columns `url`, `doi` (`NA` for a web
#'   address) and `is_reference` (whether some certificate has that DOI as its
#'   `reference`). DOIs without related references are left out.
#' @keywords internal
build_work_relations <- function(certs, work_keys, other_refs) {
  # union-find over DOIs, by relabelling: few certificates have related
  # references, so a quadratic merge costs nothing
  group <- character(0)
  members <- vector("list", length(certs))
  for (i in seq_along(certs)) {
    refs <- other_refs[[i]]
    dois <- unique(c(work_keys[i], refs$doi))
    dois <- dois[!is.na(dois)]
    members[[i]] <- dois
    if (length(dois) == 0) next
    for (doi in dois) if (!(doi %in% names(group))) group[[doi]] <- doi
    labels <- unique(unname(group[dois]))
    group[group %in% labels] <- labels[1]
  }

  primary <- unique(work_keys[!is.na(work_keys)])
  relations <- list()
  for (label in unique(unname(group))) {
    dois <- names(group)[group == label]
    certs_in_group <- which(vapply(members, function(m) any(m %in% dois), logical(1)))
    urls <- unique(unlist(lapply(other_refs[certs_in_group], function(r) r$url[is.na(r$doi)])))
    if (length(dois) + length(urls) < 2) next
    for (doi in dois) {
      others <- setdiff(dois, doi)
      # paste0() with no DOIs would still return the bare prefix
      other_urls <- if (length(others) > 0) paste0(CONFIG$HYPERLINKS[["doi"]], others) else character(0)
      relations[[doi]] <- data.frame(
        url = c(other_urls, urls %||% character(0)),
        doi = c(others, rep(NA_character_, length(urls))),
        is_reference = c(others %in% primary, rep(FALSE, length(urls))),
        stringsAsFactors = FALSE
      )
    }
  }
  relations
}

#' Explode the register table into one row per certificate and work
#'
#' A certificate is listed on the work page of its `reference` and on the work
#' page of every DOI in its `reference-other`, with the `Referenced as` column
#' saying which. The OpenAlex ID and publication date of a row for another
#' reference are that DOI's own (see [add_work_key()]), not those of the
#' certificate's `reference`.
#'
#' @param register_table The register table, with `Work` and `Work other`
#'   columns (see [add_work_key()])
#' @return The register table, one row per certificate and work DOI, with a
#'   `Referenced as` column; certificates without any DOI are left out
#' @keywords internal
explode_work_records <- function(register_table) {
  has_other <- "Work other" %in% names(register_table)
  rows <- list()
  for (i in seq_len(nrow(register_table))) {
    row <- register_table[i, , drop = FALSE]
    if (!is.na(row$Work)) {
      primary <- row
      primary$`Referenced as` <- "Reference"
      rows[[length(rows) + 1]] <- primary
    }
    if (!has_other) next
    others <- register_table$`Work other`[[i]]
    if (is.null(others)) next
    for (j in which(!is.na(others$doi))) {
      other <- row
      other$Work <- others$doi[j]
      other$`Referenced as` <- "Other reference"
      if ("OpenAlex" %in% names(other)) other$OpenAlex <- others$openalex[j]
      if ("Work publication date" %in% names(other)) {
        other$`Work publication date` <- others$publication_date[j]
      }
      rows[[length(rows) + 1]] <- other
    }
  }

  if (length(rows) == 0) {
    empty <- register_table[0, , drop = FALSE]
    empty$`Referenced as` <- character(0)
    return(empty)
  }
  dplyr::bind_rows(rows)
}

#' Every DOI that has a work page: the references and the further references
#'
#' @param register_table The register table, with `Work` and, optionally,
#'   `Work other` columns
#' @return A character vector of unique DOIs
#' @keywords internal
all_work_keys <- function(register_table) {
  keys <- register_table$Work
  if ("Work other" %in% names(register_table)) {
    keys <- c(keys, unlist(lapply(register_table$`Work other`, function(r) r$doi)))
  }
  unique(keys[!is.na(keys)])
}

#' The OpenAlex ID and publication date of another reference's DOI
#'
#' Looked up by the DOI alone: the title and author search that backs up the
#' lookup of a certificate's own reference would find the very work the
#' certificate references, not this version of it. An OpenAlex record that
#' describes another work (a preprint merged into its published version) is
#' not this DOI's, so its ID is not used, and the date comes from the DOI's
#' own registry record or landing page instead.
#'
#' @param url The DOI as a URL
#' @return A list with `openalex` and `publication_date`, each possibly `NA`
#' @keywords internal
get_other_reference_fields <- function(url) {
  openalex <- tryCatch(get_openalex_id_cached_result(url)$value,
                       error = function(e) NA_character_)
  publication_date <- NA_character_
  if (!is.na(openalex)) {
    fields <- tryCatch(get_openalex_work_fields_for(openalex, url)$value,
                       error = function(e) NULL)
    # a record of another work is not this DOI's: neither its ID nor its date
    if (is.null(fields) || !openalex_record_is_work(fields$doi, url)) {
      openalex <- NA_character_
    } else {
      publication_date <- fields$publication_date %||% NA_character_
    }
  }
  if (is.na(publication_date)) {
    fallback <- tryCatch(get_fallback_publication_date(url), error = function(e) NULL)
    if (!is.null(fallback) && identical(fallback$status, "found")) {
      publication_date <- fallback$value
    }
  }
  list(openalex = openalex, publication_date = publication_date)
}

#' The other references of a work, with their types, for a work page
#'
#' @param doi The work page's DOI
#' @return A list of lists, one per row of the work's relations in
#'   `CONFIG$WORK_RELATIONS` (see [add_work_key()]): `url`, `doi` (`NA` for a
#'   web address), `is_reference`, `type` and `agency`; empty when the work has
#'   no other references
#' @keywords internal
get_work_related_references <- function(doi) {
  relations <- CONFIG$WORK_RELATIONS[[doi]]
  if (is.null(relations) || nrow(relations) == 0) {
    return(list())
  }
  lapply(seq_len(nrow(relations)), function(i) as.list(relations[i, , drop = FALSE]))
}

#' Whisker data for a list of references, linking DOIs to their work pages
#'
#' Shared by the certificate page's "Other references" and the work page's
#' "Same work as": a DOI links to its work page and, by its DOI icon, to
#' doi.org; a web address that is not a DOI has no work page and links out.
#'
#' @param references A list of lists with `url`, `doi` and, optionally,
#'   `type`/`agency` (see [get_reference_type()])
#' @param works_base The relative path from the page to the `works/` directory,
#'   ending in "/"
#' @return A list of lists for a whisker section, the last one marked `last`
#' @keywords internal
reference_list_data <- function(references, works_base) {
  n <- length(references)
  lapply(seq_len(n), function(i) {
    ref <- references[[i]]
    has_page <- !is.na(ref$doi)
    list(
      has_page = has_page,
      page_url = if (has_page) paste0(works_base, ref$doi, "/") else NULL,
      doi = ref$doi,
      url = ref$url,
      label = sub("^https?://", "", ref$url),
      reference_type = reference_type_data(ref$type, ref$agency),
      last = i == n
    )
  })
}

#' A certificate's further references for its `index.json`
#'
#' @param refs The further references with their types, see
#'   [typed_reference_other()]
#' @return A list of lists with `url` and, where known, `doi` and `type`;
#'   empty without further references
#' @keywords internal
reference_other_json <- function(refs) {
  lapply(seq_len(nrow(refs)), function(i) {
    entry <- list(url = refs$url[i], doi = refs$doi[i], type = refs$type[i])
    entry[!is.na(entry)]
  })
}
