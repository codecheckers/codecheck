#' Create the "all works" overview table (docs/works/index.html)
#'
#' Mirrors [create_all_codecheckers_table()]: one row per distinct DOI-keyed
#' work, with its title and its check count. A certificate with no DOI (see
#' [normalize_work_key()]) simply has no work and contributes no row here,
#' per #150.
#'
#' @param register_table The register table, with a `Work` column.
#' @return A list with a single element, the works table.
#' @keywords internal
create_all_works_table <- function(register_table) {
  register_table <- register_table %>% filter(!is.na(Work))

  if (nrow(register_table) == 0) {
    empty <- data.frame(Title = character(0), Work = character(0), no_checks = integer(0), stringsAsFactors = FALSE)
    col_names_dict <- CONFIG$NON_REG_TABLE_COL_NAMES[["works"]]
    for (key in names(col_names_dict)) colnames(empty)[colnames(empty) == key] <- col_names_dict[[key]]
    return(list(works = empty[, unname(col_names_dict), drop = FALSE]))
  }

  title_lookup <- register_table %>%
    group_by(Work) %>%
    summarise(title_cell = dplyr::first(`Paper Title`), .groups = "drop") %>%
    mutate(Title = ifelse(
      !is.na(title_cell) & grepl("\\[.*\\]\\(.*\\)", title_cell),
      sub("\\[(.*)\\]\\(.*\\)", "\\1", title_cell),
      title_cell
    )) %>%
    select(Work, Title)

  check_counts <- register_table %>% count(Work, name = "no_checks")

  new_table <- register_table %>%
    select(Work) %>%
    distinct() %>%
    left_join(title_lookup, by = "Work") %>%
    left_join(check_counts, by = "Work")

  col_names_dict <- CONFIG$NON_REG_TABLE_COL_NAMES[["works"]]
  for (key in names(col_names_dict)) {
    colnames(new_table)[colnames(new_table) == key] <- col_names_dict[[key]]
  }
  new_table <- new_table[, unname(col_names_dict), drop = FALSE]

  list(works = new_table)
}

#' Add hyperlinks to the "all works" overview table
#'
#' Mirrors [add_all_codecheckers_hyperlink()]. The DOI, which may itself
#' contain "/" characters, is what the relative link is built from -
#' `./10.1093/gigascience/giaa026/` correctly resolves from
#' `docs/works/index.html` to `docs/works/10.1093/gigascience/giaa026/`,
#' the same nesting [generate_output_dir()] already produces.
#'
#' @param table The works table (see [create_all_works_table()]).
#' @param table_details Unused; kept for signature parity with the other
#'   `add_all_*_hyperlink()` functions.
#' @return The data frame with hyperlinks added.
#' @keywords internal
add_all_works_hyperlink <- function(table, table_details = NULL) {
  works_base <- "./"
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["works"]]

  table <- table %>%
    mutate(
      !!col_names[["Title"]] := paste0(
        "[", !!sym(col_names[["Title"]]), "](", works_base, !!sym(col_names[["Work"]]), "/)"
      ),
      !!col_names[["no_checks"]] := paste0(
        !!sym(col_names[["no_checks"]]), " [(see all checks)](", works_base, !!sym(col_names[["Work"]]), "/)"
      ),
      !!col_names[["Work"]] := paste0(
        "[", !!sym(col_names[["Work"]]), "](", CONFIG$HYPERLINKS[["doi"]], !!sym(col_names[["Work"]]), ")"
      )
    )

  table[, unname(col_names), drop = FALSE]
}
