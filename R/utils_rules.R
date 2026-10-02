#' Generate the human-readable pages of the validation rules
#'
#' Writes one page per rules file to `<output_dir>/rules/<version>/index.html`,
#' for example `docs/rules/2.0/index.html`. The pages are reachable by direct
#' URL only: there is no `rules/index.html`, nothing links to them from the
#' navigation, and they are neither in the sitemap nor indexed (`noindex`).
#'
#' The rules files are read from `rules_dir` first, because the register
#' repository holds the authoritative copies, and only fall back to the copy
#' bundled with the package, which can lag behind.
#'
#' @param output_dir Output directory (default: "docs")
#' @param rules_dir Directory searched for `rules-<version>.yml` before the
#'   bundled copies (default: the working directory, i.e. the register)
#' @return Invisibly returns the paths of the generated pages
#' @export
generate_rules_pages <- function(output_dir = "docs", rules_dir = ".") {
  local_files <- list.files(rules_dir, pattern = "^rules-[0-9.]+\\.yml$",
                            full.names = TRUE)
  bundled_files <- list.files(system.file("extdata", "rules", package = "codecheck"),
                              pattern = "^rules-[0-9.]+\\.yml$", full.names = TRUE)
  files <- c(local_files, bundled_files)
  files <- files[!duplicated(basename(files))]
  parsed <- lapply(files, yaml::read_yaml)
  versions <- vapply(parsed, function(p) as.character(p$spec_version), character(1))
  parsed <- parsed[order(package_version(versions), decreasing = TRUE)]
  versions <- versions[order(package_version(versions), decreasing = TRUE)]
  names(parsed) <- versions

  template <- paste(readLines(
    system.file("extdata", "templates/general/rules_template.html", package = "codecheck"),
    warn = FALSE), collapse = "\n")

  footer_template <- paste(readLines(
    system.file("extdata", "templates/general/footer.html", package = "codecheck"),
    warn = FALSE), collapse = "\n")
  # CONFIG only exists inside register_render(); standalone, build the metadata
  build_metadata <- if (exists("CONFIG") && exists("BUILD_METADATA", envir = CONFIG) &&
                        !is.null(CONFIG$BUILD_METADATA)) {
    CONFIG$BUILD_METADATA
  } else {
    get_build_metadata()
  }
  footer_html <- whisker::whisker.render(
    footer_template, list(build_info = generate_footer_build_info(build_metadata)))

  pages <- vapply(versions, function(version) {
    page_dir <- file.path(output_dir, "rules", version)
    dir.create(page_dir, recursive = TRUE, showWarnings = FALSE)
    html <- whisker::whisker.render(
      template, c(rules_page_data(parsed[[version]], version, versions),
        list(footer_html = footer_html)))
    page_path <- file.path(page_dir, "index.html")
    writeLines(html, page_path)
    page_path
  }, character(1))

  cli::cli_alert_success("Generated {length(pages)} rules page{?s} in {.path {file.path(output_dir, 'rules')}}")
  invisible(unname(pages))
}

#' Template data of one rules page
#' @keywords internal
#' @noRd
rules_page_data <- function(parsed, version, versions) {
  esc <- function(x) {
    x <- gsub("&", "&amp;", as.character(x), fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE)
    gsub(">", "&gt;", x, fixed = TRUE)
  }
  area_titles <- c(config = "Configuration file", metadata = "External identifiers and metadata",
                   bundle = "Bundle and repository", report = "Certificate and its archive record",
                   register = "Register entry")
  others <- setdiff(versions, version)

  rules <- parsed$rules
  areas <- unique(vapply(rules, function(r) r$area, character(1)))
  sections <- lapply(areas, function(area) {
    rows <- lapply(Filter(function(r) identical(r$area, area), rules), function(r) {
      list(
        id = esc(r$id), name = esc(r$name), severity = esc(r$severity),
        status = esc(r$status), deprecated = identical(r$status, "deprecated"),
        reference = esc(r$reference), description = esc(r$description)
      )
    })
    list(title = esc(if (area %in% names(area_titles)) area_titles[[area]] else area),
         rows = rows)
  })

  list(
    nav_header_html = generate_navigation_header(NA, "../..", list()),
    version = esc(version),
    spec_date = esc(parsed$spec_date),
    updated = esc(parsed$updated),
    count = length(rules),
    spec_url = esc(paste0("https://codecheck.org.uk/spec/config/", version, "/")),
    superseded = !identical(version, versions[1]),
    newest = esc(versions[1]),
    other_versions = lapply(others, function(v) list(version = esc(v))),
    sections = sections
  )
}
