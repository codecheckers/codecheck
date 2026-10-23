# What the export would add to items that already exist (codecheckers/register#50).
#
# preview_wikidata_export() only creates: an item that exists keeps its
# statements, because that preview is about what is missing. The model does
# change, though - a new statement, a value the register learned later - and an
# item created before that change never gets it. This is the second set: every
# statement the model would write on an existing item and the item does not
# carry yet.
#
# A property the item already has is never written again with another value,
# because on Wikidata that is a second value, not a correction; such a
# difference is reported for a person to look at. The one exception is what the
# export wrote itself: a statement whose only references point into the
# register, and whose value the model no longer produces, is removed - the
# register learned better, and the export cleans up after itself. Labels and
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

#' Whether a claim was written by the CODECHECK export alone
#'
#' Every statement the export writes carries a reference URL into the register
#' (see [WIKIDATA_REFERENCE]). A claim all of whose references are such URLs
#' rests on the register alone, and when the register no longer supports it the
#' claim can go. One that somebody else referenced as well is shared: the value
#' may be wrong for our reasons and right for theirs.
#'
#' @param claim one claim, with its references
#' @return `"ours"`, `"shared"` (ours among others) or `"theirs"`
#' @keywords internal
wikidata_claim_provenance <- function(claim) {
  references <- claim$references %||% list()
  if (length(references) == 0) return("theirs")
  ours <- vapply(references, function(reference) {
    urls <- vapply(reference$snaks$P854 %||% list(), function(snak) {
      snak$datavalue$value %||% NA_character_
    }, character(1))
    any(startsWith(urls, WIKIDATA_REGISTER_URL), na.rm = TRUE)
  }, logical(1))
  if (all(ours)) "ours" else if (any(ours)) "shared" else "theirs"
}

#' Where the reference URLs of the export point
#'
#' @keywords internal
WIKIDATA_REGISTER_URL <- "https://codecheck.org.uk/register/"

#' A claim's value as QuickStatements v1 writes it
#'
#' For removing the claim: QuickStatements finds the statement to remove by
#' its value, so the value has to be written exactly as stored.
#'
#' @param claim one claim
#' @return the value token, or `NA` for "no value" and "unknown value"
#' @keywords internal
wikidata_claim_token <- function(claim) {
  datavalue <- claim$mainsnak$datavalue
  if (is.null(datavalue)) return(NA_character_)
  value <- datavalue$value
  switch(
    datavalue$type,
    "wikibase-entityid" = value$id,
    time = paste0(value$time, "/", value$precision),
    monolingualtext = paste0(value$language, ":", quickstatements_value("string", value$text)),
    if (is.character(value)) quickstatements_value("string", value) else NA_character_
  )
}

#' The statements an existing item is missing, and those it should lose
#'
#' Compares the commands the model would write on an item with the claims the
#' item has. A statement whose value is there already is dropped; one whose
#' property the item does not carry at all is an addition; one whose property it
#' carries with other values is a difference, reported but never written.
#'
#' Given the item and the model's properties, it also looks the other way, at
#' the claims the export wrote alone (see [wikidata_claim_provenance()]). One
#' of those is a removal when its value is known to be wrong - listed in
#' `rejected`, such as an OpenAlex ID whose record turned out to be another
#' work's - or when the model now writes another value for the property, such as
#' a corrected title. A property the model writes nothing for is left as it is:
#' that the register no longer knows a value does not make the value wrong. The
#' removed claim no longer counts as carried, so its replacement is an addition
#' rather than a difference. A claim the export wrote together with somebody
#' else is reported as `"shared"` and left alone.
#'
#' @param commands the commands for the item, from
#'   [quickstatements_for_entity()] with its QID
#' @param claims the item's claims, as `wbgetentities` returns them
#' @param item the item's QID, needed for removals
#' @param properties the properties the model writes on this kind of item;
#'   empty for no removals
#' @param rejected a named list, property to the values (as
#'   [wikidata_claim_key()] gives them) known to be wrong for this item
#' @return a `data.frame` with `property`, `proposed`, `current`, `action`
#'   (`"add"`, `"differs"`, `"remove"` or `"shared"`) and `command`
#' @keywords internal
wikidata_missing_statements <- function(commands, claims, item = NULL,
                                        properties = character(0),
                                        rejected = list()) {
  empty <- data.frame(property = character(0), proposed = character(0),
                      current = character(0), action = character(0),
                      command = character(0), stringsAsFactors = FALSE)

  desired <- lapply(commands, function(command) {
    fields <- strsplit(command, "\t", fixed = TRUE)[[1]]
    if (length(fields) < 3 || !grepl("^P[0-9]+$", fields[2])) return(NULL)
    list(property = fields[2], key = quickstatements_token_key(fields[3]), command = command)
  })
  desired <- Filter(Negate(is.null), desired)
  desired_keys <- function(property) {
    unlist(lapply(Filter(function(d) d$property == property, desired), function(d) d$key))
  }

  removals <- list()
  if (!is.null(item)) {
    for (property in intersect(properties, names(claims))) {
      kept <- list()
      for (claim in claims[[property]]) {
        key <- wikidata_claim_key(claim)
        provenance <- wikidata_claim_provenance(claim)
        wrong <- key %in% toupper(rejected[[property]] %||% character(0)) ||
          length(desired_keys(property)) > 0
        if (is.na(key) || key %in% desired_keys(property) || provenance == "theirs" || !wrong) {
          kept[[length(kept) + 1]] <- claim
          next
        }
        if (provenance == "shared") kept[[length(kept) + 1]] <- claim
        removals[[length(removals) + 1]] <- data.frame(
          property = property, proposed = NA_character_, current = key,
          action = if (provenance == "ours") "remove" else "shared",
          command = if (provenance == "ours") {
            paste(paste0("-", item), property, wikidata_claim_token(claim), sep = "\t")
          } else NA_character_,
          stringsAsFactors = FALSE
        )
      }
      claims[[property]] <- kept
    }
  }

  current <- function(property) {
    keys <- vapply(claims[[property]] %||% list(), wikidata_claim_key, character(1))
    keys[!is.na(keys)]
  }
  carried <- function(property) {
    group <- Filter(function(g) property %in% g, WIKIDATA_EQUIVALENT_PROPERTIES)
    properties <- if (length(group) > 0) group[[1]] else property
    any(vapply(properties, function(p) length(claims[[p]] %||% list()) > 0, logical(1)))
  }

  additions <- lapply(desired, function(d) {
    values <- current(d$property)
    if (d$key %in% values) return(NULL)
    data.frame(
      property = d$property, proposed = d$key,
      current = if (length(values) == 0) NA_character_ else paste(values, collapse = "; "),
      action = if (carried(d$property)) "differs" else "add",
      command = d$command, stringsAsFactors = FALSE
    )
  })
  rows <- c(removals, Filter(Negate(is.null), additions))
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

#' The values known to be wrong on each existing work
#'
#' An OpenAlex ID is wrong for a work when its record has been deleted or
#' describes another DOI - OpenAlex merged the preprint into its published
#' version (see [openalex_record_is_work()]). That covers the ID the register
#' rejected (`Rejected OpenAlex`, see [read_register_records()]) and any ID the
#' item carries already, which an earlier export may have taken from a record
#' OpenAlex has since deleted. The venue and the publication date of such a
#' record are the other work's too.
#'
#' Wrong is not the same as removed: [wikidata_missing_statements()] only
#' removes what the export wrote alone, and never a value the model writes, so
#' a date the preprint shares with the merged record stays.
#'
#' @param existing the existing items, each a list with `kind`, `item` and `row`
#' @param claims their claims, see [wikidata_item_claims()]
#' @param method how to resolve the venues, see [preview_wikidata_export()]
#' @return a list parallel to `existing`, each a named list of property to
#'   values as [wikidata_claim_key()] gives them
#' @keywords internal
wikidata_rejected_values <- function(existing, claims, method = "search") {
  records <- lapply(existing, function(e) {
    if (e$kind != "paper") return(list())
    reference <- e$row$`Paper reference`
    ids <- c(e$row$`Rejected OpenAlex` %||% NA_character_,
             vapply(claims[[e$item]]$P10283 %||% list(), wikidata_claim_key, character(1)))
    ids <- unique(stats::na.omit(wikidata_transform(ids, "openalex")))
    wrong <- list()
    for (id in ids) {
      result <- tryCatch(get_openalex_work_fields_cached_result(paste0("https://openalex.org/", id)),
                         error = function(e) NULL)
      if (is.null(result) || identical(result$status, "failed")) next
      if (identical(result$status, "absent") ||
          !openalex_record_is_work(result$value$doi, reference)) {
        wrong[[id]] <- result$value
      }
    }
    wrong
  })

  issns <- unique(stats::na.omit(unlist(lapply(records, function(r) {
    vapply(r, function(fields) fields$issn %||% NA_character_, character(1))
  }))))
  venues <- if (length(issns) > 0) wikidata_resolve("venue", issns, method = method) else character(0)

  lapply(records, function(r) {
    if (length(r) == 0) return(list())
    issn <- vapply(r, function(fields) fields$issn %||% NA_character_, character(1))
    dates <- vapply(r, function(fields) fields$publication_date %||% NA_character_, character(1))
    list(
      P10283 = names(r),
      P1433 = stats::na.omit(unname(venues[issn])),
      P577 = stats::na.omit(dates)
    )
  })
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

  rejected <- wikidata_rejected_values(existing, claims, method = method)

  plan <- lapply(seq_along(existing), function(j) {
    e <- existing[[j]]
    commands <- quickstatements_for_entity(e$kind, e$row, qid = e$item, resolve = resolve)
    properties <- unique(vapply(wikidata_statements(e$kind), function(s) s$property, character(1)))
    missing <- wikidata_missing_statements(commands, claims[[e$item]] %||% list(),
                                           item = e$item, properties = properties,
                                           rejected = rejected[[j]])
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
#' A statement whose property the item already carries with another value is
#' a difference, listed in the report but not in the batch: on Wikidata it
#' would become a second value rather than a correction. Statements the export
#' wrote itself are the exception: when their only references point into the
#' register and the model no longer produces their value, the batch removes
#' them, before it adds anything, so a corrected value takes the place of the
#' wrong one. One the export wrote together with somebody else is reported as
#' `"shared"` and left alone. See [wikidata_missing_statements()].
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
#' @return the plan, invisibly: one row per statement to add, to remove, or
#'   that differs or is shared,
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
  cli::cli_h2("What the export would change on items already on Wikidata")

  if (is.null(records)) records <- read_register_records(dir)
  plan <- wikidata_update_plan(records, method = method, origin = origin,
                               log_file = log_file)
  batch <- "wikidata-updates"
  report <- file.path(out_dir, paste0(batch, ".csv"))

  if (is.null(plan)) {
    cli::cli_alert_success("Every existing item carries every statement of the model, and nothing the export wrote is outdated")
    return(invisible(plan))
  }

  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(plan, report, row.names = FALSE)
  cli::cli_alert_info("Report of {nrow(plan)} statement{?s} written to {.file {report}}")

  removals <- plan[plan$action == "remove", ]
  additions <- plan[plan$action == "add", ]
  differences <- plan[plan$action == "differs", ]
  shared <- plan[plan$action == "shared", ]
  if (nrow(removals) + nrow(additions) > 0) {
    # Removals first, so a corrected value replaces the wrong one rather than
    # sitting next to it; then the export's own items, whose additions need the
    # least review.
    removals <- removals[order(removals$kind, removals$key), ]
    additions <- additions[order(additions$origin != "codecheck export", additions$kind, additions$key), ]
    quickstatements_write(c(removals$command, additions$command), batch, dir = out_dir,
                          target = "wikidata", file = log_file)
    if (nrow(removals) > 0) {
      items <- length(unique(removals$item))
      cli::cli_alert_success("{nrow(removals)} statement{?s} the export wrote to remove from {items} item{?s}")
    }
    origins <- ifelse(is.na(additions$origin), "unknown origin", additions$origin)
    for (o in unique(origins)) {
      statements <- sum(origins == o)
      items <- length(unique(additions$item[origins == o]))
      cli::cli_alert_success("{statements} statement{?s} to add on {items} item{?s} from {.emph {o}}")
    }
  } else {
    cli::cli_alert_success("Nothing to add or remove")
  }
  if (nrow(differences) > 0) {
    cli::cli_alert_warning("{nrow(differences)} statement{?s} differ{?s/} from what the item carries: not in the batch, see the report")
  }
  if (nrow(shared) > 0) {
    cli::cli_alert_warning("{nrow(shared)} statement{?s} the export wrote together with others no longer follow{?s/} from the register: left alone, see the report")
  }
  invisible(plan)
}
