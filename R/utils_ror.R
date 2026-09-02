#' Look up the ROR-identified affiliations on a public ORCID record
#'
#' Reads the `employments`, `educations` and `qualifications` sections of an
#' ORCID record from the public, unauthenticated ORCID API
#' (\url{https://pub.orcid.org}) - the same API [get_orcid_name_public()]
#' uses, and the only one that works for other people's records.
#'
#' An affiliation's organisation is only counted as ROR-identified when ORCID
#' itself records `disambiguation-source: ROR`. Most affiliations are
#' disambiguated against RINGGOLD, GRID or FundRef instead, or not at all;
#' mapping those to a ROR would be a guess, and register#53 needs to know what
#' the profiles actually assert.
#'
#' @param orcid An ORCID identifier (NNNN-NNNN-NNNN-NNNX).
#' @return A list with `status` ("found", "absent" or "failed") and `value`, a
#'   data frame with one row per affiliation and the columns `section`,
#'   `organization`, `ror` (the bare ROR id, `NA` when not ROR-identified),
#'   `start` and `end` (the raw ORCID date lists, see [orcid_date_covered()]).
#' @keywords internal
get_orcid_affiliations_result <- function(orcid) {
  if (is.null(orcid) || length(orcid) != 1 || is.na(orcid) || !nzchar(orcid)) {
    return(list(status = "absent", value = empty_orcid_affiliations()))
  }

  sections <- c("employments", "educations", "qualifications")
  rows <- list()

  for (section in sections) {
    response <- codecheck_GET_retry(
      paste0("https://pub.orcid.org/v3.0/", orcid, "/", section),
      httr::add_headers(Accept = "application/json")
    )

    # A section that could not be read makes the whole record inconclusive:
    # reporting "no ROR" for it would be indistinguishable from a person who
    # genuinely has none, and caching that would freeze the gap in place.
    if (is.null(response) || httr::status_code(response) != 200) {
      return(list(status = "failed", value = empty_orcid_affiliations()))
    }

    parsed <- tryCatch(
      jsonlite::fromJSON(
        httr::content(response, as = "text", encoding = "UTF-8"),
        simplifyVector = FALSE
      ),
      error = function(e) NULL
    )
    if (is.null(parsed)) {
      return(list(status = "failed", value = empty_orcid_affiliations()))
    }

    for (group in parsed$`affiliation-group`) {
      for (summary in group$summaries) {
        # the key is named after the section, e.g. "employment-summary"
        affiliation <- summary[[1]]
        rows[[length(rows) + 1]] <- orcid_affiliation_row(section, affiliation)
      }
    }
  }

  if (length(rows) == 0) {
    return(list(status = "absent", value = empty_orcid_affiliations()))
  }

  affiliations <- do.call(rbind, lapply(rows, function(row) {
    data.frame(section = row$section, organization = row$organization,
               ror = row$ror, stringsAsFactors = FALSE)
  }))
  affiliations$start <- lapply(rows, function(row) row$start)
  affiliations$end <- lapply(rows, function(row) row$end)

  list(status = "found", value = affiliations)
}

#' The empty affiliation table [get_orcid_affiliations_result()] returns
#'
#' @return A zero-row data frame with the affiliation columns
#' @keywords internal
empty_orcid_affiliations <- function() {
  affiliations <- data.frame(section = character(0), organization = character(0),
                             ror = character(0), stringsAsFactors = FALSE)
  affiliations$start <- list()
  affiliations$end <- list()
  affiliations
}

#' Turn one ORCID affiliation summary into an affiliation row
#'
#' @param section The record section the summary came from
#' @param affiliation One `*-summary` element of an affiliation group
#' @return A list with `section`, `organization`, `ror`, `start` and `end`
#' @keywords internal
orcid_affiliation_row <- function(section, affiliation) {
  organization <- affiliation$organization
  disambiguated <- organization$`disambiguated-organization`

  ror <- NA_character_
  if (!is.null(disambiguated) &&
      identical(disambiguated$`disambiguation-source`, "ROR")) {
    # ORCID stores it as the full https://ror.org/<id> URL
    ror <- sub("^.*ror\\.org/", "", disambiguated$`disambiguated-organization-identifier`)
  }

  list(
    section = section,
    organization = if (is.null(organization$name)) NA_character_ else organization$name,
    ror = ror,
    start = affiliation$`start-date`,
    end = affiliation$`end-date`
  )
}

#' Cached version of [get_orcid_affiliations_result()]
#'
#' Caches on disk, but only when ORCID actually answered, see
#' [cached_lookup()]. Cleared by [register_clear_cache()].
#'
#' @inheritParams get_orcid_affiliations_result
#' @return The affiliation data frame
#' @keywords internal
get_orcid_affiliations_cached <- function(orcid) {
  cached_lookup(
    key = list("orcid_affiliations", orcid),
    dirs = c("codecheck", "orcid_affiliations"),
    lookup = function() get_orcid_affiliations_result(orcid)
  )
}

#' Turn an ORCID partial date into a `Date`
#'
#' ORCID dates carry a year and, often, no month or day at all. `bound`
#' decides what an absent month/day means: the start of the year for a lower
#' bound, its end for an upper one, so a year-only affiliation covers the whole
#' year instead of just its first day.
#'
#' @param date An ORCID date list (`year`/`month`/`day`), or NULL
#' @param bound Either "lower" or "upper"
#' @return A `Date`, or `NA` when there is no year
#' @keywords internal
orcid_date <- function(date, bound = c("lower", "upper")) {
  bound <- match.arg(bound)

  year <- if (is.null(date)) NULL else date$year$value
  if (is.null(year) || is.na(year) || !nzchar(year)) {
    return(as.Date(NA))
  }

  month <- if (is.null(date$month$value)) NA else date$month$value
  day <- if (is.null(date$day$value)) NA else date$day$value

  if (is.na(month)) {
    return(as.Date(paste0(year, if (bound == "lower") "-01-01" else "-12-31")))
  }
  if (is.na(day)) {
    first <- as.Date(paste(year, month, "01", sep = "-"))
    if (bound == "lower") {
      return(first)
    }
    # last day of that month
    return(seq(first, by = "month", length.out = 2)[2] - 1)
  }

  as.Date(paste(year, month, day, sep = "-"))
}

#' Was an ORCID affiliation held at a given date?
#'
#' A missing start date is treated as unbounded in the past and a missing end
#' date as ongoing, which is how ORCID itself presents an affiliation without
#' an end date.
#'
#' @param start,end ORCID date lists (`year`/`month`/`day`), or NULL
#' @param at The `Date` to test
#' @return `TRUE` when the affiliation covers `at`
#' @keywords internal
orcid_date_covered <- function(start, end, at) {
  if (is.null(at) || is.na(at)) {
    return(FALSE)
  }

  from <- orcid_date(start, "lower")
  to <- orcid_date(end, "upper")

  (is.na(from) || from <= at) && (is.na(to) || to >= at)
}

#' The RORs a person's ORCID profile asserts
#'
#' Reads the affiliations on a public ORCID record (employments, educations
#' and qualifications) and returns the RORs of those the record identifies
#' with a ROR - the identifiers organisation pages for the register would be
#' built on (register#53).
#'
#' @param orcid An ORCID identifier (NNNN-NNNN-NNNN-NNNX).
#' @param at Optional `Date`. When given, only affiliations held at that date
#'   are considered; when `NULL` (the default), only current ones, i.e. those
#'   the record gives no end date for.
#' @return A character vector of ROR ids (without the `https://ror.org/`
#'   prefix), in record order and without duplicates. Empty when the profile
#'   asserts none, or when ORCID could not be reached.
#' @export
#' @examples
#' \dontrun{
#'   orcid_rors("0000-0001-8607-8025")
#'   orcid_rors("0000-0001-8607-8025", at = as.Date("2019-02-14"))
#' }
orcid_rors <- function(orcid, at = NULL) {
  rors_from(get_orcid_affiliations_cached(orcid), at = at)
}

#' Look up a work's publication date on OpenAlex
#'
#' @param openalex_id An OpenAlex work URL or ID, e.g.
#'   "https://openalex.org/W3014157798"
#' @return A list with `status` ("found", "absent" or "failed") and `value`,
#'   the publication date as a character string or `NA_character_`
#' @keywords internal
get_openalex_publication_date_result <- function(openalex_id) {
  if (is.null(openalex_id) || length(openalex_id) != 1 || is.na(openalex_id) ||
      !nzchar(openalex_id)) {
    return(list(status = "absent", value = NA_character_))
  }

  work_id <- sub("^.*openalex\\.org/", "", openalex_id)
  response <- codecheck_GET_openalex(paste0("https://api.openalex.org/works/", work_id))

  if (is.null(response)) {
    return(list(status = "failed", value = NA_character_))
  }
  status <- httr::status_code(response)
  if (status == 404) {
    return(list(status = "absent", value = NA_character_))
  }
  if (status != 200) {
    return(list(status = "failed", value = NA_character_))
  }

  data <- httr::content(response, "parsed")
  date <- data$publication_date
  if (is.null(date) || !nzchar(date)) {
    return(list(status = "absent", value = NA_character_))
  }

  list(status = "found", value = date)
}

#' Cached version of [get_openalex_publication_date_result()]
#'
#' @inheritParams get_openalex_publication_date_result
#' @return The publication date as a character string, or `NA_character_`
#' @keywords internal
get_openalex_publication_date_cached <- function(openalex_id) {
  cached_lookup(
    key = list("openalex_publication_date", openalex_id),
    dirs = c("codecheck", "openalex_publication_date"),
    lookup = function() get_openalex_publication_date_result(openalex_id)
  )
}

#' How many register persons have a ROR in their ORCID profile
#'
#' Preparation for register#53, which wants organisation pages built from the
#' RORs of the register's authors and codecheckers: for every ORCID-identified
#' person on every certificate, this reports whether their ORCID profile
#' asserts a ROR-identified affiliation, and whether one of those was held
#' when the work they are on was published.
#'
#' A codechecker's date is the register's check date. An author's is the
#' paper's publication date from OpenAlex, falling back to the check date for
#' the certificates without an OpenAlex ID - `date_source` says which was
#' used.
#'
#' @param register_table A preprocessed register table with a `Person` list
#'   column (see `preprocess_register()`). When `NULL` (the default), the
#'   register is read and preprocessed, so the function can be run in one call
#'   from a register checkout.
#' @param register The register data frame, used when `register_table` is
#'   `NULL`.
#' @param config Path(s) to the register configuration, sourced when
#'   `register_table` is `NULL`.
#' @return A data frame with one row per (certificate, person, role) and the
#'   columns `Certificate ID`, `Person`, `Role`, `date`, `date_source`,
#'   `n_affiliations`, `has_ror`, `has_current_ror`, `ror_at_date` (a list
#'   column) and `matched_at_date`. The per-ORCID affiliation tables are kept
#'   in the `affiliations` attribute.
#' @export
#' @examples
#' \dontrun{
#'   # from a checkout of codecheckers/register
#'   coverage <- register_ror_coverage()
#'   ror_coverage_summary(coverage)
#' }
register_ror_coverage <- function(register_table = NULL,
                                  register = read.csv("register.csv", as.is = TRUE,
                                                      comment.char = "#"),
                                  config = system.file("extdata", "config.R",
                                                       package = "codecheck")) {
  if (is.null(register_table)) {
    for (i in seq(length(config))) {
      source(config[i])
    }
    register_table <- preprocess_register(register, filter_by = "persons")
  }

  exploded <- explode_person_records(register_table)
  if (nrow(exploded) == 0) {
    stop("The register table has no ORCID-identified persons.")
  }

  check_dates <- as.Date(exploded$`Check date`)

  cli::cli_alert_info("Looking up publication dates for {nrow(exploded)} person record{?s}")
  dates <- check_dates
  date_sources <- rep("check date", nrow(exploded))
  for (i in seq_len(nrow(exploded))) {
    if (exploded$Role[i] != "author") next

    openalex_id <- if ("OpenAlex" %in% names(exploded)) exploded$OpenAlex[i] else NA_character_
    published <- get_openalex_publication_date_cached(openalex_id)
    if (!is.null(published) && !is.na(published)) {
      dates[i] <- as.Date(published)
      date_sources[i] <- "openalex"
    }
  }

  orcids <- unique(exploded$Person)
  cli::cli_alert_info("Reading ORCID affiliations for {length(orcids)} person{?s}")
  affiliations <- stats::setNames(
    lapply(orcids, get_orcid_affiliations_cached),
    orcids
  )

  coverage <- data.frame(
    `Certificate ID` = exploded$`Certificate ID`,
    Person = exploded$Person,
    Role = exploded$Role,
    date = dates,
    date_source = date_sources,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  coverage$n_affiliations <- vapply(coverage$Person, function(orcid) {
    nrow(affiliations[[orcid]])
  }, integer(1))
  coverage$has_ror <- vapply(coverage$Person, function(orcid) {
    any(!is.na(affiliations[[orcid]]$ror))
  }, logical(1))
  coverage$has_current_ror <- vapply(coverage$Person, function(orcid) {
    length(rors_from(affiliations[[orcid]], at = NULL)) > 0
  }, logical(1))
  coverage$ror_at_date <- lapply(seq_len(nrow(coverage)), function(i) {
    rors_from(affiliations[[coverage$Person[i]]], at = coverage$date[i])
  })
  coverage$matched_at_date <- lengths(coverage$ror_at_date) > 0

  attr(coverage, "affiliations") <- affiliations
  coverage
}

#' Filter an affiliation table down to the RORs held at a date
#'
#' The table-level half of [orcid_rors()], so a caller that already has the
#' affiliations does not look them up again for every certificate.
#'
#' @param affiliations An affiliation table (see
#'   [get_orcid_affiliations_result()])
#' @param at A `Date`, or `NULL` for the current affiliations
#' @return A character vector of ROR ids
#' @keywords internal
rors_from <- function(affiliations, at = NULL) {
  if (is.null(affiliations) || nrow(affiliations) == 0) {
    return(character(0))
  }

  with_ror <- affiliations[!is.na(affiliations$ror), , drop = FALSE]
  if (nrow(with_ror) == 0) {
    return(character(0))
  }

  held <- vapply(seq_len(nrow(with_ror)), function(i) {
    if (is.null(at)) {
      is.null(with_ror$end[[i]])
    } else {
      orcid_date_covered(with_ror$start[[i]], with_ror$end[[i]], at)
    }
  }, logical(1))

  unique(with_ror$ror[held])
}

#' Summarise ROR coverage over the register
#'
#' Reports the share of persons with a current ROR and with a ROR held at the
#' publication date, both per (certificate, person, role) record and per
#' unique person - a handful of prolific codecheckers dominate the record
#' counts, so the two numbers answer different questions.
#'
#' @param coverage The data frame returned by [register_ror_coverage()]
#' @param quiet When `FALSE` (the default), print the summary
#' @return Invisibly, a data frame with one row per unit and role and the
#'   columns `unit`, `role`, `n`, `has_current_ror`, `pct_current_ror`,
#'   `matched_at_date` and `pct_matched_at_date`
#' @export
ror_coverage_summary <- function(coverage, quiet = FALSE) {
  by_role <- function(rows, unit, role) {
    data.frame(
      unit = unit, role = role, n = nrow(rows),
      has_current_ror = sum(rows$has_current_ror),
      pct_current_ror = round(100 * mean(rows$has_current_ror), 1),
      matched_at_date = sum(rows$matched_at_date),
      pct_matched_at_date = round(100 * mean(rows$matched_at_date), 1),
      stringsAsFactors = FALSE
    )
  }

  # Per person, a role counts as matched when any of their records matched -
  # asking "does this person have a ROR for their work" rather than repeating
  # a prolific codechecker once per certificate.
  per_person <- function(rows) {
    if (nrow(rows) == 0) return(rows)
    split_rows <- split(rows, rows$Person)
    do.call(rbind, lapply(split_rows, function(person_rows) {
      person_rows$has_current_ror <- any(person_rows$has_current_ror)
      person_rows$matched_at_date <- any(person_rows$matched_at_date)
      person_rows[1, , drop = FALSE]
    }))
  }

  roles <- c("author", "codechecker")
  summary_rows <- list(by_role(coverage, "record", "all"))
  for (role in roles) {
    summary_rows[[length(summary_rows) + 1]] <-
      by_role(coverage[coverage$Role == role, , drop = FALSE], "record", role)
  }
  summary_rows[[length(summary_rows) + 1]] <- by_role(per_person(coverage), "person", "all")
  for (role in roles) {
    summary_rows[[length(summary_rows) + 1]] <- by_role(
      per_person(coverage[coverage$Role == role, , drop = FALSE]), "person", role)
  }

  result <- do.call(rbind, summary_rows)
  rownames(result) <- NULL

  if (!quiet) {
    cli::cli_h2("ROR coverage of register persons")
    for (i in seq_len(nrow(result))) {
      row <- result[i, ]
      cli::cli_alert_info(paste0(
        "{row$unit}s, {row$role}: {row$n} | current ROR {row$has_current_ror} ",
        "({row$pct_current_ror}%) | ROR at publication {row$matched_at_date} ",
        "({row$pct_matched_at_date}%)"
      ))
    }
  }

  invisible(result)
}
