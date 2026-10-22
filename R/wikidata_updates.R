# What the export would add to items that already exist (codecheckers/register#50).
#
# preview_wikidata_export() only creates: an item that exists keeps its
# statements, because that preview is about what is missing. The model does
# change, though - a new statement, a value the register learned later - and an
# item created before that change never gets it. This is the second set: every
# statement the model would write on an existing item and the item does not
# carry yet.
#
# Only additions. A property the item already has is never written again with
# another value, because on Wikidata that is a second value, not a correction;
# such a difference is reported for a person to look at. Labels and
# descriptions are left alone for the same reason as in the export.
#
# Where the item came from matters for how much to trust such a batch: an item
# the CODECHECK export created holds exactly what the model wrote, and adding to
# it is finishing our own work, while an item somebody else created - a work
# imported from CrossRef, a certificate entered by hand - is shared, and its
# gaps may be deliberate. The first revision of an item says who created it,
# and a QuickStatements create names its batch, which the edit log records.

#' Properties that say the same thing in two ways
#'
#' An author is either an item (`P50`) or a name string (`P2093`), and a work
#' that has its authors one way must not get them a second time the other way.
#'
#' @keywords internal
WIKIDATA_EQUIVALENT_PROPERTIES <- list(c("P50", "P2093"))

#' The comparable form of a QuickStatements value token
#'
#' @param token a value as [quickstatements_value()] writes it
#' @return the value, without quotes, language or time precision, uppercased
#' @keywords internal
quickstatements_token_key <- function(token) {
  token <- sub("^[a-z-]+:\"", "\"", token)
  token <- sub("^\"(.*)\"$", "\\1", token)
  token <- gsub("\\\\\"", "\"", token)
  # Day precision is all the model writes, and a stored time carries a clock.
  if (grepl("^\\+[0-9]{4}-", token)) token <- substr(token, 2, 11)
  toupper(token)
}

#' The comparable form of a claim's value
#'
#' The counterpart of [quickstatements_token_key()] for a claim as
#' `wbgetentities` returns it.
#'
#' @param claim one claim
#' @return the value, uppercased, or `NA` for "no value" and "unknown value"
#' @keywords internal
wikidata_claim_key <- function(claim) {
  datavalue <- claim$mainsnak$datavalue
  if (is.null(datavalue)) return(NA_character_)
  value <- datavalue$value
  key <- switch(
    datavalue$type,
    "wikibase-entityid" = value$id,
    time = substr(value$time, 2, 11),
    monolingualtext = value$text,
    if (is.character(value)) value else NA_character_
  )
  toupper(key %||% NA_character_)
}

#' The statements an existing item is missing
#'
#' Compares the commands the model would write on an item with the claims the
#' item has. A statement whose value is there already is dropped; one whose
#' property the item does not carry at all is an addition; one whose property it
#' carries with other values is a difference, reported but never written.
#'
#' @param commands the commands for the item, from
#'   [quickstatements_for_entity()] with its QID
#' @param claims the item's claims, as `wbgetentities` returns them
#' @return a `data.frame` with `property`, `proposed`, `current`, `action`
#'   (`"add"` or `"differs"`) and `command`
#' @keywords internal
wikidata_missing_statements <- function(commands, claims) {
  empty <- data.frame(property = character(0), proposed = character(0),
                      current = character(0), action = character(0),
                      command = character(0), stringsAsFactors = FALSE)
  if (length(commands) == 0) return(empty)

  current <- function(property) {
    keys <- vapply(claims[[property]] %||% list(), wikidata_claim_key, character(1))
    keys[!is.na(keys)]
  }
  carried <- function(property) {
    group <- Filter(function(g) property %in% g, WIKIDATA_EQUIVALENT_PROPERTIES)
    properties <- if (length(group) > 0) group[[1]] else property
    any(vapply(properties, function(p) length(claims[[p]] %||% list()) > 0, logical(1)))
  }

  rows <- lapply(commands, function(command) {
    fields <- strsplit(command, "\t", fixed = TRUE)[[1]]
    if (length(fields) < 3 || !grepl("^P[0-9]+$", fields[2])) return(NULL)
    property <- fields[2]
    proposed <- quickstatements_token_key(fields[3])
    values <- current(property)
    if (proposed %in% values) return(NULL)
    data.frame(
      property = property, proposed = proposed,
      current = if (length(values) == 0) NA_character_ else paste(values, collapse = "; "),
      action = if (carried(property)) "differs" else "add",
      command = command, stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0) return(empty)
  do.call(rbind, rows)
}

#' The QuickStatements batches the edit log records as run on Wikidata
#'
#' A create names its batch in the edit comment: `#temporary_batch_<id>` for a
#' run in the foreground, `batch/<id>` for one in the background. The log
#' records the same ids in the URLs of the batches it was told were submitted.
#'
#' @param log_file the edit log
#' @return the batch ids, as character
#' @keywords internal
wikidata_logged_batch_ids <- function(log_file = NULL) {
  log <- wikibase_log_read(log_file)
  log <- log[which(log$target == "wikidata" & log$status == "submitted"), ]
  text <- stats::na.omit(c(log$id, log$detail))
  unique(unlist(regmatches(text, gregexpr("[0-9]{6,}", text))))
}

#' Who created an item, and whether it was the CODECHECK export
#'
#' @param comment the edit comment of the item's first revision
#' @param batch_ids the batches the edit log records, see
#'   [wikidata_logged_batch_ids()]
#' @return `"codecheck export"` for a create from a logged batch,
#'   `"quickstatements"` for one from a batch the log does not know, and
#'   `"other"` for anything else
#' @keywords internal
wikidata_item_origin <- function(comment, batch_ids = character(0)) {
  if (is.null(comment) || length(comment) == 0 || is.na(comment)) return("other")
  batch <- regmatches(comment, regexpr("(temporary_batch_|batch/|batch #)[0-9]+", comment))
  if (length(batch) == 0) {
    return(if (grepl("#quickstatements", comment, fixed = TRUE)) "quickstatements" else "other")
  }
  if (sub("^\\D+", "", batch) %in% batch_ids) "codecheck export" else "quickstatements"
}

#' The first revision of each item
#'
#' One request per item: the revisions API only goes back to the first
#' revision for a single page.
#'
#' @param qids the items
#' @return a `data.frame` with `item`, `user`, `timestamp` and `comment`
#' @keywords internal
wikidata_item_creations <- function(qids) {
  rows <- lapply(unique(qids), function(qid) {
    pages <- wikibase_get(NULL, list(
      action = "query", prop = "revisions", titles = qid,
      rvlimit = 1, rvdir = "newer", rvprop = "user|timestamp|comment"
    ), api = WIKIDATA_API)$query$pages
    revision <- if (length(pages) > 0) pages[[1]]$revisions[[1]] else NULL
    data.frame(item = qid,
               user = revision$user %||% NA_character_,
               timestamp = revision$timestamp %||% NA_character_,
               comment = revision$comment %||% NA_character_,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

#' The claims of each item
#'
#' Read with `wbgetentities`, 50 items a request. A merged item answers under
#' the item it redirects to, so the claims are filed under the QID asked for.
#'
#' @param qids the items
#' @return a named list, QID to claims
#' @keywords internal
wikidata_item_claims <- function(qids) {
  claims <- list()
  qids <- unique(qids)
  for (batch in split(qids, ceiling(seq_along(qids) / 50))) {
    entities <- wikibase_get(NULL, list(
      action = "wbgetentities", ids = paste(batch, collapse = "|"), props = "claims"
    ), api = WIKIDATA_API)$entities
    for (id in names(entities)) {
      entity <- entities[[id]]
      from <- entity$redirects$from %||% id
      claims[[from]] <- entity$claims %||% list()
    }
  }
  claims
}

#' Plan the additions to items that already exist on Wikidata
#'
#' @param records the output of [read_register_records()]
#' @param method how to resolve against Wikidata, see [preview_wikidata_export()]
#' @param origin whether to look up who created each item, one request per item
#' @param log_file the edit log, to recognise the export's own batches
#' @return a `data.frame` with one row per statement the model would add or
#'   that differs: `kind`, `key`, `item`, `origin`, `created_by`, `property`,
#'   `proposed`, `current`, `action` and `command`
#' @keywords internal
wikidata_update_plan <- function(records, method = c("search", "sparql"),
                                 origin = TRUE, log_file = NULL) {
  method <- match.arg(method)
  known <- attr(wikidata_export_plan(records, method = method), "known")
  rows <- wikibase_export_rows(records)

  resolve <- function(entity_kind, key) {
    model <- WIKIDATA_MODEL[[entity_kind]]$resolve
    value <- wikidata_transform(key, model$transform)
    if (length(value) == 0 || is.na(value[1])) return(NA_character_)
    unname((known[[entity_kind]] %||% character(0))[value[1]])
  }

  existing <- list()
  for (kind in c("paper", "certificate")) {
    if (!wikidata_creates(kind, "wikidata")) next
    table <- rows[[kind]]
    keys <- wikibase_key_column(table, kind)
    for (i in seq_len(nrow(table))) {
      qid <- unname((known[[kind]] %||% character(0))[keys[i]])
      if (is.na(keys[i]) || length(qid) == 0 || is.na(qid)) next
      existing[[length(existing) + 1]] <- list(kind = kind, key = keys[i], item = qid,
                                               row = table[i, , drop = FALSE])
    }
  }
  if (length(existing) == 0) return(NULL)

  items <- vapply(existing, function(e) e$item, character(1))
  claims <- wikidata_item_claims(items)
  creations <- if (origin) wikidata_item_creations(items) else NULL
  batch_ids <- wikidata_logged_batch_ids(log_file)

  plan <- lapply(existing, function(e) {
    commands <- quickstatements_for_entity(e$kind, e$row, qid = e$item, resolve = resolve)
    missing <- wikidata_missing_statements(commands, claims[[e$item]] %||% list())
    if (nrow(missing) == 0) return(NULL)
    created <- if (is.null(creations)) NULL else creations[creations$item == e$item, ]
    cbind(
      data.frame(
        kind = e$kind, key = e$key, item = e$item,
        origin = if (is.null(created)) NA_character_ else wikidata_item_origin(created$comment, batch_ids),
        created_by = if (is.null(created)) NA_character_ else created$user,
        stringsAsFactors = FALSE
      ),
      missing
    )
  })
  plan <- Filter(Negate(is.null), plan)
  if (length(plan) == 0) return(NULL)
  out <- do.call(rbind, plan)
  rownames(out) <- NULL
  out
}

#' Preview the additions to items already on Wikidata
#'
#' The second set of QuickStatements next to [preview_wikidata_export()]: that
#' one creates the items that are missing, this one adds to the items that
#' exist every statement of the model they do not carry - a statement the model
#' gained after the item was created, or a value the register learned later.
#' Nothing is sent.
#'
#' Only additions are written. A statement whose property the item already
#' carries with another value is a difference, listed in the report but not in
#' the batch: on Wikidata it would become a second value rather than a
#' correction.
#'
#' Each item is marked with where it came from. `"codecheck export"` is an item
#' a batch in the edit log created, so the additions finish the export's own
#' work; `"quickstatements"` is one created by a batch the log does not record,
#' and `"other"` one somebody created otherwise - by hand, or by an import of
#' the publisher's metadata. Those are shared items, and the additions to them
#' are worth a look before they are pasted.
#'
#' @param dir the register repository to read from
#' @param out_dir where to write the batch and the report
#' @param log_file the edit log, to record the batch in and to recognise the
#'   export's own items by
#' @param records already-read records, as from [read_register_records()]
#' @param method how to resolve against Wikidata, see [preview_wikidata_export()]
#' @param origin whether to look up who created each item, one request per item
#' @return the plan, invisibly: one row per statement to add or that differs,
#'   with the item, its origin and creator, the property, the proposed and the
#'   current value, the action and the command
#' @examples
#' \dontrun{
#' preview_wikidata_updates("../register", out_dir = "wikidata",
#'                          log_file = "wikidata/wikibase-log.csv")
#' }
#' @export
preview_wikidata_updates <- function(dir = "../register", out_dir = ".",
                                     log_file = NULL, records = NULL,
                                     method = c("search", "sparql"),
                                     origin = TRUE) {
  method <- match.arg(method)
  cli::cli_h2("What the export would add to items already on Wikidata")

  if (is.null(records)) records <- read_register_records(dir)
  plan <- wikidata_update_plan(records, method = method, origin = origin,
                               log_file = log_file)
  batch <- "wikidata-updates"
  report <- file.path(out_dir, paste0(batch, ".csv"))

  if (is.null(plan)) {
    cli::cli_alert_success("Every existing item carries every statement of the model")
    return(invisible(plan))
  }

  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(plan, report, row.names = FALSE)
  cli::cli_alert_info("Report of {nrow(plan)} statement{?s} written to {.file {report}}")

  additions <- plan[plan$action == "add", ]
  differences <- plan[plan$action == "differs", ]
  if (nrow(additions) > 0) {
    # The export's own items first: those additions need the least review.
    order <- order(additions$origin != "codecheck export", additions$kind, additions$key)
    quickstatements_write(additions$command[order], batch, dir = out_dir,
                          target = "wikidata", file = log_file)
    origins <- ifelse(is.na(additions$origin), "unknown origin", additions$origin)
    for (o in unique(origins)) {
      statements <- sum(origins == o)
      items <- length(unique(additions$item[origins == o]))
      cli::cli_alert_success("{statements} statement{?s} to add on {items} item{?s} from {.emph {o}}")
    }
  } else {
    cli::cli_alert_success("Nothing to add")
  }
  if (nrow(differences) > 0) {
    cli::cli_alert_warning("{nrow(differences)} statement{?s} differ{?s/} from what the item carries: not in the batch, see the report")
  }
  invisible(plan)
}
