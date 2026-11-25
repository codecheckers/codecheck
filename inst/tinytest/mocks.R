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


#' A mock_response() carrying a JSON body, enough for httr::content(), also
#' with "parsed", which looks the content type up case-insensitively.
#'
#' @param body a JSON string, or an R value to serialise
mock_json_response <- function(url, body, status = 200L) {
  response <- mock_response(url, status)
  response$headers <- structure(list(`content-type` = "application/json; charset=utf-8"),
                                class = c("insensitive", "list"))
  if (!is.character(body)) {
    body <- jsonlite::toJSON(body, auto_unbox = TRUE, null = "null")
  }
  response$content <- charToRaw(as.character(body))
  response
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


#' Answer zen4R's vocabulary lookups without the Zenodo API.
#'
#' zen4R checks every licence, language and resource type it is given against
#' the live Zenodo API, from a ZenodoManager it creates itself, so the codecheck
#' namespace mocks above cannot reach it. A Zenodo outage then aborted the test
#' run: a 504 page is not JSON, and zen4R fails parsing it. The three lookups
#' are replaced on the R6 class, which every new ZenodoManager picks up, and
#' simply accept the identifier they are asked about.
#'
#' @return A function that puts the original methods back; call it at the end
#'   of the test file.
mock_zenodo_vocabularies <- function() {
  methods <- c("getLicenseById", "getLanguageById", "getResourceTypeById")
  originals <- zen4R::ZenodoManager$public_methods[methods]
  for (method in methods) {
    zen4R::ZenodoManager$set("public", method, function(id) list(id = id),
                             overwrite = TRUE)
  }
  function() {
    for (method in methods) {
      zen4R::ZenodoManager$set("public", method, originals[[method]],
                               overwrite = TRUE)
    }
  }
}

#' Run a lookup against a live service, or skip it when the service is down
#'
#' A test that calls a service live checks the package's handling of its
#' answers, not the service's uptime: an OSF outage, answering 500 for an hour,
#' failed R CMD check of a release. An error whose message matches `outage`
#' becomes a message and `NULL`, so the caller leaves out the assertions on
#' the result; any other error is raised as before.
#'
#' @param expr the lookup
#' @param service the service's name, for the message
#' @param outage a regular expression for the errors that mean the service is
#'   down, e.g. an HTTP 5xx status
#' @return the value of `expr`, or `NULL` during an outage
live_or_outage <- function(expr, service, outage) {
  tryCatch(expr, error = function(e) {
    if (!grepl(outage, conditionMessage(e))) stop(e)
    message(service, " is down, skipping its checks: ", conditionMessage(e))
    NULL
  })
}

# get_osf_cert_link() on an OSF API that answers 5xx or not at all
OSF_OUTAGE <- "Failed to retrieve files: (5[0-9]{2}|no response)"
