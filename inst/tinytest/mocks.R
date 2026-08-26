# Shared mocks for tests that would otherwise depend on remote services.
#
# The suite used to reach out to doi.org, Zenodo, the Zenodo sandbox, GitHub and
# ResearchEquals while testing logic that has nothing to do with those services.
# That made runs slow and, worse, non-deterministic: a 504 from doi.org aborted
# the whole suite, and a record edited upstream silently changed what a test
# asserted.
#
# tinytest only collects files matching "^test.*\\.[rR]$", so this file is not
# run as a test. Use it from a test file with source("mocks.R").


#' Replace functions inside the codecheck namespace while `expr` runs.
#'
#' The package calls its own helpers unqualified, so replacing them in the
#' namespace is what reaches the code under test. The originals are always put
#' back, including when `expr` fails.
#'
#' @param replacements named list of functions, names as in the namespace
#' @param expr evaluated with the replacements in place
with_mocked_codecheck <- function(replacements, expr) {
  originals <- lapply(names(replacements), getFromNamespace, ns = "codecheck")
  names(originals) <- names(replacements)

  for (name in names(replacements)) {
    assignInNamespace(name, replacements[[name]], ns = "codecheck")
  }
  on.exit({
    for (name in names(originals)) {
      assignInNamespace(name, originals[[name]], ns = "codecheck")
    }
  }, add = TRUE)

  force(expr)
}


#' A minimal httr response, enough for status_code(), http_error() and
#' http_status() as the package uses them.
mock_response <- function(url, status = 200L) {
  structure(list(url = url,
                 status_code = as.integer(status),
                 headers = list(),
                 all_headers = list(),
                 content = raw(0)),
            class = "response")
}


#' A codecheck_GET() answering from a table of URL patterns instead of the network.
#'
#' @param status_by_pattern named list, fixed-string pattern -> status code
#' @param default status for every URL matching no pattern
mock_codecheck_GET <- function(status_by_pattern = list(does_not_exist = 404L),
                               default = 200L) {
  function(url, ...) {
    status <- default
    for (pattern in names(status_by_pattern)) {
      if (grepl(pattern, url, fixed = TRUE)) status <- status_by_pattern[[pattern]]
    }
    mock_response(url, status)
  }
}


#' The codecheck.yml of the Zenodo sandbox record 145250, from the local copy in
#' yaml/zenodo-sandbox/, with any field overridden through `...`.
#'
#' Kept as a fixture so tests state what they need instead of depending on what
#' the sandbox record happens to contain today.
mock_codecheck_yml <- function(..., fixture = "zenodo-sandbox") {
  config <- yaml::read_yaml(file.path("yaml", fixture, "codecheck.yml"))
  overrides <- list(...)
  # plain replacement, not modifyList(): that merges recursively and iterates
  # over names(value), so it silently leaves an unnamed list such as
  # `codechecker` untouched
  for (name in names(overrides)) config[[name]] <- overrides[[name]]
  config
}


#' A get_codecheck_yml() serving a fixture instead of Zenodo, the sandbox or GitHub.
mock_get_codecheck_yml <- function(config = mock_codecheck_yml()) {
  function(x, ...) config
}
