#' The configured OpenAlex API key
#'
#' Read from the `OPENALEX_API_KEY` environment variable, which can be set in
#' `~/.Renviron` or passed in by the register Makefile.
#'
#' Requests without a key share a small daily quota that a single register
#' render exhausts, after which OpenAlex answers 429 and certificates are
#' rendered without their OpenAlex ID. A free key raises that quota tenfold,
#' see https://help.openalex.org/api.
#'
#' @return The API key, or an empty string when none is configured
openalex_api_key <- function() {
  Sys.getenv("OPENALEX_API_KEY", unset = "")
}

#' Add the OpenAlex API key to a request URL
#'
#' OpenAlex authenticates with an `api_key` query parameter. The URL is
#' returned unchanged when no key is configured, requests then use the free
#' anonymous quota.
#'
#' @param url The OpenAlex API URL, with or without existing query parameters
#' @return The URL, with the API key appended when one is configured
openalex_url_with_key <- function(url) {
  key <- openalex_api_key()

  if (nchar(key) == 0) {
    return(url)
  }

  separator <- if (grepl("?", url, fixed = TRUE)) "&" else "?"
  paste0(url, separator, "api_key=", utils::URLencode(key, reserved = TRUE))
}

#' GET an OpenAlex API URL with the configured API key and retries
#'
#' @param url The OpenAlex API URL
#' @param ... Additional arguments passed to \code{codecheck_GET_retry()}
#' @return An \code{httr} response object, or NULL if every attempt errored
codecheck_GET_openalex <- function(url, ...) {
  response <- codecheck_GET_retry(openalex_url_with_key(url), ...)

  # a rejected key is a configuration problem and would otherwise look like
  # every paper having disappeared from OpenAlex
  if (!is.null(response) && httr::status_code(response) == 401) {
    warning("OpenAlex rejected the API key set in OPENALEX_API_KEY")
  }

  return(response)
}
