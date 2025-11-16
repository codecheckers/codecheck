#' Download and Setup External Libraries Locally
#'
#' Downloads CSS and JavaScript libraries from their official sources and stores them
#' locally in the docs/libs directory. This removes dependency on external CDNs and
#' ensures reproducibility.
#'
#' @param libs_dir Directory where libraries should be installed (default: "docs/libs")
#' @param force If TRUE, re-download libraries even if they already exist
#'
#' @return Invisibly returns a data frame with provenance information for all libraries
#'
#' @importFrom httr GET write_disk progress
#' @importFrom utils unzip
#'
#' @export
setup_external_libraries <- function(libs_dir = "docs/libs", force = FALSE) {
  # Create libs directory if it doesn't exist
  if (!dir.exists(libs_dir)) {
    dir.create(libs_dir, recursive = TRUE)
    message("Created libraries directory: ", libs_dir)
  }

  # Define library specifications with provenance information
  libraries <- list(
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
      )
    )
  )

  # Download each library
  provenance <- data.frame()

  for (lib_key in names(libraries)) {
    lib <- libraries[[lib_key]]
    message("Processing ", lib$name, " ", lib$version, "...")

    lib_dir <- file.path(libs_dir, dirname(lib$files[[1]]))
    if (!dir.exists(lib_dir)) {
      dir.create(lib_dir, recursive = TRUE)
    }

    # Download all files for this library
    for (file_key in names(lib$urls)) {
      url <- lib$urls[[file_key]]
      dest_file <- file.path(libs_dir, lib$files[[file_key]])

      if (force || !file.exists(dest_file)) {
        message("  Downloading ", basename(dest_file), "...")
        tryCatch({
          response <- httr::GET(url, httr::write_disk(dest_file, overwrite = TRUE), httr::progress())
          if (httr::status_code(response) == 200) {
            message("    \u2713 Downloaded successfully")
          } else {
            warning("    \u2717 Failed with status ", httr::status_code(response))
          }
        }, error = function(e) {
          warning("    \u2717 Error downloading: ", e$message)
        })
      } else {
        message("  \u2713 Already exists: ", basename(dest_file))
      }
    }

    # Handle font downloads for Font Awesome and Academicons
    if (lib_key == "font_awesome") {
      download_font_awesome_fonts(libs_dir, lib$version)
    } else if (lib_key == "academicons") {
      download_academicons_fonts(libs_dir, lib$version)
    }

    # Record provenance
    provenance <- rbind(provenance, data.frame(
      library = lib$name,
      version = lib$version,
      license = lib$license,
      license_url = lib$license_url,
      description = lib$description,
      date_configured = Sys.Date(),
      stringsAsFactors = FALSE
    ))
  }

  # Copy codecheck-register.css from package templates to docs/assets
  message("\nCopying CODECHECK register CSS...")
  assets_dir <- "docs/assets"
  if (!dir.exists(assets_dir)) {
    dir.create(assets_dir, recursive = TRUE)
    message("Created assets directory: ", assets_dir)
  }

  css_source <- system.file("extdata", "templates/assets/codecheck-register.css", package = "codecheck")
  css_dest <- file.path(assets_dir, "codecheck-register.css")

  if (file.exists(css_source)) {
    file.copy(css_source, css_dest, overwrite = TRUE)
    message("  \u2713 Copied codecheck-register.css to ", css_dest)
  } else {
    warning("  \u2717 Could not find codecheck-register.css in package templates")
  }

  # Write provenance information
  provenance_file <- file.path(libs_dir, "PROVENANCE.csv")
  write.csv(provenance, provenance_file, row.names = FALSE)
  message("\nProvenance information written to: ", provenance_file)

  # Create README
  create_libs_readme(libs_dir, provenance)

  message("\n\u2713 All libraries installed successfully in: ", libs_dir)
  invisible(provenance)
}

#' Download Font Awesome Fonts
#'
#' @param libs_dir Base libraries directory
#' @param version Font Awesome version
#' @keywords internal
download_font_awesome_fonts <- function(libs_dir, version) {
  fonts_dir <- file.path(libs_dir, "font-awesome", "fonts")
  if (!dir.exists(fonts_dir)) {
    dir.create(fonts_dir, recursive = TRUE)
  }

  font_files <- c(
    "fontawesome-webfont.eot",
    "fontawesome-webfont.svg",
    "fontawesome-webfont.ttf",
    "fontawesome-webfont.woff",
    "fontawesome-webfont.woff2"
  )

  for (font_file in font_files) {
    url <- paste0("https://maxcdn.bootstrapcdn.com/font-awesome/", version, "/fonts/", font_file)
    dest_file <- file.path(fonts_dir, font_file)

    if (!file.exists(dest_file)) {
      message("  Downloading font: ", font_file, "...")
      tryCatch({
        httr::GET(url, httr::write_disk(dest_file, overwrite = TRUE))
        message("    \u2713 Downloaded")
      }, error = function(e) {
        warning("    \u2717 Error: ", e$message)
      })
    }
  }
}

#' Download Academicons Fonts
#'
#' @param libs_dir Base libraries directory
#' @param version Academicons version
#' @keywords internal
download_academicons_fonts <- function(libs_dir, version) {
  fonts_dir <- file.path(libs_dir, "academicons", "fonts")
  if (!dir.exists(fonts_dir)) {
    dir.create(fonts_dir, recursive = TRUE)
  }

  font_files <- c(
    "academicons.eot",
    "academicons.svg",
    "academicons.ttf",
    "academicons.woff"
  )

  for (font_file in font_files) {
    url <- paste0("https://cdn.jsdelivr.net/gh/jpswalsh/academicons@", version, "/fonts/", font_file)
    dest_file <- file.path(fonts_dir, font_file)

    if (!file.exists(dest_file)) {
      message("  Downloading font: ", font_file, "...")
      tryCatch({
        httr::GET(url, httr::write_disk(dest_file, overwrite = TRUE))
        message("    \u2713 Downloaded")
      }, error = function(e) {
        warning("    \u2717 Error: ", e$message)
      })
    }
  }
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
  message("README created: ", readme_file)
}
