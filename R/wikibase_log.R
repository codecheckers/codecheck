# The record of what was written where (codecheckers/register#50).
#
# The export has two routes and they could not be more different. Our own
# Wikibase is written through the API: authenticated, idempotent, repeatable at
# will. Wikidata is not - the ~132 certificate items are submitted once, as
# QuickStatements batches pasted into the web interface by a person under their
# own account, because that is what keeps this within bot policy without
# operating a bot.
#
# The manual route is the one that needs the log more. An API write that failed
# can simply be repeated; a batch somebody pasted at some point last week,
# against an item set that has since changed, cannot be reconstructed from
# anywhere. So both routes append to the same log: what was prepared, what was
# actually submitted, and when.

#' The columns of the edit log
#'
#' @keywords internal
WIKIBASE_LOG_COLUMNS <- c("time", "target", "action", "kind", "id", "label",
                          "status", "batch", "detail")

#' Where the edit log is written
#'
#' `NULL` - the default - means no log is kept, which is what an exploratory
#' `dry_run` wants. Set `options(codecheck.wikibase_log = "wikibase-log.csv")`,
#' or pass a path, to keep one.
#'
#' @param file an explicit path, or `NULL` to fall back to the option
#' @return the path, or `NULL`
#' @keywords internal
wikibase_log_file <- function(file = NULL) {
  if (!is.null(file)) return(file)
  getOption("codecheck.wikibase_log", NULL)
}

#' Append entries to the edit log
#'
#' Appends rather than rewrites, and never fails the write it is recording: a
#' log that cannot be written is worth a warning, not a lost edit.
#'
#' @param ... columns of one entry, named as in [WIKIBASE_LOG_COLUMNS]; `time`
#'   is filled in
#' @param file the log path, or `NULL` to keep no log
#' @return the entry, invisibly
#' @keywords internal
wikibase_log <- function(..., file = NULL) {
  entry <- list(...)
  entry$time <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  row <- as.data.frame(
    lapply(stats::setNames(WIKIBASE_LOG_COLUMNS, WIKIBASE_LOG_COLUMNS),
           function(column) as.character(entry[[column]] %||% NA_character_)),
    stringsAsFactors = FALSE
  )

  file <- wikibase_log_file(file)
  if (is.null(file)) return(invisible(row))

  tryCatch({
    exists_already <- file.exists(file)
    utils::write.table(row, file, append = exists_already, sep = ",",
                       row.names = FALSE, col.names = !exists_already,
                       qmethod = "double")
  }, error = function(e) {
    warning("Could not append to the edit log at ", file, ": ", conditionMessage(e))
  })
  invisible(row)
}

#' Read the edit log back
#'
#' @param file the log path, or `NULL` to use the option
#' @return a `data.frame`, empty when there is no log yet
#' @keywords internal
wikibase_log_read <- function(file = NULL) {
  file <- wikibase_log_file(file)
  empty <- stats::setNames(
    as.data.frame(matrix(character(0), ncol = length(WIKIBASE_LOG_COLUMNS)),
                  stringsAsFactors = FALSE),
    WIKIBASE_LOG_COLUMNS
  )
  if (is.null(file) || !file.exists(file)) return(empty)
  utils::read.csv(file, colClasses = "character")
}

#' Write a QuickStatements batch out for somebody to paste
#'
#' The Wikidata half of the export is a person copying commands into
#' QuickStatements under their own account, so what the code can do is prepare
#' exactly what they paste, keep a copy of it, and record that it was prepared.
#' The file is the evidence of what was submitted; without it, a batch that
#' half-succeeded is unreconstructable, since the register will have moved on.
#'
#' @param commands the QuickStatements v1 commands, one per element
#' @param batch a name for this batch, used for the file name and in the log
#' @param dir where to write the `.qs` file
#' @param target `"wikidata"` or `"wikibase"`, which instance it is meant for
#' @param file the log path, or `NULL` to use the option
#' @return the path of the written file, invisibly
#' @export
quickstatements_write <- function(commands, batch, dir = ".",
                                  target = c("wikidata", "wikibase"),
                                  file = NULL) {
  target <- match.arg(target)
  path <- file.path(dir, paste0(batch, ".qs"))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  writeLines(commands, path)

  wikibase_log(target = target, action = "quickstatements", kind = "batch",
               id = path, label = batch, status = "prepared",
               batch = batch, detail = paste(length(commands), "commands"),
               file = file)

  where <- if (target == "wikidata") "https://quickstatements.toolforge.org/"
           else WIKIBASE_INSTANCE$quickstatements
  cli::cli_alert_info("{length(commands)} command{?s} written to {.file {path}}")
  cli::cli_alert_info("Paste them into {.url {where}}, then record the batch with
                       {.code quickstatements_submitted('{batch}', url = ...)}")
  invisible(path)
}

#' Record that a QuickStatements batch was actually submitted
#'
#' The one thing the code cannot observe, and the one thing worth knowing later:
#' that a prepared batch was pasted, by whom it was run and where its result can
#' be seen. QuickStatements gives every run a batch URL; that is what belongs
#' here.
#'
#' @param batch the batch name given to [quickstatements_write()]
#' @param url the QuickStatements batch URL, if there is one
#' @param note anything worth recording, e.g. which commands failed
#' @param file the log path, or `NULL` to use the option
#' @return the log entry, invisibly
#' @examples
#' \dontrun{
#' quickstatements_submitted("certificates-2026-09", url = "https://...batch/12345")
#' }
#' @export
quickstatements_submitted <- function(batch, url = NA_character_,
                                      note = NA_character_, file = NULL) {
  prepared <- wikibase_log_read(file)
  prepared <- prepared[which(prepared$batch == batch & prepared$status == "prepared"), ]
  if (nrow(prepared) == 0) {
    warning("No prepared batch called '", batch, "' in the log - recording it anyway")
  }
  target <- if (nrow(prepared) > 0) prepared$target[1] else "wikidata"

  wikibase_log(target = target, action = "quickstatements", kind = "batch",
               id = url, label = batch, status = "submitted", batch = batch,
               detail = note, file = file)
}
