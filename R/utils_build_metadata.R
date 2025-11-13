#' Get Build Metadata
#'
#' Retrieves metadata about the current build including timestamp, package version,
#' and git commit information from both the register and codecheck package repositories.
#'
#' @param register_repo_path Path to the register repository (default: current directory)
#' @param codecheck_repo_path Optional path to the codecheck package repository (default: NULL, will attempt to find it)
#' @return A list with build metadata including commits from both repositories
#' @importFrom utils packageVersion
#' @importFrom git2r repository commits sha remotes remote_url
#' @export
get_build_metadata <- function(register_repo_path = ".", codecheck_repo_path = NULL) {
  metadata <- list(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    package_version = as.character(packageVersion("codecheck"))
  )

  # Helper function to get git info for a repository
  get_repo_git_info <- function(repo_path, prefix) {
    info <- list()
    tryCatch({
      if (requireNamespace("git2r", quietly = TRUE)) {
        repo <- git2r::repository(repo_path, discover = TRUE)
        commit <- git2r::commits(repo, n = 1)[[1]]
        commit_sha <- git2r::sha(commit)

        info[[paste0(prefix, "_commit")]] <- commit_sha
        info[[paste0(prefix, "_commit_short")]] <- substr(commit_sha, 1, 7)

        # Try to construct GitHub URL
        remotes <- git2r::remotes(repo)
        if ("origin" %in% remotes) {
          remote_url <- git2r::remote_url(repo, "origin")

          if (grepl("github.com", remote_url)) {
            # Extract owner/repo from URL
            if (grepl("git@github.com:", remote_url)) {
              repo_path <- sub("git@github.com:", "", remote_url)
              repo_path <- sub("\\.git$", "", repo_path)
            } else {
              repo_path <- sub("https://github.com/", "", remote_url)
              repo_path <- sub("\\.git$", "", repo_path)
            }
            info[[paste0(prefix, "_commit_url")]] <- paste0("https://github.com/", repo_path, "/commit/", commit_sha)
          }
        }
      }
    }, error = function(e) {
      info[[paste0(prefix, "_commit")]] <- NULL
      info[[paste0(prefix, "_commit_short")]] <- NULL
      info[[paste0(prefix, "_commit_url")]] <- NULL
    })
    return(info)
  }

  # Get register repository git info
  register_info <- get_repo_git_info(register_repo_path, "register")
  metadata <- c(metadata, register_info)

  # Get codecheck package repository git info if path provided
  if (!is.null(codecheck_repo_path) && dir.exists(codecheck_repo_path)) {
    codecheck_info <- get_repo_git_info(codecheck_repo_path, "codecheck")
    metadata <- c(metadata, codecheck_info)
  }

  return(metadata)
}

#' Generate Meta Generator Content
#'
#' Creates the content value for the HTML meta generator tag with build information.
#'
#' @param metadata Build metadata from get_build_metadata()
#' @return String with generator content (without HTML tags)
#' @export
generate_meta_generator_content <- function(metadata) {
  parts <- c(sprintf("codecheck %s", metadata$package_version))

  # Add register commit info
  if (!is.null(metadata$register_commit_short)) {
    parts <- c(parts, sprintf("register commit %s", metadata$register_commit_short))
  }

  # Add codecheck commit info if available
  if (!is.null(metadata$codecheck_commit_short)) {
    parts <- c(parts, sprintf("package commit %s", metadata$codecheck_commit_short))
  }

  return(paste(parts, collapse=", "))
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

  # Add codecheck package git commit with link if available
  if (!is.null(metadata$codecheck_commit_short)) {
    if (!is.null(metadata$codecheck_commit_url)) {
      parts <- c(parts, sprintf('codecheck <a href="%s">%s</a>',
                               metadata$codecheck_commit_url,
                               metadata$codecheck_commit_short))
    } else {
      parts <- c(parts, sprintf("codecheck %s", metadata$codecheck_commit_short))
    }
  }

  # Add register git commit with link if available
  if (!is.null(metadata$register_commit_short)) {
    if (!is.null(metadata$register_commit_url)) {
      parts <- c(parts, sprintf('register <a href="%s">%s</a>',
                               metadata$register_commit_url,
                               metadata$register_commit_short))
    } else {
      parts <- c(parts, sprintf("register %s", metadata$register_commit_short))
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
