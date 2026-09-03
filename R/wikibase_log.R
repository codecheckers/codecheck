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

#' How many items a batch may create before Wikidata throttles it
#'
#' Wikidata allows a normal account 90 edits per minute, and QuickStatements
#' writes one edit per item. A background batch pushes as fast as the API takes
#' it, so item 91 onwards is rejected - reported, unhelpfully, as "No success
#' flag set in API result". The default leaves headroom for whatever else the
#' account is doing in the same minute.
#'
#' @format a single number
#' @keywords internal
QUICKSTATEMENTS_EDIT_LIMIT <- 80

#' Split QuickStatements commands into batches of whole items
#'
#' Splits only at `CREATE`, never inside an item: the statements after a
#' `CREATE` address it as `LAST`, so a chunk boundary in the middle of one would
#' attach them to whatever the previous chunk created last.
#'
#' @param commands the QuickStatements v1 commands, one per element
#' @param size how many items per chunk
#' @return a list of command vectors; a single element if no split is needed
#' @keywords internal
quickstatements_chunks <- function(commands, size = QUICKSTATEMENTS_EDIT_LIMIT) {
  starts <- which(commands == "CREATE")
  # Anything that is not a run of CREATEs - updates to items that already have
  # QIDs - is one edit per line, and has no LAST to keep together.
  if (length(starts) == 0) {
    item <- seq_along(commands)
  } else {
    item <- cumsum(commands == "CREATE")
    # Lines before the first CREATE belong with it rather than to item zero.
    item[item == 0] <- 1
  }
  if (max(item) <= size) return(list(commands))
  unname(split(commands, (item - 1) %/% size))
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
#' @param chunk_size how many items one file may create before it is split;
#'   see [QUICKSTATEMENTS_EDIT_LIMIT]
#' @return the paths of the written files, invisibly
#' @details
#' A batch that would create more items than Wikidata lets an account edit in a
#' minute is written as several numbered files, each its own batch in the log,
#' to be pasted one after another. Splitting beforehand is the difference
#' between a run that stops cleanly at a file boundary and one that fails
#' part-way through with 42 items missing and no record of which.
#' @export
quickstatements_write <- function(commands, batch, dir = ".",
                                  target = c("wikidata", "wikibase"),
                                  file = NULL,
                                  chunk_size = QUICKSTATEMENTS_EDIT_LIMIT) {
  target <- match.arg(target)
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  chunks <- quickstatements_chunks(commands, chunk_size)
  names <- if (length(chunks) == 1) batch else
    sprintf("%s-%02d", batch, seq_along(chunks))

  where <- if (target == "wikidata") "https://quickstatements.toolforge.org/"
           else WIKIBASE_INSTANCE$quickstatements
  if (length(chunks) > 1) {
    cli::cli_alert_warning(
      "{sum(commands == 'CREATE')} items is more than the {chunk_size} an account may create per minute: split into {length(chunks)} batches to paste in turn"
    )
  }

  paths <- character(length(chunks))
  for (i in seq_along(chunks)) {
    paths[i] <- file.path(dir, paste0(names[i], ".qs"))
    writeLines(chunks[[i]], paths[i])
    wikibase_log(target = target, action = "quickstatements", kind = "batch",
                 id = paths[i], label = names[i], status = "prepared",
                 batch = names[i],
                 detail = paste(length(chunks[[i]]), "commands"),
                 file = file)
    cli::cli_alert_info("{length(chunks[[i]])} command{?s} written to {.file {paths[i]}}")
  }

  cli::cli_alert_info("Paste {cli::qty(length(chunks))}{?it/them in turn} into {.url {where}}, recording each with
                       {.code quickstatements_submitted('{names[1]}', url = ...)}")
  if (length(chunks) > 1) {
    cli::cli_alert_info("Leave a minute between them, or the next one runs into the same limit.")
  }
  invisible(paths)
}

#' Retire a batch file that has been pasted
#'
#' A `.qs` file whose batch has been run is the duplicate-paste hazard itself:
#' QuickStatements' `CREATE` has no idempotency, so a second paste makes a
#' second item for everything in it. Renaming rather than deleting keeps the
#' commands around - which ones failed is a question worth being able to answer
#' - while taking away the name that invites a paste.
#'
#' @param path the file recorded when the batch was prepared
#' @return the new path, or `NA` if there was nothing to retire
#' @keywords internal
quickstatements_retire <- function(path) {
  if (length(path) != 1 || is.na(path) || !grepl("\\.qs$", path)) return(NA_character_)
  if (!file.exists(path)) return(NA_character_)
  retired <- paste0(path, ".submitted")
  if (!file.rename(path, retired)) return(NA_character_)
  retired
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
#' @details
#' Recording a batch also retires the `.qs` file it was pasted from, renaming it
#' with a `.submitted` suffix so that a later run cannot paste the same creates
#' a second time.
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

  entry <- wikibase_log(target = target, action = "quickstatements", kind = "batch",
                        id = url, label = batch, status = "submitted", batch = batch,
                        detail = note, file = file)

  # The file this batch was pasted from must not stay pasteable.
  if (nrow(prepared) > 0) {
    retired <- quickstatements_retire(prepared$id[nrow(prepared)])
    if (!is.na(retired)) {
      cli::cli_alert_info("Batch recorded as submitted; its file is now {.file {retired}} so it cannot be pasted again")
    }
  }
  entry
}
