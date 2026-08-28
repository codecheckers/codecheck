#' Function for adding repository links in the register table for the creation of the json file.
#' 
#' @param register_table The register table
#' @return Register table with adjusted repository links
add_repository_links_json <- function(register_table) {
  register_table$`Repository Link` <- sapply(
    X = register_table$Repository,
    FUN = function(repository) {
      # ! Needs refactoring
      spec <- parse_repository_spec(repository)
      if (spec[["type"]] == "github") {
        paste0(CONFIG$HYPERLINKS[["github"]], spec[["repo"]])
      } else if (spec[["type"]] == "osf") {
        paste0(CONFIG$HYPERLINKS[["osf"]], spec[["repo"]])
      } else if (spec[["type"]] == "gitlab") {
        paste0(CONFIG$HYPERLINKS[["gitlab"]], spec[["repo"]])
      } else if (spec[["type"]] == "zenodo") {
        paste0(CONFIG$HYPERLINKS[["zenodo"]], spec[["repo"]])
      } else {
        repository
      }
    }
  )
  return(register_table)
}

#' Set "Title" and "Paper reference" columns and values to the register_table
#' 
#' @param register_table The register table
#' @return Updated register table including "Title" and "Paper reference" columns
set_paper_title_references <- function(register_table){
  titles <- c()
  references <- c()
  for (i in seq_len(nrow(register_table))) {
    config_yml <- get_codecheck_yml(register_table[i, ]$Repository)

    title <- NA
    reference <- NA
    if (!is.null(config_yml)) {
      title <- config_yml$paper$title
      reference <- config_yml$paper$reference
    }

    titles <- c(titles, title)
    references <- c(references, reference)
  }
  register_table$Title <- stringr::str_trim(titles)
  register_table$`Paper reference` <- stringr::str_trim(references)

  return(register_table)
}

#' Add certificate PDF download URLs to the register table
#'
#' Resolves report DOIs to direct PDF download URLs using get_cert_link().
#'
#' @param register_table The register table (must have "Report" and "Certificate ID" columns)
#' @return Register table with added "Certificate PDF" column
add_cert_pdf_links <- function(register_table) {
  register_table$`Certificate PDF` <- sapply(
    seq_len(nrow(register_table)),
    function(i) {
      # use [[ ]] on the column: [i, "col"] returns a 1x1 tibble for tibble-backed
      # tables (venue and type sub-tables), which downstream HTTP calls reject
      report <- register_table[["Report"]][[i]]
      cert_id <- register_table[["Certificate ID"]][[i]]
      if (is.na(report) || is.null(report) || nchar(report) == 0) {
        return(NA_character_)
      }
      tryCatch(
        {
          link <- get_cert_link(report, cert_id)
          if (is.null(link)) NA_character_ else link
        },
        error = function(e) {
          warning(cert_id, " | Could not resolve certificate PDF URL: ", e$message)
          NA_character_
        }
      )
    }
  )
  return(register_table)
}

#' Build a full metadata register from the preprocessed register table
#'
#' Enriches the register with all available fields from each codecheck.yml,
#' including paper authors, codechecker details, summary, and source.
#' Writes register-full.json and register-full.csv (addresses register#57).
#'
#' @param register_table The full preprocessed register table
#' @param output_dir The output directory (e.g., "docs/")
render_register_full <- function(register_table, output_dir) {
  cli::cli_alert_info("Generating full register export (register-full.json, register-full.csv)")

  n <- nrow(register_table)

  # JSON entries as list-of-lists (supports nested authors/codecheckers arrays)
  json_entries <- vector("list", n)
  # CSV columns as flat vectors (semicolon-separated for multi-value fields)
  csv_report <- rep(NA_character_, n)
  csv_title <- rep(NA_character_, n)
  csv_paper_ref <- rep(NA_character_, n)
  csv_paper_authors <- rep(NA_character_, n)
  csv_paper_author_orcids <- rep(NA_character_, n)
  csv_codecheckers <- rep(NA_character_, n)
  csv_codechecker_orcids <- rep(NA_character_, n)
  csv_summary <- rep(NA_character_, n)
  csv_source <- rep(NA_character_, n)
  csv_repo_links <- rep(NA_character_, n)

  for (i in seq_len(n)) {
    repo_spec <- register_table[i, "Repository"]

    # Repository link
    spec <- parse_repository_spec(repo_spec)
    hyperlink_key <- spec[["type"]]
    repo_link <- if (hyperlink_key %in% names(CONFIG$HYPERLINKS)) {
      paste0(CONFIG$HYPERLINKS[[hyperlink_key]], spec[["repo"]])
    } else {
      repo_spec
    }
    csv_repo_links[i] <- repo_link

    entry <- list(
      `Certificate ID` = register_table[i, "Certificate ID"],
      Repository = repo_spec,
      `Repository Link` = repo_link,
      Type = register_table[i, "Type"],
      Venue = register_table[i, "Venue"],
      `Check date` = if ("Check date" %in% names(register_table)) register_table[i, "Check date"] else NA_character_,
      OpenAlex = if ("OpenAlex" %in% names(register_table)) register_table[i, "OpenAlex"] else NA_character_
    )

    # Fetch full codecheck.yml metadata (cached from preprocessing)
    config_yml <- get_codecheck_yml(repo_spec)

    if (!is.null(config_yml)) {
      entry$Report <- config_yml$report %||% NA_character_
      csv_report[i] <- entry$Report
      entry$Title <- if (!is.null(config_yml$paper$title)) stringr::str_trim(config_yml$paper$title) else NA_character_
      csv_title[i] <- entry$Title
      entry$`Paper reference` <- if (!is.null(config_yml$paper$reference)) stringr::str_trim(config_yml$paper$reference) else NA_character_
      csv_paper_ref[i] <- entry$`Paper reference`

      # Paper authors as structured array for JSON
      if (!is.null(config_yml$paper$authors)) {
        entry$`Paper authors` <- lapply(config_yml$paper$authors, function(a) {
          obj <- list(name = a$name %||% NA_character_)
          if (!is.null(a$ORCID) && a$ORCID != "") obj$orcid <- a$ORCID
          obj
        })
        a_names <- vapply(config_yml$paper$authors, function(a) a$name %||% NA_character_, character(1))
        a_orcids <- vapply(config_yml$paper$authors, function(a) if (!is.null(a$ORCID) && a$ORCID != "") a$ORCID else NA_character_, character(1))
        csv_paper_authors[i] <- paste(a_names[!is.na(a_names)], collapse = "; ")
        orcids_valid <- a_orcids[!is.na(a_orcids)]
        csv_paper_author_orcids[i] <- if (length(orcids_valid) > 0) paste(orcids_valid, collapse = "; ") else NA_character_
      } else {
        entry$`Paper authors` <- list()
      }

      # Codecheckers as structured array for JSON
      if (!is.null(config_yml$codechecker)) {
        entry$Codecheckers <- lapply(config_yml$codechecker, function(cc) {
          obj <- list(name = cc$name %||% NA_character_)
          if (!is.null(cc$ORCID) && cc$ORCID != "") obj$orcid <- cc$ORCID
          obj
        })
        cc_names <- vapply(config_yml$codechecker, function(cc) cc$name %||% NA_character_, character(1))
        cc_orcids <- vapply(config_yml$codechecker, function(cc) if (!is.null(cc$ORCID) && cc$ORCID != "") cc$ORCID else NA_character_, character(1))
        csv_codecheckers[i] <- paste(cc_names[!is.na(cc_names)], collapse = "; ")
        cc_valid <- cc_orcids[!is.na(cc_orcids)]
        csv_codechecker_orcids[i] <- if (length(cc_valid) > 0) paste(cc_valid, collapse = "; ") else NA_character_
      } else {
        entry$Codecheckers <- list()
      }

      entry$Summary <- config_yml$summary %||% NA_character_
      csv_summary[i] <- entry$Summary
      entry$Source <- config_yml$source %||% NA_character_
      csv_source[i] <- entry$Source
    } else {
      entry$Report <- NA_character_
      entry$Title <- NA_character_
      entry$`Paper reference` <- NA_character_
      entry$`Paper authors` <- list()
      entry$Codecheckers <- list()
      entry$Summary <- NA_character_
      entry$Source <- NA_character_
    }

    json_entries[[i]] <- entry
  }

  # Sort by Certificate ID for consistent diffs (as requested in issue)
  cert_ids <- vapply(json_entries, function(e) e$`Certificate ID`, character(1))
  sort_order <- order(cert_ids)
  json_entries <- json_entries[sort_order]

  # Write JSON (list-of-lists preserves nested author/codechecker arrays)
  jsonlite::write_json(
    json_entries,
    path = file.path(output_dir, "register-full.json"),
    pretty = TRUE,
    auto_unbox = TRUE,
    na = "null"
  )

  # Write CSV (flat columns with semicolon-separated multi-value fields)
  csv_df <- data.frame(
    `Certificate ID` = register_table$`Certificate ID`,
    Repository = register_table$Repository,
    `Repository Link` = csv_repo_links,
    Type = register_table$Type,
    Venue = register_table$Venue,
    `Check date` = if ("Check date" %in% names(register_table)) register_table$`Check date` else NA_character_,
    Report = csv_report,
    Title = csv_title,
    `Paper reference` = csv_paper_ref,
    OpenAlex = if ("OpenAlex" %in% names(register_table)) register_table$OpenAlex else NA_character_,
    `Paper authors` = csv_paper_authors,
    `Paper author ORCIDs` = csv_paper_author_orcids,
    Codecheckers = csv_codecheckers,
    `Codechecker ORCIDs` = csv_codechecker_orcids,
    Summary = csv_summary,
    Source = csv_source,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  csv_df <- csv_df[sort_order, ]
  rownames(csv_df) <- NULL

  utils::write.csv(
    csv_df,
    file = file.path(output_dir, "register-full.csv"),
    row.names = FALSE,
    na = ""
  )

  cli::cli_alert_success("Written register-full.json and register-full.csv ({n} entries)")
}

#' Detect the publication platform from a report URL
#'
#' Extracts a human-readable platform name from the report URL's domain.
#' For doi.org URLs, resolves the DOI to determine the actual hosting platform.
#'
#' @param url A report URL string
#' @return A lowercase platform name (e.g., "zenodo", "osf", "researchequals")
detect_report_platform <- function(url) {
  # Known patterns (checked before any HTTP request)
  if (grepl("zenodo", url, ignore.case = TRUE)) return("zenodo")
  if (grepl("osf\\.io", url, ignore.case = TRUE)) return("osf")
  if (grepl("researchequals", url, ignore.case = TRUE)) return("researchequals")

  # For doi.org URLs, follow the redirect to find the actual platform
  if (grepl("doi\\.org/", url, ignore.case = TRUE)) {
    resolved <- tryCatch({
      resp <- codecheck_GET(url, httr::config(followlocation = FALSE))
      loc <- httr::headers(resp)[["location"]]
      if (!is.null(loc)) loc else url
    }, error = function(e) url)
    # Re-check known patterns on the resolved URL
    if (grepl("zenodo", resolved, ignore.case = TRUE)) return("zenodo")
    if (grepl("osf\\.io", resolved, ignore.case = TRUE)) return("osf")
    if (grepl("researchequals", resolved, ignore.case = TRUE)) return("researchequals")
    # Extract domain name as platform
    domain <- gsub("^https?://([^/]+).*", "\\1", resolved)
    domain <- gsub("^www\\.", "", domain)
    return(domain)
  }

  # Fallback: extract domain name
  domain <- gsub("^https?://([^/]+).*", "\\1", url)
  domain <- gsub("^www\\.", "", domain)
  return(domain)
}

#' Compute annual statistics from the register table
#'
#' Computes per-year breakdowns of checks, venues, codecheckers, and report
#' platforms. Used to enrich statistics.json (addresses register#144).
#'
#' @param register_table The full preprocessed register table (before column filtering)
#' @return A list of annual statistics
compute_annual_stats <- function(register_table) {
  stats <- list()

  if (!("Check date" %in% names(register_table))) {
    return(stats)
  }

  dates <- as.Date(register_table$`Check date`)
  years <- format(dates, "%Y")
  valid <- !is.na(years)
  all_years <- sort(unique(years[valid]))

  # --- Total venue count and per-type breakdown (addresses register#76) ---
  if ("Venue" %in% names(register_table)) {
    stats$venue_count <- length(unique(register_table$Venue[valid]))
    if ("Type" %in% names(register_table)) {
      type_vec <- register_table$Type[valid]
      venue_vec <- register_table$Venue[valid]
      # Count unique venues per type
      type_venue_df <- data.frame(type = type_vec, venue = venue_vec, stringsAsFactors = FALSE)
      venues_per_type <- tapply(type_venue_df$venue, type_venue_df$type, function(v) length(unique(v)))
      stats$venues_per_type <- as.list(venues_per_type[order(names(venues_per_type))])

      # --- Checks per year, per venue type (non-cumulative) ---
      yr_vec_type <- years[valid]
      type_year_df <- data.frame(year = yr_vec_type, type = type_vec, stringsAsFactors = FALSE)
      checks_per_type_per_year <- list()
      for (y in all_years) {
        sub <- type_year_df$type[type_year_df$year == y]
        if (length(sub) > 0) {
          checks_per_type_per_year[[y]] <- as.list(table(sub)[order(names(table(sub)))])
        }
      }
      stats$checks_per_type_per_year <- checks_per_type_per_year
    }
  }

  # --- Checks per year (annual + cumulative) ---
  checks_tbl <- table(years[valid])
  checks_sorted <- checks_tbl[all_years]
  stats$checks_per_year <- as.list(checks_sorted)

  cumulative_checks <- cumsum(as.integer(checks_sorted))
  names(cumulative_checks) <- all_years
  stats$checks_cumulative <- as.list(cumulative_checks)

  # --- Unique venues per year (annual + cumulative) ---
  if ("Venue" %in% names(register_table)) {
    venue_vec <- register_table$Venue[valid]
    yr_vec <- years[valid]

    venues_by_year <- tapply(venue_vec, yr_vec, function(v) length(unique(v)))
    stats$venues_per_year <- as.list(venues_by_year[all_years])

    # Cumulative: count unique venues seen up to and including each year
    venues_cumulative <- setNames(integer(length(all_years)), all_years)
    seen_venues <- character(0)
    for (y in all_years) {
      seen_venues <- unique(c(seen_venues, venue_vec[yr_vec == y]))
      venues_cumulative[y] <- length(seen_venues)
    }
    stats$venues_cumulative <- as.list(venues_cumulative)
  }

  # --- Unique codecheckers: total count + per year + cumulative (addresses register#77) ---
  if ("Codechecker" %in% names(register_table)) {
    checkers <- register_table$Codechecker[valid]
    yr <- years[valid]
    pairs <- do.call(rbind, lapply(seq_along(checkers), function(i) {
      cc <- checkers[[i]]
      if (is.null(cc) || all(is.na(cc))) return(NULL)
      data.frame(year = yr[i], codechecker = cc, stringsAsFactors = FALSE)
    }))
    if (!is.null(pairs) && nrow(pairs) > 0) {
      stats$codechecker_count <- length(unique(pairs$codechecker))
      codecheckers_by_year <- tapply(pairs$codechecker, pairs$year, function(cc) length(unique(cc)))
      stats$codecheckers_per_year <- as.list(codecheckers_by_year[all_years[all_years %in% names(codecheckers_by_year)]])

      # Cumulative unique codecheckers
      cc_years <- sort(unique(pairs$year))
      cc_cumulative <- setNames(integer(length(cc_years)), cc_years)
      seen_cc <- character(0)
      for (y in cc_years) {
        seen_cc <- unique(c(seen_cc, pairs$codechecker[pairs$year == y]))
        cc_cumulative[y] <- length(seen_cc)
      }
      stats$codecheckers_cumulative <- as.list(cc_cumulative)
    }
  }

  # --- Checks per platform per year (annual + cumulative) ---
  if ("Report" %in% names(register_table)) {
    report_vec <- register_table$Report[valid]
    yr_vec <- years[valid]
    has_report <- !is.na(report_vec) & nchar(report_vec) > 0

    platforms <- sapply(report_vec[has_report], function(url) {
      detect_report_platform(url)
    }, USE.NAMES = FALSE)
    plat_years <- yr_vec[has_report]

    # Per-year breakdown by platform
    plat_df <- data.frame(year = plat_years, platform = platforms, stringsAsFactors = FALSE)
    platform_by_year <- list()
    for (y in all_years) {
      sub <- plat_df$platform[plat_df$year == y]
      if (length(sub) > 0) {
        platform_by_year[[y]] <- as.list(table(sub)[order(names(table(sub)))])
      }
    }
    stats$platform_per_year <- platform_by_year

    # Cumulative by platform
    all_plats <- sort(unique(platforms))
    platform_cumulative <- list()
    running <- setNames(rep(0L, length(all_plats)), all_plats)
    for (y in all_years) {
      sub <- plat_df$platform[plat_df$year == y]
      if (length(sub) > 0) {
        yr_tbl <- table(sub)
        for (p in names(yr_tbl)) {
          running[p] <- running[p] + as.integer(yr_tbl[p])
        }
      }
      platform_cumulative[[y]] <- as.list(running)
    }
    stats$platform_cumulative <- platform_cumulative
  }

  # --- Per-venue detail (metadata + cert count) and publisher grouping
  # (addresses register#33, register#48) ---
  if ("Venue" %in% names(register_table) && !is.null(CONFIG$VENUE_DATA)) {
    venue_vec <- register_table$Venue[valid]
    cert_counts <- table(venue_vec)
    venue_data <- CONFIG$VENUE_DATA

    # The venue overview pages under docs/venues/ are grouped by each
    # certificate's own `Type` column (community/journal/conference/institution),
    # not by venues.csv's `label` (which can carry other values, e.g. "check-nl",
    # used only for the GitHub issue label). To link a venue card to its actual
    # rendered page, resolve the page's type/slug from `Type` the same way, using
    # each venue's most common Type in case of any drift between the two.
    page_type_by_venue <- NULL
    if ("Type" %in% names(register_table)) {
      type_vec <- register_table$Type[valid]
      page_type_by_venue <- tapply(type_vec, venue_vec, function(t) names(sort(table(t), decreasing = TRUE))[1])
    }

    # First/last year a certificate was checked for each venue, e.g. "2021" or
    # "2021-2024", shown on the venue card.
    year_range_by_venue <- tapply(years[valid], venue_vec, function(y) {
      yy <- sort(unique(y))
      if (length(yy) == 0) NA_character_
      else if (length(yy) == 1) yy[1]
      else paste0(yy[1], "-", yy[length(yy)])
    })

    venues_detail <- lapply(seq_len(nrow(venue_data)), function(i) {
      row <- venue_data[i, ]
      count <- if (row$name %in% names(cert_counts)) as.integer(cert_counts[[row$name]]) else 0L
      page_type <- if (!is.null(page_type_by_venue) && row$name %in% names(page_type_by_venue)) {
        page_type_by_venue[[row$name]]
      } else {
        NA_character_
      }
      year_range <- if (row$name %in% names(year_range_by_venue)) year_range_by_venue[[row$name]] else NA_character_
      list(
        name = row$name,
        longname = row$longname,
        year_range = year_range,
        label = row$label,
        cert_count = count,
        page_type = page_type,
        page_type_plural = if (!is.na(page_type) && page_type %in% names(CONFIG$VENUE_SUBCAT_PLURAL)) {
          CONFIG$VENUE_SUBCAT_PLURAL[[page_type]]
        } else {
          NA_character_
        },
        # generate_table_details() (utils_render_register_general.R) uses the
        # venue name as-is (not slugified/lowercased) for the actual output
        # directory under docs/venues/ - URL-encode it (spaces -> %20) for the href.
        page_slug = utils::URLencode(row$name),
        # NA_character_ rather than NULL: jsonlite serializes a NULL list element as
        # `{}`, while NA_character_ becomes proper JSON `null` - easier for any
        # consumer (including render_statistics_page()) to check for a missing value.
        logo_url = if (!is.null(row$logo_url) && !is.na(row$logo_url) && nchar(row$logo_url) > 0) row$logo_url else NA_character_,
        website_url = if (!is.null(row$website_url) && !is.na(row$website_url) && nchar(row$website_url) > 0) row$website_url else NA_character_,
        policy_url = if (!is.null(row$policy_url) && !is.na(row$policy_url) && nchar(row$policy_url) > 0) row$policy_url else NA_character_,
        publisher = if (!is.null(row$publisher) && !is.na(row$publisher) && nchar(row$publisher) > 0) row$publisher else NA_character_
      )
    })
    # Only keep venues actually used in this register slice
    venues_detail <- Filter(function(v) v$cert_count > 0, venues_detail)
    stats$venues_detail <- venues_detail

    if ("publisher" %in% names(venue_data)) {
      publisher_key <- vapply(venues_detail, function(v) {
        if (is.null(v$publisher) || is.na(v$publisher)) "unknown" else v$publisher
      }, character(1))
      split_venues <- split(venues_detail, publisher_key)
      publishers <- Map(function(pub_name, vs) {
        list(
          name = pub_name,
          venue_count = length(vs),
          cert_count = sum(vapply(vs, function(v) v$cert_count, integer(1)))
        )
      }, names(split_venues), split_venues)
      names(publishers) <- NULL
      stats$publishers <- publishers[order(vapply(publishers, function(p) p$name, character(1)))]
    }
  }

  return(stats)
}

#' Renders register json for a single register_table
#'
#' @param register_table The register table
#' @param table_details List containing details such as the table name, subcat name.
#' @param filter The filter
#' @param full_register_table Optional full preprocessed register table for computing
#'   annual statistics (only used for the main register statistics.json)
render_register_json <- function(register_table, table_details, filter, full_register_table = NULL) {
  register_table_json <- add_repository_links_json(register_table)

  # Set paper titles and references
  register_table_json <- set_paper_title_references(register_table_json)

  # Add certificate PDF download URLs (resolves report DOIs, addresses register#87)
  register_table_json <- add_cert_pdf_links(register_table_json)

  output_dir <- table_details[["output_dir"]]

  # Keeping only those columns that are mentioned in the json columns and those that
  # register table already has
  columns_to_keep <- intersect(CONFIG$JSON_COLUMNS, names(register_table_json))

  # Main register.json: sorted by certificate identifier (done in render_register())
  jsonlite::write_json(
    register_table_json[, columns_to_keep],
    path = file.path(output_dir, "register.json"),
    pretty = TRUE,
    na = "null"
  )

  # featured.json: sorted by check date (most recent first)
  # (addresses codecheckers/register#160)
  featured_table <- register_table_json
  if ("Check date" %in% names(featured_table)) {
    featured_table <- featured_table %>% arrange(desc(`Check date`))
  }
  jsonlite::write_json(
    utils::head(featured_table, CONFIG$FEATURED_COUNT)[, columns_to_keep],
    path = file.path(output_dir, "featured.json"),
    pretty = TRUE,
    na = "null"
  )

  stats_data <- list(
    source = generate_href(filter, table_details, "json"),
    cert_count = nrow(register_table_json)
  )

  # Add the venue's structured metadata (the same information shown on its
  # landing page's metadata panel, via the shared get_venue_metadata_fields())
  # for individual venue pages (addresses register#183).
  is_venue_page <- filter == "venues" && isTRUE(table_details[["is_reg_table"]]) &&
    !is.null(table_details[["name"]]) && !is.na(table_details[["name"]])
  if (is_venue_page) {
    venue_row <- lookup_venue_row(table_details[["name"]])
    fields <- get_venue_metadata_fields(venue_row, table_details[["subcat"]])
    nullable <- function(x) if (is.null(x)) NA_character_ else x
    stats_data$venue <- list(
      name = table_details[["name"]],
      longname = if ("longname" %in% names(venue_row)) venue_row[["longname"]][1] else NA_character_,
      venue_type = fields$venue_type,
      logo_url = fields$logo_url,
      website_url = fields$website_url,
      contact_name = fields$contact_name,
      contact_email = fields$contact_email,
      description = fields$description,
      identifiers = lapply(fields$identifiers, function(i) list(
        name = i$name,
        icon = nullable(i$icon),
        value = i$value,
        url = nullable(i$link)
      ))
    )
  }

  # Add annual statistics for the main register (addresses register#144).
  # Named statistics.json rather than stats.json for this one file - it is the
  # file the statistics dashboard (render_statistics_page()) reads and links
  # to, so its name should match the page's. Sub-register files (per venue,
  # per codechecker) carry no annual breakdown and are not read by that page,
  # so they keep the shorter stats.json name.
  is_main_register <- !is.null(full_register_table)
  if (is_main_register) {
    annual <- compute_annual_stats(full_register_table)
    stats_data <- c(stats_data, annual)
  }
  # A venue page's file carries structured venue metadata (name, type,
  # contact, description, identifiers, ...) alongside cert_count/source, not
  # just statistics - index.json (matching index.html) rather than
  # stats.json/statistics.json (addresses register#84 followup).
  stats_filename <- if (is_venue_page) {
    "index.json"
  } else if (is_main_register) {
    "statistics.json"
  } else {
    "stats.json"
  }

  jsonlite::write_json(
    stats_data,
    auto_unbox = TRUE,
    path = file.path(output_dir, stats_filename),
    pretty = TRUE,
    na = "null"
  )
}
