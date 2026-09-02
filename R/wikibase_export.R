# Turning register rows into Wikibase entities (codecheckers/register#50).
#
# The model in R/wikidata.R says what a certificate is; this says how a row of
# the register becomes that. The two halves are kept apart on purpose: the
# modelling decisions are argued about in one place, and everything here is a
# mechanical projection of them, so a change to the model reaches the instance
# without anything here being edited.
#
# Everything up to wikibase_entity_payload() is pure - it takes rows and a
# mapping and returns the data a write would send. That is what makes a rehearsal
# meaningful: the payload can be inspected, diffed and tested without an account.

#' Apply a model transform to a register value
#'
#' The transforms the model's value definitions name. Each is small, and each
#' exists because the register stores something in the shape a human reads and
#' Wikidata stores it in the shape a query matches.
#'
#' @param x the raw value
#' @param transform the transform name, or `NULL` for none
#' @return the transformed value, `NA` when there is nothing to transform
#' @keywords internal
wikidata_transform <- function(x, transform = NULL) {
  if (is.null(transform)) return(x)
  if (length(x) == 0 || all(is.na(x))) return(NA_character_)
  x <- as.character(x)

  switch(
    transform,
    # Wikidata stores DOIs uppercased and bare; the register stores them as
    # resolver URLs. A lookup that does not match this exactly finds nothing.
    doi = {
      bare <- toupper(sub("^https?://(dx\\.)?doi\\.org/", "", trimws(x)))
      # A "Paper reference" is not always a DOI - some papers are linked by
      # their publisher URL or an arXiv page. Only a DOI resolves an item, and
      # pretending otherwise would create one item per URL shape.
      ifelse(grepl("^10\\.[0-9]{4,9}/", bare), bare, NA_character_)
    },
    # Day precision: the register's check date is a date, not a timestamp.
    date_day = substr(trimws(x), 1, 10),
    # The bare identifier, however the register wrote it.
    orcid = sub("^https?://orcid\\.org/", "", trimws(x)),
    # venues.csv packs identifiers as "ISSN|icon|value|url", possibly several
    # separated by ";".
    issn = {
      # The field holds either venues.csv's packed form or, once extracted, the
      # ISSN itself - the model resolves a venue by this value wherever it comes
      # from, so both shapes have to survive the transform.
      if (grepl("^[0-9]{4}-[0-9]{3}[0-9Xx]$", trimws(x[1]))) {
        toupper(trimws(x[1]))
      } else {
        parts <- unlist(strsplit(x, ";", fixed = TRUE))
        issn <- parts[grepl("^ISSN\\|", parts)]
        if (length(issn) == 0) NA_character_ else trimws(strsplit(issn[1], "|", fixed = TRUE)[[1]][3])
      }
    },
    # ResearchEquals DOIs name no platform in the string, so the prefix is
    # checked before detect_report_platform() would reach for the network.
    report_platform = if (grepl("^https?://(dx\\.)?doi\\.org/10\\.53962", x[1]) ||
                          grepl("10\\.53962", x[1])) {
      "researchequals"
    } else {
      detect_report_platform(x[1])
    },
    stop("Unknown transform: ", transform)
  )
}

#' Evaluate one value definition against a register row
#'
#' Returns zero, one or several values: zero when the row has nothing to say
#' (the statement is then simply not written, which is how a paper without a
#' venue gets no `published in`), several when the field holds several - a
#' certificate with three codecheckers gets three `author` statements.
#'
#' @param value a value definition from the model
#' @param row a one-row `data.frame` or list of register fields
#' @param resolve a function `(entity_kind, key) -> local id or NA`, used for
#'   `entity` values; `NULL` resolves nothing
#' @return a character vector of values, empty when the statement does not apply
#' @keywords internal
evaluate_model_value <- function(value, row, resolve = NULL) {
  none <- character(0)
  # A codechecker record's orcid can be missing (NULL) or empty (NA), and both
  # mean the same thing here.
  person_field <- function(person, name) {
    got <- person[[name]]
    if (is.null(got) || length(got) == 0) NA_character_ else as.character(got)[1]
  }
  field <- function(name) {
    if (is.null(name) || !name %in% names(row)) return(NULL)
    got <- row[[name]]
    if (is.list(got)) got <- got[[1]]
    got
  }

  switch(
    value$kind,
    # An item that does not exist yet is marked pending in the model, and
    # nothing is emitted for it - deliberately visible rather than silently
    # dropped, see wikidata_pending().
    constant = if (!is.null(value$pending)) none else value$item,

    field = {
      raw <- field(value$field)
      if (is.null(raw)) return(none)
      # The codechecker column holds people, not strings: "unresolved_names"
      # picks the ones without an ORCID, which are the only ones P2093 is for.
      if (identical(value$transform, "unresolved_names")) {
        names <- vapply(raw, person_field, character(1), "name")
        orcids <- vapply(raw, person_field, character(1), "orcid")
        return(stats::na.omit(names[is.na(orcids) | !nzchar(orcids)]))
      }
      out <- wikidata_transform(raw, value$transform)
      out <- out[!is.na(out) & nzchar(out)]
      as.character(out)
    },

    entity = {
      if (is.null(resolve)) return(none)
      raw <- field(value$field)
      if (is.null(raw)) return(none)
      # A person field holds records; everything else holds the key itself.
      keys <- if (is.list(raw) && length(raw) > 0 && is.list(raw[[1]])) {
        vapply(raw, person_field, character(1), "orcid")
      } else {
        as.character(raw)
      }
      keys <- keys[!is.na(keys) & nzchar(keys)]
      resolved <- vapply(keys, function(key) resolve(value$entity, key) %||% NA_character_,
                         character(1))
      unname(stats::na.omit(resolved))
    },

    render_date = format(Sys.Date(), "%Y-%m-%d"),

    switch = {
      raw <- field(value$field)
      case <- if (is.null(raw) || is.na(raw[1])) NULL else value$cases[[as.character(raw[1])]]
      case %||% value$default %||% none
    },

    mapped = {
      raw <- field(value$field)
      if (is.null(raw) || all(is.na(raw))) return(none)
      key <- wikidata_transform(raw, value$transform)
      map <- switch(value$map, platforms = WIKIDATA_PLATFORMS,
                    stop("Unknown map: ", value$map))
      map[[key]] %||% none
    },

    stop("Unknown value kind: ", value$kind)
  )
}

#' Build the datavalue for one value, in the shape wbeditentity expects
#'
#' @param datatype the property's Wikibase datatype
#' @param value the value, already transformed
#' @return a `datavalue` list
#' @keywords internal
wikibase_datavalue <- function(datatype, value) {
  switch(
    datatype,
    "wikibase-item" = list(type = "wikibase-entityid",
                           value = list(`entity-type` = "item", id = value)),
    # Day precision (11) with the Gregorian calendar, which is what a check date
    # is: the register records the day, and claiming more would be invented.
    time = list(type = "time", value = list(
      time = paste0("+", value, "T00:00:00Z"), timezone = 0, before = 0, after = 0,
      precision = 11, calendarmodel = "http://www.wikidata.org/entity/Q1985727"
    )),
    monolingualtext = list(type = "monolingualtext",
                           value = list(text = value, language = "en")),
    list(type = "string", value = value)
  )
}

#' Build one snak
#'
#' @param property the *local* property id on the instance
#' @param datatype the property's datatype
#' @param value the value
#' @keywords internal
wikibase_snak <- function(property, datatype, value) {
  list(snaktype = "value", property = property,
       datavalue = wikibase_datavalue(datatype, value))
}

#' The statements one entity kind contributes for one row
#'
#' Every statement carries the reference block from the model, which is what
#' distinguishes a statement this pipeline wrote from one somebody added by
#' hand.
#'
#' @param kind an entity kind from [wikidata_entity_kinds()]
#' @param row the register row
#' @param local a named vector mapping Wikidata property ids to local ones
#' @param resolve a function `(entity_kind, key) -> local id`
#' @return a list of claims for `wbeditentity`
#' @keywords internal
wikibase_claims <- function(kind, row, local, resolve = NULL) {
  reference_snaks <- function() {
    snaks <- list()
    for (reference in WIKIDATA_REFERENCE) {
      property <- local[[sub("^S", "P", reference$property)]]
      values <- evaluate_model_value(reference$value, row, resolve)
      if (is.null(property) || length(values) == 0) next
      snaks[[property]] <- list(wikibase_snak(property, reference$datatype, values[1]))
    }
    if (length(snaks) == 0) NULL else list(list(snaks = snaks))
  }
  references <- reference_snaks()

  # An item the model names is a Wikidata QID and has to be written as the local
  # item standing for it. A value that came out of resolve() is already local,
  # and must not be translated again - "Q5" means the human class on Wikidata
  # and Douglas Adams in the stock seed data, so guessing by shape would be
  # wrong exactly where it matters.
  as_local_item <- function(value_kind, values) {
    if (!value_kind %in% c("constant", "switch", "mapped")) return(values)
    translated <- unname(unlist(local[values]))
    translated[!is.na(translated)]
  }

  claims <- list()
  for (statement in wikidata_statements(kind)) {
    property <- local[[statement$property]]
    if (is.null(property)) next
    values <- evaluate_model_value(statement$value, row, resolve)
    if (identical(statement$datatype, "wikibase-item")) {
      values <- as_local_item(statement$value$kind, values)
    }
    if (length(values) == 0) next

    qualifiers <- list()
    for (qualifier in statement$qualifiers) {
      qualifier_property <- local[[qualifier$property]]
      qualifier_values <- evaluate_model_value(qualifier$value, row, resolve)
      if (identical(qualifier$datatype, "wikibase-item")) {
        qualifier_values <- as_local_item(qualifier$value$kind, qualifier_values)
      }
      if (is.null(qualifier_property) || length(qualifier_values) == 0) next
      qualifiers[[qualifier_property]] <- list(
        wikibase_snak(qualifier_property, qualifier$datatype, qualifier_values[1])
      )
    }

    for (value in values) {
      claim <- list(
        mainsnak = wikibase_snak(property, statement$datatype, value),
        type = "statement", rank = "normal"
      )
      if (length(qualifiers) > 0) claim$qualifiers <- qualifiers
      if (!is.null(references)) claim$references <- references
      claims[[length(claims) + 1]] <- claim
    }
  }
  claims
}

#' Everything wbeditentity needs for one entity
#'
#' @inheritParams wikibase_claims
#' @return a list with `labels`, `descriptions` and `claims`
#' @keywords internal
wikibase_entity_payload <- function(kind, row, local, resolve = NULL) {
  model <- WIKIDATA_MODEL[[kind]]
  render <- function(template) {
    if (is.null(template)) return(NULL)
    data <- as.list(row)
    # Mustache addresses a key by name and cannot express a space, so every
    # column is also offered under an underscored alias: "Certificate ID" is
    # {{Certificate_ID}} in the model's templates.
    data <- c(data, stats::setNames(data, gsub(" ", "_", names(data), fixed = TRUE)))
    text <- whisker::whisker.render(template, data)
    if (!nzchar(trimws(text))) NULL else trimws(text)
  }

  payload <- list(claims = wikibase_claims(kind, row, local, resolve))
  label <- render(model$label)
  description <- render(model$description)
  # Wikibase rejects a label longer than 250 characters, and paper titles do
  # reach that; the description is the place for the full text anyway.
  if (!is.null(label)) {
    if (nchar(label) > 250) label <- paste0(substr(label, 1, 247), "...")
    payload$labels <- list(en = list(language = "en", value = label))
  }
  if (!is.null(description)) {
    payload$descriptions <- list(en = list(language = "en", value = description))
  }
  payload
}

#' The register, in the shape the model consumes
#'
#' Read from a rendered register directory rather than from `register.csv`:
#' the model needs the enriched fields (paper title and DOI, the codecheckers
#' with their ORCIDs, the certificate PDF), and those are exactly what a render
#' has already resolved and written to `docs/`. Reading them back is offline,
#' takes seconds, and cannot disagree with the register website.
#'
#' @param dir the register repository, containing `docs/` and `venues.csv`
#' @return a list with `certificates` (one row each, `Codechecker` a list
#'   column) and `venues`
#' @keywords internal
read_register_records <- function(dir) {
  register <- jsonlite::fromJSON(file.path(dir, "docs", "register.json"),
                                 simplifyDataFrame = FALSE)
  venues <- utils::read.csv(file.path(dir, "venues.csv"), colClasses = "character")

  certificates <- lapply(register, function(entry) {
    id <- entry[["Certificate ID"]]
    detail <- file.path(dir, "docs", "certs", id, "index.json")
    codecheckers <- list()
    if (file.exists(detail)) {
      parsed <- jsonlite::fromJSON(detail, simplifyDataFrame = FALSE)
      codecheckers <- parsed$codecheck$codecheckers %||% list()
    }
    entry <- lapply(entry, function(field) {
      if (is.null(field) || length(field) == 0) NA_character_ else as.character(field)[1]
    })
    attr(entry, "codecheckers") <- codecheckers
    entry
  })

  # A field the render could not fill is absent from that entry's JSON rather
  # than empty - a certificate whose paper has no DOI has no "Paper reference"
  # key at all - so the columns are the union and a row that lacks one gets NA.
  columns <- unique(unlist(lapply(certificates, names)))
  certificates <- lapply(certificates, function(entry) {
    codecheckers <- attr(entry, "codecheckers")
    missing <- setdiff(columns, names(entry))
    entry[missing] <- NA_character_
    row <- as.data.frame(entry[columns], check.names = FALSE, stringsAsFactors = FALSE)
    # I(), so a certificate with no codecheckers - or with three - is still one
    # row holding one list, rather than none or three.
    row$Codechecker <- I(list(codecheckers))
    row
  })

  list(certificates = do.call(rbind, certificates), venues = venues)
}

#' Which entities the instance already holds, by identifier
#'
#' The counterpart of [wikibase_mapping()] for the data: an item is found by the
#' identifier the model resolves it on - a DOI, an ORCID, an ISSN - because that
#' is the only thing about it that cannot change. Built once from the Action API
#' rather than queried per entity, and updated in memory as entities are
#' created, so the query service's lag behind a write cannot cause a duplicate.
#'
#' @param local a named vector mapping Wikidata property ids to local ones
#' @param handle an optional `httr` handle
#' @return a named character vector, `"<property>=<value>"` to local id
#' @keywords internal
wikibase_identifier_index <- function(local, handle = NULL) {
  resolve_properties <- unique(vapply(wikidata_entity_kinds(),
                                      function(kind) WIKIDATA_MODEL[[kind]]$resolve$property,
                                      character(1)))
  wanted <- stats::setNames(unlist(local[resolve_properties]), resolve_properties)
  wanted <- wanted[!is.na(wanted)]

  pages <- wikibase_get(handle, list(
    action = "query", list = "allpages", apnamespace = 120, aplimit = 500
  ))$query$allpages
  ids <- vapply(pages, function(page) sub("^Item:", "", page$title), character(1))
  if (length(ids) == 0) return(stats::setNames(character(0), character(0)))

  index <- character(0)
  for (chunk in split(ids, ceiling(seq_along(ids) / 50))) {
    entities <- wikibase_get(handle, list(
      action = "wbgetentities", ids = paste(chunk, collapse = "|"), props = "claims"
    ))$entities
    for (id in names(entities)) {
      for (property in names(wanted)) {
        claims <- entities[[id]]$claims[[wanted[[property]]]]
        for (claim in claims) {
          value <- claim$mainsnak$datavalue$value
          if (is.character(value) && nzchar(value)) {
            index[paste0(property, "=", value)] <- id
          }
        }
      }
    }
  }
  index
}

#' The key an entity of this kind is found by
#'
#' @param kind an entity kind
#' @param row the row describing it
#' @return the identifier value, or `NA`
#' @keywords internal
wikibase_entity_key <- function(kind, row) {
  resolve <- WIKIDATA_MODEL[[kind]]$resolve
  raw <- if (resolve$field %in% names(row)) row[[resolve$field]] else NULL
  if (is.null(raw)) return(NA_character_)
  value <- wikidata_transform(raw, resolve$transform)
  if (length(value) == 0 || is.na(value[1]) || !nzchar(value[1])) NA_character_ else value[1]
}

#' The rows each entity kind contributes, deduplicated
#'
#' A person is one item however many certificates they checked, and a paper one
#' item however many times it was checked - so the register is turned into one
#' row per entity before anything is written, and the identifier is what decides
#' sameness.
#'
#' @param records the output of [read_register_records()]
#' @return a named list of `data.frame`s, one per entity kind
#' @keywords internal
wikibase_export_rows <- function(records) {
  certificates <- records$certificates

  people <- do.call(rbind, lapply(seq_len(nrow(certificates)), function(i) {
    codecheckers <- certificates$Codechecker[[i]]
    rows <- lapply(codecheckers, function(person) {
      orcid <- person$orcid
      if (is.null(orcid) || length(orcid) == 0 || is.na(orcid[1]) || !nzchar(orcid[1])) return(NULL)
      data.frame(name = person$name %||% NA_character_, orcid = as.character(orcid)[1],
                 stringsAsFactors = FALSE)
    })
    do.call(rbind, rows)
  }))
  if (!is.null(people)) people <- people[!duplicated(people$orcid), , drop = FALSE]

  papers <- certificates[!duplicated(
    wikidata_transform(certificates$`Paper reference`, "doi")
  ), , drop = FALSE]
  papers <- papers[!is.na(wikibase_key_column(papers, "paper")), , drop = FALSE]

  # Only venues with an ISSN: that is what the model resolves a venue by, and a
  # venue nothing can be matched on would be a new item on every run.
  venues <- records$venues
  venues$issn <- vapply(venues$identifiers, wikidata_transform, character(1), "issn")
  venues <- venues[!is.na(venues$issn), , drop = FALSE]

  list(person = people, venue = venues, paper = papers, certificate = certificates)
}

#' The identifier column of a table of rows, for a kind
#'
#' @keywords internal
wikibase_key_column <- function(rows, kind) {
  if (is.null(rows) || nrow(rows) == 0) return(character(0))
  vapply(seq_len(nrow(rows)), function(i) wikibase_entity_key(kind, rows[i, , drop = FALSE]),
         character(1))
}

#' Load the register into the CODECHECK Wikibase
#'
#' The rehearsal the Wikidata batches are worth doing only after: the whole
#' register, written as items on an instance that can be thrown away and rebuilt
#' (codecheckers/register#50).
#'
#' Entities are written in dependency order - people, venues, papers, then the
#' certificates that refer to them - because a certificate's `author` and
#' `review of` statements can only name items that already exist. Each entity is
#' matched by the identifier the model resolves it on, so a rerun updates what
#' it wrote last time instead of duplicating it, and an update replaces the
#' entity's statements rather than adding a second copy of each.
#'
#' Dry by default: with `dry_run = TRUE` nothing is written and the payloads are
#' returned for inspection.
#'
#' @param dir the register repository to read from
#' @param dry_run if `TRUE` (the default) report what would be written
#' @param log_file where to append the edit log, or `NULL` for the
#'   `codecheck.wikibase_log` option
#' @param limit process at most this many certificates, for a first rehearsal
#' @param records already-read records, as from [read_register_records()]
#' @return a `data.frame` of what was written or would be, invisibly, with the
#'   payloads attached as the `"payloads"` attribute
#' @examples
#' \dontrun{
#' load_wikibase_register("../register")                    # what would happen
#' load_wikibase_register("../register", dry_run = FALSE)   # do it
#' }
#' @export
load_wikibase_register <- function(dir = "../register", dry_run = TRUE,
                                   log_file = NULL, limit = NULL, records = NULL) {
  cli::cli_h2("Loading the register into the CODECHECK Wikibase{if (dry_run) ' (dry run)' else ''}")

  session <- if (dry_run) NULL else wikibase_session()
  handle <- if (is.null(session)) NULL else session$handle

  mapping <- wikibase_mapping(session)
  local <- stats::setNames(mapping$local_id, mapping$wikidata_id)
  local <- as.list(local[!is.na(names(local))])
  missing_model <- setdiff(unique(wikidata_properties()$property), names(local))
  if (length(missing_model) > 0) {
    stop("The instance is missing ", length(missing_model), " propert(y/ies) of the model (",
         paste(utils::head(missing_model, 5), collapse = ", "),
         "). Run bootstrap_wikibase(dry_run = FALSE) first.")
  }

  if (is.null(records)) records <- read_register_records(dir)
  rows <- wikibase_export_rows(records)
  if (!is.null(limit)) {
    rows$certificate <- utils::head(rows$certificate, limit)
    keep <- wikidata_transform(rows$certificate$`Paper reference`, "doi")
    rows$paper <- rows$paper[wikibase_key_column(rows$paper, "paper") %in% keep, , drop = FALSE]
  }

  index <- wikibase_identifier_index(local, handle)
  # A named character vector, so an absent name reads back as NA rather than
  # erroring the way a list's [[ ]] would.
  lookup <- function(property, value) unname(index[paste0(property, "=", value)])
  resolve <- function(kind, key) {
    model <- WIKIDATA_MODEL[[kind]]$resolve
    value <- wikidata_transform(key, model$transform)
    if (length(value) == 0 || is.na(value[1])) return(NA_character_)
    lookup(model$property, value[1])
  }

  written <- list()
  payloads <- list()
  # People, venues and papers first: a certificate names them, and a statement
  # pointing at an item that does not exist yet is simply lost.
  for (kind in c("person", "venue", "paper", "certificate")) {
    table <- rows[[kind]]
    if (is.null(table) || nrow(table) == 0) next
    keys <- wikibase_key_column(table, kind)
    property <- WIKIDATA_MODEL[[kind]]$resolve$property
    cli::cli_alert_info("{kind}: {nrow(table)} row{?s}, {sum(!is.na(keys))} with an identifier")

    for (i in seq_len(nrow(table))) {
      key <- keys[i]
      # No identifier, no item: it could not be found again on the next run and
      # would be created a second time.
      if (is.na(key)) next

      row <- table[i, , drop = FALSE]
      payload <- wikibase_entity_payload(kind, row, local, resolve)
      existing <- lookup(property, key)
      action <- if (is.na(existing)) "create" else "update"

      id <- existing
      if (dry_run && is.na(id)) {
        # Nothing is created, but the entities that would be have to be
        # resolvable, or every statement pointing at one of them would be
        # missing from the payloads this dry run reports.
        id <- paste0("<new ", kind, " ", i, ">")
        index[paste0(property, "=", key)] <- id
      }
      if (!dry_run) {
        result <- wikibase_edit_entity(
          session, payload,
          kind = if (action == "create") "item" else NULL,
          id = if (action == "create") NULL else existing,
          clear = TRUE,
          summary = paste0(action, " ", kind, " from the CODECHECK register"),
          what = paste0(kind, " ", key)
        )
        id <- result$entity$id
        index[paste0(property, "=", key)] <- id
      }

      wikibase_log(target = "wikibase", action = action, kind = kind, id = id,
                   label = payload$labels$en$value %||% key, status = if (dry_run) "planned" else "done",
                   detail = key, file = log_file)
      written[[length(written) + 1]] <- data.frame(
        kind = kind, key = key, action = action, id = id %||% NA_character_,
        statements = length(payload$claims), stringsAsFactors = FALSE
      )
      payloads[[paste0(kind, ":", key)]] <- payload
    }
  }

  out <- do.call(rbind, written)
  if (is.null(out)) out <- data.frame(kind = character(0), key = character(0),
                                      action = character(0), id = character(0),
                                      statements = integer(0), stringsAsFactors = FALSE)
  rownames(out) <- NULL
  attr(out, "payloads") <- payloads

  # The index that makes the items findable by certificate id, written whenever
  # anything was: an item number says nothing to somebody looking for 2020-001.
  if (!dry_run && nrow(out) > 0) {
    write_wikibase_certificates_page(session, out, records$certificates)
    wikibase_log(target = "wikibase", action = "edit", kind = "page",
                 id = WIKIBASE_INSTANCE$certificates_page, label = "certificate index",
                 status = "done", file = log_file)
    cli::cli_alert_success("Certificate index written to {.url {paste0(WIKIBASE_INSTANCE$url, '/wiki/', WIKIBASE_INSTANCE$certificates_page)}}")
  }

  summary <- table(out$kind, out$action)
  cli::cli_alert_success("{nrow(out)} entit{?y/ies}: {sum(out$action == 'create')} to create, {sum(out$action == 'update')} to update")
  print(summary)
  if (dry_run) cli::cli_alert_info("Dry run, nothing written. Pass {.code dry_run = FALSE} to write it.")
  invisible(out)
}

#' The wiki page listing the certificates on the instance
#'
#' A certificate is an item, and an item is found by its number - which says
#' nothing to a person looking for certificate 2020-001. This is the index that
#' does: one row per certificate, from its local item to the register page it
#' came from. Generated, and overwritten by every load.
#'
#' @param written the table [load_wikibase_register()] built
#' @param certificates the certificate rows, for the fields the table shows
#' @param generated_at the timestamp to stamp the page with
#' @return the page's wikitext
#' @keywords internal
wikibase_certificates_wikitext <- function(written, certificates,
                                           generated_at = Sys.time()) {
  certificates$key <- wikibase_key_column(certificates, "certificate")
  certificates$paper_key <- wikidata_transform(certificates$`Paper reference`, "doi")

  items <- written[which(written$kind == "certificate"), ]
  papers <- written[which(written$kind == "paper"), ]
  paper_item <- stats::setNames(papers$id, papers$key)

  # A field the register never filled prints as an empty cell, not as "NA".
  text <- function(x) if (is.null(x) || length(x) == 0 || is.na(x[1])) "" else as.character(x)[1]

  rows <- lapply(seq_len(nrow(items)), function(i) {
    key <- items$key[i]
    source <- certificates[which(certificates$key == key), ][1, ]
    # A named vector, so an absent or missing paper key reads back as NA - a
    # certificate whose paper has no DOI has no paper item to link to.
    paper <- if (is.na(source$paper_key)) NA_character_ else unname(paper_item[source$paper_key])

    c(
      paste0("[[Item:", items$id[i], "|", source$`Certificate ID`, "]]"),
      if (is.na(paper)) "&mdash;" else paste0("[[Item:", paper, "|", paper, "]]"),
      substr(text(source$Title), 1, 80),
      text(source$Venue),
      text(source$`Check date`),
      paste0("[", text(source$`Certificate Link`), " register]"),
      paste0("[https://doi.org/", key, " ", key, "]")
    )
  })

  c(
    "The CODECHECK certificates loaded onto this instance, one item each, as they",
    "appear in the [https://codecheck.org.uk/register/ CODECHECK Register].",
    "",
    "This page is generated by <code>codecheck::load_wikibase_register()</code> and is",
    "overwritten by every load. Do not edit it by hand. The register is the",
    "authority: nothing here exists only on this instance, and the whole instance",
    "can be rebuilt from it. See [[Project:Data model]] for the properties and",
    "class items these statements use.",
    "",
    paste0("== ", nrow(items), " certificates =="),
    "",
    "{| class=\"wikitable sortable\"",
    "! Certificate !! Checked paper !! Title !! Venue !! Check date !! Register !! Report DOI",
    unlist(lapply(rows, function(row) c("|-", paste0("| ", paste(row, collapse = " || "))))),
    "|}",
    "",
    paste0("Generated ", format(generated_at, "%Y-%m-%d %H:%M:%S %Z"), "."),
    ""
  )
}

#' Write the certificate index onto the instance
#'
#' @param session a session from [wikibase_session()]
#' @param written the table [load_wikibase_register()] built
#' @param certificates the certificate rows
#' @return the page title, invisibly
#' @keywords internal
write_wikibase_certificates_page <- function(session, written, certificates) {
  wikibase_post(session, list(
    action = "edit",
    title = WIKIBASE_INSTANCE$certificates_page,
    text = paste(wikibase_certificates_wikitext(written, certificates), collapse = "\n"),
    summary = "generated by codecheck::load_wikibase_register()",
    bot = 1
  ), what = paste0("page '", WIKIBASE_INSTANCE$certificates_page, "'"))
  invisible(WIKIBASE_INSTANCE$certificates_page)
}
