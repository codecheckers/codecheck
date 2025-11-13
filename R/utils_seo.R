#' Generate sitemap.xml for the register
#'
#' Creates a sitemap.xml file listing all generated pages in the register
#' for search engine optimization and crawling.
#'
#' @param register_table The preprocessed register table with all entries
#' @param filter_by List of filters used (e.g., "venues", "codecheckers")
#' @param output_dir Output directory for the sitemap (default: "docs")
#' @param base_url Base URL for the register (default: from CONFIG)
#' @param lastmod Last modification date (default: current date in ISO 8601 format)
#'
#' @return Invisibly returns the path to the generated sitemap.xml
#' @export
generate_sitemap <- function(register_table,
                             filter_by = c("venues", "codecheckers"),
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

  # Codecheckers overview page
  if ("codecheckers" %in% filter_by) {
    urls[[length(urls) + 1]] <- list(
      loc = paste0(base_url, "/codecheckers/"),
      lastmod = lastmod,
      changefreq = "weekly",
      priority = "0.9"
    )

    # Individual codechecker pages
    if ("Codechecker" %in% names(register_table)) {
      # Unnest codecheckers list
      codecheckers_table <- register_table %>% tidyr::unnest(Codechecker)
      codecheckers <- unique(codecheckers_table$Codechecker)

      for (codechecker in codecheckers) {
        if (!is.na(codechecker) && codechecker != "NA" && codechecker != "") {
          urls[[length(urls) + 1]] <- list(
            loc = paste0(base_url, "/codecheckers/", codechecker, "/"),
            lastmod = lastmod,
            changefreq = "monthly",
            priority = "0.7"
          )
        }
      }
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

  message("Generated sitemap.xml with ", length(urls), " URLs at ", sitemap_path)
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

  message("Generated robots.txt at ", robots_path)
  invisible(robots_path)
}
