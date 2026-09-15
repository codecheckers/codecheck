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
  # The driver cannot build a context without parsing the file, so reaching
  # this check at all means the parse worked.
  rule_pass("parsed as YAML")
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
  manifest <- as_items(context$yml$manifest)
  if (length(manifest) > 0) {
    rule_pass(paste(length(manifest), "manifest item(s)"))
  } else {
    rule_fail("no manifest, or an empty one")
  }
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
    "CC-CFG-031" = "check_reference_pdf_is_archived"
  )
}
