#' Look up a venue's row in venues.csv, with an empty fallback
#'
#' A venue not (yet) listed in venues.csv still has a type from register.csv,
#' so callers that only need a type (e.g. the metadata panel, or its JSON
#' representation) should still get something to work with rather than
#' skipping the venue entirely.
#'
#' @param venue_name The venue's name (register.csv `Venue` column / venues.csv
#'   `name` column value).
#'
#' @return A single-row data frame: the matching venues.csv row if found,
#'   otherwise a minimal one-column (`name`) data frame.
#' @keywords internal
lookup_venue_row <- function(venue_name) {
  venue_row <- NULL
  if (exists("VENUE_DATA", envir = CONFIG) && !is.null(CONFIG$VENUE_DATA)) {
    venue_row <- CONFIG$VENUE_DATA[CONFIG$VENUE_DATA$name == venue_name, , drop = FALSE]
  }
  if (is.null(venue_row) || nrow(venue_row) == 0) {
    venue_row <- data.frame(name = venue_name, stringsAsFactors = FALSE)
  }
  venue_row[1, , drop = FALSE]
}

#' Parse a venue's identifiers string into a list usable by whisker
#'
#' Identifiers are stored in venues.csv as a single column: `;`-separated
#' entries, each a `name|icon|value|url` quadruple (`icon` and `url` are
#' optional - pipes may be omitted from the right, e.g. `name|icon|value` or
#' just `name|icon`), e.g.
#' `ISSN|fa-book|2047-217X|https://portal.issn.org/resource/ISSN/2047-217X;ROR|fa-university|05wg1m734|https://ror.org/05wg1m734`.
#' `icon` is a Font Awesome class name (without the leading `fa-` prefix
#' already implied by the `fa` base class), rendered as `<i class="fa {{icon}}">`.
#'
#' @param identifiers_str The raw identifiers string from venues.csv.
#'
#' @return A list of lists, each with `name`, `icon`, `value` and `link`
#'   (`icon`/`link` are `NULL` when not provided), ready to pass to
#'   whisker.render.
#' @keywords internal
parse_venue_identifiers <- function(identifiers_str) {
  if (is.null(identifiers_str) || is.na(identifiers_str) || !nzchar(trimws(identifiers_str))) {
    return(list())
  }

  entries <- strsplit(identifiers_str, ";", fixed = TRUE)[[1]]
  entries <- trimws(entries)
  entries <- entries[nzchar(entries)]

  lapply(entries, function(entry) {
    # Only the first three "|" separate name/icon/value/url - the url itself
    # typically contains "://" but no "|", so this split is unambiguous.
    parts <- strsplit(entry, "|", fixed = TRUE)[[1]]
    parts <- trimws(parts)
    field <- function(i) if (length(parts) >= i && nzchar(parts[i])) parts[i] else NULL
    id_name <- parts[1]
    value <- if (length(parts) >= 3) parts[3] else ""
    link <- field(4)
    # An ISSN identifier without an explicit url links to its ISSN Portal
    # page by default, so venues.csv doesn't need to spell it out every time.
    if (is.null(link) && grepl("^ISSN", id_name, ignore.case = TRUE) && nzchar(value)) {
      link <- paste0("https://portal.issn.org/resource/ISSN/", value)
    }
    list(
      name = id_name,
      icon = field(2),
      value = value,
      link = link
    )
  })
}

#' Extract a venue's structured metadata fields
#'
#' Pulls a venue's metadata from venues.csv (`venue_row`) together with its
#' type from register.csv (`venue_type`) into one plain list. This is the
#' shared source of truth for both the venue landing page's metadata panel
#' (`generate_venue_metadata_html()`) and its JSON representation
#' (`render_register_json()`, addresses register#183) - both must show the
#' same information.
#'
#' @param venue_row A single-row data frame from CONFIG$VENUE_DATA (i.e. one
#'   row of venues.csv).
#' @param venue_type The venue's type (journal/conference/community/
#'   institution, i.e. the register.csv `Type` column / table_details$subcat)
#'   - not to be confused with venues.csv's `label` column, which carries
#'   GitHub issue label values instead.
#'
#' @return A list with `venue_type`, `logo_url`, `website_url`,
#'   `contact_name`, `contact_email` and `description` (each `NA_character_`
#'   when not set), and `identifiers` (a list of `name`/`icon`/`value`/`link`
#'   lists, possibly empty - see [parse_venue_identifiers()]).
#' @keywords internal
get_venue_metadata_fields <- function(venue_row, venue_type = NULL) {
  get_col <- function(name) {
    # An empty CSV cell is read as "" (venues.csv is not read with
    # na.strings = "") rather than NA - normalize both to NA_character_ so
    # downstream has_value() checks and JSON null serialization agree.
    value <- if (name %in% names(venue_row)) venue_row[[name]][1] else NA_character_
    if (is.na(value) || !nzchar(value)) NA_character_ else value
  }

  list(
    venue_type = if (!is.null(venue_type) && !is.na(venue_type) && nzchar(venue_type)) venue_type else NA_character_,
    logo_url = get_col("logo_url"),
    website_url = get_col("website_url"),
    contact_name = get_col("contact_name"),
    contact_email = get_col("contact_email"),
    description = get_col("description"),
    identifiers = parse_venue_identifiers(get_col("identifiers")),
    # The organisation page for this venue's ROR, when the register's people
    # put one there (register#53). A venue commissioned the check, the
    # organisation employed the people who did it - two pages, cross-linked.
    organisation_ror = venue_organisation_ror(parse_venue_identifiers(get_col("identifiers")))
  )
}

#' Generate the venue metadata HTML block for an individual venue landing page
#'
#' Renders venue type, contact, website, a link to the venue's own
#' index.json, description and identifiers for a venue via the
#' `venue_metadata.html` whisker template. Fields sourced from venues.csv are
#' omitted when missing rather than shown empty; the index.json link is
#' always shown, since that file is always generated alongside this page.
#'
#' @param venue_row A single-row data frame from CONFIG$VENUE_DATA (i.e. one
#'   row of venues.csv).
#' @param venue_type See [get_venue_metadata_fields()]. `NULL`/`NA` omits the row.
#'
#' @return An HTML string (never `""` - the index.json link always renders).
#' @keywords internal
#' @importFrom whisker whisker.render
generate_venue_metadata_html <- function(venue_row, venue_type = NULL) {
  has_value <- function(x) !is.null(x) && !is.na(x) && nzchar(trimws(x))
  fields <- get_venue_metadata_fields(venue_row, venue_type)

  has_logo <- has_value(fields$logo_url)
  has_website <- has_value(fields$website_url)
  has_venue_type <- has_value(fields$venue_type)
  has_contact_name <- has_value(fields$contact_name)
  has_contact_email <- has_value(fields$contact_email)
  has_contact <- has_contact_name || has_contact_email
  has_description <- has_value(fields$description)
  has_identifiers <- length(fields$identifiers) > 0

  template_path <- system.file("extdata", "templates/general/venue_metadata.html", package = "codecheck")
  template <- paste(readLines(template_path, warn = FALSE), collapse = "\n")

  data <- list(
    has_logo = has_logo,
    logo_url = fields$logo_url,
    longname = if ("longname" %in% names(venue_row)) venue_row[["longname"]][1] else NA_character_,
    has_website = has_website,
    website_url = fields$website_url,
    has_venue_type = has_venue_type,
    venue_type = fields$venue_type,
    # The venue detail page always lives at docs/venues/<type_plural>/<slug>/,
    # so the type's listing page is always exactly one level up.
    venue_type_url = "../index.html",
    # The venue's own index.json (structured metadata + cert_count/source,
    # not just statistics - hence "index" rather than "stats", matching
    # index.html) is always generated alongside this page, so the link to
    # it is unconditional - unlike the other rows.
    api_stats_url = "index.json",
    # Always TRUE: the API & statistics link above alone is always enough
    # to render the properties list, so the panel is never truly empty.
    has_properties = TRUE,
    has_contact = has_contact,
    has_contact_name = has_contact_name,
    contact_name = fields$contact_name,
    has_contact_email = has_contact_email,
    contact_email = fields$contact_email,
    has_description = has_description,
    description = fields$description,
    has_identifiers = has_identifiers,
    identifiers = fields$identifiers,
    has_organisation = has_value(fields$organisation_ror),
    # a venue page lives at docs/venues/<type_plural>/<slug>/
    organisation_url = paste0("../../../organisations/", fields$organisation_ror, "/")
  )

  whisker.render(template, data)
}

#' Generate the venue metadata YAML frontmatter block for register.md
#'
#' Renders the same structured venue metadata as [generate_venue_metadata_html()]
#' and the JSON `venue` field (see [get_venue_metadata_fields()]), but as YAML
#' lines for register.md's frontmatter header rather than as an HTML block in
#' the body - register.md is served as a plain markdown/API text file, not
#' HTML, so embedding an HTML `<div>` in it is wrong (register#84 followup).
#'
#' @param venue_row A single-row data frame from CONFIG$VENUE_DATA (i.e. one
#'   row of venues.csv).
#' @param venue_type See [get_venue_metadata_fields()]. `NULL`/`NA` omits the field.
#'
#' @return A YAML string (ending in a newline), or `""` if there is nothing to add.
#' @keywords internal
#' @importFrom yaml as.yaml
generate_venue_metadata_yaml <- function(venue_row, venue_type = NULL) {
  has_value <- function(x) !is.null(x) && !is.na(x) && nzchar(trimws(x))
  fields <- get_venue_metadata_fields(venue_row, venue_type)

  yaml_list <- list()
  if (has_value(fields$venue_type)) yaml_list$venue_type <- fields$venue_type
  if (has_value(fields$website_url)) yaml_list$website <- fields$website_url
  if (has_value(fields$logo_url)) yaml_list$logo_url <- fields$logo_url
  if (has_value(fields$contact_name)) yaml_list$contact_name <- fields$contact_name
  if (has_value(fields$contact_email)) yaml_list$contact_email <- fields$contact_email
  if (has_value(fields$description)) yaml_list$description <- fields$description
  if (length(fields$identifiers) > 0) {
    yaml_list$identifiers <- lapply(fields$identifiers, function(i) {
      entry <- list(name = i$name, value = i$value)
      if (!is.null(i$icon)) entry$icon <- i$icon
      if (!is.null(i$link)) entry$url <- i$link
      entry
    })
  }

  if (length(yaml_list) == 0) {
    return("")
  }

  yaml::as.yaml(yaml_list, line.sep = "\n")
}

#' The ROR of a venue that also has an organisation page
#'
#' @param identifiers A venue's parsed identifiers (see
#'   [parse_venue_identifiers()]).
#' @return The bare ROR id, or `NA_character_` when the venue has no ROR or
#'   no organisation page was rendered for it.
#' @keywords internal
venue_organisation_ror <- function(identifiers) {
  rendered <- if (exists("ORGANISATION_RORS", envir = CONFIG)) CONFIG$ORGANISATION_RORS else character(0)

  for (identifier in identifiers) {
    if (!grepl("^ROR$", identifier$name, ignore.case = TRUE)) next
    ror <- normalize_ror(identifier$value)
    if (ror %in% rendered) return(ror)
  }

  NA_character_
}
