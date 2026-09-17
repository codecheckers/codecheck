# Fediverse accounts and venue hashtags (codecheckers/register#217).
#
# A person's account comes from the register's persons.csv first and from the
# codechecker lists second; a venue's account and hashtags from venues.csv. The
# pages show the account as a `rel="me"` link, which is also what lets Mastodon
# verify the link back from the person's profile, and the JSON-LD lists it under
# `sameAs`. The announcing bot (codecheckers/chekhov#23) reads the same columns.

#' Normalise a fediverse account to `@user@instance`
#'
#' Accepts the form the columns are documented to hold, `@user@instance`, and
#' the same without the leading `@`. Anything else - a profile URL, a bare
#' `@user` with no instance - is not guessed at, because a wrong guess would
#' link a stranger's account.
#'
#' @param handle A character string, possibly `NA` or empty.
#' @return `@user@instance`, or `NULL` when `handle` is not one.
#' @keywords internal
fediverse_handle <- function(handle) {
  if (is.null(handle) || length(handle) == 0 || is.na(handle[1])) return(NULL)
  handle <- trimws(as.character(handle[1]))
  match <- regmatches(handle, regexec("^@?([A-Za-z0-9_.-]+)@([A-Za-z0-9.-]+\\.[A-Za-z]{2,})$", handle))[[1]]
  if (length(match) == 0) return(NULL)
  paste0("@", match[2], "@", tolower(match[3]))
}

#' The profile URL of a fediverse account
#'
#' `https://instance/@user`, the form Mastodon and most other servers answer
#' to.
#'
#' @param handle An account, see [fediverse_handle()].
#' @return The URL, or `NULL` when `handle` is not an account.
#' @keywords internal
fediverse_profile_url <- function(handle) {
  handle <- fediverse_handle(handle)
  if (is.null(handle)) return(NULL)
  parts <- strsplit(sub("^@", "", handle), "@", fixed = TRUE)[[1]]
  paste0("https://", parts[2], "/@", parts[1])
}

#' The text of a link to a fediverse account
#'
#' `@user@instance` with each `@` written as `&#64;`. The pages go through
#' pandoc, which reads `@word` in Markdown as a citation key and wraps it in a
#' citation span; an entity is text to it.
#'
#' @param handle An account, see [fediverse_handle()].
#' @return The HTML text, or `NULL` when `handle` is not an account.
#' @keywords internal
fediverse_link_text <- function(handle) {
  handle <- fediverse_handle(handle)
  if (is.null(handle)) return(NULL)
  # fediverse_handle() admits only letters, digits, _ . - and @, so nothing
  # else needs escaping.
  gsub("@", "&#64;", handle, fixed = TRUE)
}

#' Read the fediverse accounts recorded in persons.csv
#'
#' Fills `CONFIG$PERSON_FEDIVERSE`, a named character vector from ORCID to
#' account. A file without the column, or no file, is an empty lookup rather
#' than an error: the column is optional.
#'
#' @param persons_file Path to the CSV, or `NULL`.
#' @return The lookup, invisibly.
#' @keywords internal
load_person_fediverse <- function(persons_file = NULL) {
  accounts <- stats::setNames(character(0), character(0))
  if (!is.null(persons_file) && file.exists(persons_file)) {
    people <- utils::read.csv(persons_file, stringsAsFactors = FALSE, colClasses = "character")
    if (all(c("orcid", "fediverse") %in% names(people))) {
      handles <- vapply(people$fediverse, function(value) {
        handle <- fediverse_handle(value)
        if (is.null(handle)) NA_character_ else handle
      }, character(1), USE.NAMES = FALSE)
      # A column with no account in it - the register's, until people add
      # theirs - is an empty lookup, not an error.
      keep <- !is.na(handles)
      accounts <- stats::setNames(handles[keep], toupper(people$orcid[keep]))
    }
  }
  CONFIG$PERSON_FEDIVERSE <- accounts
  invisible(accounts)
}

#' A person's fediverse account
#'
#' persons.csv first, since the register's own record of a person wins, then
#' the codechecker lists.
#'
#' @param orcid The person's ORCID, or `NULL`.
#' @param profile The person's codechecker profile, see
#'   [resolve_codechecker_profile()], or `NULL`.
#' @return `@user@instance`, or `NULL`.
#' @keywords internal
person_fediverse <- function(orcid = NULL, profile = NULL) {
  accounts <- CONFIG$PERSON_FEDIVERSE
  if (!is.null(orcid) && length(orcid) > 0 && !is.na(orcid[1]) &&
      !is.null(accounts) && length(accounts) > 0) {
    account <- unname(accounts[toupper(orcid[1])])
    if (!is.na(account)) return(account)
  }
  if (is.null(profile)) return(NULL)
  fediverse_handle(profile$fediverse)
}

#' Split a venue's hashtags
#'
#' venues.csv writes them `;`-separated and without `#`, like the separators in
#' `identifiers`. A `#` written anyway is dropped rather than doubled.
#'
#' @param hashtags The raw column value, possibly `NA`.
#' @return A character vector of hashtags without `#`, possibly empty.
#' @keywords internal
split_venue_hashtags <- function(hashtags) {
  if (is.null(hashtags) || length(hashtags) == 0 || is.na(hashtags[1])) return(character(0))
  tags <- trimws(strsplit(as.character(hashtags[1]), ";", fixed = TRUE)[[1]])
  tags <- sub("^#+", "", tags)
  tags[nzchar(tags)]
}
