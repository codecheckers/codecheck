## Helpers for the `repository` field of codecheck.yml, which the spec allows
## to be one URL or a list of URLs (e.g. code and data in different places).
## yaml::read_yaml() returns such a list as a character vector, a hand-built
## metadata object may use a list, so every reader goes through
## .repository_urls() instead of checking the shape itself (codecheck#97).

## Hosts of code forges, where the repository holds code rather than data
.code_forge_hosts <- c("github.com", "gitlab.com", "codeberg.org", "bitbucket.org",
                       "git.sr.ht", "gitea.com", "gitee.com")

## Normalise the repository field of CODECHECK metadata to a character vector
##
## @param x the `repository` field: `NULL`, a string, a character vector or a list
## @return a character vector of URLs without surrounding whitespace or angle
##   brackets, and without empty entries; `character(0)` if there are none
.repository_urls <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(character(0))
  }
  urls <- as.character(unlist(x, use.names = FALSE))
  urls <- trimws(gsub("[<>]", "", urls))
  urls[!is.na(urls) & nchar(urls) > 0]
}

## Build the URL of a file in a code repository, on its default branch
##
## Only GitHub and GitLab are supported, because their `HEAD` URLs resolve to
## the default branch without knowing its name. For other hosts, and for DOIs,
## there is no reliable file URL.
##
## @param repo_url the repository URL
## @param path the file path relative to the repository root
## @return the file URL, or `NA` if the host is not supported
.repository_file_url <- function(repo_url, path) {
  repo_url <- sub("(\\.git)?/*$", "", repo_url)
  path <- sub("^/+", "", path)
  if (grepl("^https?://(www\\.)?github\\.com/[^/]+/[^/]+$", repo_url, ignore.case = TRUE)) {
    paste0(repo_url, "/blob/HEAD/", path)
  } else if (grepl("^https?://(www\\.)?gitlab\\.com/.+/[^/]+$", repo_url, ignore.case = TRUE)) {
    paste0(repo_url, "/-/blob/HEAD/", path)
  } else {
    rep(NA_character_, length(path))
  }
}
