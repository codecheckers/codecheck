#' Copy Package JavaScript Files to Output Directory
#'
#' Copies JavaScript files from the package's inst/extdata/js directory to the
#' output directory's libs/codecheck subdirectory. This ensures consistent JavaScript
#' library versions across all generated pages.
#'
#' Currently copies:
#' - citation.js: Citation formatting library
#' - cert-utils.js: Certificate page utilities (content display, image slider)
#' - cert-citation.js: Citation generator functions
#'
#' @param output_dir Base output directory (default: "docs")
#' @export
copy_package_javascript <- function(output_dir = "docs") {
  # Create libs/codecheck directory
  libs_dir <- file.path(output_dir, "libs", "codecheck")
  if (!dir.exists(libs_dir)) {
    dir.create(libs_dir, recursive = TRUE)
  }

  # Get paths to JS files in package
  pkg_js_dir <- system.file("extdata", "js", package = "codecheck")

  # Copy all JS files to libs/codecheck
  js_files <- list.files(pkg_js_dir, pattern = "\\.js$", full.names = TRUE)
  for (js_file in js_files) {
    file.copy(js_file, file.path(libs_dir, basename(js_file)), overwrite = TRUE)
  }

  message("Copied ", length(js_files), " JavaScript files to ", libs_dir)
}
