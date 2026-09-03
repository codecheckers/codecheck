#' Register entries that name a group rather than an individual
#'
#' [build_zenodo_contributors()] must not credit a group of people as if it
#' were one contributor, so a `codechecker` name known to refer to a group -
#' rather than an unresolved individual - is excluded by this explicit,
#' documented list instead of some heuristic (e.g. "no ORCID and no GitHub
#' handle") that would also catch individuals who simply lack both.
#'
#' - "Delft 2024-05 participants" (register#58): the collective name used in
#'   `codecheck.yml` for a group check during a 2024 Delft workshop, not a
#'   single person.
#'
#' @keywords internal
ZENODO_NON_PERSON_CODECHECKERS <- c("Delft 2024-05 participants")

#' Build the `contributors` array for the register's `.zenodo.json`
#'
#' Every codechecker named in `codecheck.yml` across the register becomes one
#' Zenodo contributor (register#58), crediting people whose work the register
#' otherwise only lists on their own person page. Zenodo's contributor role
#' vocabulary (<https://zenodo.org/api/vocabularies/contributorsroles>) has no
#' "reviewer" or "checker" term, so every entry is typed `type` (default
#' `"Other"`) - the record's own description is where that choice is
#' explained to a reader.
#'
#' Reads `codecheck.yml` directly (via [get_codecheck_yml_or_null()], cached)
#' rather than through [add_codechecker()]'s per-row identifiers, because that
#' column collapses every codechecker with neither an ORCID nor a resolvable
#' GitHub handle to the shared identifier `"NA"` - fine for counting checks,
#' but it would silently merge distinct people here. Working from the raw
#' name keeps them distinct; only [ZENODO_NON_PERSON_CODECHECKERS] is treated
#' as not-a-person.
#'
#' A codechecker is deduplicated by normalized ORCID when they have one,
#' otherwise by their exact recorded name - so the same person named
#' identically across certificates contributes one entry, keeping the name
#' exactly as recorded in `codecheck.yml` (no "Family, Given" reformatting:
#' a heuristic split gets compound and multi-word family names wrong, and the
#' recorded spelling is the person's own).
#'
#' @param register The register data frame (as read from `register.csv`),
#'   with `Repository` and `Certificate` columns.
#' @param exclude Character vector of codechecker names to omit as not
#'   naming an individual. Defaults to [ZENODO_NON_PERSON_CODECHECKERS].
#' @param type The Zenodo contributor role to assign every entry.
#' @return A list of `list(name=, orcid=, type=)` records (`orcid` omitted
#'   when not on record), sorted by name for a stable, diffable order.
#' @keywords internal
build_zenodo_contributors <- function(register,
                                       exclude = ZENODO_NON_PERSON_CODECHECKERS,
                                       type = "Other") {
  by_key <- list()

  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml_or_null(register[i, ]$Repository, register[i, ]$Certificate)
    if (is.null(config_yml) || is.null(config_yml$codechecker)) next

    for (codechecker in config_yml$codechecker) {
      name <- codechecker$name
      if (is.null(name) || name %in% exclude) next

      orcid <- normalize_orcid(codechecker$ORCID)
      key <- if (!is.na(orcid)) orcid else name

      if (is.null(by_key[[key]])) {
        entry <- list(name = name, type = type)
        if (!is.na(orcid)) entry$orcid <- orcid
        by_key[[key]] <- entry
      }
    }
  }

  if (length(by_key) == 0) return(list())

  names <- vapply(by_key, function(e) e$name, character(1))
  # unname(): a named list serializes to a JSON object, not an array
  unname(by_key[order(names, method = "radix")])
}

#' Update the `contributors` array of a `.zenodo.json` in place
#'
#' `.zenodo.json` at the register repo root is otherwise hand-maintained
#' (title, creators, licence, community, ...); a render only keeps its
#' `contributors` current with the codecheckers named in the register
#' (register#58), so it needs no manual fix-up before the next Zenodo
#' deposit. Every other key is preserved exactly - the file is parsed with
#' `simplifyVector = FALSE` so key order and scalar-vs-array shape survive
#' the round trip.
#'
#' A missing file is a no-op (with a message, not a warning): most working
#' directories a render runs in - a test fixture, a partial render's temp
#' copy - have no `.zenodo.json` at all, and that must never be an error.
#'
#' @param register The register data frame, passed to
#'   [build_zenodo_contributors()].
#' @param path Path to the `.zenodo.json` file. Defaults to the repo root.
#' @return Invisibly, `TRUE` if the file was updated, `FALSE` if there was
#'   no file to update.
#' @keywords internal
update_zenodo_json <- function(register, path = ".zenodo.json") {
  if (!file.exists(path)) {
    cli::cli_alert_info("No {.path {path}} found, skipping Zenodo contributors update")
    return(invisible(FALSE))
  }

  zenodo_metadata <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  zenodo_metadata$contributors <- build_zenodo_contributors(register)

  jsonlite::write_json(zenodo_metadata, path, auto_unbox = TRUE, pretty = TRUE)
  # write_json() does not end the file with a newline
  cat("\n", file = path, append = TRUE)

  cli::cli_alert_success("Updated {.path {path}} with {length(zenodo_metadata$contributors)} contributor{?s}")
  invisible(TRUE)
}
