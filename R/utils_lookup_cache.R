#' Cache the result of a metadata lookup on disk, but only when conclusive
#'
#' The register is rendered from thousands of requests to external APIs, and
#' rendering the same certificate repeatedly re-runs the same lookups. Caching
#' them keeps renders fast and stable, but caching a failed request would
#' persist a gap in the register until the cache is cleared, which is how
#' certificates lost their OpenAlex ID (register#185).
#'
#' Only conclusive results are stored: a value that was found, or an absence
#' the API actually confirmed. Failed requests (network errors, rate limiting)
#' are returned but not stored, so the next render retries them.
#'
#' The cache lives under the R.cache root and is therefore removed by
#' \code{\link{register_clear_cache}}, i.e. by `make clean`.
#'
#' @param key List of values identifying the lookup
#' @param dirs Cache subdirectory below the R.cache root
#' @param lookup Function of no arguments returning a list with elements
#'   `status` ("found", "absent" or "failed") and `value`
#' @importFrom R.cache loadCache saveCache
#' @return The `value` element of the lookup result
cached_lookup <- function(key, dirs, lookup) {
  cached_lookup_result(key, dirs, lookup)$value
}

#' Same as \code{\link{cached_lookup}}, but returns the full result
#'
#' Callers that need to tell a confirmed "absent" apart from an inconclusive
#' "failed" lookup (see \code{\link{resolve_external_field}}) need the status,
#' not just the value \code{\link{cached_lookup}} returns.
#'
#' @inheritParams cached_lookup
#' @return A list with `status` ("found", "absent" or "failed") and `value`
cached_lookup_result <- function(key, dirs, lookup) {
  cached <- tryCatch(R.cache::loadCache(key = key, dirs = dirs),
                     error = function(e) NULL)

  # only results written by this function are usable, anything else is ignored
  if (is.list(cached) && !is.null(cached$status)) {
    return(cached)
  }

  result <- lookup()

  if (!identical(result$status, "failed")) {
    tryCatch(R.cache::saveCache(result, key = key, dirs = dirs),
             error = function(e) {
               warning("Could not cache lookup result: ", conditionMessage(e))
             })
  }

  return(result)
}
