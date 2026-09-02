#' Generate navigation header with logo and menu
#'
#' Creates a header navigation bar with CODECHECK logo and optional menu.
#' The logo links to register home, same as the "All Checks" menu item -
#' kept as a second, explicit route to the same place since a logo-as-home
#' link is a common web convention but not a self-explanatory one, and the
#' logo also carries a hover title saying so.
#'
#' @param filter The filter type (NA for main register, "venues", "works",
#'   "persons", "statistics", ...)
#' @param base_path Relative path to register root for logo link
#' @param table_details List containing page metadata to determine if it's an overview page
#'
#' @return HTML string with navigation header
#' @export
generate_navigation_header <- function(filter = NA, base_path = ".", table_details = list()) {

  # Logo always links to register home
  logo_link <- paste0(base_path, "/index.html")

  # The menu is on every page - it used to be gated to overview/listing
  # pages only, leaving every detail page (a certificate, a specific venue,
  # work or person) with just breadcrumbs, which forces a visitor there to
  # go back to a section's overview before they can jump to a different
  # section. base_path is already computed correctly for any page's depth
  # before this function is called, so the menu's own link paths below need
  # no special-casing to reach every page uniformly.
  show_menu <- TRUE

  menu_html <- ""
  if (show_menu) {
    # Calculate paths relative to base_path
    if (base_path == ".") {
      venues_path <- "venues/index.html"
      works_path <- "works/index.html"
      persons_path <- "persons/index.html"
      organisations_path <- "organisations/index.html"
      statistics_path <- "statistics/index.html"
    } else {
      # Special handling for a venue *type* overview page (e.g.,
      # /venues/communities/index.html): it is one level *inside* the
      # venues directory already, so "All Venues" is just one level up -
      # works/persons/statistics are not nested that way, so they still
      # need the full base_path distance back to the docs root. A specific
      # venue's own detail page (e.g. /venues/communities/gigascience/)
      # also carries a "subcat" in table_details, but sits one level
      # *deeper* than the type overview - excluding is_reg_table pages here
      # is what keeps it out of this shortcut (it wants the general
      # base_path-relative form below instead).
      if (filter == "venues" && "subcat" %in% names(table_details) &&
          !isTRUE(table_details$is_reg_table)) {
        venues_path <- "../index.html"
        works_path <- paste0(base_path, "/works/index.html")
        persons_path <- paste0(base_path, "/persons/index.html")
        organisations_path <- paste0(base_path, "/organisations/index.html")
        statistics_path <- paste0(base_path, "/statistics/index.html")
      } else {
        venues_path <- paste0(base_path, "/venues/index.html")
        works_path <- paste0(base_path, "/works/index.html")
        persons_path <- paste0(base_path, "/persons/index.html")
        organisations_path <- paste0(base_path, "/organisations/index.html")
        statistics_path <- paste0(base_path, "/statistics/index.html")
      }
    }

    # Determine which page is active based on filter
    venues_active <- ""
    works_active <- ""
    persons_active <- ""
    organisations_active <- ""
    statistics_active <- ""
    if (!is.na(filter)) {
      if (filter == "venues") {
        venues_active <- " active"
      } else if (filter == "works") {
        works_active <- " active"
      } else if (filter == "persons") {
        persons_active <- " active"
      } else if (filter == "organisations") {
        organisations_active <- " active"
      } else if (filter == "statistics") {
        statistics_active <- " active"
      }
    }

    menu_html <- paste0('
    <nav class="navbar-menu">
      <a href="', logo_link, '" class="nav-link" title="Browse all CODECHECK certificates">Checks</a>
      <a href="', venues_path, '" class="nav-link', venues_active, '" title="Browse venues that have hosted a CODECHECK">Venues</a>
      <a href="', works_path, '" class="nav-link', works_active, '" title="Browse checked papers">Works</a>
      <a href="', persons_path, '" class="nav-link', persons_active, '" title="Browse people who authored or checked a paper">People</a>
      <a href="', organisations_path, '" class="nav-link', organisations_active, '" title="Browse organisations whose people authored or checked a paper">Organisations</a>
      <a href="', statistics_path, '" class="nav-link', statistics_active, '" title="View register statistics">Statistics</a>
      <a href="https://codecheck.org.uk/" class="nav-link" title="About the CODECHECK project">About</a>
    </nav>')
  }

  # Calculate logo path (avoid "./" prefix for root page)
  if (base_path == ".") {
    logo_path <- "codecheck_logo.svg"
  } else {
    logo_path <- paste0(base_path, "/codecheck_logo.svg")
  }

  html <- paste0(
    '<div class="codecheck-navbar">\n',
    '  <div class="navbar-container">\n',
    '    <a href="', logo_link, '" class="navbar-brand" title="Go to list of checks">\n',
    '      <img src="', logo_path, '" alt="Go to list of checks" class="navbar-logo">\n',
    '    </a>\n',
    menu_html, '\n',
    '  </div>\n',
    '</div>\n'
  )

  return(html)
}

#' Generate breadcrumb navigation HTML
#'
#' Creates Bootstrap-styled breadcrumb navigation based on page context.
#' Breadcrumbs help users navigate from detail pages back to overview pages.
#'
#' @param filter The filter type (NA for main register, "venues", "codecheckers", "certs")
#' @param table_details List containing page metadata (name, subcat, slug_name, is_reg_table)
#' @param base_path Relative path to register root (e.g., "../..", ".", etc.)
#'
#' @return HTML string with breadcrumb navigation
#' @export
generate_breadcrumb <- function(filter = NA, table_details = list(), base_path = ".") {

  # Initialize breadcrumb items
  items <- list()

  # Root: CODECHECK Register (always first)
  root_link <- paste0(base_path, "/index.html")
  items[[1]] <- list(label = "CODECHECK Register", url = root_link, active = FALSE)

  # Handle different page types
  if (is.na(filter)) {
    # Main register page - only show root, make it active
    items[[1]]$active <- TRUE

  } else if (filter == "venues") {
    # Venues section
    venues_link <- paste0(base_path, "/venues/index.html")

    if (!table_details$is_reg_table && "subcat" %in% names(table_details)) {
      # Venue *type* overview page (e.g. /venues/journals/) - not a reg
      # table itself, but still carries a subcat, one level below the top
      # venues overview (which has neither is_reg_table nor subcat set).
      subcat <- table_details$subcat
      subcat_plural <- CONFIG$VENUE_SUBCAT_PLURAL[[subcat]]
      subcat_label <- stringr::str_to_title(subcat_plural)

      items[[2]] <- list(label = "Venues", url = venues_link, active = FALSE)
      items[[3]] <- list(label = subcat_label, url = NULL, active = TRUE)

    } else if (!table_details$is_reg_table) {
      # Venues overview page
      items[[2]] <- list(label = "Venues", url = venues_link, active = TRUE)

    } else if ("subcat" %in% names(table_details)) {
      # Specific venue page or certificate page within venue context
      subcat <- table_details$subcat
      subcat_plural <- CONFIG$VENUE_SUBCAT_PLURAL[[subcat]]
      subcat_label <- stringr::str_to_title(subcat_plural)

      # Add Venues link
      items[[2]] <- list(label = "Venues", url = venues_link, active = FALSE)

      # Add venue type link
      venue_type_link <- paste0(base_path, "/venues/", subcat_plural, "/index.html")
      items[[3]] <- list(label = subcat_label, url = venue_type_link, active = FALSE)

      # Add specific venue
      venue_name <- table_details$name
      venue_longname <- CONFIG$DICT_VENUE_NAMES[[venue_name]]
      if (is.null(venue_longname)) venue_longname <- venue_name

      # Check if this is a certificate page (has cert_id)
      if ("cert_id" %in% names(table_details)) {
        # Certificate page: venue is a link, cert_id is active
        venue_slug <- gsub(" ", "_", tolower(venue_name))
        venue_page_link <- paste0(base_path, "/venues/", subcat_plural, "/", venue_slug, "/index.html")
        items[[4]] <- list(label = venue_longname, url = venue_page_link, active = FALSE)
        items[[5]] <- list(label = table_details$cert_id, url = NULL, active = TRUE)
      } else {
        # Venue page: venue is active
        items[[4]] <- list(label = venue_longname, url = NULL, active = TRUE)
      }
    }

  } else if (filter == "codecheckers") {
    # Codecheckers section
    codecheckers_link <- paste0(base_path, "/codecheckers/index.html")

    if (!table_details$is_reg_table) {
      # Codecheckers overview page
      items[[2]] <- list(label = "Codecheckers", url = codecheckers_link, active = TRUE)

    } else {
      # Specific codechecker page
      items[[2]] <- list(label = "Codecheckers", url = codecheckers_link, active = FALSE)

      # Get codechecker name
      orcid <- table_details$name
      codechecker_name <- CONFIG$DICT_ORCID_ID_NAME[[orcid]]
      if (is.null(codechecker_name)) codechecker_name <- orcid

      items[[3]] <- list(label = codechecker_name, url = NULL, active = TRUE)
    }

  } else if (filter == "certs") {
    # Certificate pages
    certs_link <- paste0(base_path, "/certs/index.html")
    items[[2]] <- list(label = "Certificates", url = certs_link, active = FALSE)

    if ("name" %in% names(table_details)) {
      cert_id <- table_details$name
      items[[3]] <- list(label = cert_id, url = NULL, active = TRUE)
    } else {
      items[[2]]$active <- TRUE
    }

  } else if (filter == "statistics") {
    # Statistics dashboard page
    items[[2]] <- list(label = "Statistics", url = NULL, active = TRUE)
  }

  # Generate Bootstrap breadcrumb HTML
  html <- '<nav aria-label="breadcrumb">\n'
  html <- paste0(html, '  <ol class="breadcrumb">\n')

  for (item in items) {
    if (item$active) {
      # Active item (current page)
      html <- paste0(html, '    <li class="breadcrumb-item active" aria-current="page">',
                     item$label, '</li>\n')
    } else {
      # Clickable link
      html <- paste0(html, '    <li class="breadcrumb-item"><a href="',
                     item$url, '">', item$label, '</a></li>\n')
    }
  }

  html <- paste0(html, '  </ol>\n')
  html <- paste0(html, '</nav>')

  return(html)
}

#' Calculate base path for breadcrumb links
#'
#' Determines the relative path to the register root based on page depth.
#'
#' @param filter The filter type
#' @param table_details List containing page metadata
#'
#' @return Relative path string (e.g., ".", "..", "../..")
#' @export
calculate_breadcrumb_base_path <- function(filter = NA, table_details = list()) {

  # Main register: base path is "."
  if (is.na(filter)) {
    return(".")
  }

  # Prefer deriving depth directly from the output directory when available -
  # the filter-shape heuristic below assumes a directory nesting no deeper
  # than "filter/subcat/slug/", which a DOI-keyed work page routinely
  # exceeds (a DOI's own "/" characters become path segments, so
  # "works/10.31222/osf.io/a8rmu/" is four levels deep, not two or three).
  if (!is.null(table_details$output_dir)) {
    rel_path <- gsub("^docs/|/$", "", table_details$output_dir)
    depth <- if (nchar(rel_path) == 0) 0 else length(strsplit(rel_path, "/")[[1]])
    return(if (depth == 0) "." else paste(rep("..", depth), collapse = "/"))
  }

  # Calculate depth based on filter and table type
  depth <- 1  # Default: one level deep (/venues/, /codecheckers/)

  if (table_details$is_reg_table) {
    # Register table pages are deeper
    if ("subcat" %in% names(table_details)) {
      # Three levels deep: /venues/journals/gigascience/
      depth <- 3
    } else {
      # Two levels deep: /codecheckers/0000-0001-2345-6789/
      depth <- 2
    }
  } else {
    # Non-register table pages (venue/codechecker lists)
    # Check if this is a venue type page (e.g., /venues/institutions/, /venues/journals/)
    if ("subcat" %in% names(table_details)) {
      # Two levels deep: /venues/institutions/, /venues/journals/, etc.
      depth <- 2
    }
    # Otherwise depth stays 1 for /venues/ or /codecheckers/
  }

  # Generate relative path
  if (depth == 0) {
    return(".")
  } else {
    return(paste(rep("..", depth), collapse = "/"))
  }
}
