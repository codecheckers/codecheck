#' Function to add the markdown title based on the specific register table name.
#' 
#' @param table_details List containing details such as the table name, subcat name.
#' @param md_table The markdown table where the title needs to be added
#' @param filter The filter
#'
#' @return The modified markdown table
add_markdown_title <- function(table_details, md_table, filter){
  # The filter is in the CONFIG$MD_TITLES
  title_fn <- NULL
  
  if (is.na(filter)) {
    title_fn <- CONFIG$MD_TITLES[["default"]]
  } else if (filter %in% names(CONFIG$MD_TITLES)) {
    # Loading the title function (if present) and passing the argument
    title_fn <- CONFIG$MD_TITLES[[filter]]
  } else {
    # No filter or no titles provided in the CONFIG file for the filter type
    # Stopping the process
    stop("Invalid filter provided.")
  }

  title <- title_fn(table_details)

  # The title lands in a YAML frontmatter line ("title: $title$") unquoted,
  # which every other filter's title happened never to break (they're all
  # fixed phrases plus a codechecker/venue name) - MD_TITLES$works is the
  # first to embed an arbitrary paper title, and titles routinely contain a
  # colon ("svaRetro and svaNUMT: Modular packages for..."), which YAML
  # reads as a second mapping key and fails to parse. Quoting here protects
  # every title generically rather than each MD_TITLES entry having to know
  # to do it itself.
  title_yaml <- paste0('"', gsub('"', '\\"', title, fixed = TRUE), '"')
  # fixed = TRUE on both sides: a title that itself contains a literal
  # quote (e.g. "\"Landmark Route\": A Comparison to the Shortest Route",
  # certificate 2022-009) needs its escaping backslash to survive into the
  # replacement text unchanged - gsub()'s regex-mode replacement scanning
  # otherwise consumes a lone backslash before a `"`, silently dropping it
  # and producing invalid YAML (a second, unescaped quote). With
  # fixed = TRUE the pattern is matched literally too, so it drops the
  # regex escaping of "$" that non-fixed mode needed.
  md_table <- gsub("$title$", title_yaml, md_table, fixed = TRUE)
  return(md_table)
}

#' Renders register md for a single register_table
#'
#' @param register_table The register table
#' @param table_details List containing details such as the table name, subcat name.
#' @param filter The filter
render_register_md <- function(register_table, table_details, filter) {
  # Codechecker/person identity metadata (and, for a person, the
  # contributed-venues list within it) need the pristine per-group
  # register_table, before add_venue_hyperlinks_reg() below rewrites its
  # Venue column into a markdown link - so compute them first, same as the
  # venue/work metadata panel below.
  profile_links <- ""
  profile_frontmatter <- ""
  is_codechecker_page <- filter == "codecheckers" &&
    !is.null(table_details[["name"]]) && !is.na(table_details[["name"]])
  is_persons_page <- filter == "persons" &&
    !is.null(table_details[["name"]]) && !is.na(table_details[["name"]])

  if (is_codechecker_page) {
    identifier <- table_details[["name"]]
    if ("for_html_file" %in% names(table_details)) {
      profile_links <- generate_codechecker_metadata_html(identifier, register_table, table_details)
    } else {
      profile_frontmatter <- generate_codechecker_metadata_yaml(identifier, register_table)
    }
  } else if (is_persons_page && "for_html_file" %in% names(table_details)) {
    # No frontmatter branch: a person page never writes register.md (see
    # CONFIG$FILTERS_WITHOUT_MD), so profile_frontmatter stays "".
    profile_links <- generate_person_metadata_html(table_details[["name"]], register_table, table_details)
  }

  # Add venue/work metadata for individual venue/work pages: as an HTML
  # block in the body for the HTML-rendered page (temp.md, fed to pandoc),
  # but as YAML frontmatter for the plain register.md export - register.md
  # is served as a markdown/API text file, not HTML, so an embedded HTML div
  # there is wrong (register#84 followup). Both panels reuse the template's
  # $venue_metadata$/$venue_frontmatter$ tokens - "a block of extra content
  # above the table" is the same slot regardless of which entity it's for.
  venue_metadata <- ""
  venue_frontmatter <- ""
  is_venues_page <- filter == "venues" && isTRUE(table_details[["is_reg_table"]]) &&
    !is.null(table_details[["name"]]) && !is.na(table_details[["name"]])
  is_works_page <- filter == "works" && isTRUE(table_details[["is_reg_table"]]) &&
    !is.null(table_details[["name"]]) && !is.na(table_details[["name"]])
  is_organisations_page <- filter == "organisations" && isTRUE(table_details[["is_reg_table"]]) &&
    !is.null(table_details[["name"]]) && !is.na(table_details[["name"]])

  if (is_venues_page) {
    venue_row <- lookup_venue_row(table_details[["name"]])
    if ("for_html_file" %in% names(table_details)) {
      venue_metadata <- generate_venue_metadata_html(venue_row, venue_type = table_details[["subcat"]])
    } else {
      venue_frontmatter <- generate_venue_metadata_yaml(venue_row, venue_type = table_details[["subcat"]])
    }
  } else if (is_works_page) {
    if ("for_html_file" %in% names(table_details)) {
      venue_metadata <- generate_work_metadata_html(table_details, register_table)
    } else {
      venue_frontmatter <- generate_work_metadata_yaml(table_details, register_table)
    }
  } else if (is_organisations_page && "for_html_file" %in% names(table_details)) {
    # No frontmatter branch: an organisation page never writes register.md
    # (see CONFIG$FILTERS_WITHOUT_MD), same as a person page.
    venue_metadata <- generate_organisation_metadata_html(table_details[["name"]], register_table)
  }

  # Convert certificate links to relative paths for HTML display
  # (JSON and CSV keep absolute URLs)
  register_table <- adjust_cert_links_relative(register_table, table_details)

  # Format Report column for display (removes "https://" from text)
  register_table <- add_report_hyperlinks_reg(register_table)

  register_table <- add_venue_hyperlinks_reg(register_table, table_details)
  register_table <- add_venue_type_hyperlinks_reg(register_table, table_details)

  # Fill in the content
  if (!is.na(filter) && filter == "organisations") {
    md_table <- create_organisations_md_table(register_table, table_details)
  } else if (!is.na(filter) && filter == "persons") {
    # Two tables (works authored, checks conducted), not one - the generic
    # single-kable create_md_table() can't represent that, so this filter
    # gets its own content builder. Still lands in temp.md only, since
    # persons never reaches the register.md-writing branch below.
    md_table <- create_persons_md_table(register_table, table_details)
  } else {
    if (!is.na(filter) && filter == "works") {
      # Repository and OpenAlex rode along only so generate_work_metadata_html()
      # above could look up authors/abstract and the work's identifiers - they
      # are not columns the visible table should show.
      register_table <- register_table[, setdiff(names(register_table),
                                                 c("Repository", "OpenAlex")),
                                       drop = FALSE]
    }
    md_table <- create_md_table(register_table, table_details, filter)
  }

  md_table <- gsub("\\$profile_links\\$", profile_links, md_table)
  md_table <- gsub("\\$profile_frontmatter\\$", profile_frontmatter, md_table)
  md_table <- gsub("\\$venue_metadata\\$", venue_metadata, md_table)
  md_table <- gsub("\\$venue_frontmatter\\$", venue_frontmatter, md_table)

  # A note below the page content, for the filters that have one - everything
  # else empties the slot (see CONFIG$PAGE_NOTES).
  page_note <- ""
  if (!is.na(filter) && isTRUE(table_details[["is_reg_table"]]) &&
      filter %in% names(CONFIG$PAGE_NOTES)) {
    page_note <- CONFIG$PAGE_NOTES[[filter]]
  }
  md_table <- gsub("\\$page_note\\$", page_note, md_table)

  output_dir <- table_details[["output_dir"]]

  # Saving the md file
  if ("for_html_file" %in% names(table_details)){
    output_dir <- file.path(output_dir, "temp.md")
  }

  else{
    output_dir <- file.path(output_dir, "register.md")
  }
  writeLines(md_table, output_dir)
}

#' Build the temp.md content for a person page: two tables, not one
#'
#' A person page shows works authored and checks conducted as two separate
#' sections (confirmed against a mockup on real data - see the #123/#150
#' implementation plan), so it can't go through [create_md_table()], which
#' assumes a single kable(). This never runs for the public register.md
#' export (see CONFIG$FILTERS_WITHOUT_MD) - only for the HTML-bound temp.md,
#' so there is no column-width override to apply here (kable's own alignment
#' row is a valid table either way, just not custom-widened like the others).
#'
#' @param register_table The person's exploded, per-role register rows (see
#'   [explode_person_records()]), already hyperlinked for display.
#' @param table_details List containing details such as the table name.
#' @return The markdown lines (a character vector, one per line).
#' @keywords internal
create_persons_md_table <- function(register_table, table_details) {
  md_table <- readLines(CONFIG$TEMPLATE_DIR[["reg"]][["md_template"]])
  md_table <- add_markdown_title(table_details, md_table, "persons")

  has_role <- "Role" %in% names(register_table)
  authored <- if (has_role) register_table[register_table$Role == "author", , drop = FALSE] else register_table[0, , drop = FALSE]
  checked  <- if (has_role) register_table[register_table$Role == "codechecker", , drop = FALSE] else register_table[0, , drop = FALSE]

  authored_cols <- intersect(c("Report", "Paper Title", "Venue", "Check date"), names(authored))
  checked_cols  <- intersect(c("Certificate", "Report", "Paper Title", "Venue", "Type", "Check date"), names(checked))

  authored_md <- if (nrow(authored) > 0) {
    capture.output(kable(rename_paper_title_column_for_display(authored[, authored_cols, drop = FALSE]), format = "markdown"))
  } else {
    "*No authored works with a DOI-identified check yet.*"
  }
  checked_md <- if (nrow(checked) > 0) {
    capture.output(kable(rename_paper_title_column_for_display(checked[, checked_cols, drop = FALSE]), format = "markdown"))
  } else {
    "*No checks conducted yet.*"
  }

  content <- c(
    paste0("## Works authored (", nrow(authored), ")"), "",
    authored_md, "",
    paste0("## Checks conducted (", nrow(checked), ")"), "",
    checked_md
  )

  md_table <- gsub("\\$content\\$", paste(content, collapse = "\n"), md_table)
  unlist(strsplit(md_table, "\n", fixed = TRUE))
}

#' Build the temp.md content for an organisation page
#'
#' The organisation analogue of [create_persons_md_table()]: the same two
#' sections, works authored and checks conducted, but every row also names the
#' person the organisation is on that certificate through - an organisation is
#' never on a certificate in its own right (register#53).
#'
#' @param register_table The organisation's exploded, per-person-per-role rows
#'   (see [explode_organisation_records()]), already hyperlinked for display.
#' @param table_details List containing details such as the table name.
#' @return The markdown lines (a character vector, one per line).
#' @keywords internal
create_organisations_md_table <- function(register_table, table_details) {
  md_table <- readLines(CONFIG$TEMPLATE_DIR[["reg"]][["md_template"]])
  md_table <- add_markdown_title(table_details, md_table, "organisations")

  register_table <- add_person_hyperlinks_reg(register_table, table_details)

  has_role <- "Role" %in% names(register_table)
  authored <- if (has_role) register_table[register_table$Role == "author", , drop = FALSE] else register_table[0, , drop = FALSE]
  checked  <- if (has_role) register_table[register_table$Role == "codechecker", , drop = FALSE] else register_table[0, , drop = FALSE]

  authored_cols <- intersect(c("Report", "Paper Title", "Person", "Venue", "Check date"), names(authored))
  checked_cols  <- intersect(c("Certificate", "Report", "Paper Title", "Person", "Venue", "Type", "Check date"), names(checked))

  authored_md <- if (nrow(authored) > 0) {
    capture.output(kable(rename_paper_title_column_for_display(authored[, authored_cols, drop = FALSE]), format = "markdown"))
  } else {
    "*No authored works with a DOI-identified check yet.*"
  }
  checked_md <- if (nrow(checked) > 0) {
    capture.output(kable(rename_paper_title_column_for_display(checked[, checked_cols, drop = FALSE]), format = "markdown"))
  } else {
    "*No checks conducted yet.*"
  }

  content <- c(
    paste0("## Works authored (", nrow(authored), ")"), "",
    authored_md, "",
    paste0("## Checks conducted (", nrow(checked), ")"), "",
    checked_md
  )

  md_table <- gsub("\\$content\\$", paste(content, collapse = "\n"), md_table)
  unlist(strsplit(md_table, "\n", fixed = TRUE))
}

#' Turn the Person column into links to the person pages
#'
#' The organisation page's tables show who each row is attributed through, by
#' name rather than by ORCID. Links are relative, like every other internal
#' link (see [add_venue_hyperlinks_reg()]), so a locally served `docs/` works.
#'
#' @param register_table A register table with a `Person` (ORCID) column.
#' @param table_details List containing the page's `output_dir`.
#' @return The table, with `Person` rewritten as a markdown link.
#' @keywords internal
add_person_hyperlinks_reg <- function(register_table, table_details = NULL) {
  if (!("Person" %in% names(register_table)) || nrow(register_table) == 0) {
    return(register_table)
  }

  persons_base <- CONFIG$HYPERLINKS[["persons"]]
  if (!is.null(table_details) && "output_dir" %in% names(table_details)) {
    depth <- stringr::str_count(gsub("^docs/", "", table_details[["output_dir"]]), "/")
    persons_base <- if (depth == 0) "./persons/" else paste0(strrep("../", depth), "persons/")
  }

  register_table$Person <- vapply(register_table$Person, function(orcid) {
    name <- CONFIG$DICT_ORCID_ID_NAME[[orcid]]
    if (is.null(name)) name <- orcid
    paste0("[", name, "](", persons_base, orcid, "/)")
  }, character(1))

  register_table
}

#' Rename the "Paper Title" column to "Work" for display
#'
#' The underlying data column stays "Paper Title" everywhere it is read
#' internally (title extraction, work-key lookups, etc.) - only the header
#' text a reader actually sees in a rendered table is renamed, to align with
#' "work" as used everywhere else on the platform (the `/works/` section,
#' the `Work` column in `CONFIG$NON_REG_TABLE_COL_NAMES[["works"]]`, the
#' JSON `work` field). Renaming the data column itself would touch every
#' function that reads it; this only ever runs on a copy about to be handed
#' straight to `kable()`.
#'
#' @param register_table A register table, possibly with a "Paper Title" column.
#' @return The same table, with that column renamed to "Work" if present.
#' @keywords internal
rename_paper_title_column_for_display <- function(register_table) {
  if ("Paper Title" %in% names(register_table)) {
    names(register_table)[names(register_table) == "Paper Title"] <- "Work"
  }
  register_table
}

#' Creates a markdown table from a register template
#' Adds title to the markdown and adjusts the column widths of the table 
#' before returning it.
#'
#' @param register_table DataFrame of the register data.
#' @param table_details List containing details such as the table name, subcat name.
#' @param filter Type of filter (e.g., "venues", "codecheckers").
#'
#' @return The markdown table
create_md_table <- function(register_table, table_details, filter){
  # Loading the template and filling in the content
  md_table <- readLines(CONFIG$TEMPLATE_DIR[["reg"]][["md_template"]])

  register_table <- rename_paper_title_column_for_display(register_table)
  md_content <- capture.output(kable(register_table, format = "markdown"))
  md_table <- add_markdown_title(table_details, md_table, filter)
  md_table <- gsub("\\$content\\$", paste(md_content, collapse = "\n"), md_table)

  # Adjusting the column widths
  md_table <- unlist(strsplit(md_table, "\n", fixed = TRUE))
  # Determining which line to add the md column widths in
  alignment_line_index <- grep("^\\|:---", md_table)
  # Selecting filter specific column widths
  if (filter %in% names(CONFIG$MD_TABLE_COLUMN_WIDTHS[["reg"]])){
    md_table[alignment_line_index] <- CONFIG$MD_TABLE_COLUMN_WIDTHS[["reg"]][[filter]]
  }

  # For some filters we can use the "general" column widths
  else{
    md_table[alignment_line_index] <- CONFIG$MD_TABLE_COLUMN_WIDTHS[["reg"]][["general"]]
  }
  return(md_table)
}