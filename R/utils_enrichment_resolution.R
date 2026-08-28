#' Read a previously rendered certificate's value at a JSON key path
#'
#' The per-certificate `index.json` written by \code{\link{generate_cert_json}}
#' is the closest thing the register has to a durable record of externally
#' enriched fields (OpenAlex ID, abstract): unlike the on-disk lookup cache, it
#' is committed to the repository and survives \code{\link{register_clear_cache}}.
#' \code{\link{resolve_external_field}} reads it as the fallback when this
#' render's live lookup did not produce a usable answer.
#'
#' @param cert_id Certificate identifier, e.g. "2020-018"
#' @param json_key_path Character vector naming the nested keys to read, e.g.
#'   `c("paper", "openalex")`
#' @return The value at that path, or `NULL` if the file, or the path within
#'   it, does not exist
#' @keywords internal
read_previous_cert_field <- function(cert_id, json_key_path) {
  json_path <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id, "index.json")

  if (!file.exists(json_path)) {
    return(NULL)
  }

  previous <- tryCatch(
    jsonlite::read_json(json_path, simplifyVector = FALSE),
    error = function(e) NULL
  )

  for (key in json_key_path) {
    if (!is.list(previous) || !(key %in% names(previous))) {
      return(NULL)
    }
    previous <- previous[[key]]
  }

  previous
}

#' Resolve an externally enriched field, protecting it from transient failures
#'
#' Every render re-fetches externally enriched fields (currently the OpenAlex
#' ID and the CrossRef/OpenAlex abstract) from scratch, and \code{docs/} is
#' fully regenerated each time - so a lookup that merely failed this run (rate
#' limiting, a network blip) would otherwise overwrite a previously-known-good
#' value with nothing, once per output format that looks the value up. This
#' function is the single place that decides what a certificate's rendered
#' output should show for such a field, given this run's lookup outcome and
#' whatever the certificate's existing `index.json` already says (register#185,
#' and the further regression that motivated this function).
#'
#' - `"found"`: the new value always wins.
#' - `"absent"` (the API conclusively has no such data): the previous value is
#'   kept unless `prune_unavailable` is `TRUE` - DOIs and abstracts are not
#'   expected to be retracted, so a confirmed absence is more often a query
#'   problem than a real removal, and removing it is a deliberate, explicit
#'   action rather than something a routine render does silently.
#' - `"failed"` (no conclusive answer - network error, rate limit): the
#'   previous value is always kept, regardless of `prune_unavailable`. A
#'   non-response is never treated as confirmation that the data is gone.
#'
#' @param cert_id Certificate identifier, used to find the previous value
#' @param json_key_path Character vector naming the nested keys where this
#'   field lives in the certificate's `index.json`, e.g. `c("paper", "openalex")`
#' @param status This run's lookup status: `"found"`, `"absent"` or `"failed"`
#' @param value This run's lookup value (used only when `status` is `"found"`)
#' @param empty_value Value to return when neither this run nor the previous
#'   render has anything - the field's own "nothing here" shape, e.g.
#'   `NA_character_` for the OpenAlex ID or `list(source = NULL, text = NULL)`
#'   for the abstract
#' @param prune_unavailable Logical; if `TRUE`, a confirmed `"absent"` result
#'   actually removes a previously-present value instead of keeping it.
#'   Defaults to `FALSE`. Set via `register_render(prune_unavailable_metadata = TRUE)`.
#' @return The resolved value to render for this certificate
#' @keywords internal
resolve_external_field <- function(cert_id, json_key_path, status, value,
                                    empty_value = NULL, prune_unavailable = FALSE) {
  if (identical(status, "found")) {
    return(value)
  }

  previous <- read_previous_cert_field(cert_id, json_key_path)
  field_label <- paste(json_key_path, collapse = ".")

  if (identical(status, "absent")) {
    if (is.null(previous)) {
      return(empty_value)
    }
    if (isTRUE(prune_unavailable)) {
      cli::cli_alert_warning(
        "{cert_id} | {field_label} confirmed no longer available, removing previous value (prune_unavailable_metadata = TRUE)"
      )
      return(empty_value)
    }
    cli::cli_alert_info(
      "{cert_id} | {field_label} came back absent this run, keeping the previous value (pass prune_unavailable_metadata = TRUE to remove it)"
    )
    return(previous)
  }

  # status == "failed": inconclusive, never treated as removal
  if (!is.null(previous)) {
    cli::cli_alert_info(
      "{cert_id} | {field_label} lookup failed this run, keeping the previous value"
    )
    return(previous)
  }
  return(empty_value)
}
