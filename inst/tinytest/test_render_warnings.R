# register_render() holds its warnings back until the end, so when a render
# fails they are printed before the error propagates - they usually explain
# it, e.g. a codecheck.yml that could not be fetched (codecheckers/register#241)

report <- getFromNamespace("report_captured_warnings", "codecheck")

capture_cli <- function(expr) {
  out <- character(0)
  withCallingHandlers(expr, message = function(m) {
    out <<- c(out, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
  paste(out, collapse = "")
}

warnings_seen <- c("2026-033 | No check date: codecheck.yml from github::a/b could not be read",
                   "something else", "something else")

out <- capture_cli(report(warnings_seen, failed = TRUE))
expect_true(grepl("3 warnings (2 unique) before the render failed", out, fixed = TRUE), info = out)
expect_true(grepl("2026-033 | No check date", out, fixed = TRUE), info = out)
expect_true(grepl("[x2] something else", out, fixed = TRUE), info = out)

out <- capture_cli(report(warnings_seen))
expect_false(grepl("before the render failed", out, fixed = TRUE), info = out)

out <- capture_cli(report(character(0), failed = TRUE))
expect_true(grepl("No warnings before the render failed", out, fixed = TRUE), info = out)
expect_equal(capture_cli(report(character(0))), "")

# the error handler in register_render(): warnings raised before an error are
# reported, then the error itself still reaches the caller unchanged
render_like <- function() {
  captured <- character(0)
  withCallingHandlers(
    {
      warning("2026-033 | No check date: codecheck.yml could not be read")
      stop("argument 1 is not a vector")
    },
    warning = function(w) {
      captured <<- c(captured, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    error = function(e) report(captured, failed = TRUE)
  )
}
out <- capture_cli(err <- tryCatch(render_like(), error = function(e) conditionMessage(e)))
expect_equal(err, "argument 1 is not a vector")
expect_true(grepl("2026-033 | No check date", out, fixed = TRUE), info = out)
