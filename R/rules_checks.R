# One function per validation rule, see R/rules.R for the rule catalogue and
# R/rules_validate.R for the driver that runs them.
#
# A check function takes the validation context and returns rule_pass(),
# rule_fail() or rule_skip(). It never decides how loud the result is: the
# severity comes from the rule file, so the same function serves every
# specification version that has the rule, and a version that hardens a rule
# changes nothing here.
#
# A check that cannot reach a verdict - an API that is down, a file that is not
# on disk - returns rule_skip(). "Could not check" is not a failed check.

#' Outcome of a single rule check
#'
#' @param detail One line saying what was found, shown next to the rule.
#' @return A list with `status` and `detail`.
#' @keywords internal
#' @noRd
rule_pass <- function(detail = NULL) {
  list(status = "pass", detail = detail)
}

#' @rdname rule_pass
#' @keywords internal
#' @noRd
rule_fail <- function(detail) {
  list(status = "fail", detail = detail)
}

#' @rdname rule_pass
#' @keywords internal
#' @noRd
rule_skip <- function(detail) {
  list(status = "skip", detail = detail)
}

#' Is a value present and non-empty?
#' @keywords internal
#' @noRd
has_value <- function(value) {
  !is.null(value) && length(value) > 0 &&
    (!is.character(value) || any(nzchar(trimws(value))))
}

#' Items of a `codecheck.yml` node that is a sequence of named items
#'
#' A single item can be written without the sequence dash, in which case the
#' YAML parser hands back a plain named list rather than a list of lists.
#'
#' @keywords internal
#' @noRd
as_items <- function(node) {
  if (!has_value(node)) {
    return(list())
  }
  if (!is.null(names(node))) list(node) else node
}

# --- the file itself -------------------------------------------------------

#' @keywords internal
#' @noRd
check_yaml_parses <- function(context) {
  # The encoding is checked on the raw bytes and before the parse: an invalid
  # byte inside a quoted scalar makes the YAML parser fail with a scanner error
  # rather than saying the file is not UTF-8.
  if (!is.null(context$raw_lines) && !all(validUTF8(context$raw_lines))) {
    return(rule_fail("the file is not valid UTF-8 encoded"))
  }
  if (!is.null(context$parse_error)) {
    return(rule_fail(paste("the file is not valid YAML:", context$parse_error)))
  }
  if (is.null(context$raw_lines)) rule_pass() else rule_pass("valid UTF-8 YAML")
}

#' @keywords internal
#' @noRd
check_orcid_format <- function(context) {
  # Both the paper's authors and the codecheckers, because the rule is about
  # the form of an ORCID wherever it appears in the file.
  people <- context_people(context)
  orcids <- unlist(lapply(people, function(person) person$ORCID))
  if (length(orcids) == 0) {
    return(rule_skip("no ORCID to inspect"))
  }
  malformed <- orcids[!grepl("^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$",
                             orcids, perl = TRUE)]
  if (length(malformed) > 0) {
    return(rule_fail(paste("ORCIDs must be plain and without URL prefix, but found:",
                           paste(malformed, collapse = ", "))))
  }
  # The template's placeholder has no valid check digit, and is reported by
  # CC-CFG-023 no-placeholder-values instead.
  checked <- orcids[!vapply(orcids, is_orcid_placeholder, logical(1))]
  wrong_checksum <- checked[!vapply(checked, orcid_checksum_valid, logical(1))]
  if (length(wrong_checksum) > 0) {
    return(rule_fail(paste("ORCID(s) with a wrong check digit, likely a typo:",
                           paste(wrong_checksum, collapse = ", "))))
  }
  rule_pass(paste(length(orcids), "ORCID(s)"))
}

#' Does an ORCID's last character match its check digit?
#'
#' ISO 7064 11,2 over the first fifteen digits, as described in
#' <https://support.orcid.org/hc/en-us/articles/360006897674>. Expects a
#' well-formed ORCID, see `is_orcid()`.
#'
#' @keywords internal
#' @noRd
orcid_checksum_valid <- function(orcid) {
  digits <- strsplit(gsub("-", "", orcid), "")[[1]]
  total <- 0
  for (digit in digits[1:15]) {
    total <- (total + as.integer(digit)) * 2
  }
  result <- (12 - total %% 11) %% 11
  expected <- if (result == 10) "X" else as.character(result)
  identical(digits[16], expected)
}

#' @keywords internal
#' @noRd
check_explicit_document <- function(context) {
  if (is.null(context$lines)) {
    return(rule_skip("no file on disk to inspect"))
  }
  non_empty <- trimws(context$lines)
  non_empty <- non_empty[nzchar(non_empty)]
  if (length(non_empty) > 0 && identical(non_empty[1], "---")) {
    rule_pass()
  } else {
    rule_fail("the file does not start with the document marker '---'")
  }
}

#' @keywords internal
#' @noRd
check_file_name_and_location <- function(context) {
  if (is.null(context$path)) {
    return(rule_skip("no file on disk to inspect"))
  }
  if (identical(basename(context$path), "codecheck.yml")) {
    rule_pass()
  } else {
    rule_fail(paste0("the file is named ", basename(context$path),
                     ", not codecheck.yml"))
  }
}

# --- manifest --------------------------------------------------------------

#' @keywords internal
#' @noRd
check_manifest_present <- function(context) {
  # The rule is about the node being there. An empty manifest is odd but not a
  # violation, and the specification does not make it one.
  if (is.null(context$yml$manifest)) {
    return(rule_fail("no root-level manifest"))
  }
  rule_pass(paste(length(as_items(context$yml$manifest)), "manifest item(s)"))
}

#' @keywords internal
#' @noRd
check_manifest_item_file <- function(context) {
  manifest <- as_items(context$yml$manifest)
  if (length(manifest) == 0) {
    return(rule_skip("no manifest to inspect"))
  }
  without_file <- which(!vapply(manifest, function(item) has_value(item$file),
                                logical(1)))
  if (length(without_file) == 0) {
    rule_pass()
  } else {
    rule_fail(paste("manifest item(s) without a file:",
                    paste(without_file, collapse = ", ")))
  }
}

#' @keywords internal
#' @noRd
check_manifest_files_exist <- function(context) {
  if (is.null(context$bundle_dir)) {
    return(rule_skip("no bundle on disk to look in"))
  }
  files <- unlist(lapply(as_items(context$yml$manifest), function(item) item$file))
  if (length(files) == 0) {
    return(rule_skip("no manifest files to look for"))
  }
  missing <- files[!file.exists(file.path(context$bundle_dir, files))]
  if (length(missing) == 0) {
    rule_pass(paste(length(files), "manifest file(s)"))
  } else {
    rule_fail(paste("manifest file(s) not in the bundle:",
                    paste(missing, collapse = ", ")))
  }
}

#' @keywords internal
#' @noRd
check_manifest_path_relative <- function(context) {
  manifest <- as_items(context$yml$manifest)
  files <- unlist(lapply(manifest, function(item) item$file))
  if (length(files) == 0) {
    return(rule_skip("no manifest files to inspect"))
  }
  # An absolute path, a Windows drive letter or a parent-directory step all
  # leave the bundle, which is what the rule is about.
  absolute <- grepl("^(/|~|[A-Za-z]:)", files) | grepl("(^|/)\\.\\.(/|$)", files)
  if (!any(absolute)) {
    rule_pass()
  } else {
    rule_fail(paste("path(s) not relative to the bundle:",
                    paste(files[absolute], collapse = ", ")))
  }
}

#' @keywords internal
#' @noRd
check_manifest_item_comment <- function(context) {
  manifest <- as_items(context$yml$manifest)
  if (length(manifest) == 0) {
    return(rule_skip("no manifest to inspect"))
  }
  without_comment <- sum(!vapply(manifest,
                                 function(item) has_value(item$comment),
                                 logical(1)))
  if (without_comment == 0) {
    rule_pass("every manifest item has a comment")
  } else {
    rule_fail(paste(without_comment,
                    "manifest item(s) have no comment to explain them"))
  }
}

# --- codechecker and report ------------------------------------------------

#' @keywords internal
#' @noRd
check_codechecker_present <- function(context) {
  codecheckers <- as_items(context$yml$codechecker)
  if (length(codecheckers) > 0) {
    rule_pass(paste(length(codecheckers), "codechecker(s)"))
  } else {
    rule_fail("no codechecker recorded")
  }
}

#' @keywords internal
#' @noRd
check_codechecker_name <- function(context) {
  codecheckers <- as_items(context$yml$codechecker)
  if (length(codecheckers) == 0) {
    return(rule_skip("no codechecker to inspect"))
  }
  without_name <- which(!vapply(codecheckers,
                                function(person) has_value(person$name),
                                logical(1)))
  if (length(without_name) == 0) {
    rule_pass()
  } else {
    rule_fail(paste("codechecker(s) without a name:",
                    paste(without_name, collapse = ", ")))
  }
}

#' @keywords internal
#' @noRd
check_codechecker_orcid <- function(context) {
  codecheckers <- as_items(context$yml$codechecker)
  if (length(codecheckers) == 0) {
    return(rule_skip("no codechecker to inspect"))
  }
  without_orcid <- which(!vapply(codecheckers,
                                 function(person) has_value(person$ORCID),
                                 logical(1)))
  if (length(without_orcid) == 0) {
    rule_pass()
  } else {
    rule_fail(paste("codechecker(s) without an ORCID:",
                    paste(without_orcid, collapse = ", ")))
  }
}

#' @keywords internal
#' @noRd
check_report_present <- function(context) {
  if (has_value(context$yml$report)) {
    rule_pass(as.character(context$yml$report))
  } else {
    rule_fail("no report identifier")
  }
}

#' @keywords internal
#' @noRd
check_report_resolvable <- function(context) {
  report <- context$yml$report
  if (!has_value(report)) {
    return(rule_skip("no report identifier to resolve"))
  }
  if (!grepl("^https?://", report)) {
    return(rule_fail(paste0("'", report, "' is not a resolvable URL")))
  }
  url_resolves(report)
}

#' @keywords internal
#' @noRd
check_report_doi_not_placeholder <- function(context) {
  report <- context$yml$report
  if (!has_value(report)) {
    return(rule_skip("no report identifier to inspect"))
  }
  if (is_doi_placeholder(report)) {
    rule_fail(paste0("'", report, "' is a placeholder"))
  } else {
    rule_pass()
  }
}

# --- specification version -------------------------------------------------

#' @keywords internal
#' @noRd
check_version_present <- function(context) {
  if (has_value(context$yml$version)) {
    rule_pass(as.character(context$yml$version))
  } else {
    rule_fail(paste0("no version node; the newest specification (",
                     codecheck_spec_versions()[1], ") is assumed"))
  }
}

#' @keywords internal
#' @noRd
check_version_known <- function(context) {
  version <- context$yml$version
  if (!has_value(version)) {
    return(rule_skip("no version node to inspect"))
  }
  if (is.na(spec_version_from_url(version))) {
    rule_fail(paste0("'", version, "' is not a published specification version"))
  } else {
    rule_pass()
  }
}

# --- paper metadata --------------------------------------------------------

#' @keywords internal
#' @noRd
check_paper_present <- function(context) {
  if (has_value(context$yml$paper)) {
    rule_pass()
  } else {
    rule_fail("no paper metadata")
  }
}

#' @keywords internal
#' @noRd
check_paper_title <- function(context) {
  if (!has_value(context$yml$paper)) {
    return(rule_skip("no paper metadata to inspect"))
  }
  if (has_value(context$yml$paper$title)) {
    rule_pass()
  } else {
    rule_fail("the paper has no title")
  }
}

#' @keywords internal
#' @noRd
check_paper_authors <- function(context) {
  if (!has_value(context$yml$paper)) {
    return(rule_skip("no paper metadata to inspect"))
  }
  authors <- as_items(context$yml$paper$authors)
  if (length(authors) > 0) {
    rule_pass(paste(length(authors), "author(s)"))
  } else {
    rule_fail("the paper has no authors")
  }
}

#' @keywords internal
#' @noRd
check_paper_author_name <- function(context) {
  authors <- as_items(context$yml$paper$authors)
  if (length(authors) == 0) {
    return(rule_skip("no authors to inspect"))
  }
  without_name <- which(!vapply(authors,
                                function(person) has_value(person$name),
                                logical(1)))
  if (length(without_name) == 0) {
    rule_pass()
  } else {
    rule_fail(paste("author(s) without a name:",
                    paste(without_name, collapse = ", ")))
  }
}

#' @keywords internal
#' @noRd
check_paper_author_orcid <- function(context) {
  authors <- as_items(context$yml$paper$authors)
  if (length(authors) == 0) {
    return(rule_skip("no authors to inspect"))
  }
  without_orcid <- which(!vapply(authors,
                                 function(person) has_value(person$ORCID),
                                 logical(1)))
  if (length(without_orcid) == 0) {
    rule_pass()
  } else {
    rule_fail(paste("author(s) without an ORCID:",
                    paste(without_orcid, collapse = ", ")))
  }
}

#' @keywords internal
#' @noRd
check_paper_reference <- function(context) {
  if (has_value(context$yml$paper$reference)) {
    rule_pass(as.character(context$yml$paper$reference))
  } else {
    rule_fail("the paper has no reference")
  }
}

#' @keywords internal
#' @noRd
check_reference_is_url <- function(context) {
  reference <- context$yml$paper$reference
  if (!has_value(reference)) {
    return(rule_skip("no reference to inspect"))
  }
  if (grepl("^https?://[^[:space:]]+$", trimws(reference))) {
    rule_pass()
  } else {
    rule_fail(paste0("'", reference,
                     "' is not a bare URL; tools do not extract a URL from",
                     " surrounding text"))
  }
}

#' @keywords internal
#' @noRd
check_reference_prefers_doi <- function(context) {
  reference <- context$yml$paper$reference
  if (!has_value(reference)) {
    return(rule_skip("no reference to inspect"))
  }
  if (grepl("doi\\.org/|^doi:|^10\\.[0-9]{4,}/", reference)) {
    rule_pass()
  } else {
    rule_fail("the reference is not a DOI, which is preferred for long-term availability")
  }
}

#' @keywords internal
#' @noRd
check_reference_not_bare_pdf <- function(context) {
  reference <- context$yml$paper$reference
  if (!has_value(reference)) {
    return(rule_skip("no reference to inspect"))
  }
  if (!is_pdf_link(reference)) {
    return(rule_pass())
  }
  if (is_web_archive_link(reference)) {
    # Reported by CC-CFG-031 instead, which is advisory: an archived snapshot
    # is what the specification asks for where nothing better exists.
    rule_pass("a PDF link, but an archived one")
  } else {
    rule_fail(paste0("'", reference,
                     "' is a direct PDF link; prefer a DOI or a landing page"))
  }
}

#' @keywords internal
#' @noRd
check_reference_pdf_is_archived <- function(context) {
  reference <- context$yml$paper$reference
  if (!has_value(reference) || !is_pdf_link(reference)) {
    return(rule_skip("the reference is not a PDF link"))
  }
  if (is_web_archive_link(reference)) {
    rule_pass("archived snapshot of a PDF")
  } else {
    rule_fail("a direct PDF link that is not archived; a Wayback Machine snapshot lasts longer")
  }
}

#' @keywords internal
#' @noRd
check_reference_other_is_list <- function(context) {
  other <- context$yml$paper[["reference-other"]]
  if (is.null(other)) {
    return(rule_skip("no reference-other"))
  }
  if (is.list(other) && is.null(names(other))) {
    rule_pass(paste(length(other), "further reference(s)"))
  } else {
    rule_fail("reference-other is not a sequence")
  }
}

#' @keywords internal
#' @noRd
check_reference_other_item_form <- function(context) {
  other <- context$yml$paper[["reference-other"]]
  if (is.null(other) || !is.list(other) || !is.null(names(other))) {
    return(rule_skip("no reference-other sequence"))
  }
  entries <- unlist(other)
  not_url <- entries[!grepl("^https?://[^[:space:]]+$", trimws(entries))]
  if (length(not_url) == 0) {
    rule_pass()
  } else {
    rule_fail(paste("reference-other entries that are not resolvable URLs:",
                    paste(not_url, collapse = ", ")))
  }
}

# --- certificate and summary -----------------------------------------------

#' @keywords internal
#' @noRd
check_summary_present <- function(context) {
  if (has_value(context$yml$summary)) {
    rule_pass()
  } else {
    rule_fail("no summary of the check")
  }
}

#' @keywords internal
#' @noRd
check_certificate_present <- function(context) {
  if (has_value(context$yml$certificate)) {
    rule_pass(as.character(context$yml$certificate))
  } else {
    rule_fail("no certificate identifier")
  }
}

#' @keywords internal
#' @noRd
check_certificate_id_format <- function(context) {
  certificate <- context$yml$certificate
  if (!has_value(certificate)) {
    return(rule_skip("no certificate identifier to inspect"))
  }
  if (grepl("^[0-9]{4}-[0-9]{3}$", certificate)) {
    rule_pass()
  } else {
    rule_fail(paste0("'", certificate, "' is not of the form YYYY-NNN"))
  }
}

#' @keywords internal
#' @noRd
check_no_placeholder_values <- function(context) {
  # The template this package writes uses FIXME, and a certificate that keeps
  # one has not been filled in. is_doi_placeholder() covers the report DOI,
  # which has placeholder forms of its own.
  flat <- unlist(context$yml)
  flat <- flat[is.character(flat)]
  placeholders <- flat[grepl("FIXME|TODO|XXXX|0000-0000-0000-0000", flat)]
  if (has_value(context$yml$report) && is_doi_placeholder(context$yml$report)) {
    placeholders <- c(placeholders, as.character(context$yml$report))
  }
  placeholders <- unique(placeholders)
  if (length(placeholders) == 0) {
    rule_pass()
  } else {
    rule_fail(paste("placeholder value(s) left in the file:",
                    paste(placeholders, collapse = ", ")))
  }
}


# --- the bundle on disk ----------------------------------------------------

#' @keywords internal
#' @noRd
check_codecheck_directory_present <- function(context) {
  if (is.null(context$bundle_dir)) {
    return(rule_skip("no bundle on disk to inspect"))
  }
  directories <- file.path(context$bundle_dir, c("codecheck", ".codecheck"))
  if (any(dir.exists(directories))) {
    rule_pass(basename(directories[dir.exists(directories)][1]))
  } else {
    rule_fail("the bundle has no codecheck/ or .codecheck/ directory")
  }
}

#' @keywords internal
#' @noRd
check_report_file_present <- function(context) {
  if (is.null(context$bundle_dir)) {
    return(rule_skip("no bundle on disk to inspect"))
  }
  directories <- file.path(context$bundle_dir, c("codecheck", ".codecheck"))
  directories <- directories[dir.exists(directories)]
  if (length(directories) == 0) {
    return(rule_skip("no codecheck/ directory to look in"))
  }
  reports <- list.files(directories, pattern = "\\.pdf$", ignore.case = TRUE)
  if (length(reports) > 0) {
    rule_pass(paste(reports, collapse = ", "))
  } else {
    rule_fail("no certificate report in the codecheck/ directory")
  }
}

#' @keywords internal
#' @noRd
check_licence_present <- function(context) {
  if (is.null(context$bundle_dir)) {
    return(rule_skip("no bundle on disk to inspect"))
  }
  licences <- list.files(context$bundle_dir,
                         pattern = "^(LICEN[CS]E|COPYING)(\\..*)?$",
                         ignore.case = TRUE)
  if (length(licences) > 0) {
    rule_pass(paste(licences, collapse = ", "))
  } else {
    rule_fail("the repository under check states no licence")
  }
}

#' @keywords internal
#' @noRd
check_reference_other_resolves <- function(context) {
  other <- context$yml$paper[["reference-other"]]
  if (is.null(other) || !is.list(other) || !is.null(names(other))) {
    return(rule_skip("no reference-other sequence"))
  }
  entries <- unlist(other)
  entries <- entries[grepl("^https?://", entries)]
  if (length(entries) == 0) {
    return(rule_skip("no reference-other entry to resolve"))
  }
  results <- lapply(entries, url_resolves)
  failed <- entries[vapply(results, function(r) r$status == "fail", logical(1))]
  if (length(failed) > 0) {
    return(rule_fail(paste("reference-other entries that do not resolve:",
                           paste(failed, collapse = ", "))))
  }
  if (all(vapply(results, function(r) r$status == "skip", logical(1)))) {
    return(rule_skip("could not reach any reference-other entry"))
  }
  rule_pass()
}

# --- external records: ORCID and Crossref ---------------------------------

#' @keywords internal
#' @noRd
check_orcid_resolves <- function(context) {
  people <- context_people(context)
  people <- people[vapply(people, function(p) is_orcid(p$ORCID), logical(1))]
  # The template's placeholder is well-formed but no one's ORCID; it is reported
  # by CC-CFG-023 no-placeholder-values, not looked up.
  people <- people[!vapply(people, function(p) is_orcid_placeholder(p$ORCID), logical(1))]
  if (length(people) == 0) {
    return(rule_skip("no well-formed ORCID to look up"))
  }
  orcids <- unique(vapply(people, function(p) p$ORCID, character(1)))
  records <- lapply(orcids, context_orcid, context = context)
  status <- vapply(records, function(r) r$status, character(1))

  if (any(status == "not_found")) {
    return(rule_fail(paste("ORCID(s) with no record:",
                           paste(orcids[status == "not_found"], collapse = ", "))))
  }
  if (all(status == "unreachable")) {
    return(rule_skip(paste("could not reach the ORCID API:",
                           records[[1]]$detail)))
  }
  unreachable <- sum(status == "unreachable")
  rule_pass(paste0(sum(status == "ok"), " ORCID record(s)",
                   if (unreachable > 0) paste0(", ", unreachable, " not reachable") else ""))
}

#' @keywords internal
#' @noRd
check_orcid_name_match <- function(context) {
  people <- context_people(context)
  people <- people[vapply(people, function(p) {
    is_orcid(p$ORCID) && !is_orcid_placeholder(p$ORCID) && has_value(p$name)
  }, logical(1))]
  if (length(people) == 0) {
    return(rule_skip("no named person with a well-formed ORCID"))
  }

  compared <- 0
  mismatches <- character(0)
  for (person in people) {
    record <- context_orcid(context, person$ORCID)
    # A record that cannot be read, or one whose name is not public, gives
    # nothing to compare against.
    if (record$status != "ok" || is.null(record$name)) next
    compared <- compared + 1
    if (!names_match(person$name, record$name)) {
      mismatches <- c(mismatches, paste0(person$name, " (", person$ORCID,
                                         ") is '", record$name, "' on ORCID"))
    }
  }

  if (length(mismatches) > 0) {
    return(rule_fail(paste(mismatches, collapse = "; ")))
  }
  if (compared == 0) {
    return(rule_skip("no public ORCID name to compare against"))
  }
  rule_pass(paste(compared, "name(s) match"))
}

#' @keywords internal
#' @noRd
check_paper_reference_resolves <- function(context) {
  crossref <- context_crossref(context)
  switch(crossref$status,
    ok = rule_pass(paste("Crossref record for", crossref$doi)),
    datacite = rule_pass(paste(crossref$doi, "resolves, but is not a Crossref DOI")),
    not_found = rule_fail(paste(crossref$doi, "is not a registered DOI")),
    not_doi = url_resolves(crossref$reference),
    rule_skip(crossref$detail)
  )
}

#' @keywords internal
#' @noRd
check_crossref_title_match <- function(context) {
  crossref <- context_crossref(context)
  if (crossref$status != "ok") {
    return(rule_skip(crossref_skip_detail(crossref)))
  }
  local <- context$yml$paper$title
  remote <- unlist(crossref$record$title)
  if (!has_value(local) || !has_value(remote)) {
    return(rule_skip("no title to compare"))
  }
  normalise <- function(title) {
    gsub("[[:punct:]]", "", gsub("\\s+", " ", tolower(trimws(title))))
  }
  if (identical(normalise(local), normalise(remote[1]))) {
    rule_pass()
  } else {
    rule_fail(paste0("'", local, "' is '", remote[1], "' on Crossref"))
  }
}

#' @keywords internal
#' @noRd
check_crossref_author_count_match <- function(context) {
  crossref <- context_crossref(context)
  if (crossref$status != "ok") {
    return(rule_skip(crossref_skip_detail(crossref)))
  }
  local <- as_items(context$yml$paper$authors)
  remote <- crossref$record$author
  if (length(local) == 0 || length(remote) == 0) {
    return(rule_skip("no authors to compare"))
  }
  if (length(local) == length(remote)) {
    rule_pass(paste(length(local), "author(s)"))
  } else {
    rule_fail(paste(length(local), "author(s) here,", length(remote), "on Crossref"))
  }
}

#' @keywords internal
#' @noRd
check_crossref_author_name_match <- function(context) {
  crossref <- context_crossref(context)
  if (crossref$status != "ok") {
    return(rule_skip(crossref_skip_detail(crossref)))
  }
  local <- as_items(context$yml$paper$authors)
  remote <- crossref$record$author
  # Compared by position, as far as both lists go: the count is CC-MET-006.
  pairs <- seq_len(min(length(local), length(remote)))
  pairs <- pairs[vapply(pairs, function(i) has_value(local[[i]]$name), logical(1))]
  if (length(pairs) == 0) {
    return(rule_skip("no author names to compare"))
  }
  mismatches <- character(0)
  for (i in pairs) {
    remote_name <- crossref_author_name(remote[[i]])
    if (!names_match(local[[i]]$name, remote_name)) {
      mismatches <- c(mismatches, paste0("author ", i, " '", local[[i]]$name,
                                         "' is '", remote_name, "' on Crossref"))
    }
  }
  if (length(mismatches) == 0) {
    rule_pass(paste(length(pairs), "name(s) match"))
  } else {
    rule_fail(paste(mismatches, collapse = "; "))
  }
}

#' @keywords internal
#' @noRd
check_crossref_author_orcid_match <- function(context) {
  crossref <- context_crossref(context)
  if (crossref$status != "ok") {
    return(rule_skip(crossref_skip_detail(crossref)))
  }
  local <- as_items(context$yml$paper$authors)
  remote <- crossref$record$author
  # Only where both sides give an ORCID: an ORCID the publisher did not
  # deposit is not a mismatch.
  pairs <- seq_len(min(length(local), length(remote)))
  pairs <- pairs[vapply(pairs, function(i) {
    has_value(local[[i]]$ORCID) && has_value(remote[[i]]$ORCID)
  }, logical(1))]
  if (length(pairs) == 0) {
    return(rule_skip("no author with an ORCID both here and on Crossref"))
  }
  mismatches <- character(0)
  for (i in pairs) {
    here <- strip_orcid_prefix(local[[i]]$ORCID)
    there <- strip_orcid_prefix(remote[[i]]$ORCID)
    if (!identical(here, there)) {
      mismatches <- c(mismatches, paste0("author ", i, " ", here, " is ",
                                         there, " on Crossref"))
    }
  }
  if (length(mismatches) == 0) {
    rule_pass(paste(length(pairs), "ORCID(s) match"))
  } else {
    rule_fail(paste(mismatches, collapse = "; "))
  }
}

#' The people whose ORCIDs the ORCID rules look at
#'
#' The paper's authors and the codecheckers, unless `context$people` narrows it
#' to one group, as `validate_codecheck_yml_orcid()` does on request.
#'
#' @keywords internal
#' @noRd
context_people <- function(context) {
  groups <- if (is.null(context$people)) c("authors", "codecheckers") else context$people
  c(if ("authors" %in% groups) as_items(context$yml$paper$authors),
    if ("codecheckers" %in% groups) as_items(context$yml$codechecker))
}

#' One ORCID record, requested once per validation run
#'
#' Uses the public ORCID API, which reads any record without a token.
#' Authenticated access would only add the authenticated user's own record.
#'
#' @return A list with `status` (`"ok"`, `"not_found"` or `"unreachable"`),
#'   `name` (`NULL` when the record has no public name) and `detail`.
#' @keywords internal
#' @noRd
context_orcid <- function(context, orcid) {
  key <- paste0("orcid:", orcid)
  if (!is.null(context$lookups[[key]])) {
    return(context$lookups[[key]])
  }

  url <- paste0("https://pub.orcid.org/v3.0/", orcid, "/person")
  response <- tryCatch(
    codecheck_GET(url, httr::add_headers(Accept = "application/json")),
    error = function(e) e)

  record <- if (inherits(response, "error")) {
    list(status = "unreachable", name = NULL, detail = conditionMessage(response))
  } else if (httr::status_code(response) == 404) {
    list(status = "not_found", name = NULL, detail = paste(orcid, "has no record"))
  } else if (httr::status_code(response) != 200) {
    # Rate limits and server errors say nothing about the ORCID.
    list(status = "unreachable", name = NULL,
         detail = paste("the ORCID API answered", httr::status_code(response)))
  } else {
    person <- tryCatch(
      jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"),
                         simplifyVector = FALSE),
      error = function(e) NULL)
    given <- person$name$`given-names`$value
    family <- person$name$`family-name`$value
    name <- if (is.null(given) && is.null(family)) NULL else trimws(paste(given, family))
    list(status = "ok", name = name, detail = NULL)
  }

  assign(key, record, envir = context$lookups)
  record
}

#' The Crossref record of the paper, requested once per validation run
#'
#' A DOI Crossref does not know is looked up in the DOI handle system before it
#' is called unregistered, because a DataCite DOI (a Zenodo or OSF preprint, for
#' example) is a perfectly good paper reference with no Crossref record.
#'
#' @return A list with `status`, one of `"ok"` (with `record`), `"datacite"`
#'   (registered, but not with Crossref), `"not_found"`, `"not_doi"` (with
#'   `reference`), `"none"`, `"placeholder"` or `"unreachable"`, plus `doi`
#'   and `detail`.
#' @keywords internal
#' @noRd
context_crossref <- function(context) {
  if (!is.null(context$lookups$crossref)) {
    return(context$lookups$crossref)
  }
  result <- lookup_crossref(context$yml$paper$reference)
  assign("crossref", result, envir = context$lookups)
  result
}

#' @keywords internal
#' @noRd
lookup_crossref <- function(reference) {
  if (!has_value(reference)) {
    return(list(status = "none", detail = "no paper reference"))
  }
  reference <- trimws(as.character(reference)[1])
  if (grepl("FIXME|TODO|template|example", reference, ignore.case = TRUE)) {
    return(list(status = "placeholder",
                detail = "the paper reference is a placeholder"))
  }
  doi <- doi_from_reference(reference)
  if (is.na(doi)) {
    return(list(status = "not_doi", reference = reference,
                detail = "the paper reference is not a DOI"))
  }

  response <- tryCatch(
    codecheck_GET(paste0("https://api.crossref.org/works/", doi)),
    error = function(e) e)
  if (inherits(response, "error")) {
    return(list(status = "unreachable", doi = doi,
                detail = paste("could not reach Crossref:", conditionMessage(response))))
  }
  status <- httr::status_code(response)
  if (status == 200) {
    record <- tryCatch(
      jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"),
                         simplifyVector = FALSE)$message,
      error = function(e) NULL)
    if (!is.null(record)) {
      return(list(status = "ok", doi = doi, record = record, detail = NULL))
    }
  }
  if (status != 404) {
    return(list(status = "unreachable", doi = doi,
                detail = paste("Crossref answered", status, "for", doi)))
  }

  handle <- tryCatch(
    codecheck_GET(paste0("https://doi.org/api/handles/", doi)),
    error = function(e) e)
  if (inherits(handle, "error") ||
      !httr::status_code(handle) %in% c(200, 404)) {
    return(list(status = "unreachable", doi = doi,
                detail = paste(doi, "is not on Crossref and doi.org could not be reached")))
  }
  if (httr::status_code(handle) == 200) {
    list(status = "datacite", doi = doi, detail = paste(doi, "has no Crossref record"))
  } else {
    list(status = "not_found", doi = doi, detail = paste(doi, "is not a registered DOI"))
  }
}

#' Why a Crossref comparison could not run
#' @keywords internal
#' @noRd
crossref_skip_detail <- function(crossref) {
  if (crossref$status %in% c("datacite", "not_found", "not_doi")) {
    "no Crossref record to compare against"
  } else {
    crossref$detail
  }
}

#' The DOI in a paper reference, or `NA`
#' @keywords internal
#' @noRd
doi_from_reference <- function(reference) {
  doi <- sub("^https?://(dx\\.)?doi\\.org/", "", reference, ignore.case = TRUE)
  doi <- sub("^doi:\\s*", "", doi, ignore.case = TRUE)
  if (grepl("^10\\.[0-9]{4,}/\\S+$", doi)) doi else NA_character_
}

#' @keywords internal
#' @noRd
crossref_author_name <- function(author) {
  if (!is.null(author$name)) {
    return(author$name)
  }
  trimws(paste(if (is.null(author$given)) "" else author$given,
               if (is.null(author$family)) "" else author$family))
}

#' Is a value a well-formed ORCID?
#' @keywords internal
#' @noRd
is_orcid <- function(value) {
  has_value(value) &&
    grepl("^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$", value, perl = TRUE)
}

#' Is an ORCID the template's placeholder, see CC-CFG-023?
#' @keywords internal
#' @noRd
is_orcid_placeholder <- function(orcid) {
  identical(trimws(as.character(orcid)), "0000-0000-0000-0000")
}

#' @keywords internal
#' @noRd
strip_orcid_prefix <- function(orcid) {
  sub("^https?://orcid\\.org/", "", trimws(orcid))
}

#' Do two spellings of a name refer to the same person?
#'
#' Tolerant on purpose: case, diacritics, full stops, word order and missing
#' middle names do not matter, so "S. J. Eglen", "Stephen Eglen" and "Eglen,
#' Stephen J." all match, and so do "Grišiūtė" and "Grisiute", which is how
#' many ORCID records spell names. The significant parts (two characters or more) of one name must all
#' appear in the other.
#'
#' @keywords internal
#' @noRd
names_match <- function(a, b) {
  parts <- function(name) {
    # Transliterate, then drop what some platforms' iconv leaves behind, such
    # as the apostrophe in 'e for an e with an acute accent.
    ascii <- iconv(name, from = "UTF-8", to = "ASCII//TRANSLIT")
    if (!is.na(ascii)) name <- gsub("[^A-Za-z.,[:space:]-]", "", ascii)
    words <- strsplit(tolower(gsub("[.,]", " ", name)), "\\s+")[[1]]
    words[nchar(words) >= 2]
  }
  pa <- parts(a)
  pb <- parts(b)
  all(pa %in% pb) || all(pb %in% pa)
}

# --- the register as a whole -----------------------------------------------
#
# These take a register context, see register_rules_context(), and are run by
# validate_register_rules() rather than by the per-file driver.

#' The venue types the register knows, as in the `Type` column
#' @keywords internal
#' @noRd
REGISTER_TYPES <- c("journal", "conference", "community", "institution")

#' How far a certificate number may jump past the year's previous one
#'
#' Identifiers are reserved when a check starts, and a check that is abandoned
#' leaves its number unused, so a year's sequence has gaps. A jump beyond this
#' is far more likely a typo than a run of abandoned checks.
#'
#' @keywords internal
#' @noRd
CERTIFICATE_ID_MAX_JUMP <- 9

#' @keywords internal
#' @noRd
check_certificate_id_sequence <- function(context) {
  ids <- trimws(as.character(context$register$Certificate))
  ids <- ids[!is.na(ids) & nzchar(ids)]
  if (length(ids) == 0) {
    return(rule_skip("no certificate identifiers in the register"))
  }

  malformed <- ids[!grepl("^[0-9]{4}-[0-9]{3}$", ids)]
  well_formed <- setdiff(ids, malformed)
  years <- as.integer(substr(well_formed, 1, 4))
  numbers <- as.integer(substr(well_formed, 6, 8))

  current_year <- as.integer(format(context$today, "%Y"))
  future <- well_formed[years > current_year]

  jumps <- character(0)
  for (i in seq_along(well_formed)) {
    earlier <- numbers[years == years[i] & numbers < numbers[i]]
    previous <- if (length(earlier) == 0) 0L else max(earlier)
    if (numbers[i] - previous > CERTIFICATE_ID_MAX_JUMP) {
      jumps <- c(jumps, paste0(well_formed[i], " (after ",
                               if (previous == 0) "the start of the year" else
                                 sprintf("%d-%03d", years[i], previous), ")"))
    }
  }

  problems <- c(
    if (length(malformed) > 0) paste("not YYYY-NNN:", paste(malformed, collapse = ", ")),
    if (length(future) > 0) paste("in a future year:", paste(future, collapse = ", ")),
    if (length(jumps) > 0) paste("more than", CERTIFICATE_ID_MAX_JUMP,
                                 "past the year's previous identifier:",
                                 paste(jumps, collapse = ", ")))
  if (length(problems) == 0) {
    rule_pass(paste(length(ids), "identifier(s)"))
  } else {
    rule_fail(paste(problems, collapse = "; "))
  }
}

#' @keywords internal
#' @noRd
check_type_known <- function(context) {
  register <- context$register
  if (!"Type" %in% names(register) || nrow(register) == 0) {
    return(rule_skip("no Type column"))
  }
  unknown <- !register$Type %in% REGISTER_TYPES
  if (!any(unknown)) {
    rule_pass()
  } else {
    rule_fail(paste("unknown type(s):",
                    paste0(register$Certificate[unknown], " '",
                           register$Type[unknown], "'", collapse = ", ")))
  }
}

#' @keywords internal
#' @noRd
check_venue_known <- function(context) {
  register <- context$register
  if (is.null(context$venues)) {
    return(rule_skip("no venues.csv to compare with"))
  }
  if (!"Venue" %in% names(register) || nrow(register) == 0) {
    return(rule_skip("no Venue column"))
  }
  unknown <- !register$Venue %in% context$venues
  if (!any(unknown)) {
    rule_pass()
  } else {
    rule_fail(paste("venue(s) not in venues.csv:",
                    paste0(register$Certificate[unknown], " '",
                           register$Venue[unknown], "'", collapse = ", ")))
  }
}

#' The check function for each register-wide rule
#'
#' Kept apart from `rule_checks()`, so that validating a single `codecheck.yml`
#' never runs a check that needs the whole register.
#'
#' @return Named character vector, rule identifier to check function name.
#' @keywords internal
#' @noRd
register_rule_checks <- function() {
  c(
    "CC-REG-002" = "check_certificate_id_sequence",
    "CC-REG-004" = "check_type_known",
    "CC-REG-005" = "check_venue_known"
  )
}

# --- helpers shared by several checks --------------------------------------

#' Does a reference point directly at a PDF?
#' @keywords internal
#' @noRd
is_pdf_link <- function(reference) {
  grepl("\\.pdf($|[?#])", reference, ignore.case = TRUE)
}

#' Is a reference a web archive snapshot?
#' @keywords internal
#' @noRd
is_web_archive_link <- function(reference) {
  grepl("web\\.archive\\.org/|archive\\.ph/|webcitation\\.org/", reference,
        ignore.case = TRUE)
}

#' Does a URL resolve?
#'
#' A network failure is a skip, not a failure: an unreachable server says
#' nothing about the `codecheck.yml`.
#'
#' @keywords internal
#' @noRd
url_resolves <- function(url) {
  response <- tryCatch(codecheck_GET(url), error = function(e) e)
  if (inherits(response, "error")) {
    return(rule_skip(paste0("could not reach '", url, "': ",
                            conditionMessage(response))))
  }
  if (httr::http_error(response)) {
    rule_fail(paste0("'", url, "' answers ", httr::status_code(response)))
  } else {
    rule_pass()
  }
}

#' The check function for each rule
#'
#' The driver looks a rule up here by identifier, so a specification version
#' runs exactly the rules its own file lists, see [validate_codecheck_yml_rules()].
#' A rule missing from this table is not checked, and the tests fail unless it
#' is recorded in `rules_not_implemented()`.
#'
#' @return Named character vector, rule identifier to check function name.
#' @keywords internal
#' @noRd
rule_checks <- function() {
  c(
    "CC-CFG-001" = "check_yaml_parses",
    "CC-CFG-002" = "check_explicit_document",
    "CC-CFG-003" = "check_file_name_and_location",
    "CC-CFG-004" = "check_manifest_present",
    "CC-CFG-005" = "check_manifest_item_file",
    "CC-CFG-006" = "check_manifest_path_relative",
    "CC-CFG-007" = "check_manifest_item_comment",
    "CC-CFG-008" = "check_codechecker_present",
    "CC-CFG-009" = "check_codechecker_name",
    "CC-CFG-010" = "check_codechecker_orcid",
    "CC-CFG-011" = "check_report_present",
    "CC-CFG-012" = "check_report_resolvable",
    "CC-CFG-013" = "check_report_doi_not_placeholder",
    "CC-CFG-014" = "check_version_present",
    "CC-CFG-015" = "check_version_known",
    "CC-CFG-016" = "check_paper_present",
    "CC-CFG-017" = "check_paper_title",
    "CC-CFG-018" = "check_paper_authors",
    "CC-CFG-019" = "check_paper_author_name",
    "CC-CFG-020" = "check_paper_author_orcid",
    "CC-CFG-021" = "check_paper_reference",
    "CC-CFG-022" = "check_reference_not_bare_pdf",
    "CC-CFG-023" = "check_no_placeholder_values",
    "CC-CFG-024" = "check_summary_present",
    "CC-CFG-025" = "check_certificate_present",
    "CC-CFG-026" = "check_certificate_id_format",
    "CC-CFG-027" = "check_reference_is_url",
    "CC-CFG-028" = "check_reference_prefers_doi",
    "CC-CFG-029" = "check_reference_other_is_list",
    "CC-CFG-030" = "check_reference_other_item_form",
    "CC-CFG-031" = "check_reference_pdf_is_archived",
    "CC-MET-001" = "check_orcid_format",
    "CC-MET-002" = "check_orcid_resolves",
    "CC-MET-003" = "check_orcid_name_match",
    "CC-MET-004" = "check_paper_reference_resolves",
    "CC-MET-005" = "check_crossref_title_match",
    "CC-MET-006" = "check_crossref_author_count_match",
    "CC-MET-007" = "check_crossref_author_name_match",
    "CC-MET-008" = "check_crossref_author_orcid_match",
    "CC-MET-009" = "check_reference_other_resolves",
    "CC-BUN-001" = "check_manifest_files_exist",
    "CC-BUN-002" = "check_codecheck_directory_present",
    "CC-BUN-003" = "check_report_file_present",
    "CC-BUN-005" = "check_licence_present"
  )
}
