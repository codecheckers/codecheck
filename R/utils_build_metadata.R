#' Get Build Metadata
#'
#' Retrieves metadata about the current build including timestamp, package version,
#' and git commit information from the register repository.
#'
#' @param register_repo_path Path to the register repository (default: current directory)
#' @return A list with build metadata (timestamp, package_version, git_commit, git_commit_short, git_commit_url)
#' @importFrom utils packageVersion
#' @importFrom git2r repository commits sha remotes remote_url
#' @export
get_build_metadata <- function(register_repo_path = ".") {
  metadata <- list(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    package_version = as.character(packageVersion("codecheck"))
  )

  # Try to get git commit information
  tryCatch({
    # Check if git2r is available and we're in a git repo
    if (requireNamespace("git2r", quietly = TRUE)) {
      repo <- git2r::repository(register_repo_path, discover = TRUE)

      # Get the latest commit
      commit <- git2r::commits(repo, n = 1)[[1]]
      commit_sha <- git2r::sha(commit)

      metadata$git_commit <- commit_sha
      metadata$git_commit_short <- substr(commit_sha, 1, 7)

      # Try to construct GitHub URL
      # Check if origin remote exists
      remotes <- git2r::remotes(repo)
      if ("origin" %in% remotes) {
        remote_url <- git2r::remote_url(repo, "origin")

        # Convert SSH or HTTPS URL to GitHub web URL
        if (grepl("github.com", remote_url)) {
          # Extract owner/repo from URL
          if (grepl("git@github.com:", remote_url)) {
            # SSH format: git@github.com:owner/repo.git
            repo_path <- sub("git@github.com:", "", remote_url)
            repo_path <- sub("\\.git$", "", repo_path)
          } else {
            # HTTPS format: https://github.com/owner/repo.git
            repo_path <- sub("https://github.com/", "", remote_url)
            repo_path <- sub("\\.git$", "", repo_path)
          }
          metadata$git_commit_url <- paste0("https://github.com/", repo_path, "/commit/", commit_sha)
        }
      }
    }
  }, error = function(e) {
    # If git information is not available, set to NULL
    metadata$git_commit <- NULL
    metadata$git_commit_short <- NULL
    metadata$git_commit_url <- NULL
  })

  return(metadata)
}

#' Generate HTML Meta Generator Tag
#'
#' Creates an HTML meta generator tag with build information.
#'
#' @param metadata Build metadata from get_build_metadata()
#' @return HTML string with meta generator tag
#' @export
generate_meta_generator_tag <- function(metadata) {
  if (!is.null(metadata$git_commit_short)) {
    content <- sprintf("codecheck %s based on register commit %s",
                      metadata$package_version,
                      metadata$git_commit_short)
  } else {
    content <- sprintf("codecheck %s", metadata$package_version)
  }

  return(sprintf('<meta name="generator" content="%s">', content))
}

#' Generate Footer Build Information HTML
#'
#' Creates HTML content for displaying build information in the footer.
#' Styling should be applied in the template or CSS file.
#'
#' @param metadata Build metadata from get_build_metadata()
#' @return HTML string with build information (without wrapper styling)
#' @export
generate_footer_build_info <- function(metadata) {
  parts <- c()

  # Add timestamp
  parts <- c(parts, sprintf("Built: %s", metadata$timestamp))

  # Add package version
  parts <- c(parts, sprintf("codecheck v%s", metadata$package_version))

  # Add git commit with link if available
  if (!is.null(metadata$git_commit_short)) {
    if (!is.null(metadata$git_commit_url)) {
      parts <- c(parts, sprintf('<a href="%s">commit %s</a>',
                               metadata$git_commit_url,
                               metadata$git_commit_short))
    } else {
      parts <- c(parts, sprintf("commit %s", metadata$git_commit_short))
    }
  }

  # Return content without styling wrapper
  return(paste(parts, collapse = " | "))
}

#' Write Build Metadata to JSON File
#'
#' Writes build metadata to a .meta.json file in the specified directory.
#'
#' @param metadata Build metadata from get_build_metadata()
#' @param output_path Path where .meta.json should be written (default: current directory)
#' @importFrom jsonlite write_json
#' @export
write_meta_json <- function(metadata, output_path = ".") {
  filepath <- file.path(output_path, ".meta.json")
  jsonlite::write_json(metadata, filepath, pretty = TRUE, auto_unbox = TRUE)
  message("Build metadata written to ", filepath)
}
