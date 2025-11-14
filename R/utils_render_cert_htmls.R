#' Generates HTML files for each certificate listed in the given register table.
#' It checks for the existence of the certificate PDF, downloads it if necessary, and
#' converts it to JPEG format for embedding.
#'
#' @param register_table A data frame containing details of each certificate, including repository links and report links.
#' @param force_download Logical; if TRUE, forces the download of certificate PDFs even if they already exist locally. Defaults to FALSE.
#' @param parallel Logical; if TRUE, renders certificates in parallel using multiple cores. Defaults to FALSE.
#' @param ncores Integer; number of CPU cores to use for parallel rendering. If NULL, automatically detects available cores minus 1. Defaults to NULL.
render_cert_htmls <- function(register_table, force_download = FALSE, parallel = FALSE, ncores = NULL){
  # Read template
  html_template <- readLines(CONFIG$CERTS_DIR[["cert_page_template"]])

  # Auto-detect cores if not specified
  if (is.null(ncores)) {
    ncores <- max(1, parallel::detectCores() - 1)
  }

  # Disable parallel if only 1 core requested or only 1 certificate
  if (ncores <= 1 || nrow(register_table) <= 1) {
    parallel <- FALSE
  }

  message("[", format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"), "] Starting certificate HTML rendering for ", nrow(register_table), " certificates")
  if (parallel) {
    message("    Using parallel execution with ", ncores, " cores")
  } else {
    message("    Using sequential execution")
  }
  start_time_total <- Sys.time()

  # Define the function to render one certificate
  # This will be executed by each worker in parallel or sequentially
  render_one_certificate <- function(i, register_table, force_download, verbose = TRUE) {
    start_time_cert <- Sys.time()

    # Extract certificate information
    cert_row <- register_table[i, ]
    cert_hyperlink <- cert_row$Certificate
    cert_id <- sub("\\[(.*)\\]\\(.*\\)", "\\1", cert_hyperlink)
    report_link <- cert_row$Report
    repo_link <- cert_row$Repository
    cert_type <- cert_row$Type
    cert_venue <- cert_row$Venue

    tryCatch({
      # Get abstract
      abstract <- get_abstract(repo_link)

      download_cert_status <- NA

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

          # Convert PDF to PNG (CPU/I/O-bound)
          if (download_cert_status == 1) {
            tryCatch(
              convert_cert_pdf_to_png(cert_id),
              error = function(e) {
                warning(cert_id, " | Error converting PDF: ", e$message)
              }
            )
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
        error = NULL
      )

    }, error = function(e) {
      elapsed_cert <- as.numeric(difftime(Sys.time(), start_time_cert, units = "secs"))
      list(
        cert_id = cert_id,
        index = i,
        elapsed = elapsed_cert,
        success = FALSE,
        error = conditionMessage(e)
      )
    })
  }

  # Execute rendering (parallel or sequential)
  results <- if (parallel && ncores > 1) {
    message("[", format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"), "] Launching ", ncores, " parallel workers...")

    if (.Platform$OS.type == "windows") {
      # Windows: use cluster (parLapply)
      cl <- parallel::makeCluster(ncores)

      # Export required objects and functions to cluster
      # This ensures each worker has access to needed data and functions
      parallel::clusterExport(cl,
                            c("CONFIG", "register_table", "force_download", "parallel"),
                            envir = environment())

      # Load required packages on each worker
      parallel::clusterEvalQ(cl, {
        library(codecheck)
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
    message("[", format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"), "] Processing certificates sequentially...")

    lapply(1:nrow(register_table), function(i) {
      result <- render_one_certificate(i, register_table, force_download, verbose = FALSE)
      # Log each completion in sequential mode
      message("[", format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
              "] ", result$cert_id, " | Completed",
              " (", result$index, "/", nrow(register_table), ") in ",
              sprintf("%.2f", result$elapsed), " seconds")
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
  message("[", format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
          "] Completed all ", nrow(register_table), " certificates")
  message("    Total time: ", sprintf("%.2f", elapsed_total), " seconds")
  message("    Avg time per cert: ", sprintf("%.2f", avg_time), " seconds")
  message("    Median time: ", sprintf("%.2f", median_time), " seconds")
  message("    Range: ", sprintf("%.2f", min_time), " - ", sprintf("%.2f", max_time), " seconds")
  message("    Successes: ", successes, " / ", length(results))

  if (failures > 0) {
    message("    Failures: ", failures)
    message("    Failed certificates:")
    failed <- results[!sapply(results, function(r) r$success)]
    for (f in failed) {
      message("      - ", f$cert_id, ": ", f$error)
    }
  }

  if (parallel && ncores > 1) {
    theoretical_speedup <- nrow(register_table) * avg_time / elapsed_total
    efficiency <- theoretical_speedup / ncores
    message("    Theoretical speedup: ", sprintf("%.2fx", theoretical_speedup))
    message("    Parallel efficiency: ", sprintf("%.1f%%", efficiency * 100))
  }
}

#'
#' Converts each page of a certificate PDF to JPEG format images, saving them in the specified certificate directory. 
#'
#' @importFrom pdftools pdf_info
#' @param cert_id The certificate identifier. This ID is used to locate the PDF and save the resulting images.
convert_cert_pdf_to_png <- function(cert_id){
  # Checking if the certs dir exist
  cert_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id) 

  # Get the number of pages in the PDF
  cert_pdf_path <- file.path(cert_dir, "cert.pdf")
  num_pages <- pdftools::pdf_info(cert_pdf_path)$pages

  # Create image filenames
  image_filenames <- sapply(1:num_pages, function(page) file.path(cert_dir, paste0("cert_", page, ".png")))
  
  # Read and convert PDF to PNG images
  pdftools::pdf_convert(cert_pdf_path, format = "png", filenames = image_filenames, dpi = CONFIG$CERT_DPI)
}

#' Renders an HTML certificate file from a Markdown template for a specific certificate.
#'
#' @param cert_id A character string representing the unique identifier of the certificate.
#' @param repo_link A character string containing the repository link associated with the certificate.
#' @param download_cert_status An integer (0 or 1) indicating whether the certificate PDF was downloaded (1) or not (0).
#' @param cert_type A character string containing the venue type (journal, conference, community, institution).
#' @param cert_venue A character string containing the venue name.
render_cert_html <- function(cert_id, repo_link, download_cert_status, cert_type, cert_venue){
  create_cert_md(cert_id, repo_link, download_cert_status, cert_type, cert_venue)

  output_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  temp_md_path <- file.path(output_dir, "temp.md")

  # Creating html document yml with breadcrumbs and schema.org metadata
  create_cert_page_section_files(output_dir, cert_id, cert_type, cert_venue, repo_link)
  generate_html_document_yml(output_dir)

  yaml_path <- normalizePath(file.path(getwd(), file.path(output_dir, "html_document.yml")))

  # Render HTML from markdown
  rmarkdown::render(
    input = temp_md_path,
    output_file = "index.html",
    output_dir = output_dir,
    output_yaml = yaml_path
  )

  # Remove temporary files (content already embedded in index.html)
  file.remove(temp_md_path)
  file.remove(file.path(output_dir, "index_header.html"))
  file.remove(file.path(output_dir, "index_prefix.html"))
  file.remove(file.path(output_dir, "index_postfix.html"))
  file.remove(file.path(output_dir, "html_document.yml"))

  # Adjusting the path to the libs folder in the html itself
  # so that the path to the libs folder refers to the libs folder "docs/libs".
  # This is done to remove duplicates of "libs" folders.
  html_file_path <- file.path(output_dir, "index.html")
  edit_html_lib_paths(html_file_path)

  # Deleting the libs folder after changing the html lib path
  unlink(file.path(output_dir, "libs"), recursive = TRUE)

  # Generate JSON file with certificate metadata
  generate_cert_json(cert_id, repo_link, cert_type, cert_venue)
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
#' @importFrom jsonlite write_json
#' @export
generate_cert_json <- function(cert_id, repo_link, cert_type, cert_venue) {
  # Get codecheck.yml metadata
  config_yml <- get_codecheck_yml(repo_link)

  # Get abstract
  abstract_data <- get_abstract(repo_link)

  # Build JSON structure matching the certificate landing page
  cert_json <- list(
    certificate = list(
      id = config_yml$certificate,
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

  # Write JSON file
  output_dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  json_path <- file.path(output_dir, "index.json")

  jsonlite::write_json(
    cert_json,
    path = json_path,
    pretty = TRUE,
    auto_unbox = TRUE
  )

  message(cert_id, " | Generated JSON at ", json_path)
}

#' Generates section files for a certificate HTML page, including prefix, postfix, and header HTML components.
#'
#' @param output_dir A character string specifying the directory where the section files will be saved.
#' @param cert_id The certificate identifier for breadcrumb generation
#' @param cert_type The venue type (journal, conference, community, institution) for breadcrumb generation
#' @param cert_venue The venue name for breadcrumb generation
#' @param repo_link Repository link to fetch codecheck.yml for Schema.org metadata generation (default: NULL)
#' @importFrom whisker whisker.render
create_cert_page_section_files <- function(output_dir, cert_id = NULL, cert_type = NULL, cert_venue = NULL, repo_link = NULL){

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

  # Generate Schema.org JSON-LD if repo_link is provided
  schema_org_jsonld <- ""
  if (!is.null(repo_link) && repo_link != "") {
    tryCatch({
      config_yml <- get_codecheck_yml(repo_link)
      abstract_data <- get_abstract(repo_link)
      schema_org_jsonld <- generate_cert_schema_org(cert_id, config_yml, abstract_data)
    }, error = function(e) {
      warning(cert_id, " | Failed to generate Schema.org metadata: ", e$message)
      schema_org_jsonld <- ""
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

  output <- whisker.render(paste(header_template, collapse = "\n"),
                          list(meta_generator = meta_generator,
                               base_path = base_path,
                               schema_org_jsonld = schema_org_jsonld))
  writeLines(output, file.path(output_dir, "index_header.html"))
}
