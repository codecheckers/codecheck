#' @importFrom stats median setNames
#' @keywords internal
"_PACKAGE"

#' Custom HTTP GET with proper User-Agent header
#'
#' Wraps \code{httr::GET()} with a descriptive User-Agent to avoid being
#' blocked by services like Figshare that reject default libcurl requests,
#' especially from CI runner IPs (e.g., GitHub Actions).
#'
#' @param url The URL to request
#' @param ... Additional arguments passed to \code{httr::GET()}
#' @return An \code{httr} response object
codecheck_GET <- function(url, ...) {
  ua <- paste0("codecheck/", utils::packageVersion("codecheck"),
               " (https://codecheck.org.uk; mailto:daniel.nuest@tu-dresden.de)")
  httr::GET(url,
    httr::user_agent(ua),
    ...
  )
}

#' Custom HTTP GET that retries transient failures
#'
#' Wraps \code{codecheck_GET()} and retries when the server rate limits the
#' request (HTTP 429) or reports a server error, honouring a Retry-After
#' header when one is sent. A whole register render makes thousands of
#' requests to the same few APIs, so without backing off a short burst of 429
#' responses turns into missing metadata in the rendered register.
#'
#' Waiting only helps for a short burst. OpenAlex, for example, enforces a
#' daily quota and answers with a Retry-After of several hours once it is used
#' up, and no render can wait that long. When the required wait is longer than
#' `max_wait` the response is returned as it is, so the caller can report the
#' lookup as failed and the next render retries it.
#'
#' @param url The URL to request
#' @param ... Additional arguments passed to \code{codecheck_GET()}
#' @param max_attempts Maximum number of attempts, including the first one
#' @param max_wait Longest wait between attempts, in seconds
#' @return An \code{httr} response object, or NULL if every attempt errored
codecheck_GET_retry <- function(url, ..., max_attempts = 4, max_wait = 30) {
  response <- NULL
  wait <- 1

  for (attempt in seq_len(max_attempts)) {
    response <- tryCatch(codecheck_GET(url, ...), error = function(e) NULL)

    if (!is.null(response)) {
      status <- httr::status_code(response)
      if (status != 429 && status < 500) {
        return(response)
      }

      # servers may tell us how long to wait, that beats guessing
      retry_after <- suppressWarnings(
        as.numeric(httr::headers(response)[["retry-after"]]))
      if (length(retry_after) == 1 && !is.na(retry_after) && retry_after > 0) {
        wait <- retry_after
      }

      # the quota is exhausted rather than the requests being too fast
      if (wait > max_wait) {
        return(response)
      }
    }

    if (attempt < max_attempts) {
      Sys.sleep(min(wait, max_wait))
      wait <- wait * 2
    }
  }

  return(response)
}

# Declare global variables used in NSE (non-standard evaluation)
# to avoid R CMD check NOTEs about "no visible binding for global variable"
utils::globalVariables(c(
  # Column names used in data.frame/dplyr operations
  "Certificate",
  "Certificate ID",
  "Check date",
  "codechecker_name",
  "venue_label"
))
