#' Whether a `from`/`to` range covers a whole register, in either direction
#'
#' `register_render()`'s `register[(from:to),]` accepts `from`/`to` in either
#' direction (newest-first or oldest-first, as `register_check()` also
#' supports, see codecheckers/codecheck#79), so a full run is either
#' `from = 1, to = n` or `from = n, to = 1` - checking only the first would
#' wrongly treat a newest-first full run as partial and skip [prune_libs()].
#'
#' @param from The `from` argument as passed to `register_render()`
#' @param to The `to` argument as passed to `register_render()`
#' @param n Number of rows in the (unsubset) register
#'
#' @return `TRUE` if `from`/`to` covers every row of the register
#' @keywords internal
is_full_register_run <- function(from, to, n) {
  (isTRUE(from == 1) && isTRUE(to == n)) || (isTRUE(from == n) && isTRUE(to == 1))
}

#' Function for rendering the register into different view
#'
#' NOTE: You should put a GitHub API token in the environment variable `GITHUB_PAT` to fix rate limits. Acquire one at see https://github.com/settings/tokens.
#'
#' - `.html`
#' - `.md``
#'
#' @param register A `data.frame` with all required information for the register's view
#' @param filter_by The filter or list o filters (if applicable)
#' @param outputs The output formats to create
#' @param config A list of configuration files to be sourced at the beginning of the rending process
#' @param venues_file Path to the venues.csv file containing venue names and labels
#' @param codecheck_repo_path Optional path to the codecheck package repository for build metadata (default: NULL)
#' @param from The first register entry to check
#' @param to The last register entry to check
#' @param parallel Logical; if TRUE, renders certificates in parallel using multiple cores. Defaults to FALSE.
#' @param ncores Integer; number of CPU cores to use for parallel rendering. If NULL, automatically detects available cores minus 1. Defaults to NULL.
#' @param verbose Logical; if TRUE, shows detailed output including pandoc commands from rmarkdown::render(). Defaults to FALSE.
#' @param check_zenodo_policy Logical; if TRUE (the default), audits all Zenodo-hosted certificates against the CODECHECK community curation policy after rendering and reports the findings on the console. Never fails a render. Results are cached, so only a cold render pays for the extra requests; set to FALSE to skip them entirely.
#' @param check_researchequals_policy Logical; if TRUE (the default), audits all certificates published on ResearchEquals against the CODECHECK curation policy after rendering, including membership in the CODECHECK collection and, for AGILEGIS certificates, in the Reproducible AGILE collection, and reports the findings on the console. Never fails a render. Results are cached like the Zenodo ones; set to FALSE to skip them entirely.
#' @param prune_unreferenced_libs Logical; if TRUE (the default), removes directories under `docs/libs` that no rendered HTML file references any more (see [prune_libs()] and codecheckers/codecheck#89) once rendering finishes. Only actually runs after a complete, unfiltered render (`from`/`to` covering the whole register) with no certificate failures; otherwise the step is skipped with a message, since a partial render can leave HTML that still references a directory this would delete.
#' @param prune_unavailable_metadata Logical; if TRUE, a certificate's OpenAlex ID or abstract that this render's live lookup conclusively confirms is no longer available (as opposed to a lookup that simply failed - network error, rate limit) is actually removed from the rendered output. Defaults to FALSE: such a confirmed absence is more often a query problem than a real removal upstream, so by default the previously rendered value is kept, and a lookup failure never removes anything regardless of this flag. See [resolve_external_field()].
#'
#' @return A `data.frame` of the register enriched with information from the configuration files of respective CODECHECKs from the online repositories
#'
#' @author Daniel Nuest
#' @importFrom parsedate parse_date
#' @importFrom rmarkdown render
#' @importFrom knitr kable
#' @importFrom utils capture.output read.csv tail packageVersion
#' @importFrom cli cli_h1 cli_h2 cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger cli_progress_bar cli_progress_update cli_progress_done
#' @import     jsonlite
#' @import     dplyr
#'
#' @export
register_render <- function(register = read.csv("register.csv", as.is = TRUE, comment.char = '#'),
                            filter_by = c("venues", "codecheckers"),
                            outputs = c("html", "md", "json"),
                            config = c(system.file("extdata", "config.R", package = "codecheck")),
                            venues_file = "venues.csv",
                            codecheck_repo_path = NULL,
                            from = 1,
                            to = nrow(register),
                            parallel = FALSE,
                            ncores = NULL,
                            verbose = FALSE,
                            check_zenodo_policy = TRUE,
                            check_researchequals_policy = TRUE,
                            prune_unreferenced_libs = TRUE,
                            prune_unavailable_metadata = FALSE) {
  cli::cli_h1("CODECHECK Register Rendering")
  cli::cli_alert_info("codecheck v{utils::packageVersion('codecheck')} | entries {from} to {to}")

  # rmarkdown versions the header-attrs HTML dependency with
  # packageVersion("rmarkdown"), so its directory name in docs/libs changes on
  # every rmarkdown release even though the file itself never does, and the
  # script is a no-op on the register's output (no `div.section` markup). See
  # https://github.com/codecheckers/codecheck/issues/89
  old_opts <- options(rmarkdown.html_dependency.header_attr = FALSE)
  on.exit(options(old_opts), add = TRUE)

  # Whether this is a complete, unfiltered render; prune_libs() must only run
  # after one of these, since a partial render can leave HTML that still
  # references a directory it would otherwise delete.
  full_run <- is_full_register_run(from, to, nrow(register))
  render_result <- NULL

  # Capture all warnings so they can be shown as structured log entries at the
  # end, rather than R's default "There were N warnings" prompt.
  captured_warnings <- character(0)

  register_table <- withCallingHandlers(
    {
      # Loading config.R files (creates CONFIG environment)
      for (i in seq(length(config))) {
        source(config[i])
      }

      # Store verbosity setting in CONFIG for use by all rendering functions
      # (must be after config sourcing, which creates the CONFIG environment)
      CONFIG$VERBOSE <- verbose
      CONFIG$PRUNE_UNAVAILABLE_METADATA <- prune_unavailable_metadata

      # Load venues configuration
      load_venues_config(venues_file)

      # Setup external libraries locally (Bootstrap, Font Awesome, Academicons, etc.)
      setup_external_libraries()

      # Copy package JavaScript files (citation.js, cert-utils.js, etc.)
      copy_package_javascript()

      cli::cli_alert_info("Cache path: {.path {R.cache::getCacheRootPath()}}")

      # Get build metadata for footer and meta tags
      build_metadata <- get_build_metadata(".", codecheck_repo_path)
      CONFIG$BUILD_METADATA <- build_metadata

      register <- register[(from:to),]

      register_table <- preprocess_register(register, filter_by)
      # Setting number of codechecks now for later use. This is done to avoid double counting codechecks
      # done by multiple authors.
      CONFIG$NO_CODECHECKS <- nrow(register_table)

      if("html" %in% outputs) {
        render_result <- render_cert_htmls(register_table, force_download = FALSE, parallel = parallel, ncores = ncores)
      }

      create_filtered_reg_csvs(register_table, filter_by)
      create_register_files(register_table, filter_by, outputs)
      create_non_register_files(register_table, filter_by)

      # Render the statistics dashboard (addresses register#33, register#48).
      # Reads the docs/statistics.json just written above, so must run after it.
      if ("html" %in% outputs) {
        tryCatch(
          render_statistics_page("docs"),
          error = function(e) cli::cli_alert_warning("Could not render statistics page: {conditionMessage(e)}")
        )
      }

      # Generate redirect pages for codecheckers with ORCID
      if ("codecheckers" %in% filter_by) {
        generate_codechecker_redirects(register_table)
      }

      # Generate redirect page for /certs/ (without certificate ID)
      generate_certs_redirect()

      # Write build metadata JSON file
      write_meta_json(build_metadata, "docs")

      # Generate SEO files (sitemap.xml and robots.txt)
      generate_sitemap(register_table, filter_by, output_dir = "docs")
      generate_robots_txt(output_dir = "docs")

      register_table
    },
    warning = function(w) {
      captured_warnings <<- c(captured_warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  # Display captured warnings as structured log entries
  if (length(captured_warnings) > 0) {
    # Deduplicate with counts: show each unique warning once, with [xN] prefix if repeated
    warn_table <- sort(table(captured_warnings), decreasing = TRUE)
    cli::cli_h2("{length(captured_warnings)} warning{?s} ({length(warn_table)} unique)")
    for (msg in names(warn_table)) {
      count <- warn_table[[msg]]
      if (count > 1) {
        cli::cli_alert_warning("[x{count}] {msg}")
      } else {
        cli::cli_alert_warning("{msg}")
      }
    }
  }

  # Audit the Zenodo records against the community curation policy. This is a
  # maintainer signal only: a finding, an outage or an unexpected error here
  # must never fail a render that otherwise succeeded.
  if (check_zenodo_policy) {
    tryCatch({
      report_zenodo_policy_findings(check_register_zenodo_policy(register_table))
    }, error = function(e) {
      cli::cli_alert_info("Could not run the Zenodo curation policy check: {conditionMessage(e)}")
    })
  }

  # The same audit for the certificates published on ResearchEquals, whose
  # counterpart of the Zenodo community is the CODECHECK collection.
  if (check_researchequals_policy) {
    tryCatch({
      report_researchequals_policy_findings(
        check_register_researchequals_policy(register_table))
    }, error = function(e) {
      cli::cli_alert_info("Could not run the ResearchEquals curation policy check: {conditionMessage(e)}")
    })
  }

  # Prune docs/libs directories no HTML file references any more (#89). Only
  # safe after a complete, unfiltered render with no certificate failures -
  # see prune_libs()'s documentation for why.
  no_failures <- is.null(render_result) || render_result$failures == 0
  if (prune_unreferenced_libs && full_run && no_failures) {
    tryCatch(
      prune_libs(),
      error = function(e) cli::cli_alert_warning("Could not prune docs/libs: {conditionMessage(e)}")
    )
  } else if (prune_unreferenced_libs) {
    cli::cli_alert_info("Skipping docs/libs pruning: not a complete, failure-free render")
  }

  cli::cli_alert_success("Register rendering complete")
  invisible(register_table)
}

#' Render a single certificate page by its ID
#'
#' Re-renders the HTML page and JSON metadata for one specific certificate
#' without modifying any index or list pages. Useful for updating a single
#' certificate after its PDF or metadata has changed, without a full
#' register re-render.
#'
#' @param cert_id Character string with the certificate identifier (e.g., "2024-017").
#' @param register A \code{data.frame} of the register, or a path to the register CSV file.
#'   Defaults to reading \code{"register.csv"} from the working directory.
#' @param config A character vector of configuration file paths to source.
#'   Defaults to the package's built-in \code{config.R}.
#' @param venues_file Path to the venues.csv file containing venue names and labels.
#' @param force_download Logical; if TRUE, forces re-download of certificate PDF
#'   even if it already exists locally. Defaults to TRUE.
#' @param download_and_convert Logical; if TRUE, downloads and converts the
#'   certificate PDF to PNG images. Defaults to TRUE.
#' @param verbose Logical; if TRUE, shows detailed output including pandoc
#'   commands from rmarkdown::render(). Defaults to FALSE.
#' @param prune_unavailable_metadata Logical; see [register_render()]. Defaults to FALSE.
#'
#' @return The certificate ID (invisibly).
#'
#' @examples
#' \dontrun{
#'   register_render_cert("2024-017")
#'   register_render_cert("2024-017", force_download = FALSE)
#' }
#'
#' @author Daniel Nuest
#' @export
register_render_cert <- function(cert_id,
                                 register = read.csv("register.csv", as.is = TRUE, comment.char = '#'),
                                 config = c(system.file("extdata", "config.R", package = "codecheck")),
                                 venues_file = "venues.csv",
                                 force_download = TRUE,
                                 download_and_convert = TRUE,
                                 verbose = FALSE,
                                 prune_unavailable_metadata = FALSE) {
  cli::cli_h1("CODECHECK Render Certificate {cert_id}")

  # See register_render() for why (codecheckers/codecheck#89).
  old_opts <- options(rmarkdown.html_dependency.header_attr = FALSE)
  on.exit(options(old_opts), add = TRUE)

  # Load register from file path if a string was provided
  if (is.character(register) && length(register) == 1 && !is.data.frame(register)) {
    if (!file.exists(register)) {
      stop("Register file not found: ", register)
    }
    register <- read.csv(register, as.is = TRUE, comment.char = '#')
  }

  # Look up cert_id in the register
  cert_row <- register[register$Certificate == cert_id, ]
  if (nrow(cert_row) == 0) {
    stop("Certificate '", cert_id, "' not found in register")
  }
  if (nrow(cert_row) > 1) {
    warning("Multiple entries for '", cert_id, "' in register; using the first")
    cert_row <- cert_row[1, ]
  }

  repo_link <- cert_row$Repository
  cert_type <- cert_row$Type
  cert_venue <- cert_row$Venue

  # Load configuration
  for (i in seq_along(config)) {
    source(config[i])
  }
  CONFIG$VERBOSE <- verbose
  CONFIG$PRUNE_UNAVAILABLE_METADATA <- prune_unavailable_metadata

  # Load venues configuration
  load_venues_config(venues_file)

  # Setup shared libraries (needed for HTML rendering)
  setup_external_libraries()
  copy_package_javascript()

  cli::cli_alert_info("Repository: {repo_link}")
  cli::cli_alert_info("Type: {cert_type} | Venue: {cert_venue}")

  start_time <- Sys.time()

  # Download and convert certificate PDF
  download_cert_status <- 0
  if (download_and_convert) {
    config_yml <- get_codecheck_yml(repo_link)
    report_link <- config_yml$report

    pdf_path <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id, "cert.pdf")
    pdf_exists <- file.exists(pdf_path)

    if (!pdf_exists || force_download) {
      download_cert_status <- tryCatch(
        download_cert_pdf(report_link, cert_id),
        error = function(e) {
          cli::cli_alert_warning("{cert_id} | Error downloading PDF: {e$message}")
          0
        }
      )

      if (download_cert_status == 1) {
        conversion <- convert_cert_pdf_to_png(cert_id)
        if (!conversion$success) {
          cli::cli_alert_danger("{cert_id} | PDF could not be converted: {conversion$error} - inspect {.path {pdf_path}}")
        } else if (length(conversion$fatal) > 0) {
          cli::cli_alert_danger("{cert_id} | PDF could not be fully parsed ({paste(conversion$fatal, collapse = '; ')}) - inspect {.path {pdf_path}}")
        } else if (conversion$cosmetic_count > 0) {
          cli::cli_alert_info("{cert_id} | Suppressed {conversion$cosmetic_count} cosmetic poppler warning{?s}")
        }
      }
    } else {
      download_cert_status <- 1
      cli::cli_alert_info("PDF already exists, skipping download (use force_download = TRUE to re-download)")
    }
  }

  # Render HTML page and JSON metadata
  render_cert_html(cert_id, repo_link, download_cert_status, cert_type, cert_venue)

  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  cli::cli_alert_success("Certificate {cert_id} rendered in {sprintf('%.1f', elapsed)}s")
  cli::cli_alert_info("Output: {.path {file.path(CONFIG$CERTS_DIR[['cert']], cert_id, 'index.html')}}")

  invisible(cert_id)
}

#' Regenerate all statistics files from existing register.json files
#'
#' Fast alternative to a full re-render when only the stats computation has
#' changed. Reads the already-generated register.json files under `docs/` and
#' rewrites `docs/statistics.json` (the main register's file, read by
#' [render_statistics_page()]) and every sub-register's `stats.json`
#' (`index.json` for a venue, which also gets its structured venue metadata),
#' with up-to-date statistics (including annual and cumulative breakdowns for
#' the main file).
#'
#' @param docs_dir Path to the docs output directory (default: "docs")
#' @param config Path to the config.R file
#' @param venues_file Path to the venues.csv file containing venue names, labels
#'   and optional metadata (logo_url, website_url, policy_url, publisher)
#'
#' @author Daniel Nuest
#' @export
register_update_stats <- function(docs_dir = "docs",
                                  config = system.file("extdata", "config.R", package = "codecheck"),
                                  venues_file = "venues.csv") {
  cli::cli_h1("CODECHECK Stats Update")
  source(config)
  load_venues_config(venues_file)

  main_json_path <- file.path(docs_dir, "register.json")
  if (!file.exists(main_json_path)) {
    stop("No register.json found at ", main_json_path, ". Run register_render() first.")
  }

  # --- Main register stats ---
  main_data <- jsonlite::fromJSON(main_json_path)
  stats_data <- list(
    source = paste0(CONFIG$HREF_DETAILS$json$base_url, "register", CONFIG$HREF_DETAILS$json$ext),
    cert_count = nrow(main_data)
  )
  annual <- compute_annual_stats(main_data)
  stats_data <- c(stats_data, annual)

  # Add codechecker_count from codecheckers index.json if available (addresses register#77)
  cc_index_path <- file.path(docs_dir, "codecheckers", "index.json")
  if (is.null(stats_data$codechecker_count) && file.exists(cc_index_path)) {
    cc_index <- tryCatch(jsonlite::fromJSON(cc_index_path), error = function(e) NULL)
    if (!is.null(cc_index)) {
      stats_data$codechecker_count <- nrow(cc_index)
    }
  }

  jsonlite::write_json(stats_data, auto_unbox = TRUE,
                       path = file.path(docs_dir, "statistics.json"), pretty = TRUE)
  cli::cli_alert_success("Updated {.path {file.path(docs_dir, 'statistics.json')}} ({nrow(main_data)} certs)")

  # --- Sub-register stats (venues, codecheckers, etc.) ---
  sub_jsons <- list.files(docs_dir, pattern = "^register\\.json$",
                          recursive = TRUE, full.names = TRUE)
  # Exclude the main register.json already handled above (normalize both sides)
  main_norm <- normalizePath(main_json_path, mustWork = FALSE)
  sub_jsons <- sub_jsons[normalizePath(sub_jsons, mustWork = FALSE) != main_norm]

  updated <- 0L
  for (json_path in sub_jsons) {
    sub_dir <- dirname(json_path)
    sub_data <- tryCatch(jsonlite::fromJSON(json_path), error = function(e) NULL)
    if (is.null(sub_data) || nrow(sub_data) == 0) next

    # Reconstruct the source URL from the relative path under docs/
    rel_path <- gsub(paste0("^", gsub("([.\\\\])", "\\\\\\1", docs_dir), "/?"), "", sub_dir)
    source_url <- paste0(CONFIG$HREF_DETAILS$json$base_url, rel_path, "/register.json")

    sub_stats <- list(
      source = source_url,
      cert_count = nrow(sub_data)
    )

    # A venue's file carries structured venue metadata alongside
    # cert_count/source, not just statistics - index.json rather than
    # stats.json (matching the full render path, addresses register#84
    # followup). The venue-specific register.json view drops the
    # (redundant, on that page) Venue/Type columns, so the venue's name and
    # type are recovered from the path instead: docs/venues/<type_plural>/<slug>.
    path_parts <- strsplit(rel_path, "/", fixed = TRUE)[[1]]
    is_venue_dir <- length(path_parts) == 3 && path_parts[1] == "venues"
    stats_filename <- "stats.json"
    if (is_venue_dir) {
      type_plural <- path_parts[2]
      slug <- path_parts[3]
      venue_type <- names(CONFIG$VENUE_SUBCAT_PLURAL)[
        vapply(CONFIG$VENUE_SUBCAT_PLURAL, identical, logical(1), type_plural)
      ]
      venue_type <- if (length(venue_type) > 0) venue_type[1] else NA_character_
      # Recover the venues.csv-cased name from the lowercased slug
      # (register#192); fall back to the slug itself for a venue not (yet)
      # listed in venues.csv.
      venue_name <- slug
      if (exists("VENUE_DATA", envir = CONFIG) && !is.null(CONFIG$VENUE_DATA)) {
        candidate_slugs <- gsub(" ", "_", tolower(CONFIG$VENUE_DATA$name))
        match_idx <- which(candidate_slugs == tolower(slug))
        if (length(match_idx) > 0) venue_name <- CONFIG$VENUE_DATA$name[match_idx[1]]
      }

      venue_row <- lookup_venue_row(venue_name)
      fields <- get_venue_metadata_fields(venue_row, venue_type)
      nullable <- function(x) if (is.null(x)) NA_character_ else x
      sub_stats$venue <- list(
        name = venue_name,
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
      stats_filename <- "index.json"
    }

    jsonlite::write_json(sub_stats, auto_unbox = TRUE,
                         path = file.path(sub_dir, stats_filename), pretty = TRUE, na = "null")
    updated <- updated + 1L
  }

  cli::cli_alert_success("Updated {updated} sub-register stats.json/index.json files")

  tryCatch(
    render_statistics_page(docs_dir),
    error = function(e) cli::cli_alert_warning("Could not render statistics page: {conditionMessage(e)}")
  )
}

#' Function for checking all entries in the register
#'
#' This functions starts of a `data.frame` read from the local register file.
#'
#' **Note**: The validation of `codecheck.yml` files happens in function `validate_codecheck_yml()`.
#' Certificate IDs must also be unique across the whole register; this is checked
#' once up front, over all rows, before any per-entry checks run.
#'
#' Also checks the checked repository itself: organisation membership
#' (`check_repository_org()`), archived status (`check_repository_archived()`),
#' CODECHECK badge presence (`check_repository_badge()`), license presence
#' (`check_repository_license()`) and the `codecheck` topic tag
#' (`check_repository_topic()`).
#'
#' By default entries are checked newest-first (`from` defaults to the last
#' row, `to` to the first): problems are more likely to appear in recent
#' checks and certificates than in old, already-vetted ones, so breaking
#' issues surface earlier in a full-register run (closes #79). Pass
#' `from = 1, to = nrow(register)` to check oldest-first instead.
#'
#' @param register A `data.frame` with all required information for the register's view
#' @param from The first register entry to check (defaults to the last row, i.e. the newest entry)
#' @param to The last register entry to check (defaults to the first row, i.e. the oldest entry)
#' @param check_zenodo_policy Logical; if TRUE (the default), also audits the Zenodo records against the CODECHECK community curation policy
#' @param check_researchequals_policy Logical; if TRUE (the default), also audits the certificates published on ResearchEquals against the CODECHECK curation policy, including membership in the CODECHECK collection and, for AGILEGIS certificates, in the Reproducible AGILE collection
#'
#' @author Daniel Nuest
#' @importFrom R.cache getCacheRootPath
#' @importFrom utils packageVersion
#' @importFrom gh gh
#' @export
register_check <- function(register = read.csv("register.csv", as.is = TRUE, comment.char = '#'),
                           from = nrow(register),
                           to = 1,
                           check_zenodo_policy = TRUE,
                           check_researchequals_policy = TRUE) {
  cli::cli_h1("CODECHECK Register Check")
  cli::cli_alert_info("codecheck v{utils::packageVersion('codecheck')} | entries {from} to {to}")

  # Loading config.R file
  source(system.file("extdata", "config.R", package = "codecheck"))

  cli::cli_alert_info("Cache path: {.path {R.cache::getCacheRootPath()}}")

  # certificate IDs must be unique across the whole register, see #9; checked
  # once up front over all rows, not just the from:to range being audited
  dup <- duplicated(register$Certificate) | duplicated(register$Certificate, fromLast = TRUE)
  if (any(dup)) {
    stop("Duplicate certificate ID(s) in register: ",
         toString(unique(register$Certificate[dup])))
  }

  # The raw register has no Report column, the report DOI comes from each
  # codecheck.yml, so collect it while the configurations are being read anyway.
  # The platform-specific policy checks pick their own entries from this table.
  report_entries <- list()

  for (i in seq(from = from, to = to)) {
    cat("Checking", toString(register[i, ]), "\n")
    entry <- register[i, ]

    # repository-level checks: org membership (fail), archived status
    # (warning), badge and license presence (info)
    spec <- tryCatch(parse_repository_spec(entry$Repository), error = function(e) NULL)
    if (!is.null(spec)) {
      check_repository_org(entry, spec)
      check_repository_archived(entry, spec)
      check_repository_badge(entry, spec)
      check_repository_license(entry, spec)
      check_repository_topic(entry, spec)
    }

    # check certificate IDs if there is a codecheck.yml
    codecheck_yaml <- get_codecheck_yml(entry$Repository)
    check_certificate_id(entry, codecheck_yaml)
    check_issue_status(entry)

    if (!is.null(codecheck_yaml) && !is.null(codecheck_yaml$report)) {
      report_entries[[length(report_entries) + 1]] <- data.frame(
        Certificate = as.character(entry$Certificate),
        Report = as.character(codecheck_yaml$report),
        # the ResearchEquals policy check needs the venue: the Reproducible
        # AGILE collection is only required for AGILEGIS certificates
        Venue = if (!is.null(entry$Venue)) as.character(entry$Venue) else NA_character_,
        stringsAsFactors = FALSE)
    }

    cat("Completed checking registry entry", toString(register[i, "Certificate"]), "\n")
  }

  reports <- if (length(report_entries) > 0) do.call(rbind, report_entries) else NULL

  if (check_zenodo_policy && !is.null(reports)) {
    tryCatch({
      report_zenodo_policy_findings(check_register_zenodo_policy(reports))
    }, error = function(e) {
      cli::cli_alert_info("Could not run the Zenodo curation policy check: {conditionMessage(e)}")
    })
  }

  if (check_researchequals_policy && !is.null(reports)) {
    tryCatch({
      report_researchequals_policy_findings(check_register_researchequals_policy(reports))
    }, error = function(e) {
      cli::cli_alert_info("Could not run the ResearchEquals curation policy check: {conditionMessage(e)}")
    })
  }
}
