#' Generate navigation header with logo and menu
#'
#' Creates a header navigation bar with CODECHECK logo and optional menu.
#' Logo links to register home. Menu appears on main register and overview pages.
#'
#' @param filter The filter type (NA for main register, "venues", "codecheckers", etc.)
#' @param base_path Relative path to register root for logo link
#' @param table_details List containing page metadata to determine if it's an overview page
#'
#' @return HTML string with navigation header
#' @export
generate_navigation_header <- function(filter = NA, base_path = ".", table_details = list()) {

  # Logo always links to register home
  logo_link <- paste0(base_path, "/index.html")

  # Menu shown on:
  # - Main register page (is.na(filter))
  # - Venues overview page (filter == "venues" && !table_details$is_reg_table)
  # - Codecheckers overview page (filter == "codecheckers" && !table_details$is_reg_table)
  show_menu <- FALSE
  if (is.na(filter)) {
    show_menu <- TRUE
  } else if (filter %in% c("venues", "codecheckers")) {
    # Check if this is an overview page (not a specific venue/codechecker page)
    is_overview <- !isTRUE(table_details$is_reg_table)
    show_menu <- is_overview
  }

  menu_html <- ""
  if (show_menu) {
    # Calculate paths relative to base_path
    if (base_path == ".") {
      venues_path <- "venues/index.html"
      codecheckers_path <- "codecheckers/index.html"
    } else {
      venues_path <- paste0(base_path, "/venues/index.html")
      codecheckers_path <- paste0(base_path, "/codecheckers/index.html")
    }

    menu_html <- paste0('
    <nav class="navbar-menu">
      <a href="', venues_path, '" class="nav-link">All Venues</a>
      <a href="', codecheckers_path, '" class="nav-link">All Codecheckers</a>
      <a href="https://codecheck.org.uk/" class="nav-link">About</a>
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
    '    <a href="', logo_link, '" class="navbar-brand">\n',
    '      <img src="', logo_path, '" alt="CODECHECK" class="navbar-logo">\n',
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

    if (!table_details$is_reg_table) {
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
  }

  # Generate Bootstrap breadcrumb HTML
  html <- '<nav aria-label="breadcrumb" style="margin-bottom: 1.5rem;">\n'
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
  }

  # Generate relative path
  if (depth == 0) {
    return(".")
  } else {
    return(paste(rep("..", depth), collapse = "/"))
  }
}
