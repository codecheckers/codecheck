# Lookups of remote resources that failed because a service was down.
#
# A lookup that fails is not cached and the render carries on without its
# value, so a render can complete with data missing that the previous one had:
# an OSF outage took certificates' codecheckers off the statistics pages, and CI
# committed that (codecheckers/register#247). register_render() therefore fails
# at its end when a lookup failed because a service was down, so that CI
# commits nothing and a later render asks again; successful lookups stay
# cached, so it asks only for what failed.
#
# Two things must hold for a failure to count, and no single layer knows both.
# The HTTP layer knows that a service was down - a server error, a rate limit,
# a timeout, no connection - but not whether the caller recovered, e.g. by a
# title search after a failed DOI lookup. The lookup knows whether it ended
# without a value, but not why: a 404 or broken YAML will be the same next time
# and must not fail every render. So a lookup runs in a scope that collects the
# outages its requests hit (note_outage()), and records them only if it ends
# without a value (collect_outages()). An outage outside any scope is recorded
# right away.
#
# The record is a file named by an environment variable rather than a variable
# in memory, so that the workers of a parallel render - forked by mclapply() or
# started by parLapply(), both of which inherit the environment - add to it too.

#' Start recording failed lookups
#'
#' @return the path of the record, to pass to [stop_lookup_failures()]
#' @keywords internal
start_lookup_failures <- function() {
  path <- tempfile("codecheck-lookup-failures-", fileext = ".txt")
  file.create(path)
  # a render interrupted inside a lookup leaves its scope behind
  outage_scopes$stack <- list()
  Sys.setenv(CODECHECK_LOOKUP_FAILURES = path)
  path
}

#' Record a failed lookup, when a render is recording them
#'
#' An API key in a URL is masked: the record is printed, also in CI logs.
#'
#' @param what what could not be looked up
#' @return nothing
#' @keywords internal
record_lookup_failure <- function(what) {
  path <- Sys.getenv("CODECHECK_LOOKUP_FAILURES")
  if (!nzchar(path)) return(invisible(NULL))
  what <- gsub("([?&]api_key=)[^&[:space:]]*", "\\1***", gsub("[[:space:]]+", " ", what))
  tryCatch(cat(what, "\n", file = path, append = TRUE, sep = ""), error = function(e) NULL)
  invisible(NULL)
}

# The outages noted by the lookups running now, innermost last.
outage_scopes <- new.env(parent = emptyenv())
outage_scopes$stack <- list()

#' Note that a service was down for a request
#'
#' Inside [collect_outages()] the outage is held until the lookup ends; outside
#' any, it is recorded right away.
#'
#' @param what the request and what went wrong
#' @return nothing
#' @keywords internal
note_outage <- function(what) {
  depth <- length(outage_scopes$stack)
  if (depth == 0) {
    record_lookup_failure(what)
  } else {
    outage_scopes$stack[[depth]] <- c(outage_scopes$stack[[depth]], what)
  }
  invisible(NULL)
}

#' Run a lookup, recording the outages it hit only if it ends without a value
#'
#' @param expr the lookup
#' @param failed function of the lookup's value, `TRUE` if it has no value; a
#'   lookup that raises an error has none either
#' @return the lookup's value; its error is raised again
#' @keywords internal
collect_outages <- function(expr, failed = function(value) FALSE) {
  depth <- length(outage_scopes$stack) + 1
  outage_scopes$stack[[depth]] <- character(0)
  # popped however the lookup ends, an interrupt included
  on.exit(outage_scopes$stack <- outage_scopes$stack[seq_len(depth - 1)])
  outcome <- tryCatch(list(value = expr), error = function(e) list(error = e))
  outages <- outage_scopes$stack[[depth]]
  outage_scopes$stack <- outage_scopes$stack[seq_len(depth - 1)]
  if (!is.null(outcome$error) || isTRUE(failed(outcome$value))) {
    # to the enclosing lookup, which may still recover, e.g. by a fallback;
    # recorded if there is none
    for (outage in outages) note_outage(outage)
  }
  if (!is.null(outcome$error)) stop(outcome$error)
  outcome$value
}

#' The services the register depends on
#'
#' Only their outages fail a render. Any other site - a publisher's landing
#' page, an institutional repository - may answer 429 or 5xx to every request
#' from a script, for good: UNESCO's IIEP does, and would fail every render.
#'
#' @keywords internal
CORE_SERVICE_HOSTS <- c("osf.io", "github.com", "githubusercontent.com", "gitlab.com",
                        "zenodo.org", "openalex.org", "crossref.org", "datacite.org",
                        "doi.org", "wikidata.org", "orcid.org", "ror.org",
                        "researchequals.com", "wikibase.cloud")

#' Whether a URL is one of the services the register depends on
#'
#' @param url a URL
#' @return `TRUE` for a host in [CORE_SERVICE_HOSTS] or below one
#' @keywords internal
is_core_service <- function(url) {
  host <- tryCatch(tolower(httr::parse_url(url)$hostname %||% ""), error = function(e) "")
  any(host == CORE_SERVICE_HOSTS | endsWith(host, paste0(".", CORE_SERVICE_HOSTS)))
}

#' Stop on an outage the HTTP layer has noted already
#'
#' @param ... the message
#' @return nothing; an error of class `codecheck_noted_outage`
#' @keywords internal
stop_noted_outage <- function(...) {
  stop(structure(class = c("codecheck_noted_outage", "error", "condition"),
                 list(message = paste0(...), call = NULL)))
}

#' Whether an error says a service is unavailable for now
#'
#' For the clients that do their own HTTP (osfr, gh) and report it only as an
#' error message: a server error or rate limit by its status, a timeout, a
#' connection that failed, or an HTML error page where JSON was expected, as OSF
#' sends during an outage; and a name of a [CORE_SERVICE_HOSTS] that does not
#' resolve. Anything else - a 404, a private node, broken YAML, a malformed
#' repository specification, another host that does not resolve - is an answer. A status counts only where it is one, not as any number in a URL.
#'
#' @param e a condition
#' @return `TRUE` for an outage
#' @keywords internal
is_outage_error <- function(e) {
  message <- conditionMessage(e)
  status <- "(5[0-9]{2}|429)"
  grepl(paste0(
    "\\(", status, "\\)|HTTP (error |status )?", status, "\\b|[Ss]tatus( code)?:? ", status, "\\b|",
    "answered (HTTP )?", status, "\\b|",
    "[Tt]imeout was reached|[Oo]peration timed out|[Rr]ate limit|",
    "[Ff]ailed to connect|[Cc]ould not connect|[Cc]onnection (refused|reset|timed out)|",
    "[Rr]ecv failure|[Ss]end failure|Failure when receiving data|Empty reply from server|",
    "was not closed cleanly|SSL connect error|",
    # a service the register depends on does not go away, its name not resolving
    # is the network's fault
    "[Cc]ould not resolve host:? *(", paste(gsub(".", "\\.", CORE_SERVICE_HOSTS, fixed = TRUE), collapse = "|"),
    "|[a-z.]*\\.(", paste(gsub(".", "\\.", CORE_SERVICE_HOSTS, fixed = TRUE), collapse = "|"), "))|",
    # TODO(osfr): osfr parses OSF's HTML error page as JSON, so an outage
    # arrives as this parse error rather than as a status; file an upstream
    # issue at https://github.com/ropensci/osfr (see get_codecheck_yml_osf())
    "OSF request failed.*(lexical error|invalid char in json)"), message) ||
    any(grepl(paste0("http_(error_)?", status), class(e)))
}

#' Stop recording failed lookups, and read them
#'
#' @param path the record, see [start_lookup_failures()]
#' @return each failed lookup once; none once the record is gone
#' @keywords internal
stop_lookup_failures <- function(path) {
  Sys.unsetenv("CODECHECK_LOOKUP_FAILURES")
  failures <- if (file.exists(path)) unique(readLines(path, warn = FALSE)) else character(0)
  unlink(path)
  failures
}

#' Fail a render that could not look everything up
#'
#' Lists every failed lookup, then stops with a short error: R cuts an error
#' message off at 1000 characters, and a lookup's key can be a whole title.
#' With `options(codecheck.fail_on_outages = FALSE)` it warns instead, for a
#' test that renders with live services and is not about this.
#'
#' @param failures the failed lookups, see [stop_lookup_failures()]
#' @return nothing; an error if there are failures
#' @keywords internal
stop_on_lookup_failures <- function(failures) {
  if (length(failures) == 0) return(invisible(NULL))
  cli::cli_alert_danger("{length(failures)} lookup{?s} of remote resources failed:")
  for (failure in cli::ansi_strtrim(failures, 150)) cli::cli_bullets(c("x" = "{failure}"))
  message <- paste0(cli::pluralize("{length(failures)} lookup{?s}"),
                    " of remote resources failed (listed above), so this render is incomplete and may ",
                    "lack data the previous one had - run it again later. Every page is written.")
  if (isFALSE(getOption("codecheck.fail_on_outages", TRUE))) {
    warning(message, call. = FALSE)
    return(invisible(NULL))
  }
  stop(message, call. = FALSE)
}
