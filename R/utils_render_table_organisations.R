#' Create the "all organisations" overview table (docs/organisations/index.html)
#'
#' Mirrors [create_all_persons_table()], counting per organisation instead of
#' per person: the works its people authored, the checks its people conducted,
#' and how many people it is on the register through. Only organisations a
#' person's ORCID profile identifies with a ROR appear at all - see
#' [add_organisation_records()] and the provenance note the pages carry
#' (register#53).
#'
#' @param register_table The register table, with an `Organisation` list column.
#' @return A list with a single element, the organisations table.
#' @keywords internal
create_all_organisations_table <- function(register_table) {
  col_names_dict <- CONFIG$NON_REG_TABLE_COL_NAMES[["organisations"]]
  exploded <- explode_organisation_records(register_table)

  if (nrow(exploded) == 0) {
    empty <- data.frame(
      organisation_name = character(0), Organisation = character(0),
      country = character(0), no_works = integer(0), no_checks = integer(0),
      no_persons = integer(0), stringsAsFactors = FALSE
    )
    matched <- match(colnames(empty), names(col_names_dict))
    colnames(empty)[!is.na(matched)] <- unname(col_names_dict)[matched[!is.na(matched)]]
    return(list(organisations = empty[, unname(col_names_dict), drop = FALSE]))
  }

  # A certificate is counted once per organisation and role, however many of
  # its people that organisation is on it through - two co-authors from the
  # same university are one authored work, not two.
  works_counts <- exploded %>%
    filter(Role == "author") %>%
    distinct(Organisation, `Certificate ID`) %>%
    count(Organisation, name = "no_works")

  checks_counts <- exploded %>%
    filter(Role == "codechecker") %>%
    distinct(Organisation, `Certificate ID`) %>%
    count(Organisation, name = "no_checks")

  person_counts <- exploded %>%
    distinct(Organisation, Person) %>%
    count(Organisation, name = "no_persons")

  new_table <- exploded %>%
    select(Organisation) %>%
    distinct() %>%
    left_join(works_counts, by = "Organisation") %>%
    left_join(checks_counts, by = "Organisation") %>%
    left_join(person_counts, by = "Organisation") %>%
    mutate(
      no_works = ifelse(is.na(no_works), 0L, no_works),
      no_checks = ifelse(is.na(no_checks), 0L, no_checks),
      no_persons = ifelse(is.na(no_persons), 0L, no_persons)
    )

  metadata <- lapply(new_table$Organisation, get_organisation_metadata)
  new_table$organisation_name <- vapply(metadata, function(fields) fields$name, character(1))
  new_table$country <- vapply(metadata, function(fields) {
    if (is.na(fields$country)) "" else fields$country
  }, character(1))

  new_table <- new_table[order(-new_table$no_checks, -new_table$no_works,
                               new_table$organisation_name), , drop = FALSE]
  # kable() prints the row names as an unlabelled first column otherwise
  rownames(new_table) <- NULL

  # Renamed in one step, not key by key: "organisation_name" becomes
  # "Organisation", which is also the name of the column holding the ROR, so a
  # sequential rename would collide with a column not yet renamed.
  matched <- match(colnames(new_table), names(col_names_dict))
  colnames(new_table)[!is.na(matched)] <- unname(col_names_dict)[matched[!is.na(matched)]]
  new_table <- new_table[, unname(col_names_dict), drop = FALSE]

  list(organisations = new_table)
}

#' Add hyperlinks to the "all organisations" overview table
#'
#' Mirrors [add_all_persons_hyperlink()].
#'
#' @param table The organisations table (see [create_all_organisations_table()]).
#' @param table_details Unused; kept for signature parity with the other
#'   `add_all_*_hyperlink()` functions.
#' @return The data frame with hyperlinks added.
#' @keywords internal
add_all_organisations_hyperlink <- function(table, table_details = NULL) {
  organisations_base <- "./"
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["organisations"]]

  table <- table %>%
    mutate(
      !!col_names[["organisation_name"]] := paste0(
        "[", !!sym(col_names[["organisation_name"]]), "](",
        organisations_base, !!sym(col_names[["Organisation"]]), "/)"
      ),
      !!col_names[["Organisation"]] := paste0(
        "[", !!sym(col_names[["Organisation"]]), "](https://ror.org/",
        !!sym(col_names[["Organisation"]]), ")"
      )
    )

  table[, unname(col_names), drop = FALSE]
}
