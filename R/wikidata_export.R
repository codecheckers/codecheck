# What the export to Wikidata would look like (codecheckers/register#50).
#
# Wikidata is not written by this code. The batches are pasted into
# QuickStatements by a person under their own account, which keeps this within
# bot policy without operating a bot - so what the package owes them is an exact
# preview: which items already exist, which would be created, and the commands
# themselves, generated from the same model the Wikibase mirror is built from.
#
# QuickStatements v1 can only refer to an item it just created, as LAST. A
# certificate therefore cannot name a paper created in the same batch, and the
# export is two batches in order: the checked works first, then the
# certificates, once the works have QIDs to point at.

#' Which of these identifiers already have items on Wikidata
#'
#' Batched with `VALUES`: one query per 60 identifiers rather than one per
#' identifier, and against the endpoint that actually serves the kind - the
#' query service was split in 2025 and asking the wrong one returns no match
#' rather than an error.
#'
#' @param kind an entity kind from [wikidata_entity_kinds()]
#' @param keys the identifier values, as the model's resolve transform produces
#' @return a named character vector, identifier to QID, holding only what exists
#' @keywords internal
wikidata_resolve <- function(kind, keys, method = c("search", "sparql")) {
  method <- match.arg(method)
  model <- WIKIDATA_MODEL[[kind]]$resolve
  keys <- unique(stats::na.omit(keys))
  found <- stats::setNames(character(0), character(0))
  if (length(keys) == 0) return(found)

  if (method == "search") {
    return(wikidata_search_by_statement(model$property, keys))
  }

  for (chunk in wikibase_values_chunks(keys, size = 60)) {
    query <- paste0("SELECT ?item ?value WHERE { VALUES ?value { ", chunk,
                    " } ?item wdt:", model$property, " ?value. }")
    result <- wikibase_sparql(query, model$endpoint)
    if (nrow(result) == 0) next
    qids <- sub("^.*/", "", result$item)
    found[result$value] <- qids
  }
  found
}

#' The search string that asks for any of these statement values
#'
#' One `haswbstatement` keyword with the values OR'd inside it. Repeating the
#' keyword instead ANDs the terms, and no item carries two of these identifiers
#' at once, so that form quietly finds almost nothing - it returned 3 of 33
#' known works before this was written the right way round.
#'
#' @param property the property to match on
#' @param values the values, any of which may match
#' @return the `srsearch` string
#' @keywords internal
haswbstatement_search <- function(property, values) {
  paste0("haswbstatement:", paste0(property, "=", values, collapse = "|"))
}

#' Find items by a statement they carry, through the search index
#'
#' The query service is not the right tool immediately after a batch has run:
#' its updater can be hours behind, and the scholarly endpoint is the slower of
#' the two, so a work created ten minutes ago is invisible there and would be
#' created a second time. The Action API's `haswbstatement` search indexes the
#' same fact within minutes and does not care which graph an item ended up in.
#'
#' Values are searched in batches - `haswbstatement` ORs them with `|` - and the
#' matches are then read back with `wbgetentities`, since a search result says
#' which items matched but not which value each one matched on.
#'
#' @param property the Wikidata property to match on, e.g. `"P356"`
#' @param values the identifier values
#' @param size how many values to put in one search
#' @return a named character vector, value to QID, holding only what exists
#' @keywords internal
wikidata_search_by_statement <- function(property, values, size = 20) {
  values <- unique(stats::na.omit(values))
  found <- stats::setNames(character(0), character(0))
  if (length(values) == 0) return(found)

  for (chunk in split(values, ceiling(seq_along(values) / size))) {
    search <- haswbstatement_search(property, chunk)
    hits <- wikibase_get(NULL, list(
      action = "query", list = "search", srsearch = search,
      srnamespace = 0, srlimit = length(chunk) * 2
    ), api = WIKIDATA_API)$query$search
    if (length(hits) == 0) next
    ids <- vapply(hits, function(hit) hit$title, character(1))

    # Which item matched which value: the search does not say, so the statement
    # is read off the items themselves.
    # Wikidata mostly stores DOIs uppercased, but not always - the search is
    # case-insensitive and the stored value may not match the one asked for, so
    # the comparison is too. The key kept is the one the caller passed in.
    wanted <- stats::setNames(chunk, toupper(chunk))

    for (batch in split(ids, ceiling(seq_along(ids) / 50))) {
      entities <- wikibase_get(NULL, list(
        action = "wbgetentities", ids = paste(batch, collapse = "|"), props = "claims"
      ), api = WIKIDATA_API)$entities
      for (id in names(entities)) {
        for (claim in entities[[id]]$claims[[property]]) {
          value <- claim$mainsnak$datavalue$value
          if (!is.character(value)) next
          key <- unname(wanted[toupper(value)])
          if (!is.na(key)) found[key] <- id
        }
      }
    }
  }
  found
}
#' Render one value as QuickStatements v1 writes it
#'
#' @param datatype the property's Wikibase datatype
#' @param value the value
#' @return the value as a QuickStatements token
#' @keywords internal
quickstatements_value <- function(datatype, value) {
  switch(
    datatype,
    "wikibase-item" = value,
    # Day precision, which is all a check date claims.
    time = paste0("+", value, "T00:00:00Z/11"),
    monolingualtext = paste0("en:\"", gsub("\"", "\\\\\"", value), "\""),
    paste0("\"", gsub("\"", "\\\\\"", value), "\"")
  )
}

#' The QuickStatements commands for one entity
#'
#' @param kind an entity kind
#' @param row the register row
#' @param qid the existing item to add to, or `NULL` to create one
#' @param resolve a function `(entity_kind, key) -> QID`
#' @return a character vector of commands, tab separated
#' @keywords internal
quickstatements_for_entity <- function(kind, row, qid = NULL, resolve = NULL) {
  model <- WIKIDATA_MODEL[[kind]]
  subject <- if (is.null(qid)) "LAST" else qid
  commands <- if (is.null(qid)) "CREATE" else character(0)

  render <- function(template) {
    if (is.null(template)) return(NULL)
    data <- as.list(row)
    data <- c(data, stats::setNames(data, gsub(" ", "_", names(data), fixed = TRUE)))
    text <- trimws(whisker::whisker.render(template, data))
    if (!nzchar(text)) NULL else text
  }

  # Labels and descriptions only on a new item: an item that already exists has
  # a label somebody chose, and overwriting it is not this export's business.
  if (is.null(qid)) {
    label <- render(model$label)
    description <- render(model$description)
    if (!is.null(label)) {
      if (nchar(label) > 250) label <- paste0(substr(label, 1, 247), "...")
      commands <- c(commands, paste(subject, "Len", quickstatements_value("string", label), sep = "\t"))
    }
    if (!is.null(description)) {
      commands <- c(commands, paste(subject, "Den",
                                    quickstatements_value("string", description), sep = "\t"))
    }
  }

  reference <- character(0)
  for (block in WIKIDATA_REFERENCE) {
    values <- evaluate_model_value(block$value, row, resolve)
    if (length(values) == 0) next
    reference <- c(reference, block$property, quickstatements_value(block$datatype, values[1]))
  }

  for (statement in wikidata_statements(kind)) {
    values <- evaluate_model_value(statement$value, row, resolve)
    if (length(values) == 0) next

    qualifiers <- character(0)
    for (qualifier in statement$qualifiers) {
      qualifier_values <- evaluate_model_value(qualifier$value, row, resolve)
      if (length(qualifier_values) == 0) next
      qualifiers <- c(qualifiers, qualifier$property,
                      quickstatements_value(qualifier$datatype, qualifier_values[1]))
    }

    for (value in values) {
      commands <- c(commands, paste(c(
        subject, statement$property, quickstatements_value(statement$datatype, value),
        qualifiers, reference
      ), collapse = "\t"))
    }
  }
  commands
}

#' Whether a batch of creates would repeat one that was already submitted
#'
#' QuickStatements' `CREATE` has no idempotency and Wikidata will not stop a
#' second paste: running the works batch twice makes a second item for every
#' work, which then has to be merged by hand. The dangerous moment is narrow and
#' predictable - a batch has been submitted, and the entities it created still
#' do not resolve, either because the index has not caught up or because the
#' batch failed. Either way the answer is to wait and look, not to paste again.
#'
#' @param kind the entity kind the batch is for
#' @param creates how many entities the new batch would create
#' @param log_file the edit log to consult
#' @return the time of the last submission that looks unaccounted for, or `NA`
#' @keywords internal
wikidata_batch_conflict <- function(kind, creates, log_file = NULL) {
  if (creates == 0) return(NA_character_)
  log <- wikibase_log_read(log_file)
  if (nrow(log) == 0) return(NA_character_)

  batch <- paste0("wikidata-", kind, "s")
  submitted <- log[which(log$batch == batch & log$status == "submitted"), ]
  if (nrow(submitted) == 0) return(NA_character_)
  submitted$time[nrow(submitted)]
}

#' Preview the export to Wikidata
#'
#' Resolves every checked work and certificate against Wikidata, works out what
#' exists and what would be created, and writes the QuickStatements batches a
#' person would paste in. Nothing is sent: Wikidata is written by hand, and this
#' is what makes that hand-work reviewable beforehand.
#'
#' Two batches, in order. The checked works come first, because QuickStatements
#' can only refer to an item it just created as `LAST`, so a certificate can
#' only name a work that already has a QID. After the works batch has run,
#' generate the preview again: the works then resolve, and the certificates get
#' their `review of` statements.
#'
#' @param dir the register repository to read from
#' @param out_dir where to write the `.qs` batches
#' @param log_file where to append the edit log, or `NULL` for the option
#' @param records already-read records, as from [read_register_records()]
#' @param publish also write the preview onto the CODECHECK Wikibase, as
#'   `Project:Wikidata export`; needs `WIKIBASE_USER`/`WIKIBASE_TOKEN`
#' @param method how to resolve against Wikidata: `"search"` (the default) asks
#'   the Action API, which indexes a new item within minutes and sees every
#'   graph; `"sparql"` asks the query service, which is hours behind and only
#'   sees the graph the entity kind is served from
#' @param force write a batch of creates even when the log says a batch of the
#'   same name was already submitted - see [wikidata_batch_conflict()]
#' @return a `data.frame` with one row per entity, invisibly, saying whether it
#'   exists on Wikidata and how many commands it contributes
#' @examples
#' \dontrun{
#' preview_wikidata_export("../register")
#' }
#' @export
preview_wikidata_export <- function(dir = "../register", out_dir = ".",
                                    log_file = NULL, records = NULL,
                                    publish = FALSE,
                                    method = c("search", "sparql"),
                                    force = FALSE) {
  method <- match.arg(method)
  cli::cli_h2("What the export to Wikidata would look like")

  if (is.null(records)) records <- read_register_records(dir)
  rows <- wikibase_export_rows(records)
  # On Wikidata a collision is unrecoverable: the item that loses is gone, and
  # nothing records that it was ever there.
  check_export_keys(rows, kinds = c("paper", "certificate"))

  planned <- list()
  batches <- list()
  known <- list()

  # Venues are resolved but never created here: a journal item belongs to the
  # community that maintains it. Resolving them is still worth a query, because
  # a work this export creates should say where it appeared, and most journals
  # do have an item.
  issns <- unique(stats::na.omit(records$certificates$`Paper ISSN`))
  if (length(issns) > 0) {
    known$venue <- wikidata_resolve("venue", issns, method = method)
    cli::cli_alert_info("venue: {length(issns)} publication{?s} in the register, {length(known$venue)} on Wikidata")
  }

  for (kind in c("paper", "certificate")) {
    if (!wikidata_creates(kind, "wikidata")) next
    table <- rows[[kind]]
    keys <- wikibase_key_column(table, kind)
    existing <- wikidata_resolve(kind, keys, method = method)
    known[[kind]] <- existing
    cli::cli_alert_info(
      "{kind}: {length(keys)} in the register, {sum(keys %in% names(existing))} already on Wikidata"
    )

    resolve <- function(entity_kind, key) {
      model <- WIKIDATA_MODEL[[entity_kind]]$resolve
      value <- wikidata_transform(key, model$transform)
      if (length(value) == 0 || is.na(value[1])) return(NA_character_)
      unname((known[[entity_kind]] %||% character(0))[value[1]])
    }

    commands <- character(0)
    for (i in seq_len(nrow(table))) {
      key <- keys[i]
      if (is.na(key)) next
      qid <- unname(existing[key])
      row <- table[i, , drop = FALSE]
      # An item that exists already keeps its statements: this preview is about
      # what is missing, not about re-asserting what Wikidata has.
      entity_commands <- if (is.na(qid)) {
        quickstatements_for_entity(kind, row, qid = NULL, resolve = resolve)
      } else {
        character(0)
      }
      commands <- c(commands, entity_commands)
      planned[[length(planned) + 1]] <- data.frame(
        kind = kind, key = key, wikidata = qid %||% NA_character_,
        action = if (is.na(qid)) "create" else "exists",
        commands = length(entity_commands), stringsAsFactors = FALSE
      )
    }
    batches[[kind]] <- commands
  }

  out <- do.call(rbind, planned)
  rownames(out) <- NULL

  for (kind in names(batches)) {
    if (length(batches[[kind]]) == 0) next
    creates <- sum(out$action == "create" & out$kind == kind)
    conflict <- if (force) NA_character_ else wikidata_batch_conflict(kind, creates, log_file)
    if (!is.na(conflict)) {
      # Plain R rather than cli's pluralisation: an interpolated noun resets the
      # quantity {?s} would agree with, so it reads "90 paper".
      noun <- if (creates == 1) kind else paste0(kind, "s")
      cli::cli_alert_danger(
        "Not writing the {kind} batch: one was submitted at {conflict}, and {creates} {noun} still do not resolve."
      )
      cli::cli_alert_info(
        "Either the search index has not caught up - wait and run this again - or that batch failed, which its QuickStatements page will say. Pasting it again would create every one of them a second time."
      )
      cli::cli_alert_info("Pass {.code force = TRUE} once you know which it was.")
      next
    }
    quickstatements_write(batches[[kind]], paste0("wikidata-", kind, "s"),
                          dir = out_dir, target = "wikidata", file = log_file)
  }

  certificates <- out[which(out$kind == "certificate"), ]
  papers <- out[which(out$kind == "paper"), ]
  unlinked <- sum(vapply(seq_len(nrow(rows$certificate)), function(i) {
    key <- wikidata_transform(rows$certificate$`Paper reference`[i], "doi")
    is.na(key) || !key %in% names(known$paper %||% character(0))
  }, logical(1)))

  cli::cli_alert_success("{sum(papers$action == 'create')} work{?s} to create, {sum(papers$action == 'exists')} already on Wikidata")
  cli::cli_alert_success("{sum(certificates$action == 'create')} certificate{?s} to create, {sum(certificates$action == 'exists')} already there")
  cli::cli_alert_warning("{unlinked} certificate{?s} cannot state {.emph review of} until the works batch has run")
  cli::cli_alert_info("Run the works batch first, then generate this again: QuickStatements can only refer to an item it just created")

  if (publish) {
    session <- wikibase_session()
    write_wikidata_preview_page(session, out, records$certificates, batches)
    wikibase_log(target = "wikibase", action = "edit", kind = "page",
                 id = WIKIBASE_INSTANCE$wikidata_page, label = "wikidata preview",
                 status = "done", file = log_file)
    cli::cli_alert_success("Preview published to {.url {paste0(WIKIBASE_INSTANCE$url, '/wiki/', WIKIBASE_INSTANCE$wikidata_page)}}")
  }

  attr(out, "batches") <- batches
  invisible(out)
}

#' The wiki page showing what the Wikidata export would do
#'
#' The Wikibase mirror is where this work can be looked at before any of it
#' reaches Wikidata, so the preview belongs there too: which works already have
#' items, which would be created, and the commands themselves, in the two
#' batches they have to run in.
#'
#' @param preview the table [preview_wikidata_export()] built
#' @param certificates the certificate rows, for titles and links
#' @param batches the QuickStatements batches, as attached to the preview
#' @param generated_at the timestamp to stamp the page with
#' @return the page's wikitext
#' @keywords internal
wikidata_preview_wikitext <- function(preview, certificates, batches,
                                      generated_at = Sys.time()) {
  text <- function(x) if (is.null(x) || length(x) == 0 || is.na(x[1])) "" else as.character(x)[1]
  wikidata_link <- function(qid) paste0("[https://www.wikidata.org/wiki/", qid, " ", qid, "]")

  papers <- preview[which(preview$kind == "paper"), ]
  certs <- preview[which(preview$kind == "certificate"), ]
  by_paper <- stats::setNames(seq_len(nrow(certificates)),
                              wikidata_transform(certificates$`Paper reference`, "doi"))

  paper_rows <- lapply(seq_len(nrow(papers)), function(i) {
    key <- papers$key[i]
    source <- certificates[unname(by_paper[key]), ]
    c(
      paste0("[https://doi.org/", key, " ", key, "]"),
      substr(text(source$Title), 1, 80),
      text(source$Venue),
      if (papers$action[i] == "exists") wikidata_link(papers$wikidata[i]) else "'''to create'''"
    )
  })

  example <- utils::head(batches$certificate %||% character(0), 16)

  c(
    "What an export to Wikidata would do, generated by",
    "<code>codecheck::preview_wikidata_export()</code> from the same model this",
    "instance is built from ([https://github.com/codecheckers/register/issues/50 register#50]).",
    "Nothing here has been sent: the batches are pasted into",
    "[https://quickstatements.toolforge.org/ QuickStatements] by a person, under their",
    "own account, which is what keeps this within bot policy without running a bot.",
    "",
    "== What would happen ==",
    "",
    "{| class=\"wikitable\"",
    "! Entity !! On Wikidata already !! Would be created !! Commands",
    "|-",
    paste0("| checked works || ", sum(papers$action == "exists"), " || ",
           sum(papers$action == "create"), " || ", length(batches$paper %||% character(0))),
    "|-",
    paste0("| certificates || ", sum(certs$action == "exists"), " || ",
           sum(certs$action == "create"), " || ", length(batches$certificate %||% character(0))),
    "|}",
    "",
    "Only certificates and the works they check are created on Wikidata. The people",
    "and venues a certificate refers to are resolved against items the communities",
    "that own them maintain, and are mirrored on this instance instead.",
    "",
    "=== The order matters ===",
    "",
    "QuickStatements can only refer to an item it has just created, as <code>LAST</code>,",
    "so a certificate cannot name a work created in the same batch. The works batch",
    "runs first; the preview is then generated again, and the certificates get their",
    "''review of'' statements pointing at the new items.",
    "",
    "== Checked works ==",
    "",
    "{| class=\"wikitable sortable\"",
    "! DOI !! Title !! Venue !! Wikidata",
    unlist(lapply(paper_rows, function(row) c("|-", paste0("| ", paste(row, collapse = " || "))))),
    "|}",
    "",
    "== What the commands look like ==",
    "",
    "The first certificate of the batch, as pasted:",
    "",
    "<pre>",
    gsub("\t", "    ", example),
    "</pre>",
    "",
    paste0("Generated ", format(generated_at, "%Y-%m-%d %H:%M:%S %Z"), "."),
    ""
  )
}

#' Write the Wikidata preview onto the instance
#'
#' @param session a session from [wikibase_session()]
#' @param preview the table [preview_wikidata_export()] built
#' @param certificates the certificate rows
#' @param batches the QuickStatements batches
#' @return the page title, invisibly
#' @keywords internal
write_wikidata_preview_page <- function(session, preview, certificates, batches) {
  wikibase_post(session, list(
    action = "edit",
    title = WIKIBASE_INSTANCE$wikidata_page,
    text = paste(wikidata_preview_wikitext(preview, certificates, batches), collapse = "\n"),
    summary = "generated by codecheck::preview_wikidata_export()",
    bot = 1
  ), what = paste0("page '", WIKIBASE_INSTANCE$wikidata_page, "'"))
  invisible(WIKIBASE_INSTANCE$wikidata_page)
}

#' Check what actually arrived on Wikidata
#'
#' The step after a batch has run, and the one that proves the model's central
#' decision worked: a certificate and the work it reviews have to be in the
#' *same* graph of the split query service, or a query cannot join them. The
#' search index says whether an item exists; only SPARQL says whether it is
#' reachable from the graph its certificate lives in.
#'
#' Run it after the query service has caught up - hours rather than minutes,
#' and the scholarly endpoint is the slower of the two. An item that exists but
#' is not yet visible here is a lag, not a failure; the same result days later
#' is a failure.
#'
#' @param dir the register repository to read from
#' @param records already-read records, as from [read_register_records()]
#' @return a `data.frame` with one row per certificate, invisibly: its report
#'   DOI, its item if it has one, whether the query service can see it, and the
#'   work it states `review of` on
#' @examples
#' \dontrun{
#' verify_wikidata_export("../register")
#' }
#' @export
verify_wikidata_export <- function(dir = "../register", records = NULL) {
  cli::cli_h2("Checking what arrived on Wikidata")

  if (is.null(records)) records <- read_register_records(dir)
  rows <- wikibase_export_rows(records)
  keys <- wikibase_key_column(rows$certificate, "certificate")
  keys <- stats::na.omit(keys)

  # Two questions, two sources: does the item exist at all, and can a query
  # reach it from the graph its certificate is in.
  existing <- wikidata_resolve("certificate", keys, method = "search")

  joined <- stats::setNames(character(0), character(0))
  visible <- character(0)
  for (chunk in wikibase_values_chunks(keys, size = 60)) {
    query <- paste0(
      "SELECT ?item ?doi ?paper WHERE { VALUES ?doi { ", chunk, " } ",
      "?item wdt:P356 ?doi. OPTIONAL { ?item wdt:P6977 ?paper } }"
    )
    result <- wikibase_sparql(query, "scholarly")
    if (nrow(result) == 0) next
    visible <- c(visible, result$doi)
    reviewed <- result[!is.na(result$paper), ]
    if (nrow(reviewed) > 0) joined[reviewed$doi] <- sub("^.*/", "", reviewed$paper)
  }

  out <- data.frame(
    certificate = rows$certificate$`Certificate ID`[match(keys, wikibase_key_column(rows$certificate, "certificate"))],
    doi = keys,
    item = unname(existing[keys]),
    in_scholarly_graph = keys %in% visible,
    review_of = unname(joined[keys]),
    stringsAsFactors = FALSE
  )
  rownames(out) <- NULL

  cli::cli_alert_info("{sum(!is.na(out$item))} of {nrow(out)} certificate{?s} exist on Wikidata")
  cli::cli_alert_info("{sum(out$in_scholarly_graph)} visible in the scholarly graph")
  cli::cli_alert_info("{sum(!is.na(out$review_of))} state {.emph review of} on the work they checked")

  missing_graph <- out$doi[!is.na(out$item) & !out$in_scholarly_graph]
  if (length(missing_graph) > 0) {
    cli::cli_alert_warning(
      "{length(missing_graph)} certificate{?s} exist but are not in the scholarly graph. If the query service has caught up, check that each carries P13046 - that statement is what puts it there."
    )
  }
  unlinked <- out$doi[!is.na(out$item) & is.na(out$review_of)]
  if (length(unlinked) > 0) {
    cli::cli_alert_warning("{length(unlinked)} certificate{?s} state no {.emph review of}: the work they checked has no item, or the certificates batch ran before the works batch")
  }
  if (all(!is.na(out$item)) && all(out$in_scholarly_graph) && all(!is.na(out$review_of))) {
    cli::cli_alert_success("Every certificate is on Wikidata, in the scholarly graph, linked to the work it checked")
  }

  invisible(out)
}
