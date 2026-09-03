# Linking the register's pages to the records it exported to Wikidata
# (codecheckers/register#50).
#
# Three kinds of page can name a Wikidata item, and each learns it differently:
# a certificate from the `Wikidata` column update_register_wikidata() writes
# into register.csv, a checked work by resolving its DOI, and a person by
# resolving their ORCID. Collected here once per render so that the
# signposting, the Schema.org metadata and the JSON exports all answer from the
# same source rather than each resolving on its own.
#
# The resolutions are cached per identifier, so a render costs a request only
# for an identifier nobody has looked up yet. That is what makes it safe to
# resolve on every render rather than only when something has been exported:
# the second render, and every test run after the first, asks nothing.

#' Where a Wikidata item is addressed
#'
#' Two URLs for the same item, and the difference matters. The entity URI is
#' what Schema.org `sameAs` wants: the identity of the thing. `Special:EntityData`
#' is what signposting's `describedby` wants: a document *about* it, which
#' Wikidata serves as JSON.
#'
#' @param qid a Wikidata item, e.g. "Q42"
#' @return the URL
#' @keywords internal
wikidata_entity_url <- function(qid) paste0("https://www.wikidata.org/entity/", qid)

#' @rdname wikidata_entity_url
#' @keywords internal
wikidata_entitydata_url <- function(qid) {
  paste0("https://www.wikidata.org/wiki/Special:EntityData/", qid, ".json")
}

#' The identifier an entity kind is resolved on
#'
#' The model already says how to turn a register field into the value Wikidata
#' holds - a DOI out of a URL, an ORCID out of a profile link - and the lookup
#' has to be keyed on the same value the resolution was.
#'
#' @param kind an entity kind from [wikidata_entity_kinds()]
#' @param value the register's value
#' @return the identifier, or `NA_character_`
#' @keywords internal
wikidata_lookup_key <- function(kind, value) {
  transform <- WIKIDATA_MODEL[[kind]]$resolve$transform
  if (is.null(transform)) return(as.character(value))
  wikidata_transform(value, transform)
}

#' Resolve identifiers against Wikidata, remembering the answers
#'
#' [wikidata_resolve()] asks Wikidata about every identifier it is given, every
#' time. Rendering the register would then repeat 124 work lookups and 65 ORCID
#' lookups on every run, and a test suite would do it on every file. This asks
#' only about identifiers no previous run has asked about, in one batch, and
#' remembers each answer - including a confirmed "no item", which is an answer
#' too.
#'
#' Cached with [R.cache] under `codecheck/wikidata_items`, alongside the other
#' external lookups; clear it with [register_clear_cache()].
#'
#' @param kind an entity kind from [wikidata_entity_kinds()]
#' @param keys the identifiers, as [wikidata_lookup_key()] produces
#' @return a named character vector, identifier to QID, holding only what exists
#' @keywords internal
wikidata_resolve_cached <- function(kind, keys) {
  keys <- unique(stats::na.omit(as.character(keys)))
  keys <- keys[nzchar(keys)]
  empty <- stats::setNames(character(0), character(0))
  if (length(keys) == 0) return(empty)

  dirs <- c("codecheck", "wikidata_items")
  cache_key <- function(key) list("wikidata_item", kind, key)

  cached <- lapply(keys, function(key) {
    tryCatch(R.cache::loadCache(key = cache_key(key), dirs = dirs),
             error = function(e) NULL)
  })
  usable <- vapply(cached, function(x) is.list(x) && !is.null(x$status), logical(1))

  known <- stats::setNames(rep(NA_character_, length(keys)), keys)
  known[usable] <- vapply(cached[usable], function(x) x$value %||% NA_character_,
                          character(1))

  unknown <- keys[!usable]
  if (length(unknown) > 0) {
    found <- tryCatch(wikidata_resolve(kind, unknown, method = "search"),
                      error = function(e) {
                        cli::cli_alert_warning(
                          "Could not resolve {kind}s on Wikidata: {conditionMessage(e)}")
                        NULL
                      })
    # A failed lookup is not remembered: only an answer is, so that an outage
    # does not bake "no item" into the cache for the next year.
    if (!is.null(found)) {
      for (key in unknown) {
        value <- unname(found[key])
        if (is.null(value) || is.na(value)) value <- NA_character_
        known[key] <- value
        tryCatch(R.cache::saveCache(
          list(status = if (is.na(value)) "absent" else "found", value = value),
          key = cache_key(key), dirs = dirs), error = function(e) NULL)
      }
    }
  }

  known[!is.na(known)]
}

#' The ORCIDs the register knows about
#'
#' @param register_table the preprocessed register table
#' @return the ORCIDs, unique and without `NA`
#' @keywords internal
register_orcids <- function(register_table) {
  if (!"Person" %in% names(register_table)) return(character(0))
  orcids <- unlist(lapply(register_table$Person, function(records) {
    vapply(records, function(record) record$orcid %||% NA_character_, character(1))
  }))
  orcids <- unique(stats::na.omit(as.character(orcids)))
  orcids[nzchar(orcids)]
}

#' Read and write the register's record of the people on Wikidata
#'
#' Resolved by ORCID rather than curated by hand, but written down all the same:
#' the file is what a render reads before asking Wikidata anything, so a clone
#' of the register renders the same links without network access, and a person
#' whose item appears is visible in the register's own history rather than only
#' in a cache directory.
#'
#' @param persons_file path to the CSV, or `NULL` to neither read nor write
#' @param resolved the ORCID-to-QID mapping this render resolved
#' @return the merged mapping
#' @keywords internal
sync_persons_file <- function(persons_file, resolved) {
  if (is.null(persons_file)) return(resolved)

  known <- stats::setNames(character(0), character(0))
  if (file.exists(persons_file)) {
    people <- utils::read.csv(persons_file, stringsAsFactors = FALSE)
    if (all(c("orcid", "wikidata") %in% names(people))) {
      keep <- !is.na(people$wikidata) & nzchar(people$wikidata)
      known <- stats::setNames(people$wikidata[keep], people$orcid[keep])
    } else {
      cli::cli_alert_warning("{.path {persons_file}} has no {.field orcid} and {.field wikidata} columns, ignoring it")
    }
  }

  merged <- known
  merged[names(resolved)] <- resolved
  merged <- merged[order(names(merged))]

  if (!identical(merged, known[order(names(known))])) {
    utils::write.csv(
      data.frame(orcid = names(merged), wikidata = unname(merged),
                 stringsAsFactors = FALSE),
      persons_file, row.names = FALSE, quote = FALSE
    )
    cli::cli_alert_success("{length(merged)} person item{?s} recorded in {.file {persons_file}}")
  }

  merged
}

#' Collect the Wikidata items the register's pages can link to
#'
#' Fills `CONFIG$WIKIDATA_IDS` with one lookup per entity kind, each a named
#' character vector from the identifier the page is keyed on to a QID.
#'
#' @param register_table the preprocessed register table
#' @param persons_file path to the register's record of people on Wikidata, a
#'   CSV with `orcid` and `wikidata` columns, read before resolving and written
#'   back after. `NULL` to neither read nor write it.
#' @return the lookups, invisibly
#' @keywords internal
load_wikidata_ids <- function(register_table, persons_file = NULL) {
  ids <- list(certificate = character(0), paper = character(0), person = character(0))

  # A certificate's item cannot be resolved: the register is the only place
  # that says which item an export created, see update_register_wikidata().
  cert_key <- if ("Certificate ID" %in% names(register_table)) "Certificate ID" else "Certificate"
  if (WIKIDATA_REGISTER_COLUMN %in% names(register_table) &&
      cert_key %in% names(register_table)) {
    qids <- as.character(register_table[[WIKIDATA_REGISTER_COLUMN]])
    keep <- !is.na(qids) & nzchar(qids)
    ids$certificate <- stats::setNames(qids[keep],
                                       as.character(register_table[[cert_key]])[keep])
  }

  # `Work` is the DOI-keyed identity of the checked paper, which is also what a
  # work page is addressed by, so both sides of the lookup agree. `Paper
  # reference` is the raw field, present only in the JSON path.
  references <- if ("Work" %in% names(register_table)) {
    register_table$Work
  } else if ("Paper reference" %in% names(register_table)) {
    register_table$`Paper reference`
  } else {
    character(0)
  }
  if (length(references) > 0) {
    ids$paper <- wikidata_resolve_cached("paper", wikidata_lookup_key("paper", references))
  }

  orcids <- register_orcids(register_table)
  resolved <- wikidata_resolve_cached("person", wikidata_lookup_key("person", orcids))
  ids$person <- sync_persons_file(persons_file, resolved)

  CONFIG$WIKIDATA_IDS <- ids
  found <- vapply(ids, length, integer(1))
  if (sum(found) > 0) {
    cli::cli_alert_success("Wikidata items: {found[['certificate']]} certificate{?s}, {found[['paper']]} work{?s}, {found[['person']]} person{?s}")
  }
  invisible(ids)
}

#' The Wikidata item for one entity, or `NULL`
#'
#' `NULL` rather than `NA` so that the link builders drop the entry the way
#' they already drop every other absent link.
#'
#' @param kind "certificate", "paper" or "person"
#' @param key the certificate ID, the work's DOI, or the person's ORCID
#' @return the QID, or `NULL` when the register does not know one
#' @keywords internal
wikidata_id_for <- function(kind, key) {
  if (is.null(key) || length(key) == 0 || is.na(key[1]) || !nzchar(key[1])) return(NULL)
  # Not every entry point loads the lookup, and a page without it simply
  # carries no Wikidata link.
  all_ids <- CONFIG$WIKIDATA_IDS
  if (is.null(all_ids)) return(NULL)
  ids <- all_ids[[kind]]
  if (is.null(ids) || length(ids) == 0) return(NULL)
  lookup <- if (kind == "certificate") key[1] else wikidata_lookup_key(kind, key[1])
  if (is.null(lookup) || is.na(lookup)) return(NULL)
  qid <- unname(ids[lookup])
  if (is.na(qid)) NULL else qid
}

#' The signposting links naming an entity's Wikidata record
#'
#' `describedby`, not `cite-as`: a certificate's persistent identifier is the
#' DOI of its report, and `cite-as` has a cardinality of one. The Wikidata item
#' is another description of the same object, which is what `describedby`
#' means, and `Special:EntityData` serves it as JSON.
#'
#' @param qid the QID, or `NULL`
#' @return a list of link entries for [signposting_link_tags()]
#' @keywords internal
wikidata_signposting_links <- function(qid) {
  if (is.null(qid)) return(list())
  list(list(rel = "describedby", href = wikidata_entitydata_url(qid),
            type = "application/json"))
}
