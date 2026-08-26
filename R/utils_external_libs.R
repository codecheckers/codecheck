#' External Library Specifications
#'
#' Single source of truth for the CSS/JavaScript libraries that are stored
#' locally in the register output, including their font files. Used both for
#' downloading the libraries and for checking whether the local copies are
#' already up to date.
#'
#' @return A named list of library specifications
#' @keywords internal
external_library_specs <- function() {
  list(
    bootstrap = list(
      name = "Bootstrap",
      version = "5.3.3",
      license = "MIT",
      license_url = "https://github.com/twbs/bootstrap/blob/v5.3.3/LICENSE",
      description = "Front-end framework for web development",
      urls = list(
        css = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css",
        css_map = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css.map",
        js = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js",
        js_map = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js.map"
      ),
      files = list(
        css = "bootstrap/bootstrap.min.css",
        css_map = "bootstrap/bootstrap.min.css.map",
        js = "bootstrap/bootstrap.bundle.min.js",
        js_map = "bootstrap/bootstrap.bundle.min.js.map"
      )
    ),

    font_awesome = list(
      name = "Font Awesome",
      version = "4.7.0",
      license = "OFL-1.1 (fonts), MIT (CSS)",
      license_url = "https://fontawesome.com/license/free",
      description = "Icon toolkit",
      urls = list(
        css = "https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css"
      ),
      files = list(
        css = "font-awesome/css/font-awesome.min.css"
      ),
      fonts = list(
        dir = file.path("font-awesome", "fonts"),
        url_pattern = "https://maxcdn.bootstrapcdn.com/font-awesome/{version}/fonts/{file}",
        files = c(
          "fontawesome-webfont.eot",
          "fontawesome-webfont.svg",
          "fontawesome-webfont.ttf",
          "fontawesome-webfont.woff",
          "fontawesome-webfont.woff2"
        )
      )
    ),

    academicons = list(
      name = "Academicons",
      version = "1.9.4",
      license = "OFL-1.1 (fonts), MIT (CSS)",
      license_url = "https://github.com/jpswalsh/academicons/blob/master/LICENSE",
      description = "Academic icons for LaTeX, XeLaTeX, web, and more",
      urls = list(
        css = "https://cdn.jsdelivr.net/gh/jpswalsh/academicons@1.9.4/css/academicons.min.css"
      ),
      files = list(
        css = "academicons/css/academicons.min.css"
      ),
      fonts = list(
        dir = file.path("academicons", "fonts"),
        url_pattern = "https://cdn.jsdelivr.net/gh/jpswalsh/academicons@{version}/fonts/{file}",
        files = c(
          "academicons.eot",
          "academicons.svg",
          "academicons.ttf",
          "academicons.woff"
        )
      )
    )
  )
}

#' Expected Files of an External Library
#'
#' @param lib A single library specification from [external_library_specs()]
#'
#' @return Character vector of file paths relative to the libraries directory
#' @keywords internal
library_expected_files <- function(lib) {
  files <- unlist(lib$files, use.names = FALSE)

  if (!is.null(lib$fonts)) {
    files <- c(files, file.path(lib$fonts$dir, lib$fonts$files))
  }

  files
}

#' Minimum plausible size of a downloaded library file, in bytes
#'
#' Downloads that fail with an HTTP error page, or that are interrupted, can
#' leave a small file behind. Such a file must not count as a valid local copy,
#' otherwise it is never downloaded again. The smallest file of the libraries
#' handled here is about 7 kB.
#'
#' @keywords internal
CODECHECK_MIN_LIB_FILE_SIZE <- 1024

#' Check Whether the Local External Libraries Are Up To Date
#'
#' The local copies are considered current when every expected file exists and
#' is of a plausible size, and when `PROVENANCE.csv` records exactly the
#' libraries and versions of the current specification.
#'
#' @param libs_dir Libraries directory
#' @param libraries Library specifications, see [external_library_specs()]
#'
#' @return `TRUE` if no download is needed, `FALSE` otherwise
#' @keywords internal
libs_are_current <- function(libs_dir, libraries = external_library_specs()) {
  provenance_file <- file.path(libs_dir, "PROVENANCE.csv")
  if (!file.exists(provenance_file)) {
    return(FALSE)
  }

  provenance <- tryCatch(
    utils::read.csv(provenance_file, stringsAsFactors = FALSE),
    error = function(e) NULL
  )
  if (is.null(provenance) || !all(c("library", "version") %in% names(provenance))) {
    return(FALSE)
  }

  expected_versions <- vapply(libraries, function(lib) paste(lib$name, lib$version), character(1))
  recorded_versions <- paste(provenance$library, provenance$version)
  if (!setequal(expected_versions, recorded_versions)) {
    return(FALSE)
  }

  for (lib in libraries) {
    for (file in library_expected_files(lib)) {
      path <- file.path(libs_dir, file)
      if (!file.exists(path) || file.size(path) < CODECHECK_MIN_LIB_FILE_SIZE) {
        return(FALSE)
      }
    }
  }

  TRUE
}

#' Download a Single Library File
#'
#' Downloads to a temporary file and only moves it into place when the request
#' succeeded, so that an HTTP error page is never stored as a library file.
#'
#' @param url URL to download from
#' @param dest_file Destination path
#' @param progress Whether to show a progress bar
#'
#' @return `TRUE` if the file was downloaded successfully
#' @keywords internal
download_library_file <- function(url, dest_file, progress = FALSE) {
  temp_file <- paste0(dest_file, ".download")
  on.exit(unlink(temp_file), add = TRUE)

  success <- tryCatch({
    args <- list(url, httr::write_disk(temp_file, overwrite = TRUE))
    if (progress) {
      args <- c(args, list(httr::progress()))
    }
    response <- do.call(codecheck_GET, args)

    status <- httr::status_code(response)
    if (status != 200) {
      warning("    ✗ Failed with status ", status, ": ", url)
      FALSE
    } else if (!file.exists(temp_file) || file.size(temp_file) < CODECHECK_MIN_LIB_FILE_SIZE) {
      warning("    ✗ Suspiciously small download, discarded: ", url)
      FALSE
    } else {
      TRUE
    }
  }, error = function(e) {
    warning("    ✗ Error downloading: ", e$message)
    FALSE
  })

  if (success) {
    success <- file.rename(temp_file, dest_file)
  }

  success
}

#' Download and Setup External Libraries Locally
#'
#' Downloads CSS and JavaScript libraries from their official sources and stores them
#' locally in the docs/libs directory. This removes dependency on external CDNs and
#' ensures reproducibility.
#'
#' Files that are already present and of a plausible size are not downloaded again.
#' When all expected files are present and `PROVENANCE.csv` matches the current
#' library versions, the function returns early and leaves `PROVENANCE.csv` and
#' `README.md` untouched, so that repeated rendering does not modify these files.
#'
#' @param libs_dir Directory where libraries should be installed (default: "docs/libs")
#' @param force If TRUE, re-download libraries even if they already exist
#'
#' @return Invisibly returns a data frame with provenance information for all libraries
#'
#' @importFrom httr GET write_disk progress
#' @importFrom utils unzip read.csv write.csv
#'
#' @export
setup_external_libraries <- function(libs_dir = "docs/libs", force = FALSE) {
  # Create libs directory if it doesn't exist
  if (!dir.exists(libs_dir)) {
    dir.create(libs_dir, recursive = TRUE)
    cli::cli_alert_info("Created libraries directory: {.path {libs_dir}}")
  }

  libraries <- external_library_specs()
  provenance_file <- file.path(libs_dir, "PROVENANCE.csv")

  # Nothing to do: keep provenance and README as they are
  if (!force && libs_are_current(libs_dir, libraries)) {
    cli::cli_alert_success("External libraries are up to date in {.path {libs_dir}}")
    copy_register_css()
    return(invisible(utils::read.csv(provenance_file, stringsAsFactors = FALSE)))
  }

  previous <- if (file.exists(provenance_file)) {
    tryCatch(utils::read.csv(provenance_file, stringsAsFactors = FALSE), error = function(e) NULL)
  } else {
    NULL
  }

  # Download each library
  provenance <- data.frame()

  for (lib_key in names(libraries)) {
    lib <- libraries[[lib_key]]
    cli::cli_alert_info("Processing {lib$name} {lib$version}...")

    lib_dir <- file.path(libs_dir, dirname(lib$files[[1]]))
    if (!dir.exists(lib_dir)) {
      dir.create(lib_dir, recursive = TRUE)
    }

    downloaded <- FALSE

    # Download all files for this library
    for (file_key in names(lib$urls)) {
      url <- lib$urls[[file_key]]
      dest_file <- file.path(libs_dir, lib$files[[file_key]])

      if (force || !file.exists(dest_file) || file.size(dest_file) < CODECHECK_MIN_LIB_FILE_SIZE) {
        cli::cli_alert_info("  Downloading {.file {basename(dest_file)}}...")
        if (download_library_file(url, dest_file, progress = TRUE)) {
          cli::cli_alert_success("    Downloaded successfully")
          downloaded <- TRUE
        }
      } else {
        cli::cli_alert_success("  Already exists: {.file {basename(dest_file)}}")
      }
    }

    # Handle font downloads
    if (!is.null(lib$fonts)) {
      downloaded <- download_library_fonts(libs_dir, lib, force = force) || downloaded
    }

    # Record provenance, keeping the original date when nothing was downloaded
    date_configured <- as.character(Sys.Date())
    if (!downloaded && !is.null(previous)) {
      previous_row <- previous[previous$library == lib$name & previous$version == lib$version, ]
      if (nrow(previous_row) == 1) {
        date_configured <- as.character(previous_row$date_configured)
      }
    }

    provenance <- rbind(provenance, data.frame(
      library = lib$name,
      version = lib$version,
      license = lib$license,
      license_url = lib$license_url,
      description = lib$description,
      date_configured = date_configured,
      stringsAsFactors = FALSE
    ))
  }

  copy_register_css()

  # Write provenance information
  utils::write.csv(provenance, provenance_file, row.names = FALSE)
  cli::cli_alert_info("Provenance information written to: {.path {provenance_file}}")

  # Create README
  create_libs_readme(libs_dir, provenance)

  cli::cli_alert_success("All libraries installed successfully in: {.path {libs_dir}}")
  invisible(provenance)
}

#' Copy the CODECHECK Register CSS to the Output Assets Directory
#'
#' @param assets_dir Directory for the register's own assets
#' @keywords internal
copy_register_css <- function(assets_dir = "docs/assets") {
  cli::cli_alert_info("Copying CODECHECK register CSS...")
  if (!dir.exists(assets_dir)) {
    dir.create(assets_dir, recursive = TRUE)
    cli::cli_alert_info("Created assets directory: {.path {assets_dir}}")
  }

  css_source <- system.file("extdata", "templates/assets/codecheck-register.css", package = "codecheck")
  css_dest <- file.path(assets_dir, "codecheck-register.css")

  if (file.exists(css_source)) {
    file.copy(css_source, css_dest, overwrite = TRUE)
    cli::cli_alert_success("Copied codecheck-register.css to {.path {css_dest}}")
  } else {
    warning("  ✗ Could not find codecheck-register.css in package templates")
  }
}

#' Download the Font Files of a Library
#'
#' @param libs_dir Base libraries directory
#' @param lib Library specification with a `fonts` entry
#' @param force If TRUE, re-download fonts even if they already exist
#'
#' @return `TRUE` if at least one font file was downloaded
#' @keywords internal
download_library_fonts <- function(libs_dir, lib, force = FALSE) {
  fonts_dir <- file.path(libs_dir, lib$fonts$dir)
  if (!dir.exists(fonts_dir)) {
    dir.create(fonts_dir, recursive = TRUE)
  }

  downloaded <- FALSE

  for (font_file in lib$fonts$files) {
    url <- gsub("{file}", font_file,
                gsub("{version}", lib$version, lib$fonts$url_pattern, fixed = TRUE),
                fixed = TRUE)
    dest_file <- file.path(fonts_dir, font_file)

    if (force || !file.exists(dest_file) || file.size(dest_file) < CODECHECK_MIN_LIB_FILE_SIZE) {
      cli::cli_alert_info("  Downloading font: {.file {font_file}}...")
      if (download_library_file(url, dest_file)) {
        cli::cli_alert_success("    Downloaded")
        downloaded <- TRUE
      }
    }
  }

  downloaded
}

#' Create README for Libraries Directory
#'
#' @param libs_dir Libraries directory
#' @param provenance Provenance data frame
#' @keywords internal
create_libs_readme <- function(libs_dir, provenance) {
  readme_content <- c(
    "# External Libraries",
    "",
    "This directory contains CSS and JavaScript libraries used by the CODECHECK register.",
    "These libraries are downloaded and stored locally to ensure reproducibility and",
    "remove dependency on external CDNs.",
    "",
    "## Installed Libraries",
    ""
  )

  for (i in seq_len(nrow(provenance))) {
    lib <- provenance[i, ]
    readme_content <- c(
      readme_content,
      paste0("### ", lib$library, " ", lib$version),
      "",
      paste0("- **Description**: ", lib$description),
      paste0("- **License**: ", lib$license),
      paste0("- **License URL**: ", lib$license_url),
      paste0("- **Configured**: ", lib$date_configured),
      ""
    )
  }

  readme_content <- c(
    readme_content,
    "## Updating Libraries",
    "",
    "To update these libraries, run:",
    "```r",
    "codecheck::setup_external_libraries(force = TRUE)",
    "```",
    "",
    "## Provenance",
    "",
    "Full provenance information is maintained in `PROVENANCE.csv` in this directory."
  )

  readme_file <- file.path(libs_dir, "README.md")
  writeLines(readme_content, readme_file)
  cli::cli_alert_info("README created: {.path {readme_file}}")
}
