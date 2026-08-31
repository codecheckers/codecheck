#' Generate redirect page for /certs/ directory
#'
#' Creates an index.html at docs/certs/ that redirects visitors to the main
#' register page. This handles the case where someone visits /register/certs/
#' without specifying a certificate ID.
#'
#' @seealso \url{https://github.com/codecheckers/register/issues/166}
generate_certs_redirect <- function() {
  certs_dir <- CONFIG$CERTS_DIR[["cert"]]
  if (!dir.exists(certs_dir)) {
    dir.create(certs_dir, recursive = TRUE)
  }

  template_path <- system.file("extdata", "templates/general/certs_redirect_template.html",
                               package = "codecheck")
  redirect_html <- readLines(template_path, warn = FALSE)
  redirect_file <- file.path(certs_dir, "index.html")
  writeLines(redirect_html, redirect_file)

  cli::cli_alert_success("Created redirect page at {.path {redirect_file}}")
}

#' Generates HTML files for each certificate listed in the given register table.
#' It checks for the existence of the certificate PDF, downloads it if necessary, and
#' converts it to JPEG format for embedding.
#'
#' @param register_table A data frame containing details of each certificate, including repository links and report links.
#' @param force_download Logical; if TRUE, forces the download of certificate PDFs even if they already exist locally. Defaults to FALSE.
#' @param parallel Logical; if TRUE, renders certificates in parallel using multiple cores. Defaults to FALSE.
#' @param ncores Integer; number of CPU cores to use for parallel rendering. If NULL, automatically detects available cores minus 1. Defaults to NULL.
render_cert_htmls <- function(register_table, force_download = FALSE, parallel = FALSE, ncores = NULL){
  # Auto-detect cores if not specified
  if (is.null(ncores)) {
    ncores <- max(1, parallel::detectCores() - 1)
  }

  # Disable parallel if only 1 core requested or only 1 certificate
  if (ncores <= 1 || nrow(register_table) <= 1) {
    parallel <- FALSE
  }

  n_certs <- nrow(register_table)
  cli::cli_h2("Rendering {n_certs} certificate{?s}")
  if (parallel) {
    cli::cli_alert_info("Using parallel execution with {ncores} cores")
  } else {
    cli::cli_alert_info("Using sequential execution")
  }
  start_time_total <- Sys.time()

  # Define the function to render one certificate
  # This will be executed by each worker in parallel or sequentially
  render_one_certificate <- function(i, register_table, force_download, verbose = TRUE) {
    start_time_cert <- Sys.time()

    # Extract certificate information
    cert_row <- register_table[i, ]
    cert_id <- cert_row$Certificate
    report_link <- cert_row$Report
    repo_link <- cert_row$Repository
    cert_type <- cert_row$Type
    cert_venue <- cert_row$Venue

    tryCatch({
      download_cert_status <- NA
      pdf_issue <- NULL
      pdf_cosmetic_count <- 0

      # PDF download and conversion
      if (CONFIG$CERT_DOWNLOAD_AND_CONVERT) {
        pdf_path <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id, "cert.pdf")
        pdf_exists <- file.exists(pdf_path)

        if (!pdf_exists || force_download) {
          # Download PDF (I/O-bound)
          download_cert_status <- tryCatch(
            download_cert_pdf(report_link, cert_id),
            error = function(e) {
              warning(cert_id, " | Error downloading PDF: ", e$message)
              0
            }
          )

          # Convert PDF to PNG (CPU/I/O-bound). Poppler's own parsing diagnostics
          # are captured and classified by convert_cert_pdf_to_png() rather than
          # printed raw to the console; a genuinely broken PDF is reported below
          # via the returned pdf_issue, which (unlike warning()) survives being
          # returned from a parallel worker back to the coordinating process.
          if (download_cert_status == 1) {
            conversion <- convert_cert_pdf_to_png(cert_id)
            pdf_cosmetic_count <- conversion$cosmetic_count
            if (!conversion$success || length(conversion$fatal) > 0) {
              pdf_issue <- list(
                cert_id = cert_id,
                pdf_path = pdf_path,
                detail = if (!conversion$success) conversion$error else paste(conversion$fatal, collapse = "; ")
              )
            }
          }

          # Rate limiting - only in sequential mode
          # In parallel mode, each worker handles its own requests without global delay
          if (!parallel) {
            Sys.sleep(CONFIG$CERT_REQUEST_DELAY)
          }
        } else {
          download_cert_status <- 1
        }
      } else {
        download_cert_status <- 0
      }

      # Render HTML (CPU/I/O-bound)
      tryCatch(
        render_cert_html(cert_id, repo_link, download_cert_status, cert_type, cert_venue),
        error = function(e) {
          warning(cert_id, " | Error rendering HTML: ", e$message)
        }
      )

      elapsed_cert <- as.numeric(difftime(Sys.time(), start_time_cert, units = "secs"))

      # Return result
      list(
        cert_id = cert_id,
        index = i,
        elapsed = elapsed_cert,
        success = TRUE,
        error = NULL,
        pdf_issue = pdf_issue,
        pdf_cosmetic_count = pdf_cosmetic_count
      )

    }, error = function(e) {
      elapsed_cert <- as.numeric(difftime(Sys.time(), start_time_cert, units = "secs"))
      list(
        cert_id = cert_id,
        index = i,
        elapsed = elapsed_cert,
        success = FALSE,
        error = conditionMessage(e),
        pdf_issue = NULL,
        pdf_cosmetic_count = 0
      )
    })
  }

  # Execute rendering (parallel or sequential)
  results <- if (parallel && ncores > 1) {
    cli::cli_alert_info("Launching {ncores} parallel workers...")

    if (.Platform$OS.type == "windows") {
      # Windows: use cluster (parLapply)
      cl <- parallel::makeCluster(ncores)

      # Export required objects and functions to cluster
      # This ensures each worker has access to needed data and functions
      parallel::clusterExport(cl,
                            c("CONFIG", "register_table", "force_download", "parallel"),
                            envir = environment())

      # Load required packages on each worker, and re-apply the option set by
      # register_render() to skip the rmarkdown header-attrs dependency (#89) -
      # options set on the main process are not inherited by PSOCK workers.
      parallel::clusterEvalQ(cl, {
        library(codecheck)
        options(rmarkdown.html_dependency.header_attr = FALSE)
      })

      # Run in parallel
      results <- tryCatch({
        parallel::parLapply(cl, 1:nrow(register_table), function(i) {
          render_one_certificate(i, register_table, force_download, verbose = FALSE)
        })
      }, finally = {
        # Always stop cluster
        parallel::stopCluster(cl)
      })

      results

    } else {
      # Unix/Mac: use forking (mclapply) - simpler and more efficient
      # Forking shares memory, so no need to export objects
      parallel::mclapply(1:nrow(register_table), function(i) {
        render_one_certificate(i, register_table, force_download, verbose = FALSE)
      }, mc.cores = ncores, mc.preschedule = TRUE)
    }

  } else {
    # Sequential execution
    n_total <- nrow(register_table)
    cli_pb_id <- cli::cli_progress_bar(
      format = "{cli::pb_spin} Rendering certificates [{cli::pb_current}/{cli::pb_total}] {cli::pb_bar} | {cli::pb_elapsed}",
      total = n_total,
      clear = FALSE
    )

    lapply(1:n_total, function(i) {
      result <- render_one_certificate(i, register_table, force_download, verbose = FALSE)
      cli::cli_progress_update(id = cli_pb_id)
      if (!result$success) {
        cli::cli_alert_danger("{result$cert_id} | Failed: {result$error}")
      }
      result
    })
  }

  # Process and report results
  elapsed_total <- as.numeric(difftime(Sys.time(), start_time_total, units = "secs"))

  # Count successes and failures
  successes <- sum(sapply(results, function(r) r$success))
  failures <- length(results) - successes

  # Calculate timing statistics
  elapsed_times <- sapply(results, function(r) r$elapsed)
  avg_time <- mean(elapsed_times)
  median_time <- median(elapsed_times)
  min_time <- min(elapsed_times)
  max_time <- max(elapsed_times)

  # Print summary
  cli::cli_alert_success("Completed {nrow(register_table)} certificate{?s} in {sprintf('%.1f', elapsed_total)}s")
  cli::cli_alert_info("Avg: {sprintf('%.2f', avg_time)}s | Median: {sprintf('%.2f', median_time)}s | Range: {sprintf('%.2f', min_time)}-{sprintf('%.2f', max_time)}s")
  cli::cli_alert_info("Successes: {successes}/{length(results)}")

  if (failures > 0) {
    cli::cli_alert_danger("{failures} certificate{?s} failed:")
    failed <- results[!sapply(results, function(r) r$success)]
    for (f in failed) {
      cli::cli_alert_danger("  {f$cert_id}: {f$error}")
    }
  }

  # Report certificate PDFs poppler could not really parse (see
  # convert_cert_pdf_to_png()) - these still produce a certificate page, but
  # with missing or unreliable page images, so they need a human to look at
  # the source PDF. Built from each certificate's returned result rather than
  # warning(), so it surfaces the same way under parallel and sequential
  # rendering.
  pdf_issues <- Filter(Negate(is.null), lapply(results, function(r) r$pdf_issue))
  if (length(pdf_issues) > 0) {
    cli::cli_alert_danger("{length(pdf_issues)} certificate PDF{?s} could not be fully parsed - inspect the source file:")
    for (issue in pdf_issues) {
      cli::cli_alert_danger("  {issue$cert_id} | {.path {issue$pdf_path}}: {issue$detail}")
    }
  }

  # Cosmetic poppler warnings (e.g. malformed embedded fonts) don't affect the
  # rendered pages, so they are condensed to a single count instead of the raw
  # per-line poppler output.
  total_cosmetic <- sum(sapply(results, function(r) {
    if (is.null(r$pdf_cosmetic_count)) 0 else r$pdf_cosmetic_count
  }))
  if (total_cosmetic > 0) {
    cli::cli_alert_info("Suppressed {total_cosmetic} cosmetic poppler warning{?s} (e.g. malformed embedded fonts) across all certificate PDFs")
  }

  if (parallel && ncores > 1) {
    theoretical_speedup <- nrow(register_table) * avg_time / elapsed_total
    efficiency <- theoretical_speedup / ncores
    cli::cli_alert_info("Speedup: {sprintf('%.2fx', theoretical_speedup)} | Efficiency: {sprintf('%.1f%%', efficiency * 100)}")

    # Clean up stray libs/ folders left behind by parallel rendering.
    # In parallel mode, forked processes share /tmp, causing occasional pandoc
    # temp file conflicts. When rmarkdown::render() fails mid-render, the libs/
    # folder it created isn't cleaned up because the error skips unlink().
    certs_base <- CONFIG$CERTS_DIR[["cert"]]
    cert_dirs <- list.dirs(certs_base, recursive = FALSE)
    stray_libs <- file.path(cert_dirs, "libs")
    stray_libs <- stray_libs[dir.exists(stray_libs)]
    if (length(stray_libs) > 0) {
      for (lib_dir in stray_libs) {
        unlink(lib_dir, recursive = TRUE)
      }
      cli::cli_alert_warning("Cleaned up {length(stray_libs)} stray libs/ folder{?s} from parallel rendering")
    }

    # Clean up stray temporary HTML files left behind by failed renders
    stray_temp_names <- c("index_header.html", "index_prefix.html", "index_postfix.html", "html_document.yml", "temp.md")
    stray_temps <- unlist(lapply(cert_dirs, function(d) {
      files <- file.path(d, stray_temp_names)
      files[file.exists(files)]
    }))
    if (length(stray_temps) > 0) {
      file.remove(stray_temps)
      cli::cli_alert_warning("Cleaned up {length(stray_temps)} stray temporary file{?s} from parallel rendering")
    }
  }

  invisible(list(n = nrow(register_table), failures = failures))
}

#' Renders an HTML certificate file from a Markdown template for a specific certificate.
#'
#' @param cert_id A character string representing the unique identifier of the certificate.
#' @param repo_link A character string containing the repository link associated with the certificate.
#' @param download_cert_status An integer (0 or 1) indicating whether the certificate PDF was downloaded (1) or not (0).
#' @param cert_type A character string containing the venue type (journal, conference, community, institution).
#' @param cert_venue A character string containing the venue name.
render_cert_html <- function(cert_id, repo_link, download_cert_status, cert_type, cert_venue){
  # Resolve the externally enriched fields once per certificate (rather than
  # once per output format below), so a single OpenAlex/CrossRef request
  # covers markdown, JSON and Schema.org, and a transient failure this run
  # falls back to the certificate's existing index.json instead of dropping
  # the field - see resolve_external_field() (register#185 and its regression).
  config_yml <- get_codecheck_yml(repo_link)
  first_author_name <- if (length(config_yml$paper$authors) > 0) config_yml$paper$authors[[1]]$name else NULL
  prune_unavailable <- isTRUE(CONFIG$PRUNE_UNAVAILABLE_METADATA)

  openalex_lookup <- tryCatch(
    get_openalex_id_cached_result(config_yml$paper$reference, config_yml$paper$title, first_author_name),
    error = function(e) list(status = "failed", value = NA_character_)
  )
  openalex_id <- resolve_external_field(
    cert_id, c("paper", "openalex"), openalex_lookup$status, openalex_lookup$value,
    empty_value = NA_character_, prune_unavailable = prune_unavailable
  )

  abstract_lookup <- tryCatch(
    get_abstract_cached_result(repo_link),
    error = function(e) list(status = "failed", value = list(source = NULL, text = NULL))
  )
  abstract_data <- resolve_external_field(
    cert_id, c("paper", "abstract"), abstract_lookup$status, abstract_lookup$value,
    empty_value = list(source = NULL, text = NULL), prune_unavailable = prune_unavailable
  )

  # The title of the record on the platform the certificate is published on -
  # Zenodo, OSF or ResearchEquals - which is what the citation metadata has to
  # show, see resolve_cert_title() (register#52).
  cert_title <- resolve_cert_title(cert_id, config_yml$report,
                                   prune_unavailable = prune_unavailable)

  create_cert_md(cert_id, repo_link, download_cert_status, cert_type, cert_venue, openalex_id, abstract_data)

  output_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  temp_md_path <- file.path(output_dir, "temp.md")

  # Creating html document yml with breadcrumbs and schema.org metadata
  create_cert_page_section_files(output_dir, cert_id, cert_type, cert_venue, repo_link, openalex_id,
                                 abstract_data, cert_title)
  generate_html_document_yml(output_dir)

  # Schedule cleanup of temporary files so they are removed even if render() fails
  temp_files <- file.path(output_dir, c("temp.md", "index_header.html", "index_prefix.html", "index_postfix.html", "html_document.yml"))
  on.exit({
    for (f in temp_files) {
      if (file.exists(f)) file.remove(f)
    }
  }, add = TRUE)

  yaml_path <- normalizePath(file.path(getwd(), file.path(output_dir, "html_document.yml")))

  # Render HTML from markdown
  # quiet = !CONFIG$VERBOSE suppresses pandoc command output; use verbose=TRUE in register_render() to see it
  rmarkdown::render(
    input = temp_md_path,
    output_file = "index.html",
    output_dir = output_dir,
    output_yaml = yaml_path,
    quiet = !isTRUE(CONFIG$VERBOSE)
  )

  # Adjusting the path to the libs folder in the html itself
  # so that the path to the libs folder refers to the libs folder "docs/libs".
  # This is done to remove duplicates of "libs" folders.
  html_file_path <- file.path(output_dir, "index.html")
  edit_html_lib_paths(html_file_path)

  # Deleting the libs folder after changing the html lib path
  unlink(file.path(output_dir, "libs"), recursive = TRUE)

  # Generate JSON file with certificate metadata
  generate_cert_json(cert_id, repo_link, cert_type, cert_venue, openalex_id, abstract_data, cert_title)
}

#' Generates a JSON file with all certificate metadata
#'
#' Creates an index.json file containing all information displayed on the
#' certificate landing page for programmatic access.
#'
#' @param cert_id A character string representing the unique identifier of the certificate.
#' @param repo_link A character string containing the repository link associated with the certificate.
#' @param cert_type A character string containing the venue type (journal, conference, community, institution).
#' @param cert_venue A character string containing the venue name.
#' @param openalex_id Optional pre-resolved OpenAlex ID (see \code{\link{resolve_external_field}});
#'   when `NULL`, looked up here directly.
#' @param abstract_data Optional pre-resolved abstract; when `NULL`, looked up here directly.
#' @param cert_title Optional pre-resolved title of the certificate's record on
#'   its publication platform; when `NULL`, looked up here directly, see
#'   \code{\link{resolve_cert_title}}.
#' @importFrom jsonlite write_json
#' @export
generate_cert_json <- function(cert_id, repo_link, cert_type, cert_venue,
                               openalex_id = NULL, abstract_data = NULL,
                               cert_title = NULL) {
  # Get codecheck.yml metadata
  config_yml <- get_codecheck_yml(repo_link)

  # Get abstract
  if (is.null(abstract_data)) {
    abstract_data <- get_abstract(repo_link)
  }

  # Build JSON structure matching the certificate landing page
  # The title of the record on the platform the certificate is published on,
  # which is also what the page's citation metadata shows (register#52)
  if (is.null(cert_title)) {
    cert_title <- resolve_cert_title(cert_id, config_yml$report,
                                     prune_unavailable = isTRUE(CONFIG$PRUNE_UNAVAILABLE_METADATA))
  }

  cert_json <- list(
    certificate = list(
      id = config_yml$certificate,
      title = cert_title,
      url = paste0("https://codecheck.org.uk/register/certs/", cert_id, "/")
    ),
    paper = list(
      title = config_yml$paper$title,
      authors = lapply(config_yml$paper$authors, function(author) {
        author_obj <- list(name = author$name)
        if (!is.null(author$ORCID) && author$ORCID != "") {
          author_obj$orcid = author$ORCID
        }
        author_obj
      }),
      reference = config_yml$paper$reference
    ),
    codecheck = list(
      codecheckers = lapply(config_yml$codechecker, function(checker) {
        checker_obj <- list(name = checker$name)
        if (!is.null(checker$ORCID) && checker$ORCID != "") {
          checker_obj$orcid = checker$ORCID
        }
        checker_obj
      }),
      check_time = config_yml$check_time,
      repository = repo_link,
      report = config_yml$report,
      type = cert_type,
      venue = cert_venue
    )
  )

  # Add summary if it exists
  if ("summary" %in% names(config_yml) && !is.null(config_yml$summary)) {
    cert_json$codecheck$summary <- config_yml$summary
  }

  # Add abstract if available
  if (!is.null(abstract_data$text)) {
    cert_json$paper$abstract <- list(
      text = abstract_data$text,
      source = abstract_data$source
    )
  }

  # Add manifest if it exists
  if ("manifest" %in% names(config_yml) && !is.null(config_yml$manifest)) {
    cert_json$codecheck$manifest <- config_yml$manifest
  }

  # Add OpenAlex link (addresses register#185)
  if (is.null(openalex_id)) {
    openalex_id <- tryCatch(
      get_openalex_id_cached(
        config_yml$paper$reference,
        paper_title = config_yml$paper$title,
        first_author_name = if (length(config_yml$paper$authors) > 0) config_yml$paper$authors[[1]]$name else NULL
      ),
      error = function(e) NA_character_
    )
  }
  if (!is.na(openalex_id)) {
    cert_json$paper$openalex <- openalex_id
  }

  # Write JSON file
  output_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  json_path <- file.path(output_dir, "index.json")

  jsonlite::write_json(
    cert_json,
    path = json_path,
    pretty = TRUE,
    auto_unbox = TRUE
  )

  cli::cli_alert_success("{cert_id} | Generated JSON at {.path {json_path}}")
}

#' Generates section files for a certificate HTML page, including prefix, postfix, and header HTML components.
#'
#' @param output_dir A character string specifying the directory where the section files will be saved.
#' @param cert_id The certificate identifier for breadcrumb generation
#' @param cert_type The venue type (journal, conference, community, institution) for breadcrumb generation
#' @param cert_venue The venue name for breadcrumb generation
#' @param repo_link Repository link to fetch codecheck.yml for Schema.org metadata generation (default: NULL)
#' @param openalex_id Optional pre-resolved OpenAlex ID
#' @param abstract_data Optional pre-resolved abstract
#' @param cert_title Optional pre-resolved title of the certificate's record on
#'   its publication platform, see \code{\link{resolve_cert_title}}
#' @importFrom whisker whisker.render
create_cert_page_section_files <- function(output_dir, cert_id = NULL, cert_type = NULL, cert_venue = NULL, repo_link = NULL,
                                           openalex_id = NULL, abstract_data = NULL, cert_title = NULL){

  # Create prefix with navigation header and breadcrumbs
  if (!is.null(cert_id) && !is.null(cert_type) && !is.null(cert_venue)) {
    # Generate breadcrumbs for certificate page with venue context
    table_details <- list(
      name = cert_venue,
      subcat = cert_type,
      cert_id = cert_id,
      is_reg_table = TRUE
    )
    base_path <- "../.."  # Certificate pages are always at docs/certs/ID/

    # Generate navigation header (no menu on certificate pages)
    nav_header_html <- generate_navigation_header(filter = "certs", base_path = base_path, table_details = table_details)

    # Generate breadcrumbs
    breadcrumb_html <- generate_breadcrumb(filter = "venues", table_details = table_details, base_path = base_path)

    prefix_content <- paste0(
      nav_header_html,
      '<div class="breadcrumb-container">\n',
      breadcrumb_html,
      '\n</div>\n'
    )
    writeLines(prefix_content, file.path(output_dir, "index_prefix.html"))
  } else {
    # Fallback to template if information not provided
    prefix_template <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["prefix"]], warn = FALSE)
    writeLines(prefix_template, file.path(output_dir, "index_prefix.html"))
  }

  # Create postfix without build metadata
  # Certificate pages should not show build info as it's confusing that all certificate
  # pages show as updated every time the register is re-rendered
  postfix_template <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["postfix"]], warn = FALSE)

  # Always use empty build_info for certificate pages
  build_info <- ""

  output <- whisker.render(paste(postfix_template, collapse = "\n"), list(build_info = build_info))
  writeLines(output, file.path(output_dir, "index_postfix.html"))

  # Create header with schema.org JSON-LD
  # Note: meta generator on certificate pages uses "codecheck" without version info
  # (similar to how build info is omitted) to avoid confusion about page freshness
  header_template <- readLines(CONFIG$TEMPLATE_DIR[["cert"]][["header"]], warn = FALSE)

  # Use "codecheck" only without version info on individual certificate pages
  meta_generator <- "codecheck"

  # Generate the metadata of this certificate page: Schema.org JSON-LD, the
  # Highwire citation tags Google Scholar and Zotero read (register#52), and
  # OpenGraph tags describing the certificate rather than the register as a
  # whole, which is what the shared header template defaults to.
  page_metadata <- register_page_header_data()
  schema_org_jsonld <- ""
  if (!is.null(repo_link) && repo_link != "") {
    page_metadata <- tryCatch({
      config_yml <- get_codecheck_yml(repo_link)
      if (is.null(abstract_data)) {
        abstract_data <- get_abstract(repo_link)
      }
      # `<-` reaches this function's frame: the tryCatch expression is a promise
      # evaluated in the calling frame, unlike the error handler below
      schema_org_jsonld <- generate_cert_schema_org(cert_id, config_yml, abstract_data,
                                                    openalex_id, cert_title = cert_title)

      # the PDF and its first-page preview, if the download succeeded, sit next
      # to the page being written
      cert_dir <- output_dir
      opengraph <- generate_cert_opengraph(
        cert_id, config_yml,
        cert_title = cert_title,
        has_preview = file.exists(file.path(cert_dir, "cert_1.png"))
      )

      citation_meta <- generate_cert_citation_meta(
        cert_id, config_yml,
        cert_title = cert_title,
        cert_venue = cert_venue,
        has_pdf = file.exists(file.path(cert_dir, "cert.pdf"))
      )

      # the codecheckers authored the certificate; the register-wide default
      # names the register editors, which is wrong on a certificate page
      checkers <- vapply(config_yml$codechecker,
                         function(checker) as.character(checker$name), character(1))
      page_author <- if (length(checkers) > 0) {
        escape_html_attribute(paste(checkers, collapse = ", "))
      } else {
        page_metadata$page_author
      }

      c(opengraph, list(page_author = page_author, citation_meta = citation_meta))
    }, error = function(e) {
      warning(cert_id, " | Failed to generate certificate page metadata: ", e$message)
      schema_org_jsonld <<- ""
      register_page_header_data()
    })
  }

  # Calculate relative path to docs root (cert pages are always 2 levels deep: docs/certs/ID/)
  # Count directory levels from docs/
  path_components <- strsplit(output_dir, "/")[[1]]
  path_components <- path_components[path_components != "" & path_components != "docs"]
  depth <- length(path_components)

  # Generate relative path
  if (depth == 0) {
    base_path <- ""
  } else {
    base_path <- paste(rep("../", depth), collapse = "")
  }

  template_data <- header_template_data(page_metadata, meta_generator, base_path,
                                        schema_org_jsonld)

  output <- whisker.render(paste(header_template, collapse = "\n"), template_data)
  writeLines(output, file.path(output_dir, "index_header.html"))
}
