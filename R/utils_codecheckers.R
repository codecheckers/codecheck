#' Fetch and cache codecheckers.csv data from GitHub
#'
#' This function downloads the codecheckers registry from the codecheckers/codecheckers
#' repository and caches it for performance.
#'
#' @param ... Additional arguments passed to the memoization mechanism
#' @param envir Environment for memoization caching (default: parent.frame())
#' @return A data frame with columns: name, handle, ORCID, contact, fields, languages
#' @importFrom utils read.csv
#' @export
get_codecheckers_data <- function() {
  url <- "https://raw.githubusercontent.com/codecheckers/codecheckers/master/codecheckers.csv"

  tryCatch({
    codecheckers <- read.csv(url, stringsAsFactors = FALSE, strip.white = TRUE)
    return(codecheckers)
  }, error = function(e) {
    warning("Failed to fetch codecheckers.csv: ", e$message)
    return(data.frame(
      name = character(0),
      handle = character(0),
      ORCID = character(0),
      contact = character(0),
      fields = character(0),
      languages = character(0)
    ))
  })
}

# Memoize the function for caching
get_codecheckers_data <- R.cache::addMemoization(get_codecheckers_data)

#' Get codechecker profile information by ORCID
#'
#' Retrieves profile information for a codechecker from the codecheckers registry.
#'
#' @param orcid The ORCID identifier (without URL prefix)
#' @return A list with profile information (name, handle, orcid, fields, languages)
#'         or NULL if not found
#' @export
get_codechecker_profile <- function(orcid) {
  if (is.null(orcid) || is.na(orcid) || orcid == "" || orcid == "0000-0000-0000-0000") {
    return(NULL)
  }

  codecheckers <- get_codecheckers_data()

  if (nrow(codecheckers) == 0) {
    return(NULL)
  }

  # Find the codechecker by ORCID
  match_idx <- which(codecheckers$ORCID == orcid)

  if (length(match_idx) == 0) {
    return(NULL)
  }

  codechecker <- codecheckers[match_idx[1], ]

  # Extract GitHub handle (remove @ prefix if present)
  github_handle <- gsub("^@", "", codechecker$handle)

  profile <- list(
    name = codechecker$name,
    github_handle = if (github_handle != "" && !is.na(github_handle)) github_handle else NULL,
    orcid = codechecker$ORCID,
    fields = codechecker$fields,
    languages = codechecker$languages
  )

  return(profile)
}

#' Get codechecker profile information by GitHub handle
#'
#' Retrieves profile information for a codechecker from the codecheckers registry.
#'
#' @param handle The GitHub handle (without @ prefix)
#' @return A list with profile information (name, handle, orcid, fields, languages)
#'         or NULL if not found
#' @export
get_codechecker_profile_by_handle <- function(handle) {
  if (is.null(handle) || is.na(handle) || handle == "") {
    return(NULL)
  }

  codecheckers <- get_codecheckers_data()

  if (nrow(codecheckers) == 0) {
    return(NULL)
  }

  # Normalize handle (remove @ prefix if present)
  handle <- gsub("^@", "", handle)

  # Find the codechecker by handle (try with and without @ prefix)
  match_idx <- which(codecheckers$handle == handle | codecheckers$handle == paste0("@", handle))

  if (length(match_idx) == 0) {
    return(NULL)
  }

  codechecker <- codecheckers[match_idx[1], ]

  # Extract GitHub handle (remove @ prefix if present)
  github_handle <- gsub("^@", "", codechecker$handle)

  profile <- list(
    name = codechecker$name,
    github_handle = if (github_handle != "" && !is.na(github_handle)) github_handle else NULL,
    orcid = if (!is.na(codechecker$ORCID) && codechecker$ORCID != "") codechecker$ORCID else NULL,
    fields = codechecker$fields,
    languages = codechecker$languages
  )

  return(profile)
}

#' Get GitHub handle for a codechecker by name
#'
#' Looks up the GitHub handle for a codechecker by their name in the codecheckers registry.
#'
#' @param name The full name of the codechecker
#' @return The GitHub handle (without @ prefix) or NULL if not found
#' @export
get_github_handle_by_name <- function(name) {
  if (is.null(name) || is.na(name) || name == "") {
    return(NULL)
  }

  codecheckers <- get_codecheckers_data()

  if (nrow(codecheckers) == 0) {
    return(NULL)
  }

  # Find the codechecker by name
  match_idx <- which(codecheckers$name == name)

  if (length(match_idx) == 0) {
    return(NULL)
  }

  codechecker <- codecheckers[match_idx[1], ]

  # Extract GitHub handle (remove @ prefix if present)
  github_handle <- gsub("^@", "", codechecker$handle)

  if (github_handle == "" || is.na(github_handle)) {
    return(NULL)
  }

  return(github_handle)
}

#' Generate HTML redirect page for codechecker
#'
#' Creates a redirect page at the GitHub handle URL that redirects to the ORCID-based page.
#' This is used for codecheckers who have both ORCID and GitHub handle.
#'
#' @param github_handle The GitHub handle (without @ prefix)
#' @param orcid The ORCID identifier
#' @param name The codechecker's name
#' @return Invisibly returns TRUE if successful, FALSE otherwise
#' @importFrom whisker whisker.render
#' @export
generate_codechecker_redirect <- function(github_handle, orcid, name) {
  if (is.null(github_handle) || is.na(github_handle) || github_handle == "") {
    return(FALSE)
  }

  if (is.null(orcid) || is.na(orcid) || orcid == "") {
    return(FALSE)
  }

  # Create output directory for handle-based page
  handle_dir <- file.path("docs", "codecheckers", github_handle)
  dir.create(handle_dir, recursive = TRUE, showWarnings = FALSE)

  # Generate redirect URL to ORCID-based page
  redirect_url <- paste0(CONFIG$HYPERLINKS[["codecheckers"]], orcid, "/")

  # Load redirect template
  template_path <- system.file("extdata", "templates/general/codechecker_redirect_template.html", package = "codecheck")
  template <- readLines(template_path, warn = FALSE)

  # Render template
  data <- list(
    redirect_url = redirect_url,
    codechecker_name = name
  )

  output <- whisker::whisker.render(paste(template, collapse = "\n"), data)

  # Write redirect page
  redirect_file <- file.path(handle_dir, "index.html")
  writeLines(output, redirect_file)

  cli::cli_alert_success("Created redirect page for {name} ({github_handle} -> {orcid})")
  invisible(TRUE)
}

#' Generate redirect pages for all codecheckers with ORCID
#'
#' Iterates through all codecheckers in the register and creates redirect pages
#' for those who have both ORCID and GitHub handle. The redirect pages are created
#' at the GitHub handle URL and redirect to the ORCID-based URL.
#'
#' @param register_table The preprocessed register table
#' @return Invisibly returns the count of redirect pages created
#' @export
generate_codechecker_redirects <- function(register_table) {
  # Get unique ORCID-based codecheckers from the register
  if (!"Codechecker" %in% names(register_table)) {
    warning("Codechecker column not found in register table")
    return(invisible(0))
  }

  # Unnest and get unique codecheckers
  codecheckers_table <- register_table %>% tidyr::unnest(Codechecker)
  unique_codecheckers <- unique(codecheckers_table$Codechecker)

  # Filter to only ORCID-based codecheckers (not GitHub username-based)
  # ORCID format: NNNN-NNNN-NNNN-NNNX
  orcid_codecheckers <- unique_codecheckers[grepl("^\\d{4}-\\d{4}-\\d{4}-\\d{3}[0-9X]$", unique_codecheckers)]
  orcid_codecheckers <- orcid_codecheckers[!is.na(orcid_codecheckers)]

  redirect_count <- 0

  for (orcid in orcid_codecheckers) {
    # Get profile to check if they have a GitHub handle
    profile <- get_codechecker_profile(orcid)

    if (!is.null(profile) && !is.null(profile$github_handle)) {
      # Generate redirect page
      success <- generate_codechecker_redirect(
        github_handle = profile$github_handle,
        orcid = orcid,
        name = profile$name
      )

      if (success) {
        redirect_count <- redirect_count + 1
      }
    }
  }

  if (redirect_count > 0) {
    cli::cli_alert_success("Generated {redirect_count} codechecker redirect page{?s}")
  }

  invisible(redirect_count)
}

#' Resolve a codechecker page identifier (ORCID or GitHub handle) to a profile
#'
#' Shared lookup used by both the HTML and YAML renderings of the codechecker
#' metadata panel (register#75), so both agree on the same ORCID/GitHub handle.
#'
#' @param identifier The codechecker page identifier: an ORCID or a GitHub
#'   username (see `table_details[["name"]]` / `is_github_username` in
#'   [generate_table_details()]).
#' @return A profile list (see [get_codechecker_profile()]), or `NULL` if not found.
#' @keywords internal
resolve_codechecker_profile <- function(identifier) {
  is_orcid <- grepl("^\\d{4}-\\d{4}-\\d{4}-\\d{3}[0-9X]$", identifier)
  if (is_orcid) {
    get_codechecker_profile(identifier)
  } else {
    get_codechecker_profile_by_handle(identifier)
  }
}

#' Compute a codechecker's contributed venues, with per-venue check counts
#'
#' Shared source of truth for the "Contributed checks" row in the codechecker
#' metadata panel (register#74/#189/#83) and the `venues` field in a
#' codechecker's `stats.json` (register#78).
#'
#' @param register_table The already-filtered per-codechecker register table
#'   (raw, i.e. before `add_venue_hyperlinks_reg()` has rewritten `Venue` into
#'   a markdown link - or a `register.json` re-read as a data frame, which
#'   keeps `Venue`/`Type` as plain strings either way).
#'
#' @return A data frame with columns `Venue`, `Type`, `cert_count` - one row
#'   per distinct venue, sorted by `Venue`. Zero rows (same columns) if the
#'   input has no usable `Venue`/`Type` data.
#' @export
get_codechecker_venues <- function(register_table) {
  empty <- data.frame(Venue = character(0), Type = character(0), cert_count = integer(0),
                       stringsAsFactors = FALSE)
  if (!all(c("Venue", "Type") %in% names(register_table)) || nrow(register_table) == 0) {
    return(empty)
  }

  venue_col <- register_table$Venue
  usable <- !is.na(venue_col) & nzchar(venue_col)
  if (!any(usable)) {
    return(empty)
  }

  venues <- register_table[usable, c("Venue", "Type"), drop = FALSE] %>%
    dplyr::count(Venue, Type, name = "cert_count") %>%
    dplyr::arrange(Venue)

  as.data.frame(venues, stringsAsFactors = FALSE)
}

#' Aggregate a codechecker's checks from venues to venue types
#'
#' The per-type counts behind the stacked bar (register#92) and the donut
#' (register#207). Built on [get_codechecker_venues()] so it counts exactly
#' what the "Contributed checks" row lists, only grouped one level up.
#'
#' @param register_table See [get_codechecker_venues()].
#' @return A named integer vector of checks per venue type, largest first;
#'   length zero if there is nothing to count.
#' @keywords internal
get_codechecker_type_counts <- function(register_table) {
  venues <- get_codechecker_venues(register_table)
  if (nrow(venues) == 0) {
    return(integer(0))
  }

  counts <- tapply(venues$cert_count, venues$Type, sum)
  order_type_counts(counts[!is.na(counts)])
}

#' Turn a single markdown link into an HTML anchor tag
#'
#' The codechecker metadata panel is a raw HTML block passed through pandoc
#' unprocessed (like the venue metadata panel - see register#84 followup), so
#' a markdown-syntax link inside it would render as literal text rather than
#' a clickable link. `add_venue_hyperlinks_reg()` only produces markdown links
#' (`[Name](url)`), so its output is converted here rather than duplicating
#' its slug/relative-path logic in an HTML-emitting copy.
#'
#' @param markdown_link A string possibly containing `[text](url)` markdown links.
#' @return The same string with any markdown links replaced by `<a href="url">text</a>`.
#' @keywords internal
markdown_link_to_html <- function(markdown_link) {
  gsub("\\[([^]]+)\\]\\(([^)]+)\\)", '<a href="\\2">\\1</a>', markdown_link)
}

#' Render a codechecker's contributed-venues list as an HTML fragment
#'
#' Produces the register#83 target format - `type <a href="...">Name</a>
#' (count)` entries, comma-separated (no surrounding label; the caller/template
#' supplies that, see `codechecker_metadata.html`). Reuses
#' `add_venue_hyperlinks_reg()` for the venue links so they match exactly what
#' the same register_table would produce elsewhere on the page.
#'
#' @param register_table See [get_codechecker_venues()].
#' @param table_details Needed for `add_venue_hyperlinks_reg()`'s
#'   relative-path depth calculation.
#' @return An HTML string, or `""` if there are no venues.
#' @keywords internal
generate_contributed_venues_html <- function(register_table, table_details) {
  venues <- get_codechecker_venues(register_table)
  if (nrow(venues) == 0) {
    return("")
  }

  linked <- add_venue_hyperlinks_reg(venues, table_details)
  entries <- sprintf("%s %s (%d)", venues$Type, markdown_link_to_html(linked$Venue), venues$cert_count)
  paste(entries, collapse = ", ")
}

#' Generate the codechecker metadata HTML panel (avatar + ORCID + GitHub + venues)
#'
#' Renders a `venue-metadata`-style panel for a codechecker's own page: a
#' GitHub avatar (a plain `https://github.com/<handle>.png` image - GitHub
#' serves this directly, so no API call or caching is needed, unlike
#' OpenAlex/CrossRef lookups elsewhere), a property list with the
#' codechecker's ORCID and GitHub profile link (register#75), and the
#' contributed-venues list (register#74/#189/#83) as a further row in the
#' same list, rather than as separate text above the panel. Reuses the
#' `.venue-metadata`/`.venue-metadata-label` CSS classes already used by the
#' venue panel.
#'
#' @param identifier See [resolve_codechecker_profile()].
#' @param register_table,table_details See [generate_contributed_venues_html()].
#'   `NULL` (the default) omits the contributed-venues row.
#' @return An HTML string, or `""` if there is nothing to show (no ORCID, no
#'   GitHub handle, and no contributed venues).
#' @importFrom whisker whisker.render
#' @export
generate_codechecker_metadata_html <- function(identifier, register_table = NULL, table_details = NULL) {
  profile <- resolve_codechecker_profile(identifier)

  has_orcid <- !is.null(profile$orcid) && nzchar(profile$orcid)
  has_github <- !is.null(profile$github_handle) && nzchar(profile$github_handle)

  venues_html <- if (!is.null(register_table)) generate_contributed_venues_html(register_table, table_details) else ""
  has_venues <- nzchar(venues_html)

  # The donut visualises the same numbers the contributed-venues row spells out
  # (register#207), aggregated from venue to venue type.
  type_counts <- if (!is.null(register_table)) get_codechecker_type_counts(register_table) else integer(0)
  donut_svg <- codechecker_type_donut_svg(type_counts)
  has_type_chart <- nzchar(donut_svg)
  type_counts_json <- if (has_type_chart) {
    as.character(jsonlite::toJSON(as.list(type_counts), auto_unbox = TRUE))
  } else {
    ""
  }

  if (!has_orcid && !has_github && !has_venues) {
    return("")
  }

  template_path <- system.file("extdata", "templates/general/codechecker_metadata.html", package = "codecheck")
  template <- paste(readLines(template_path, warn = FALSE), collapse = "\n")

  data <- list(
    has_github = has_github,
    github_handle = if (has_github) profile$github_handle else NULL,
    has_orcid = has_orcid,
    orcid = if (has_orcid) profile$orcid else NULL,
    has_venues = has_venues,
    venues_html = venues_html,
    has_type_chart = has_type_chart,
    type_chart_svg = donut_svg,
    type_counts_json = type_counts_json
  )

  whisker.render(template, data)
}

#' Generate the codechecker metadata YAML frontmatter block for register.md
#'
#' Renders the same ORCID/GitHub/contributed-venues information as
#' [generate_codechecker_metadata_html()], but as YAML lines for register.md's
#' frontmatter header rather than an HTML block in the body - same split as
#' [generate_venue_metadata_yaml()], since register.md is a plain markdown/API
#' text file, not HTML.
#'
#' @param identifier See [resolve_codechecker_profile()].
#' @param register_table See [get_codechecker_venues()]. `NULL` (the default)
#'   omits the `venues` field.
#' @return A YAML string (ending in a newline), or `""` if nothing to add.
#' @importFrom yaml as.yaml
#' @export
generate_codechecker_metadata_yaml <- function(identifier, register_table = NULL) {
  profile <- resolve_codechecker_profile(identifier)

  yaml_list <- list()
  if (!is.null(profile$orcid) && nzchar(profile$orcid)) yaml_list$orcid <- profile$orcid
  if (!is.null(profile$github_handle) && nzchar(profile$github_handle)) yaml_list$github_username <- profile$github_handle

  if (!is.null(register_table)) {
    venues <- get_codechecker_venues(register_table)
    if (nrow(venues) > 0) {
      yaml_list$venues <- lapply(seq_len(nrow(venues)), function(i) list(
        name = venues$Venue[i],
        type = venues$Type[i],
        cert_count = venues$cert_count[i]
      ))
    }
  }

  if (length(yaml_list) == 0) {
    return("")
  }

  yaml::as.yaml(yaml_list, line.sep = "\n")
}

#' Escape text for inclusion in HTML/SVG
#'
#' Small local helper rather than a new dependency on htmltools - the only
#' escaping the register needs is for the venue-type names and counts that go
#' into the check-type visualisations.
#'
#' @param text The text to escape.
#' @param attribute Whether the text goes into an attribute value (also escapes
#'   quotes) rather than element content.
#' @return The escaped text.
#' @keywords internal
html_escape <- function(text, attribute = FALSE) {
  text <- gsub("&", "&amp;", text, fixed = TRUE)
  text <- gsub("<", "&lt;", text, fixed = TRUE)
  text <- gsub(">", "&gt;", text, fixed = TRUE)
  if (attribute) {
    text <- gsub('"', "&quot;", text, fixed = TRUE)
    text <- gsub("'", "&#39;", text, fixed = TRUE)
  }
  text
}

#' Render a codechecker's checks-per-type as an SVG donut (register#207)
#'
#' Inline SVG rather than a charting library: the donut sits at 96px beside the
#' avatar, and a Chart.js tooltip is painted *inside* its canvas, so a
#' multi-line one is clipped at that size. Native SVG `<title>` tooltips are
#' drawn by the browser outside the element and cannot be clipped - and they
#' are the same hover mechanism as the stacked bar in the codecheckers table.
#'
#' Every slice's `<title>` lists *all* types (see [type_breakdown_text()]),
#' marking its own, which is what lets the chart do without a legend.
#'
#' @param counts A named integer vector of checks per venue type.
#' @return An SVG string, or `""` for no counts.
#' @keywords internal
codechecker_type_donut_svg <- function(counts) {
  counts <- counts[!is.na(counts) & counts > 0]
  if (length(counts) == 0) {
    return("")
  }

  counts <- order_type_counts(counts)
  total <- sum(counts)
  types <- names(counts)
  summary <- paste(sprintf("%d %s", counts, types), collapse = ", ")

  # The line breaks have to be character references, not literal newlines:
  # pandoc reflows the whitespace of a raw HTML block, which collapses real
  # newlines inside <title> into spaces and turns the list back into one run-on
  # line. An entity survives that untouched and the parser turns it back into a
  # newline in the tooltip.
  # Both the line breaks and the leading indent have to be character
  # references, not literal characters: pandoc reflows the whitespace of a raw
  # HTML block, collapsing real newlines into spaces and runs of spaces into
  # one, which would both break the list apart and misalign the unmarked lines
  # under the marked one. Entities survive that untouched.
  title_for <- function(type) {
    text <- html_escape(type_breakdown_text(counts, highlight = type))
    text <- gsub("\n  ", "&#10;&#160;&#160;", text, fixed = TRUE)
    gsub("\n", "&#10;", text, fixed = TRUE)
  }

  # A full circle makes an SVG arc degenerate (its start and end points
  # coincide), so a codechecker with a single venue type - which most have -
  # gets a stroked circle instead.
  if (length(counts) == 1) {
    shapes <- sprintf(
      '<circle cx="%s" cy="%s" r="%s" fill="none" stroke="%s" stroke-width="%s"><title>%s</title></circle>',
      DONUT_CENTER, DONUT_CENTER, (DONUT_R_OUTER + DONUT_R_INNER) / 2,
      venue_type_color(types[1]), DONUT_R_OUTER - DONUT_R_INNER,
      title_for(types[1])
    )
  } else {
    angles <- -pi / 2 + 2 * pi * cumsum(c(0, counts)) / total
    shapes <- vapply(seq_along(counts), function(i) {
      sprintf(
        '<path d="%s" fill="%s" stroke="#f6f8f6" stroke-width="1"><title>%s</title></path>',
        donut_slice_path(angles[i], angles[i + 1]),
        venue_type_color(types[i]),
        title_for(types[i])
      )
    }, character(1))
  }

  paste0(
    '<svg class="codechecker-type-chart" viewBox="0 0 96 96" role="img" aria-label="',
    html_escape(summary, attribute = TRUE), '">',
    paste(shapes, collapse = ""),
    '</svg>'
  )
}

#' Geometry of the codechecker donut, in the 96x96 user space of its viewBox
#' @keywords internal
DONUT_CENTER <- 48
#' @rdname DONUT_CENTER
#' @keywords internal
DONUT_R_OUTER <- 46
#' @rdname DONUT_CENTER
#' @keywords internal
DONUT_R_INNER <- 25

#' Path data for one donut slice
#'
#' Outer arc clockwise from `start` to `end`, straight in to the inner radius,
#' inner arc back again.
#'
#' @param start,end Angles in radians, 0 pointing right, measured clockwise.
#' @return An SVG `d` attribute value.
#' @keywords internal
donut_slice_path <- function(start, end) {
  point <- function(r, angle) {
    sprintf("%.2f %.2f", DONUT_CENTER + r * cos(angle), DONUT_CENTER + r * sin(angle))
  }
  large_arc <- if ((end - start) > pi) 1 else 0

  paste0(
    "M", point(DONUT_R_OUTER, start),
    "A", DONUT_R_OUTER, " ", DONUT_R_OUTER, " 0 ", large_arc, " 1 ", point(DONUT_R_OUTER, end),
    "L", point(DONUT_R_INNER, end),
    "A", DONUT_R_INNER, " ", DONUT_R_INNER, " 0 ", large_arc, " 0 ", point(DONUT_R_INNER, start),
    "Z"
  )
}
