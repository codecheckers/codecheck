#' Prefix every log line with the time elapsed since the render started
#'
#' `verbose = TRUE` reports how long each page took, but not when anything
#' happened, so a phase that takes a minute between two summary lines is
#' invisible unless the whole process is piped through a stamping filter. The
#' handler below does that inside R: each message - which is how cli writes its
#' output - is re-emitted with an elapsed-seconds prefix.
#'
#' Forked workers inherit the calling handlers of the process they were forked
#' from, so pages rendered in parallel are stamped as well.
#'
#' @param enabled Whether to stamp at all; FALSE evaluates `expr` unchanged
#' @param expr The expression to evaluate (lazily, inside the handler)
#' @param start Time the elapsed seconds are counted from
#' @return The value of `expr`
with_elapsed_log <- function(expr, enabled = TRUE, start = Sys.time()) {
  if (!isTRUE(enabled)) {
    return(expr)
  }

  withCallingHandlers(
    expr,
    message = function(m) {
      text <- conditionMessage(m)
      elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
      prefix <- sprintf("[%7.1fs] ", elapsed)

      ends_with_newline <- endsWith(text, "\n")
      lines <- strsplit(sub("\n$", "", text), "\n", fixed = TRUE)[[1]]
      if (length(lines) == 0) {
        lines <- ""
      }

      # Blank separator lines stay blank - a stamp on its own reads as an
      # event that did not happen.
      stamped <- ifelse(nzchar(trimws(lines)), paste0(prefix, lines), lines)

      cat(paste0(paste(stamped, collapse = "\n"), if (ends_with_newline) "\n" else ""),
          file = stderr())
      invokeRestart("muffleMessage")
    }
  )
}
