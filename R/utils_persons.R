#' Generate HTML redirect page for a person's GitHub handle
#'
#' The person-page analogue of [generate_codechecker_redirect()]: a person
#' with a GitHub handle on record gets a redirect stub at
#' `docs/persons/<handle>/` pointing at their canonical `docs/persons/<ORCID>/`
#' page, so a handle-based link (or bookmark from before #123) still resolves.
#' Reuses the exact same template - "redirect to a person" is the same shape
#' of page whether the person is a codechecker or an author.
#'
#' @param github_handle The GitHub handle (without @ prefix)
#' @param orcid The person's ORCID
#' @param name The person's name
#' @return Invisibly returns TRUE if successful, FALSE otherwise
#' @importFrom whisker whisker.render
#' @keywords internal
generate_person_redirect <- function(github_handle, orcid, name) {
  if (is.null(github_handle) || is.na(github_handle) || github_handle == "") {
    return(FALSE)
  }
  if (is.null(orcid) || is.na(orcid) || orcid == "") {
    return(FALSE)
  }

  handle_dir <- file.path("docs", "persons", github_handle)
  dir.create(handle_dir, recursive = TRUE, showWarnings = FALSE)

  redirect_url <- paste0(CONFIG$HYPERLINKS[["persons"]], orcid, "/")

  template_path <- system.file("extdata", "templates/general/codechecker_redirect_template.html", package = "codecheck")
  template <- readLines(template_path, warn = FALSE)

  data <- list(redirect_url = redirect_url, codechecker_name = name)
  output <- whisker::whisker.render(paste(template, collapse = "\n"), data)

  writeLines(output, file.path(handle_dir, "index.html"))
  cli::cli_alert_success("Created redirect page for {name} ({github_handle} -> {orcid})")
  invisible(TRUE)
}

#' Generate redirect pages for every person with a GitHub handle
#'
#' Iterates every ORCID-identified person in the register (author or
#' codechecker, see [add_person_records()]) and creates a
#' `docs/persons/<handle>/` redirect for those whose ORCID resolves to a
#' known GitHub handle via [resolve_codechecker_profile()] - the same lookup
#' used for the codechecker panel, so "known" here means "listed in one of
#' the codecheckers/codecheckers CSVs", which in practice means every such
#' person is also a codechecker (there is no equivalent list of paper
#' authors' GitHub handles).
#'
#' @param register_table The preprocessed register table, with a `Person`
#'   list column.
#' @return Invisibly returns the count of redirect pages created.
#' @keywords internal
generate_person_redirects <- function(register_table) {
  if (!"Person" %in% names(register_table)) {
    warning("Person column not found in register table")
    return(invisible(0))
  }

  exploded <- explode_person_records(register_table)
  orcids <- unique(exploded$Person)

  redirect_count <- 0
  for (orcid in orcids) {
    profile <- get_codechecker_profile(orcid)
    if (!is.null(profile) && !is.null(profile$github_handle)) {
      success <- generate_person_redirect(
        github_handle = profile$github_handle,
        orcid = orcid,
        name = profile$name
      )
      if (success) redirect_count <- redirect_count + 1
    }
  }

  if (redirect_count > 0) {
    cli::cli_alert_success("Generated {redirect_count} person redirect page{?s}")
  }
  invisible(redirect_count)
}

#' Generate the person metadata HTML panel (roles summary + codechecker panel)
#'
#' A person page (issue codecheckers/register#123) covers two roles at once -
#' paper author and codechecker - so its panel is a small role-count summary
#' ("N works authored, M checks conducted") followed by the existing
#' codechecker panel ([generate_codechecker_metadata_html()]: avatar, ORCID,
#' GitHub, contributed-venues list, donut), built from the codechecker-role
#' rows only. An author-only person (no codechecker-role rows) still gets the
#' role summary; the codechecker panel below it degrades to "" the same way
#' it already does for a codechecker with no ORCID/GitHub/venues.
#'
#' @param orcid The person's ORCID (`table_details[["name"]]` on a person page).
#' @param register_table The person's exploded, per-role register rows (see
#'   [explode_person_records()]), pristine (before display hyperlinks).
#' @param table_details List containing details such as the table name.
#' @return An HTML string (never `""` - the role summary always renders).
#' @keywords internal
generate_person_metadata_html <- function(orcid, register_table, table_details) {
  has_role <- "Role" %in% names(register_table)
  n_authored <- if (has_role) sum(register_table$Role == "author") else 0L
  n_checked <- if (has_role) sum(register_table$Role == "codechecker") else 0L

  role_summary <- sprintf(
    '<p class="role-summary">%d work%s authored &middot; %d check%s conducted</p>',
    n_authored, if (n_authored == 1) "" else "s",
    n_checked, if (n_checked == 1) "" else "s"
  )

  checked_table <- if (has_role) register_table[register_table$Role == "codechecker", , drop = FALSE] else register_table[0, , drop = FALSE]
  checker_panel <- generate_codechecker_metadata_html(orcid, checked_table, table_details)

  paste0(role_summary, checker_panel)
}

#' Create the "all persons" overview table (docs/persons/index.html)
#'
#' Mirrors [create_all_codecheckers_table()], but counts both roles: works
#' authored and checks conducted, per ORCID. Only ORCID-identified persons
#' are ever present in `register_table$Person` (see [add_person_records()]),
#' so no "without ORCID" row is needed here the way the old codechecker table
#' had one (#123 explicitly rules out name-matching for people without one).
#'
#' @param register_table The register table, with a `Person` list column.
#' @return A list with a single element, the persons table.
#' @keywords internal
create_all_persons_table <- function(register_table) {
  exploded <- explode_person_records(register_table)

  if (nrow(exploded) == 0) {
    empty <- data.frame(
      person_name = character(0), Person = character(0),
      no_works = integer(0), no_checks = integer(0),
      check_types = character(0),
      stringsAsFactors = FALSE
    )
    col_names_dict <- CONFIG$NON_REG_TABLE_COL_NAMES[["persons"]]
    for (key in names(col_names_dict)) colnames(empty)[colnames(empty) == key] <- col_names_dict[[key]]
    return(list(persons = empty[, unname(col_names_dict), drop = FALSE]))
  }

  # A person can be both author and codechecker on the *same* certificate
  # (two rows, one per role) - de-duplicate before counting each role so a
  # certificate is never counted twice within one role.
  works_counts <- exploded %>%
    filter(Role == "author") %>%
    distinct(Person, `Certificate ID`) %>%
    count(Person, name = "no_works")

  checks_counts <- exploded %>%
    filter(Role == "codechecker") %>%
    distinct(Person, `Certificate ID`) %>%
    count(Person, name = "no_checks")

  new_table <- exploded %>%
    select(Person) %>%
    distinct() %>%
    left_join(works_counts, by = "Person") %>%
    left_join(checks_counts, by = "Person") %>%
    mutate(
      no_works = ifelse(is.na(no_works), 0L, no_works),
      no_checks = ifelse(is.na(no_checks), 0L, no_checks),
      person_name = sapply(Person, function(orcid) {
        name <- CONFIG$DICT_ORCID_ID_NAME[[orcid]]
        if (is.null(name)) orcid else name
      })
    )

  # Per-venue-type breakdown of checks conducted (register#92), mirroring
  # create_all_codecheckers_table(): computed from the codechecker-role rows
  # only, since an authored work has no check type of its own.
  checker_rows <- exploded %>% filter(Role == "codechecker")
  type_counts <- lapply(new_table$Person, function(id) {
    types <- checker_rows$Type[checker_rows$Person == id]
    types <- types[!is.na(types) & nzchar(types)]
    if (length(types) == 0) integer(0) else table(types)
  })

  new_table$check_types <- vapply(type_counts, codechecker_type_bar_html, character(1))

  col_names_dict <- CONFIG$NON_REG_TABLE_COL_NAMES[["persons"]]
  for (key in names(col_names_dict)) {
    colnames(new_table)[colnames(new_table) == key] <- col_names_dict[[key]]
  }
  new_table <- new_table[, unname(col_names_dict), drop = FALSE]

  # The machine-readable twin of the "Check types" bar (see
  # create_all_codecheckers_table() and render_non_register_files()).
  new_table$checks_per_type <- lapply(type_counts, function(counts) {
    if (length(counts) == 0) NULL else as.list(order_type_counts(counts))
  })

  list(persons = new_table)
}

#' Add hyperlinks to the "all persons" overview table
#'
#' Mirrors [add_all_codecheckers_hyperlink()].
#'
#' @param table The persons table (see [create_all_persons_table()]).
#' @param table_details Unused; kept for signature parity with the other
#'   `add_all_*_hyperlink()` functions ([create_tables_non_register()]
#'   dispatches to all of them the same way).
#' @return The data frame with hyperlinks added.
#' @keywords internal
add_all_persons_hyperlink <- function(table, table_details = NULL) {
  persons_base <- "./"
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["persons"]]

  table <- table %>%
    mutate(
      !!col_names[["person_name"]] := paste0(
        "[", !!sym(col_names[["person_name"]]), "](", persons_base, !!sym(col_names[["Person"]]), "/)"
      ),
      # A count of 0 gets no link - the person page has nothing to show for
      # that role, and a "(see works)"/"(see checks)" addendum next to a 0
      # reads as if it did (many rows are 0 for one role or the other, since
      # a person is rarely both an author and a codechecker).
      !!col_names[["no_works"]] := ifelse(
        !!sym(col_names[["no_works"]]) == 0, "0",
        paste0(
          "[", !!sym(col_names[["no_works"]]), "](", persons_base, !!sym(col_names[["Person"]]), "/)"
        )
      ),
      !!col_names[["no_checks"]] := ifelse(
        !!sym(col_names[["no_checks"]]) == 0, "0",
        paste0(
          "[", !!sym(col_names[["no_checks"]]), "](", persons_base, !!sym(col_names[["Person"]]), "/)"
        )
      ),
      !!col_names[["Person"]] := paste0(
        "[", !!sym(col_names[["Person"]]), "](", CONFIG$HYPERLINKS[["orcid"]], !!sym(col_names[["Person"]]), ")"
      )
    )

  table[, unname(col_names), drop = FALSE]
}
