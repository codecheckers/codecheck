# Suppress R CMD check warnings for non-standard evaluation variables
# These are used in dplyr/data.table operations and the CONFIG environment
utils::globalVariables(c(
  ":=",           # data.table assignment operator
  "CONFIG",       # Global configuration environment
  "Codechecker",  # Column name in register data
  "Paper Title",  # Column name in register data
  "Repository",   # Column name in register data
  "Type",         # Column name in register data
  "Venue",        # Column name in register data
  "repository",   # Variable name in data operations
  "venue_slug"    # Variable name in data operations
))

##' Create template files for the codecheck process.
##'
##' This function simply creates some template files to help start the
##' codecheck process.  If either ./codecheck.yml or codecheck/ exists then
##' it assumes you have already started codechecking, and so will not copy any
##' files across.
##' @title Create template files for the codecheck process.
##' @param template Which certificate source template(s) to copy: `"all"`
##'   (default) copies both the R Markdown (`codecheck.Rmd`) and Quarto
##'   (`codecheck.qmd`) templates, `"rmd"` copies only `codecheck.Rmd`, and
##'   `"qmd"` copies only `codecheck.qmd`. Shipping both is convenient while
##'   deciding, but only one should end up committed/published, since having
##'   both makes it unclear which is the canonical certificate source (see
##'   the sibling-template warnings in each template and the Zenodo policy
##'   check in `zenodo_policy_check()`).
##' @return Nothing
##' @author Stephen J. Eglen
##' @export
create_codecheck_files <- function(template = c("all", "rmd", "qmd")) {
  template <- match.arg(template)

  if (file.exists("codecheck.yml"))
    warning("codecheck.yml already exists, so not overwriting it.",
            "See the template file at ",
            system.file("extdata", "templates/codecheck.yml", package="codecheck"),
            " for required metadata and examples.")
  else
    copy_codecheck_yaml_template()

  if (dir.exists("codecheck"))
    stop("codecheck folder exists, so stopping.")
  else
    copy_codecheck_report_template(template = template)
}

copy_codecheck_yaml_template <- function(target = ".") {
  templates <- system.file("extdata", "templates", package="codecheck")
  file.copy(file.path(templates, "codecheck.yml"), target)
  cli::cli_alert_success("Created {.file codecheck.yml} at {.path {target}}")
}

copy_codecheck_report_template <- function(target = ".", template = c("all", "rmd", "qmd")) {
  template <- match.arg(template)

  templates <- system.file("extdata", "templates", package="codecheck")
  src_dir <- file.path(templates, "codecheck")
  report_dir <- file.path(target, "codecheck")
  dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

  shared_files <- c("codecheck-preamble.sty", "Makefile", "codecheck-zenodo.R",
                     "CODECHECK_report_template.docx", "CODECHECK_report_template.odt",
                     "placeholder_output.txt")
  file.copy(file.path(src_dir, shared_files), report_dir)
  # "outputs/" is an empty directory in the template source, so git does not
  # track it and R CMD build strips it from the package tarball - it may not
  # exist in an installed package, in which case there is nothing to copy.
  if (dir.exists(file.path(src_dir, "outputs")))
    file.copy(file.path(src_dir, "outputs"), report_dir, recursive = TRUE)

  if (template %in% c("all", "rmd"))
    file.copy(file.path(src_dir, "codecheck.Rmd"), report_dir)
  if (template %in% c("all", "qmd"))
    file.copy(file.path(src_dir, "codecheck.qmd"), report_dir)

  cli::cli_alert_success(
    "Created CODECHECK certificate files in {.path {report_dir}}: {toString(list.files(report_dir))}"
  )
}

##' Return the metadata for the codecheck project in root folder of project
##'
##' Loads and parses the codecheck.yml file from the specified directory.
##' If the file doesn't exist, stops with a clear error message.
##'
##' @title Return the metadata for the codecheck project in root folder of project
##' @param root Path to the root folder of the project, defaults to current working directory
##' @return A list containing the metadata found in the codecheck.yml file
##' @author Stephen Eglen
##' @importFrom yaml read_yaml
##' @export
codecheck_metadata <- function(root = getwd()) {
  yml_path <- file.path(root, "codecheck.yml")

  if (!file.exists(yml_path)) {
    stop("No codecheck.yml file found in directory: ", root, "\n",
         "Please create a codecheck.yml file first using create_codecheck_files() ",
         "or run this function from a directory containing a codecheck.yml file.")
  }

  yaml::read_yaml(yml_path)
}

##' Get git repository information
##'
##' Returns a formatted string with git commit information if the path is
##' in a git repository, otherwise returns an empty string. This is used
##' in certificate templates to document which commit was checked.
##'
##' @title Get git repository information
##' @param path Path to check for git repository (defaults to current working directory)
##' @return A character string with commit information, or empty string if not in a git repo
##' @author Daniel Nuest
##' @importFrom git2r in_repository repository last_commit
##' @export
##' @examples
##' \dontrun{
##'   # In a git repository
##'   get_git_info(".")
##'   # Returns: "This check is based on the commit `abc123...`."
##'
##'   # Not in a git repository
##'   get_git_info("/tmp")
##'   # Returns: ""
##' }
get_git_info <- function(path = getwd()) {
  gitInfo <- ""

  tryCatch({
    if (git2r::in_repository(path)) {
      repo <- git2r::repository(path, discover = TRUE)
      commit <- git2r::last_commit(repo)
      gitInfo <- paste0("This check is based on the commit `", commit$sha, "`.")
    }
  }, error = function(e) {
    # If git2r fails for any reason, just return empty string
    # This ensures certificate rendering doesn't fail due to git issues
    gitInfo <<- ""
  })

  return(gitInfo)
}
