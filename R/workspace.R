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
##' @return Nothing
##' @author Stephen J. Eglen
##' @export
create_codecheck_files <- function() {
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
    copy_codecheck_report_template()
}

copy_codecheck_yaml_template <- function(target = ".") {
  templates <- system.file("extdata", "templates", package="codecheck")
  file.copy(file.path(templates, "codecheck.yml"), target)
  cat("Created codecheck.yml file at ", target, "\n")
}

copy_codecheck_report_template <- function(target = ".") {
  templates <- system.file("extdata", "templates", package="codecheck")
  file.copy(file.path(templates, "codecheck"), target, recursive = TRUE)
  cat("Created CODECHECK certificate files at ", target, ":", toString(list.files("codecheck")), "\n")
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
