#' Create Codecheckers Table
#'
#' Processes the register table to create a new table of distinct codecheckers. 
#' The resulting table has codechecker name, codechecker ID and no. of codechecks column
#'
#' @param register_table The register table
#'
#' @return A list with a single element, the codechecker table
create_all_codecheckers_table <- function(register_table){
  # Unlisting the table to split codechecks with multiple codecheckers
  # into multiple separate rows
  register_table <- register_table %>% tidyr::unnest(Codechecker)
  register_table$Codechecker <- unlist(register_table$Codechecker)

  # Filter out only R's NA (missing values), but keep "NA" string for codecheckers without ORCID
  register_table <- register_table %>% filter(!is.na(Codechecker))

  # Only keeping the Codechecker column and distinct values
  new_table <- register_table %>%
    select(Codechecker) %>%
    distinct()

  # Adding the codechecker name column
  # Merge both ORCID and GitHub username dictionaries
  all_codecheckers_dict <- c(CONFIG$DICT_ORCID_ID_NAME, CONFIG$DICT_GITHUB_USERNAME_NAME)
  # recode() errors on an empty replacement set, which is the case for a
  # register in which no codechecker has an ORCID or a GitHub username
  new_table <- new_table %>%
    mutate(`codechecker_name` = if (length(all_codecheckers_dict) > 0)
             recode(Codechecker, !!!all_codecheckers_dict) else Codechecker) %>%
    # Handle "NA" identifier by showing a descriptive name
    mutate(`codechecker_name` = ifelse(Codechecker == "NA", "Codecheckers without ORCID", codechecker_name))

  # Adding no. of codechecks column
  # Count no. codechecks per Codechecker
  codecheck_counts <- register_table %>%
    count(Codechecker, name = "no_codechecks")

  # Join no_codechecks column to new_table
  new_table <- new_table %>%
    left_join(codecheck_counts, by = "Codechecker")

  # Adding the per-venue-type breakdown (register#92), rendered as a stacked
  # bar. Computed from the same unnested table as the counts above, so the bar
  # and the "No. of codechecks" column can never disagree.
  type_counts <- lapply(new_table$Codechecker, function(id) {
    types <- register_table$Type[register_table$Codechecker == id]
    types <- types[!is.na(types) & nzchar(types)]
    if (length(types) == 0) integer(0) else table(types)
  })

  new_table$check_types <- vapply(type_counts, codechecker_type_bar_html, character(1))

  # Rename the column using the key-value pairs from the CONFIG list
  col_names_dict <- CONFIG$NON_REG_TABLE_COL_NAMES[["codecheckers"]]
  for (key in names(col_names_dict)) {
    colnames(new_table)[colnames(new_table) == key] <- col_names_dict[[key]]
  }

  # Rearrange columns to the order in the col_names_dict
  new_table <- new_table[, unname(col_names_dict)]

  # The machine-readable twin of the "Check types" bar, carried alongside it as
  # a list column: the HTML fragment is right for the rendered table but wrong
  # for index.json, which swaps in this one (see render_non_register_files()).
  # Added after the reordering above, which keeps only the CONFIG columns.
  new_table$checks_per_type <- lapply(type_counts, function(counts) {
    if (length(counts) == 0) NULL else as.list(order_type_counts(counts))
  })

  # Returning as a list for consistency with create_table_venues
  return(list(codecheckers = new_table)) 
}

#' Add Hyperlinks to Codecheckers Table
#'
#' Adds hyperlinks to the codecheckers table by modifying the codechecker names,
#' number of codechecks, and ORCID IDs into clickable links.
#' Uses relative paths for internal links (codecheckers pages) and absolute URLs for external links.
#'
#' @param table The codecheckers table
#' @param table_details A list containing metadata including output_dir for relative path calculation.
#'
#' @return The data frame with added hyperlinks in the specified columns.
add_all_codecheckers_hyperlink <- function(table, table_details = NULL){
  # Calculate relative path prefix
  # Codecheckers page is at docs/codecheckers/index.html, so use ./ for codechecker links
  codecheckers_base <- "./"

  # Extracting column names from CONFIG
  col_names <- CONFIG$NON_REG_TABLE_COL_NAMES[["codecheckers"]]

  # !!sym is used to refer to column names defined in the CONFIG$NON_REG_TABLE_COL_NAMES
  # dynamically
  table <- table %>%

    # NOTE: The order of these mutation must be kept in this order because of
    # dependencies on the links on the column values
    # Using ':=' to generate names programmatically, see https://dplyr.tidyverse.org/articles/programming.html#name-injection
    mutate(
      # Generate codechecker table hyperlink with relative path
      !!col_names[["codechecker_name"]] := paste0(
        "[", !!sym(col_names[["codechecker_name"]]),
        "](", codecheckers_base,
        !!sym(col_names[["Codechecker"]]), "/)"
      ),


      # Generate no. of codechecks hyperlink with relative path
      !!col_names[["no_codechecks"]] := paste0(
        !!sym(col_names[["no_codechecks"]]),
        " [(see all checks)](", codecheckers_base,
        !!sym(col_names[["Codechecker"]]), "/)"
      ),

      # Generate identifier hyperlink (ORCID or GitHub)
      # Check if identifier is ORCID (format: NNNN-NNNN-NNNN-NNNX), GitHub username, or NA
      !!col_names[["Codechecker"]] := sapply(!!sym(col_names[["Codechecker"]]), function(id) {
        is_orcid <- grepl("^\\d{4}-\\d{4}-\\d{4}-\\d{3}[0-9X]$", id)
        if (id == "NA") {
          # NA: no identifier available, leave empty
          ""
        } else if (is_orcid) {
          # ORCID: link to ORCID profile
          paste0("[", id, "](", CONFIG$HYPERLINKS[["orcid"]], id, ")")
        } else {
          # GitHub username: link to GitHub profile
          paste0("[@", id, "](https://github.com/", id, ")")
        }
      })
    )

  # Only keeping columns specified in the CONFIG
  table <- table[, unname(col_names)]
  return(table)
}
#' Order a codechecker's per-type check counts for display
#'
#' Largest type first, ties broken alphabetically, so the stacked bar
#' (register#92) and the donut (register#207) always segment a given
#' codechecker in the same order.
#'
#' @param counts A named integer vector of checks per venue type.
#' @return The same vector, reordered.
#' @keywords internal
order_type_counts <- function(counts) {
  counts[order(-counts, names(counts))]
}

#' The hover text shared by the check-type bar and donut
#'
#' Lists *every* type with its count and share, not just the one under the
#' pointer, so a single hover explains the whole visualisation - which is what
#' lets the donut (register#207) do without a legend. The type the pointer is
#' actually over is marked; the others are indented by two spaces so the list
#' stays aligned.
#'
#' @param counts A named integer vector of checks per venue type, already
#'   ordered by [order_type_counts()].
#' @param highlight The type to mark, or `NULL` to mark none.
#' @return A single string with `\n` between lines.
#' @keywords internal
type_breakdown_text <- function(counts, highlight = NULL) {
  total <- sum(counts)
  types <- names(counts)
  marker <- ifelse(types %in% highlight, "▸ ", "  ")
  lines <- sprintf(
    "%s%s: %d (%d%%)",
    marker, types, counts, round(100 * counts / total)
  )
  header <- paste0(total, " check", if (total != 1) "s" else "")
  paste(c(header, lines), collapse = "\n")
}

#' Render a codechecker's checks-per-type as a stacked bar (register#92)
#'
#' A row of CSS-sized `<i>` segments rather than a canvas or an image: the
#' table has one of these per codechecker, and the underlying numbers change
#' with every render, so nothing here may be pre-rendered.
#'
#' Every segment carries the same full-breakdown `title` as the wrapper, so
#' whichever segment the pointer lands on the reader sees the whole picture.
#' `&#10;` is a newline inside an HTML attribute value, which native tooltips
#' honour.
#'
#' @param counts A named integer vector of checks per venue type.
#' @return An HTML string, or `""` for no counts.
#' @keywords internal
codechecker_type_bar_html <- function(counts) {
  counts <- counts[!is.na(counts) & counts > 0]
  if (length(counts) == 0) {
    return("")
  }

  counts <- order_type_counts(counts)
  total <- sum(counts)
  tooltip <- gsub("\n", "&#10;", type_breakdown_text(counts), fixed = TRUE)
  summary <- paste(sprintf("%d %s", counts, names(counts)), collapse = ", ")

  segments <- sprintf(
    '<i style="width:%.1f%%;background:%s" title="%s"></i>',
    100 * counts / total,
    vapply(names(counts), venue_type_color, character(1)),
    tooltip
  )

  paste0(
    '<span class="type-bar" role="img" aria-label="', summary, '" title="', tooltip, '">',
    paste(segments, collapse = ""),
    '</span>'
  )
}
