#' The ROR API the organisation metadata comes from
#' @keywords internal
ROR_API <- "https://api.ror.org/v2/organizations/"

#' Look up an organisation's record on ror.org
#'
#' There is no maintained R package wrapping the ROR API (`rorcid` is ORCID),
#' so the v2 REST API is called directly, through the same request and caching
#' machinery as the register's other external metadata.
#'
#' @param ror A ROR id, with or without the `https://ror.org/` prefix.
#' @return A list with `status` ("found", "absent" or "failed") and `value`,
#'   the parsed ROR record or `NULL`.
#' @keywords internal
get_ror_record_result <- function(ror) {
  if (is.null(ror) || length(ror) != 1 || is.na(ror) || !nzchar(ror)) {
    return(list(status = "absent", value = NULL))
  }

  response <- codecheck_GET_retry(paste0(ROR_API, normalize_ror(ror)))

  if (is.null(response)) {
    return(list(status = "failed", value = NULL))
  }
  status <- httr::status_code(response)
  # ROR answers 404 for an id it does not know, which is conclusive
  if (status == 404) {
    return(list(status = "absent", value = NULL))
  }
  if (status != 200) {
    return(list(status = "failed", value = NULL))
  }

  record <- tryCatch(
    jsonlite::fromJSON(
      httr::content(response, as = "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    ),
    error = function(e) NULL
  )
  if (is.null(record) || is.null(record$id)) {
    return(list(status = "failed", value = NULL))
  }

  list(status = "found", value = record)
}

#' Cached version of [get_ror_record_result()]
#'
#' @inheritParams get_ror_record_result
#' @return The parsed ROR record, or `NULL`
#' @keywords internal
get_ror_record_cached <- function(ror) {
  cached_lookup(
    key = list("ror_record", normalize_ror(ror)),
    dirs = c("codecheck", "ror_record"),
    lookup = function() get_ror_record_result(ror)
  )
}

#' The bare ROR id
#'
#' ORCID and `venues.csv` both store a ROR as the full `https://ror.org/<id>`
#' URL, while the API and the page slugs use the id on its own.
#'
#' @param ror A ROR id or ROR URL
#' @return The id without the `https://ror.org/` prefix
#' @keywords internal
normalize_ror <- function(ror) {
  if (is.null(ror) || length(ror) == 0) {
    return(character(0))
  }
  sub("^.*ror\\.org/", "", ror)
}

#' Extract an organisation's structured metadata fields
#'
#' Flattens a ROR record into the plain list both the landing page's metadata
#' panel ([generate_organisation_metadata_html()]) and its JSON representation
#' consume, the way [get_venue_metadata_fields()] does for a venue - the two
#' descriptions of a page must not drift apart.
#'
#' @param record A ROR record (see [get_ror_record_cached()]), or `NULL`.
#' @param ror The ROR id, used when the record could not be read.
#' @return A list with `ror`, `ror_url`, `name`, `aliases`, `types`, `city`,
#'   `country`, `established`, `website_url`, `wikipedia_url`, `wikidata`,
#'   `status` (each `NA_character_`/`NULL` when not set) and `identifiers`, a
#'   list of `name`/`icon`/`value`/`link` lists in the shape
#'   [parse_venue_identifiers()] produces.
#' @keywords internal
ror_metadata_fields <- function(record, ror = NULL) {
  id <- normalize_ror(if (!is.null(record$id)) record$id else ror)

  fields <- list(
    ror = id,
    ror_url = paste0("https://ror.org/", id),
    name = ror_display_name(record, fallback = id),
    aliases = ror_names_of_type(record, c("alias", "label")),
    types = unlist(record$types),
    city = NA_character_,
    country = NA_character_,
    established = if (is.null(record$established)) NA_character_ else as.character(record$established),
    website_url = ror_link_of_type(record, "website"),
    wikipedia_url = ror_link_of_type(record, "wikipedia"),
    wikidata = ror_external_id(record, "wikidata"),
    status = if (is.null(record$status)) NA_character_ else record$status
  )

  location <- if (length(record$locations) > 0) record$locations[[1]]$geonames_details else NULL
  if (!is.null(location)) {
    if (!is.null(location$name)) fields$city <- location$name
    if (!is.null(location$country_name)) fields$country <- location$country_name
  }

  # The ROR itself first, then whatever else the record carries - the same
  # name/icon/value/link shape the venue metadata template already renders.
  identifiers <- list(list(name = "ROR", icon = "fa-university", value = id,
                           link = fields$ror_url))
  for (type in c("grid", "isni", "fundref")) {
    value <- ror_external_id(record, type)
    if (is.na(value)) next
    identifiers[[length(identifiers) + 1]] <- list(
      name = toupper(type), icon = "fa-id-card", value = value, link = NULL
    )
  }
  if (!is.na(fields$wikidata)) {
    identifiers[[length(identifiers) + 1]] <- list(
      name = "Wikidata", icon = "fa-database", value = fields$wikidata,
      link = paste0(CONFIG$HYPERLINKS[["wikidata"]], fields$wikidata)
    )
  }
  fields$identifiers <- identifiers

  fields
}

#' The name a ROR record is displayed under
#'
#' @param record A ROR record, or `NULL`
#' @param fallback Returned when the record has no display name
#' @return The `ror_display` name, or `fallback`
#' @keywords internal
ror_display_name <- function(record, fallback = NA_character_) {
  for (name in record$names) {
    if ("ror_display" %in% unlist(name$types)) {
      return(name$value)
    }
  }
  fallback
}

#' The other names a ROR record carries
#'
#' @param record A ROR record, or `NULL`
#' @param types The name types to collect
#' @return A character vector of names, without the display name
#' @keywords internal
ror_names_of_type <- function(record, types) {
  display <- ror_display_name(record)
  names <- unlist(lapply(record$names, function(name) {
    if (length(intersect(unlist(name$types), types)) == 0) return(NULL)
    name$value
  }))
  unique(setdiff(names, display))
}

#' One of a ROR record's links
#'
#' @param record A ROR record, or `NULL`
#' @param type The link type, e.g. "website" or "wikipedia"
#' @return The link, or `NA_character_`
#' @keywords internal
ror_link_of_type <- function(record, type) {
  for (link in record$links) {
    if (identical(link$type, type)) return(link$value)
  }
  NA_character_
}

#' One of a ROR record's external identifiers
#'
#' @param record A ROR record, or `NULL`
#' @param type The identifier type, e.g. "wikidata" or "grid"
#' @return The preferred value, or the first one, or `NA_character_`
#' @keywords internal
ror_external_id <- function(record, type) {
  for (external in record$external_ids) {
    if (!identical(external$type, type)) next
    if (!is.null(external$preferred)) return(external$preferred)
    if (length(external$all) > 0) return(external$all[[1]])
  }
  NA_character_
}

#' Look up an organisation's logo on Wikidata
#'
#' ROR carries no logo, so the landing page takes one from the Wikidata item
#' the ROR record points at: `P154` (logo image), or `P18` (image) when there
#' is no logo. Both are Commons filenames, which resolve to a file through
#' Special:FilePath without an API key.
#'
#' @param qid A Wikidata item id, e.g. "Q752663".
#' @return A list with `status` and `value`, the logo URL or `NA_character_`
#' @keywords internal
get_wikidata_logo_result <- function(qid) {
  if (is.null(qid) || length(qid) != 1 || is.na(qid) || !nzchar(qid)) {
    return(list(status = "absent", value = NA_character_))
  }

  entities <- tryCatch(
    wikibase_get(NULL, list(action = "wbgetentities", ids = qid, props = "claims"),
                 api = WIKIDATA_API)$entities,
    error = function(e) NULL
  )
  if (is.null(entities)) {
    return(list(status = "failed", value = NA_character_))
  }

  claims <- entities[[qid]]$claims
  for (property in c("P154", "P18")) {
    file <- claims[[property]][[1]]$mainsnak$datavalue$value
    if (is.character(file) && nzchar(file)) {
      return(list(status = "found", value = commons_file_url(file)))
    }
  }

  list(status = "absent", value = NA_character_)
}

#' Cached version of [get_wikidata_logo_result()]
#'
#' @inheritParams get_wikidata_logo_result
#' @return The logo URL, or `NA_character_`
#' @keywords internal
get_wikidata_logo_cached <- function(qid) {
  cached_lookup(
    key = list("wikidata_logo", qid),
    dirs = c("codecheck", "wikidata_logo"),
    lookup = function() get_wikidata_logo_result(qid)
  )
}

#' The URL a Wikimedia Commons file is served from
#'
#' @param file A Commons file name, e.g. "Zegel Technische Universiteit Delft.svg"
#' @param width The width to render the file at, in pixels
#' @return The Special:FilePath URL
#' @keywords internal
commons_file_url <- function(file, width = 320) {
  paste0("https://commons.wikimedia.org/wiki/Special:FilePath/",
         utils::URLencode(file, reserved = TRUE), "?width=", width)
}

#' An organisation's metadata, from ROR and Wikidata together
#'
#' The single entry point the rendering code uses: the ROR record's fields
#' (see [ror_metadata_fields()]) plus the Wikidata logo, if the record points
#' at an item that has one, and the register venue that shares the ROR, if
#' any (see [venue_for_ror()]).
#'
#' @param ror A ROR id.
#' @return The list [ror_metadata_fields()] returns, with `logo_url` and
#'   `venue` added.
#' @keywords internal
get_organisation_metadata <- function(ror) {
  record <- get_ror_record_cached(ror)
  fields <- ror_metadata_fields(record, ror)

  fields$logo_url <- if (is.na(fields$wikidata)) {
    NA_character_
  } else {
    logo <- get_wikidata_logo_cached(fields$wikidata)
    if (is.null(logo)) NA_character_ else logo
  }

  fields$venue <- venue_for_ror(ror)

  fields
}

#' The register venue that carries a ROR, if any
#'
#' An institution venue can name its ROR in `venues.csv`'s `identifiers`
#' column, which is the same organisation this page is about - commissioning
#' a check and employing the people who did it are different facts, so the two
#' pages stay separate and link to each other instead.
#'
#' @param ror A ROR id.
#' @return A list with `name`, `longname` and `url` (the venue's page), or
#'   `NULL` when no venue carries this ROR.
#' @keywords internal
venue_for_ror <- function(ror) {
  if (!exists("VENUE_DATA", envir = CONFIG) || is.null(CONFIG$VENUE_DATA)) {
    return(NULL)
  }
  venues <- CONFIG$VENUE_DATA
  if (!("identifiers" %in% names(venues))) {
    return(NULL)
  }

  id <- normalize_ror(ror)
  for (i in seq_len(nrow(venues))) {
    identifiers <- parse_venue_identifiers(venues$identifiers[i])
    rors <- unlist(lapply(identifiers, function(identifier) {
      if (!grepl("^ROR$", identifier$name, ignore.case = TRUE)) return(NULL)
      normalize_ror(identifier$value)
    }))
    if (!(id %in% rors)) next

    # venues.csv's "label" column doubles as the venue type for the venues
    # that have one; without it there is no directory to link to, so the
    # venue is named but not linked. The slug must match the one
    # generate_table_details() computes for a venue page.
    venue_type <- if ("label" %in% names(venues)) venues$label[i] else NA_character_
    plural <- if (is.na(venue_type)) NULL else CONFIG$VENUE_SUBCAT_PLURAL[[venue_type]]
    return(list(
      name = venues$name[i],
      longname = if ("longname" %in% names(venues)) venues$longname[i] else venues$name[i],
      url = if (is.null(plural)) NULL else paste0(
        CONFIG$HYPERLINKS[["venues"]], plural, "/",
        gsub(" ", "_", tolower(venues$name[i])), "/")
    ))
  }

  NULL
}
