#' Extract a work's structured metadata fields
#'
#' The shared source of truth for the work landing page's metadata panel
#' (`generate_work_metadata_html()`), its YAML frontmatter
#' (`generate_work_metadata_yaml()`) and its JSON representation
#' (`render_register_json()`), the same three-way split used for venues (see
#' [get_venue_metadata_fields()]).
#'
#' Authors are fetched once, from the first certificate's `codecheck.yml`
#' (via the same cache every other lookup in the render uses) - a work's
#' author list does not vary by which certificate checked it, so refetching
#' per certificate would only mean more requests for the same answer.
#'
#' @param doi The work's DOI (`table_details[["name"]]` on a work page).
#' @param register_table The work's filtered register rows (one per
#'   certificate that checked this DOI), still carrying `Repository`,
#'   `Paper Title`, `OpenAlex`, `Venue`, `Check date`.
#' @return A list with `title`, `doi`, `openalex` (`NA_character_` if none),
#'   `venues` (unique, comma-joined), `check_count`, `first_check_date`,
#'   `last_check_date`, and `authors` (a list of `name`/`orcid` lists, `orcid`
#'   `NULL` when not known - possibly an empty list).
#' @keywords internal
get_work_metadata_fields <- function(doi, register_table) {
  # "Paper Title" only survives to this point on the HTML/md path (see
  # REGISTER_COLUMNS$works$html) - the JSON path drops it before
  # render_register_json() calls this (its "json"/"csv" column sets use the
  # plain "Title"/"Paper reference" pair instead, synthesised later by
  # set_paper_title_references(), same as every other filter). So this
  # falls back to fetching the title from codecheck.yml directly, the same
  # source the authors list below already needs.
  config_yml <- NULL
  if ("Repository" %in% names(register_table) && nrow(register_table) > 0) {
    config_yml <- get_codecheck_yml_or_null(register_table$Repository[1])
  }

  title_cell <- if ("Paper Title" %in% names(register_table) && nrow(register_table) > 0) {
    register_table[["Paper Title"]][1]
  } else {
    NA_character_
  }
  title <- if (!is.na(title_cell) && grepl("\\[.*\\]\\(.*\\)", title_cell)) {
    sub("\\[(.*)\\]\\(.*\\)", "\\1", title_cell)
  } else if (!is.na(title_cell)) {
    title_cell
  } else if (!is.null(config_yml) && !is.null(config_yml$paper$title)) {
    trimws(config_yml$paper$title)
  } else {
    NA_character_
  }

  openalex <- if ("OpenAlex" %in% names(register_table)) {
    ids <- register_table$OpenAlex[!is.na(register_table$OpenAlex)]
    if (length(ids) > 0) ids[1] else NA_character_
  } else {
    NA_character_
  }

  venues <- if ("Venue" %in% names(register_table)) {
    unique(register_table$Venue[!is.na(register_table$Venue)])
  } else {
    character(0)
  }

  check_dates <- if ("Check date" %in% names(register_table)) {
    sort(register_table$`Check date`[!is.na(register_table$`Check date`)])
  } else {
    character(0)
  }

  authors <- list()
  if (!is.null(config_yml)) {
    authors <- lapply(config_yml$paper$authors, function(a) {
      orcid <- normalize_orcid(a$ORCID)
      list(name = a$name, orcid = if (is.na(orcid)) NULL else orcid)
    })
  }

  list(
    title = title,
    doi = doi,
    openalex = openalex,
    venues = venues,
    check_count = nrow(register_table),
    first_check_date = if (length(check_dates) > 0) check_dates[1] else NA_character_,
    last_check_date = if (length(check_dates) > 0) check_dates[length(check_dates)] else NA_character_,
    authors = authors
  )
}

#' Generate the work metadata HTML panel (DOI, OpenAlex, venues, authors)
#'
#' Renders a `venue-metadata`-style panel for a work's own page: the DOI and
#' OpenAlex identifiers, the venue(s) it was checked at, and its authors -
#' each ORCID-bearing author linked to their own `/persons/<ORCID>/` page
#' (codecheckers/register#150's "we can link authors ... if we have the
#' ORCID"; unlike #150's original text, which only linked authors who were
#' *also* a codechecker, every ORCID-bearing author gets a link now that
#' #123 gives every ORCID its own page).
#'
#' @param table_details List containing details such as the table name (the DOI).
#' @param register_table See [get_work_metadata_fields()].
#' @return An HTML string (never `""` - the DOI row always renders).
#' @keywords internal
#' @importFrom whisker whisker.render
generate_work_metadata_html <- function(table_details, register_table) {
  fields <- get_work_metadata_fields(table_details[["name"]], register_table)

  # A work page's depth varies with how many "/" the DOI itself contains
  # (docs/works/10.1093/gigascience/giaa026/ is one level deeper than
  # docs/works/10.5281/zenodo.14211707/) - calculate_breadcrumb_base_path()
  # already derives this from table_details$output_dir for the breadcrumbs,
  # so it is reused here rather than duplicated.
  base_path <- calculate_breadcrumb_base_path("works", table_details)
  persons_base <- if (base_path == ".") "persons/" else paste0(base_path, "/persons/")

  authors_html <- if (length(fields$authors) > 0) {
    entries <- vapply(fields$authors, function(a) {
      if (!is.null(a$orcid)) {
        sprintf('<a href="%s%s/">%s</a>', persons_base, a$orcid, a$name)
      } else {
        a$name
      }
    }, character(1))
    paste(entries, collapse = ", ")
  } else {
    ""
  }

  has_openalex <- !is.na(fields$openalex) && nzchar(fields$openalex)
  # The work's own Wikidata item, beside its other identifiers (register#50).
  wikidata <- wikidata_id_for("paper", fields$doi)
  has_wikidata <- !is.null(wikidata)
  has_venues <- length(fields$venues) > 0
  has_authors <- nzchar(authors_html)
  has_dates <- !is.na(fields$first_check_date)

  template_path <- system.file("extdata", "templates/general/work_metadata.html", package = "codecheck")
  template <- paste(readLines(template_path, warn = FALSE), collapse = "\n")

  data <- list(
    doi = fields$doi,
    doi_url = paste0(CONFIG$HYPERLINKS[["doi"]], fields$doi),
    has_openalex = has_openalex,
    openalex = fields$openalex,
    has_wikidata = has_wikidata,
    wikidata = wikidata,
    has_authors = has_authors,
    authors_html = authors_html,
    has_venues = has_venues,
    venues = paste(fields$venues, collapse = ", "),
    check_count = fields$check_count,
    has_dates = has_dates,
    first_check_date = fields$first_check_date,
    last_check_date = fields$last_check_date,
    single_check = fields$check_count == 1
  )

  whisker.render(template, data)
}

#' Generate the work metadata YAML frontmatter block for register.md
#'
#' Same fields as [generate_work_metadata_html()] and the JSON `work` field,
#' as YAML lines for register.md's frontmatter header rather than an HTML
#' block in the body (see [generate_venue_metadata_yaml()]).
#'
#' @param table_details,register_table See [get_work_metadata_fields()].
#' @return A YAML string (ending in a newline), or `""` if there is nothing to add.
#' @keywords internal
#' @importFrom yaml as.yaml
generate_work_metadata_yaml <- function(table_details, register_table) {
  fields <- get_work_metadata_fields(table_details[["name"]], register_table)

  yaml_list <- list(doi = fields$doi)
  if (!is.na(fields$openalex) && nzchar(fields$openalex)) yaml_list$openalex <- fields$openalex
  if (length(fields$venues) > 0) yaml_list$venues <- fields$venues
  if (length(fields$authors) > 0) {
    yaml_list$authors <- lapply(fields$authors, function(a) {
      entry <- list(name = a$name)
      if (!is.null(a$orcid)) entry$orcid <- a$orcid
      entry
    })
  }

  yaml::as.yaml(yaml_list, line.sep = "\n")
}
