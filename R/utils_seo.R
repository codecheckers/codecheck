#' Generate the register's 404 page
#'
#' `docs/` is served as its own GitHub Pages project site (verified live:
#' `codecheck.org.uk/register/<anything>` returns GitHub's stock 404 today,
#' not the parent `codecheck.org.uk` site's Jekyll one), so a `docs/404.html`
#' here is what every missing path under `/register/` gets shown.
#'
#' Reuses [generate_navigation_header()] for the nav bar - the same markup
#' every other page's prefix uses - rather than duplicating it; there is no
#' pandoc render step here, this is a small hand-built page like a
#' codechecker/person redirect stub.
#'
#' @param output_dir Output directory (default: "docs")
#' @return Invisibly returns the path to the generated 404.html
#' @export
generate_404_page <- function(output_dir = "docs") {
  template_path <- system.file("extdata", "templates/general/404_template.html", package = "codecheck")
  template <- paste(readLines(template_path, warn = FALSE), collapse = "\n")

  nav_header_html <- generate_navigation_header(NA, ".", list())

  output <- whisker::whisker.render(template, list(nav_header_html = nav_header_html))

  page_path <- file.path(output_dir, "404.html")
  writeLines(output, page_path)

  cli::cli_alert_success("Generated 404 page at {.path {page_path}}")
  invisible(page_path)
}

#' Generate sitemap.xml for the register
#'
#' Creates a sitemap.xml file listing all generated pages in the register
#' for search engine optimization and crawling.
#'
#' @param register_table The preprocessed register table with all entries
#' @param filter_by List of filters used (e.g., "venues", "works", "persons")
#' @param output_dir Output directory for the sitemap (default: "docs")
#' @param base_url Base URL for the register (default: from CONFIG)
#' @param lastmod Last modification date (default: current date in ISO 8601 format)
#'
#' @return Invisibly returns the path to the generated sitemap.xml
#' @export
generate_sitemap <- function(register_table,
                             filter_by = c("venues", "works", "persons", "organisations"),
                             output_dir = "docs",
                             base_url = CONFIG$HYPERLINKS[["register"]],
                             lastmod = format(Sys.Date(), "%Y-%m-%d")) {

  # Remove trailing slash from base_url if present
  base_url <- sub("/$", "", base_url)

  # Initialize list of URLs
  urls <- list()

  # Main register page (highest priority)
  urls[[length(urls) + 1]] <- list(
    loc = paste0(base_url, "/"),
    lastmod = lastmod,
    changefreq = "weekly",
    priority = "1.0"
  )

  # Venues overview page
  if ("venues" %in% filter_by) {
    urls[[length(urls) + 1]] <- list(
      loc = paste0(base_url, "/venues/"),
      lastmod = lastmod,
      changefreq = "weekly",
      priority = "0.9"
    )

    # Venue type pages (journals, conferences, communities, institutions)
    venue_types <- unique(register_table$Type)
    for (venue_type in venue_types) {
      if (!is.na(venue_type)) {
        # Pluralize venue type
        venue_type_plural <- if (venue_type %in% names(CONFIG$VENUE_SUBCAT_PLURAL)) {
          CONFIG$VENUE_SUBCAT_PLURAL[[venue_type]]
        } else {
          paste0(venue_type, "s")
        }

        urls[[length(urls) + 1]] <- list(
          loc = paste0(base_url, "/venues/", venue_type_plural, "/"),
          lastmod = lastmod,
          changefreq = "monthly",
          priority = "0.8"
        )
      }
    }

    # Individual venue pages
    venues <- unique(register_table$Venue)
    for (venue in venues) {
      if (!is.na(venue)) {
        venue_entry <- register_table[register_table$Venue == venue, ][1, ]
        venue_type <- venue_entry$Type
        venue_type_plural <- if (venue_type %in% names(CONFIG$VENUE_SUBCAT_PLURAL)) {
          CONFIG$VENUE_SUBCAT_PLURAL[[venue_type]]
        } else {
          paste0(venue_type, "s")
        }
        venue_slug <- tolower(gsub(" ", "_", venue))

        urls[[length(urls) + 1]] <- list(
          loc = paste0(base_url, "/venues/", venue_type_plural, "/", venue_slug, "/"),
          lastmod = lastmod,
          changefreq = "monthly",
          priority = "0.7"
        )
      }
    }
  }

  # Works overview page (codecheckers/register#150)
  if ("works" %in% filter_by && "Work" %in% names(register_table)) {
    urls[[length(urls) + 1]] <- list(
      loc = paste0(base_url, "/works/"),
      lastmod = lastmod,
      changefreq = "weekly",
      priority = "0.9"
    )

    works <- unique(register_table$Work[!is.na(register_table$Work)])
    for (doi in works) {
      urls[[length(urls) + 1]] <- list(
        loc = paste0(base_url, "/works/", doi, "/"),
        lastmod = lastmod,
        changefreq = "monthly",
        priority = "0.7"
      )
    }
  }

  # Codecheckers overview page - kept only for explicit backward-compat use
  # of the "codecheckers" filter (e.g. an existing caller/test that still
  # asks for it directly); the default filter_by no longer includes it,
  # since #123's /persons/ pages replace /codecheckers/ in a normal render.
  if ("codecheckers" %in% filter_by) {
    urls[[length(urls) + 1]] <- list(
      loc = paste0(base_url, "/codecheckers/"),
      lastmod = lastmod,
      changefreq = "weekly",
      priority = "0.9"
    )

    if ("Codechecker" %in% names(register_table)) {
      codecheckers_table <- register_table %>% tidyr::unnest(Codechecker)
      codecheckers <- unique(codecheckers_table$Codechecker)

      for (codechecker in codecheckers) {
        if (!is.na(codechecker) && codechecker != "NA" && codechecker != "") {
          is_orcid <- grepl("^\\d{4}-\\d{4}-\\d{4}-\\d{3}[0-9X]$", codechecker)

          urls[[length(urls) + 1]] <- list(
            loc = paste0(base_url, "/codecheckers/", codechecker, "/"),
            lastmod = lastmod,
            changefreq = "monthly",
            priority = "0.7"
          )

          if (is_orcid) {
            profile <- get_codechecker_profile(codechecker)
            if (!is.null(profile) && !is.null(profile$github_handle)) {
              urls[[length(urls) + 1]] <- list(
                loc = paste0(base_url, "/codecheckers/", profile$github_handle, "/"),
                lastmod = lastmod,
                changefreq = "yearly",
                priority = "0.5"
              )
            }
          }
        }
      }
    }
  }

  # People overview page (codecheckers/register#123 - a full render lists
  # "persons" in filter_by instead of "codecheckers", see above; a person's
  # handle redirect at /persons/<handle>/ is a 404-page rule, not a sitemap
  # entry - see generate_404_page() - since it exists only to catch stray
  # inbound links, not to be discovered by a crawler).
  if ("persons" %in% filter_by && "Person" %in% names(register_table)) {
    urls[[length(urls) + 1]] <- list(
      loc = paste0(base_url, "/persons/"),
      lastmod = lastmod,
      changefreq = "weekly",
      priority = "0.9"
    )

    persons <- unique(unlist(lapply(register_table$Person, function(records) {
      vapply(records, function(r) r$orcid, character(1))
    })))

    for (orcid in persons) {
      urls[[length(urls) + 1]] <- list(
        loc = paste0(base_url, "/persons/", orcid, "/"),
        lastmod = lastmod,
        changefreq = "monthly",
        priority = "0.7"
      )
    }
  }

  # Organisation pages (register#53)
  if ("organisations" %in% filter_by && "Organisation" %in% names(register_table)) {
    urls[[length(urls) + 1]] <- list(
      loc = paste0(base_url, "/organisations/"),
      lastmod = lastmod,
      changefreq = "weekly",
      priority = "0.9"
    )

    organisations <- unique(unlist(lapply(register_table$Organisation, function(records) {
      vapply(records, function(r) r$ror, character(1))
    })))

    for (ror in organisations) {
      urls[[length(urls) + 1]] <- list(
        loc = paste0(base_url, "/organisations/", ror, "/"),
        lastmod = lastmod,
        changefreq = "monthly",
        priority = "0.7"
      )
    }
  }

  # Individual certificate pages
  for (i in seq_len(nrow(register_table))) {
    cert_id <- register_table[i, ]$`Certificate ID`
    if (!is.na(cert_id)) {
      urls[[length(urls) + 1]] <- list(
        loc = paste0(base_url, "/certs/", cert_id, "/"),
        lastmod = lastmod,
        changefreq = "yearly",
        priority = "0.6"
      )
    }
  }

  # Generate XML
  xml_lines <- c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  )

  for (url in urls) {
    xml_lines <- c(
      xml_lines,
      "  <url>",
      paste0("    <loc>", url$loc, "</loc>"),
      paste0("    <lastmod>", url$lastmod, "</lastmod>"),
      paste0("    <changefreq>", url$changefreq, "</changefreq>"),
      paste0("    <priority>", url$priority, "</priority>"),
      "  </url>"
    )
  }

  xml_lines <- c(xml_lines, "</urlset>")

  # Write sitemap.xml
  sitemap_path <- file.path(output_dir, "sitemap.xml")
  writeLines(xml_lines, sitemap_path)

  cli::cli_alert_success("Generated sitemap.xml with {length(urls)} URLs at {.path {sitemap_path}}")
  invisible(sitemap_path)
}

#' Generate robots.txt for the register
#'
#' Creates a robots.txt file that allows all search engines to crawl the register
#' and references the sitemap.xml file.
#'
#' @param output_dir Output directory for robots.txt (default: "docs")
#' @param base_url Base URL for the register (default: from CONFIG)
#'
#' @return Invisibly returns the path to the generated robots.txt
#' @export
generate_robots_txt <- function(output_dir = "docs",
                                base_url = CONFIG$HYPERLINKS[["register"]]) {

  # Remove trailing slash from base_url if present
  base_url <- sub("/$", "", base_url)

  # Generate robots.txt content
  robots_lines <- c(
    "# robots.txt for CODECHECK Register",
    "# Generated by codecheck R package",
    "",
    "User-agent: *",
    "Allow: /",
    "",
    paste0("Sitemap: ", base_url, "/sitemap.xml")
  )

  # Write robots.txt
  robots_path <- file.path(output_dir, "robots.txt")
  writeLines(robots_lines, robots_path)

  cli::cli_alert_success("Generated robots.txt at {.path {robots_path}}")
  invisible(robots_path)
}
