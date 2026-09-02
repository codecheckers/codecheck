#' Generate the metadata HTML block for an organisation landing page
#'
#' The organisation analogue of [generate_venue_metadata_html()]: name, type,
#' location and identifiers from ror.org, a logo from the Wikidata item the
#' ROR record points at, the register venue that shares the ROR (if any), and
#' the people this organisation is on the register through. Fields the ROR
#' record does not carry are omitted rather than shown empty.
#'
#' @param ror The organisation's ROR id (`table_details[["name"]]` on an
#'   organisation page).
#' @param register_table The organisation's exploded, per-person-per-role rows
#'   (see [explode_organisation_records()]), pristine (before display
#'   hyperlinks).
#' @return An HTML string.
#' @importFrom whisker whisker.render
#' @keywords internal
generate_organisation_metadata_html <- function(ror, register_table) {
  has_value <- function(x) !is.null(x) && length(x) > 0 && !is.na(x[1]) && nzchar(trimws(x[1]))
  fields <- get_organisation_metadata(ror)

  location <- paste(stats::na.omit(c(fields$city, fields$country)), collapse = ", ")
  people <- organisation_people(register_table)

  template_path <- system.file("extdata", "templates/general/organisation_metadata.html",
                               package = "codecheck")
  template <- paste(readLines(template_path, warn = FALSE), collapse = "\n")

  data <- list(
    name = fields$name,
    has_logo = has_value(fields$logo_url),
    logo_url = fields$logo_url,
    has_types = length(fields$types) > 0,
    types = paste(fields$types, collapse = ", "),
    has_location = nzchar(location),
    location = location,
    has_established = has_value(fields$established),
    established = fields$established,
    has_website = has_value(fields$website_url),
    website_url = fields$website_url,
    has_wikipedia = has_value(fields$wikipedia_url),
    wikipedia_url = fields$wikipedia_url,
    identifiers = fields$identifiers,
    has_venue = !is.null(fields$venue),
    venue_longname = if (is.null(fields$venue)) NULL else fields$venue$longname,
    venue_url = if (is.null(fields$venue)) NULL else fields$venue$url,
    has_people = length(people) > 0,
    people = people,
    has_aliases = length(fields$aliases) > 0,
    aliases = paste(fields$aliases, collapse = ", "),
    # always generated next to this page, like the venue panel's
    api_stats_url = "index.json"
  )

  whisker.render(template, data)
}

#' The people an organisation is on the register through
#'
#' @param register_table The organisation's exploded rows, with a `Person`
#'   (ORCID) column.
#' @return A list of `name`/`url`/`last` lists, ready for whisker (`last`
#'   marks the final entry so the template can omit its separator).
#' @keywords internal
organisation_people <- function(register_table) {
  if (!("Person" %in% names(register_table)) || nrow(register_table) == 0) {
    return(list())
  }

  orcids <- unique(register_table$Person)
  people <- lapply(orcids, function(orcid) {
    name <- CONFIG$DICT_ORCID_ID_NAME[[orcid]]
    if (is.null(name)) name <- orcid
    # An organisation page always lives at docs/organisations/<ror>/, so the
    # persons directory is exactly two levels up.
    list(name = name, url = paste0("../../persons/", orcid, "/"), last = FALSE)
  })
  people[[length(people)]]$last <- TRUE
  people
}
