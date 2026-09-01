#' Function for checking ceritificate id if there is a codecheck_yaml.
#' If there is a mismatch a stop is sent. Else a warning is thrown.
#' 
#' @param codecheck_yaml The codecheck yaml file
#' @param entry The registry entry
#' @return None
check_certificate_id <- function(entry, codecheck_yaml) {
  # Codecheck.yml found, proceeding to check certificate id
  if (!is.null(codecheck_yaml)) {
    # validate config file
    validate_codecheck_yml(codecheck_yaml)

    # check certificate ID
    if (entry$Certificate != codecheck_yaml$certificate) {
      stop(
        "Certificate mismatch, register: ", entry$Certificate,
        " vs. repo ", codecheck_yaml$certificate
      )
    }
  }

  # Codecheck.yml not found, throwing warning
  else {
    warning(entry$Certificate, " does not have a codecheck.yml file")
  }
}

#' Check that a repository is in an allowed organisation/group
#'
#' A pure string check on the repository spec, no network call: registry
#' policy requires the checked repository to live in one of the GitHub
#' organisations or GitLab groups listed in `CONFIG$ALLOWED_REPO_ORGS` (the
#' `codecheckers` org and `cdchck` group by default, see the same rule
#' enforced for Zenodo records in `check_register_zenodo_policy()`). Add
#' further trusted orgs/groups by extending `CONFIG$ALLOWED_REPO_ORGS` in
#' `config.R`. A violation stops the check for this entry, it is not a hint
#' to fix later.
#'
#' @param entry The registry entry
#' @param spec The parsed repository spec, see `parse_repository_spec()`
#' @return None
check_repository_org <- function(entry, spec) {
  if (spec[["type"]] == "github") {
    org <- split_github_repo_spec(spec[["repo"]])$org
    allowed <- CONFIG$ALLOWED_REPO_ORGS[["github"]]
    if (!(org %in% allowed)) {
      stop(entry$Certificate, " repository is not in an allowed GitHub organisation (",
           toString(allowed), "): ", spec[["repo"]])
    }
  } else if (spec[["type"]] == "gitlab") {
    group <- strsplit(spec[["repo"]], "/", fixed = TRUE)[[1]][[1]]
    allowed <- CONFIG$ALLOWED_REPO_ORGS[["gitlab"]]
    if (!(group %in% allowed)) {
      stop(entry$Certificate, " repository is not in an allowed GitLab group (",
           toString(allowed), "): ", spec[["repo"]])
    }
  }
}

#' Check that a repository is archived
#'
#' The checked repository should be archived (read-only) once the check is
#' complete, see codecheckers/codecheck#25. Only applies to GitHub/GitLab
#' repositories; a lookup failure degrades to a no-op rather than aborting the
#' whole register check.
#'
#' @param entry The registry entry
#' @param spec The parsed repository spec, see `parse_repository_spec()`
#' @return None
check_repository_archived <- function(entry, spec) {
  metadata <- switch(spec[["type"]],
    "github" = get_github_repo_metadata(spec[["repo"]]),
    "gitlab" = get_gitlab_project_metadata(spec[["repo"]]),
    NULL
  )

  if (is.null(metadata)) {
    return(invisible(NULL))
  }

  if (identical(metadata$archived, FALSE)) {
    warning(entry$Certificate, " repository is not archived: ", spec[["repo"]])
  }
}

#' Check that a repository advertises the CODECHECK badge
#'
#' The community workflow asks codecheckers to add a CODECHECK badge to the
#' original repository, see codecheckers/codecheck#75. A missing badge is
#' informational only, not a defect, so this reports via `cli::cli_alert_info()`
#' rather than `warning()`.
#'
#' @param entry The registry entry
#' @param spec The parsed repository spec, see `parse_repository_spec()`
#' @return None
check_repository_badge <- function(entry, spec) {
  readme <- switch(spec[["type"]],
    "github" = get_github_readme_raw(spec[["repo"]]),
    "gitlab" = get_gitlab_readme_raw(spec[["repo"]]),
    NULL
  )

  if (is.null(readme)) {
    return(invisible(NULL))
  }

  badge_markers <- c("codeworks-badge", "codecheck-badge", "codecheck.org.uk/img")
  if (!any(sapply(badge_markers, grepl, x = readme, fixed = TRUE))) {
    cli::cli_alert_info("{entry$Certificate} repository does not yet have a CODECHECK badge: {spec[['repo']]}")
  }
}

#' Check that a repository has a license
#'
#' Not required by the CODECHECK spec, but good practice, see the TODO in
#' `register_check()`. Informational only.
#'
#' @param entry The registry entry
#' @param spec The parsed repository spec, see `parse_repository_spec()`
#' @return None
check_repository_license <- function(entry, spec) {
  metadata <- switch(spec[["type"]],
    "github" = get_github_repo_metadata(spec[["repo"]]),
    "gitlab" = get_gitlab_project_metadata(spec[["repo"]]),
    NULL
  )

  if (is.null(metadata)) {
    return(invisible(NULL))
  }

  if (is.null(metadata$license)) {
    cli::cli_alert_info("{entry$Certificate} repository has no license: {spec[['repo']]}")
  }
}

#' Check that a repository advertises the "codecheck" topic tag
#'
#' The community workflow asks codecheckers to tag the checked repository with
#' the `codecheck` topic, see codecheckers/codecheck#14 and
#' <https://github.com/search?q=topic%3Acodecheck+fork%3Atrue+org%3Acodecheckers&type=Repositories>.
#' A missing topic is informational only, not a defect, so this reports via
#' `cli::cli_alert_info()` rather than `warning()`, matching
#' `check_repository_badge()`.
#'
#' @param entry The registry entry
#' @param spec The parsed repository spec, see `parse_repository_spec()`
#' @return None
check_repository_topic <- function(entry, spec) {
  metadata <- switch(spec[["type"]],
    "github" = get_github_repo_metadata(spec[["repo"]]),
    "gitlab" = get_gitlab_project_metadata(spec[["repo"]]),
    NULL
  )

  if (is.null(metadata)) {
    return(invisible(NULL))
  }

  if (!("codecheck" %in% unlist(metadata$topics))) {
    cli::cli_alert_info("{entry$Certificate} repository does not have the 'codecheck' topic tag: {spec[['repo']]}")
  }
}

#' Normalize a paper title for near-duplicate comparison
#'
#' Case, punctuation and whitespace only - deliberately loose, since the
#' point is to catch the same paper recorded twice with slightly different
#' formatting (e.g. a certificate's own "Title" typed by hand rather than
#' pasted), not to be a general string-similarity metric.
#'
#' @param title A paper title, or `NA`.
#' @return The normalized title, or `NA_character_`.
#' @keywords internal
normalize_title_for_comparison <- function(title) {
  if (is.null(title) || is.na(title) || !nzchar(trimws(title))) {
    return(NA_character_)
  }
  title <- tolower(trimws(title))
  title <- gsub("[[:punct:]]", "", title)
  gsub("\\s+", " ", title)
}

#' Check for certificates that likely check the same paper without a shared work key
#'
#' codecheckers/register#150's flagship case (#133/#149, certificates
#' 2024-017/2024-025): two certificates for the same paper, but one's
#' `Paper reference` is a DOI and the other's is a preprint PDF URL, so
#' [normalize_work_key()] gives them different (or missing) keys and they
#' never land on the same `/works/` page. This is intentionally *not*
#' resolved automatically - see the "Grouping" decision in the #150/#123
#' implementation plan (group by DOI only, report near-duplicates) - a title
#' match is exactly the kind of ambiguous signal that should be reviewed by
#' hand, not merged silently.
#'
#' @param certs Character vector of certificate IDs.
#' @param work_keys Character vector of normalized work keys (see
#'   [normalize_work_key()]), same length/order as `certs`.
#' @param titles Character vector of paper titles, same length/order.
#' @return None; a `warning()` per group of near-duplicates found.
#' @keywords internal
check_near_duplicate_works <- function(certs, work_keys, titles) {
  norm_titles <- vapply(titles, normalize_title_for_comparison, character(1))
  usable <- !is.na(norm_titles)
  if (!any(usable)) {
    return(invisible(NULL))
  }

  groups <- split(which(usable), norm_titles[usable])
  for (group in groups) {
    if (length(group) < 2) next
    keys <- work_keys[group]
    if (length(unique(keys)) > 1) {
      detail <- paste(
        sprintf("%s (%s)", certs[group], ifelse(is.na(keys), "no DOI", keys)),
        collapse = ", "
      )
      warning(
        "Certificates share a paper title but not a DOI-normalized work key - ",
        "possible same-paper duplicate that will render as separate /works/ ",
        "pages: ", detail
      )
    }
  }
  invisible(NULL)
}

#' Normalize a person's name for conflict comparison
#'
#' Reduced to "first initial + surname" (the last whitespace-separated
#' token, periods stripped) so that a spelled-out middle name, a missing
#' middle initial, or a full given name vs. its initial (all routine
#' transcription differences between a certificate's codecheck.yml and its
#' co-authors' own spelling) do not read as a conflict - only a materially
#' different name does. Not a general name-matching algorithm: a
#' double-barrelled surname written with a space in one certificate and a
#' hyphen in another can still produce a false positive here, and that is an
#' accepted trade-off for a check that only needs to flag "look at this by
#' hand", not adjudicate it.
#'
#' @param name A person's name.
#' @return The normalized comparison key.
#' @keywords internal
normalize_name_for_comparison <- function(name) {
  name <- tolower(trimws(name))
  name <- gsub("\\.", "", name, fixed = FALSE)
  tokens <- strsplit(name, "\\s+")[[1]]
  tokens <- tokens[nzchar(tokens)]
  if (length(tokens) == 0) return("")
  if (length(tokens) == 1) return(tokens)
  paste(substr(tokens[1], 1, 1), tokens[length(tokens)])
}

#' Check for ORCIDs and names used inconsistently across the register
#'
#' Surfaces the two shapes of data-entry error a person page would otherwise
#' make visible only by an odd-looking page (codecheckers/register#123): the
#' same ORCID attached to two different people's names (typically one
#' certificate's data copied from another and only the name changed), or the
#' same name attached to two different ORCIDs (typically a typo in the
#' ORCID). Deliberately a warning, not a stop - the source `codecheck.yml`
#' files are fixed by hand, separately, this only needs to point at them.
#'
#' @param certs,orcids,names Character vectors, same length/order: one row
#'   per (certificate, ORCID-bearing person) pair, from either a paper
#'   author or a codechecker (see [add_person_records()], whose per-row
#'   logic this mirrors for the whole register at once).
#' @return None; a `warning()` per conflict found.
#' @keywords internal
check_orcid_conflicts <- function(certs, orcids, names) {
  if (length(orcids) == 0) {
    return(invisible(NULL))
  }

  # `names` (the parameter) shadows base::names() for the rest of this
  # function - every lookup of the *function* below must go through
  # `base::names()` explicitly.
  person_names <- names
  norm_names <- vapply(person_names, normalize_name_for_comparison, character(1))

  # Same ORCID, materially different names
  by_orcid <- split(seq_along(orcids), orcids)
  for (idx in by_orcid) {
    if (length(unique(norm_names[idx])) > 1) {
      detail <- paste(sprintf('"%s" (%s)', person_names[idx], certs[idx]), collapse = ", ")
      warning("ORCID ", orcids[idx[1]], " is recorded under different names: ", detail)
    }
  }

  # Same name, different ORCIDs
  by_name <- split(seq_along(orcids), norm_names)
  for (key in base::names(by_name)) {
    idx <- by_name[[key]]
    if (nzchar(key) && length(unique(orcids[idx])) > 1) {
      detail <- paste(sprintf("%s (%s)", orcids[idx], certs[idx]), collapse = ", ")
      warning("Name \"", person_names[idx[1]], "\" is recorded under different ORCIDs: ", detail)
    }
  }
  invisible(NULL)
}

#' Function issue status. If the issue is not closed a warning is thrown
#' stating that the issue is still open.
#'
#' @param entry The codecheck entry
#' @return None
check_issue_status <- function(entry) {
  if (!is.na(entry$Issue)) {
    # get the status and labels from an issue
    issue <- gh::gh("GET /repos/codecheckers/:repo/issues/:issue",
      repo = "register",
      issue = entry$Issue
    )
    if (issue$state != "closed") {
      warning(
        entry$Certificate, " issue is still open: <",
        CONFIG$HYPERLINKS[["codecheck_issue"]],
        entry$Issue, ">"
      )
    }
  }
}
