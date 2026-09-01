#' Normalize an ORCID to its canonical form
#'
#' ORCIDs are case-insensitive only in the trailing checksum character, which
#' the ORCID registry itself always renders as uppercase X. Two records that
#' differ only in that case must resolve to the same person page.
#'
#' @param orcid The ORCID string, with or without a URL prefix
#' @return The normalized ORCID (`NNNN-NNNN-NNNN-NNNX` form), or `NA` if not
#'   well-formed
#' @keywords internal
normalize_orcid <- function(orcid) {
  if (is.null(orcid) || is.na(orcid) || orcid == "") {
    return(NA_character_)
  }
  orcid <- sub("^https?://orcid\\.org/", "", trimws(orcid))
  orcid <- toupper(orcid)
  orcid_regex <- "^\\d{4}-\\d{4}-\\d{4}-\\d{3}(\\d|X)$"
  if (!grepl(orcid_regex, orcid, perl = TRUE)) {
    return(NA_character_)
  }
  orcid
}

#' Normalize a paper reference to a DOI-based work key
#'
#' The register identifies a "work" (issue codecheckers/register#150) by its
#' DOI. DOIs are case-insensitive, so the key must be lowercased or two
#' certificates citing the same DOI in different case would render as two
#' work directories - the same class of bug fixed for venue names in
#' codecheckers/register#192.
#'
#' @param paper_reference The `Paper reference` / `config_yml$paper$reference`
#'   value, expected to be a DOI URL (`https://doi.org/10...`) for a work
#'   page to exist at all; anything else (a PDF URL, a non-DOI landing page)
#'   yields `NA` - such a certificate simply has no work page, per #150.
#' @return The lowercased bare DOI, or `NA` if `paper_reference` is not a DOI
#' @keywords internal
normalize_work_key <- function(paper_reference) {
  if (is.null(paper_reference) || length(paper_reference) == 0 || is.na(paper_reference)) {
    return(NA_character_)
  }
  ref <- trimws(paper_reference)
  m <- stringr::str_match(ref, "(?i)^(?:https?://(?:dx\\.)?doi\\.org/|doi:)(10\\..+)$")
  if (is.na(m[1, 2])) {
    return(NA_character_)
  }
  tolower(m[1, 2])
}

#' Add the `Work` grouping column to the register table
#'
#' One row per certificate, so the same DOI checked by several certificates
#' repeats the same key - `create_register_files()`'s existing group-by
#' machinery then puts them on one work page automatically.
#'
#' @param register_table The register table
#' @param register The register from register.csv
#' @return The register table with a `Work` column added
#' @keywords internal
add_work_key <- function(register_table, register) {
  work_keys <- vapply(seq_len(nrow(register)), function(i) {
    config_yml <- get_codecheck_yml_or_null(register[i, ]$Repository, register[i, ]$Certificate)
    if (is.null(config_yml) || is.null(config_yml$paper$reference)) {
      return(NA_character_)
    }
    normalize_work_key(config_yml$paper$reference)
  }, character(1))

  register_table$Work <- work_keys
  n_found <- sum(!is.na(work_keys))
  cli::cli_alert_success("Resolved {n_found}/{nrow(register)} certificates to a DOI-keyed work")
  register_table
}

#' Add the `Person` grouping column to the register table
#'
#' Builds, for every certificate, the union of its paper authors and its
#' codecheckers that carry an ORCID - name-only entries are dropped, per
#' #123's explicit "we are not going down the rabbit hole of matching names,
#' disambiguation, etc." A person who is both author and codechecker on the
#' same certificate legitimately gets two records, distinguished by `role`,
#' so their person page can show the certificate under both headings.
#'
#' Also fills `CONFIG$DICT_ORCID_ID_NAME` for authors that are not already a
#' known codechecker, so an author-only person page has a name to title
#' itself with. The codechecker list is authoritative when both exist -
#' [add_codechecker()] already populates it and always runs first, in
#' [preprocess_register()].
#'
#' @param register_table The register table
#' @param register The register from register.csv
#' @return The register table with a `Person` list column added, each element
#'   a list of `list(orcid=, name=, role=)` records ("author" or
#'   "codechecker")
#' @keywords internal
add_person_records <- function(register_table, register) {
  person_records <- vector("list", length = nrow(register))

  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml_or_null(register[i, ]$Repository, register[i, ]$Certificate)
    records <- list()

    if (!is.null(config_yml)) {
      # Codechecker names are registered first and win on conflict: a
      # codecheck.yml's codechecker entry is the person naming themselves,
      # while a paper author entry is someone else's transcription of their
      # co-author's name - the former is the more reliable source for the
      # page title. [add_codechecker()] populates the same dict when the
      # "codecheckers" filter also runs, harmlessly redoing this work.
      for (codechecker in config_yml$codechecker) {
        orcid <- normalize_orcid(codechecker$ORCID)
        if (is.na(orcid) || is.null(codechecker$name)) next
        CONFIG$DICT_ORCID_ID_NAME[orcid] <- codechecker$name
        records[[length(records) + 1]] <- list(orcid = orcid, name = codechecker$name, role = "codechecker")
      }

      for (author in config_yml$paper$authors) {
        orcid <- normalize_orcid(author$ORCID)
        if (is.na(orcid) || is.null(author$name)) next
        if (!(orcid %in% names(CONFIG$DICT_ORCID_ID_NAME))) {
          CONFIG$DICT_ORCID_ID_NAME[orcid] <- author$name
        }
        records[[length(records) + 1]] <- list(orcid = orcid, name = author$name, role = "author")
      }
    }

    person_records[[i]] <- records
  }

  register_table$Person <- person_records
  n_certs_with_person <- sum(vapply(person_records, length, integer(1)) > 0)
  cli::cli_alert_success("Resolved ORCID-identified persons for {n_certs_with_person}/{nrow(register)} certificates")
  register_table
}

#' Explode a register table's `Person` list column into one row per record
#'
#' Turns each certificate's list of `{orcid, name, role}` records (see
#' [add_person_records()]) into its own row, replacing the `Person` list
#' column with a plain `Person` character column (the ORCID, matching
#' `CONFIG$FILTER_COLUMN_NAMES[["persons"]]`, so the caller can `group_by()`
#' it directly) plus a `Role` column ("author"/"codechecker"). A certificate
#' with no ORCID-identified person at all contributes no rows.
#'
#' @param register_table A register table with a `Person` list column.
#' @return The exploded register table - one row per person-record, `Person`
#'   now the person's ORCID and `Role` the record's role. Zero rows (same
#'   columns) if no certificate has an ORCID-identified person.
#' @keywords internal
explode_person_records <- function(register_table) {
  rows <- list()
  for (i in seq_len(nrow(register_table))) {
    records <- register_table$Person[[i]]
    for (record in records) {
      row <- register_table[i, , drop = FALSE]
      row$Person <- record$orcid
      row$Role <- record$role
      rows[[length(rows) + 1]] <- row
    }
  }

  if (length(rows) == 0) {
    empty <- register_table[0, , drop = FALSE]
    empty$Person <- character(0)
    empty$Role <- character(0)
    return(empty)
  }

  dplyr::bind_rows(rows)
}
