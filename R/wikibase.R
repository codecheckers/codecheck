# Creating the CODECHECK Wikibase's own properties and class items from the
# model in R/wikidata.R (codecheckers/register#50).
#
# The instance at https://codecheck.wikibase.cloud is deliberately temporary: a
# platform for testing the deposition code and for demonstrating the result
# before moving to Wikidata proper. That makes one rule non-negotiable - nothing
# may live only there. [bootstrap_wikibase()] therefore builds the instance from
# empty in a single run and can be run again at any time without creating
# duplicates, so a rebuilt instance is indistinguishable from the original.
#
# A Wikibase does not know Wikidata's property numbers: it mints its own, and
# P31 here is "father" in the stock seed data. Every entity this creates
# therefore carries a "Wikidata entity" statement naming its Wikidata
# counterpart, and that mapping - read back off the instance rather than kept in
# a file that could drift - is what makes the bootstrap idempotent and the later
# export a mechanical projection of the same model.

#' The property that maps a local entity to its Wikidata counterpart
#'
#' Created before anything else, since every other entity refers to it.
#'
#' @keywords internal
WIKIBASE_MAPPING_PROPERTY <- list(
  label = "Wikidata entity",
  description = "the entity on Wikidata this property or item corresponds to",
  datatype = "external-id",
  formatter_url = "https://www.wikidata.org/entity/$1"
)

#' How this client identifies itself
#'
#' Wikimedia's User-Agent policy asks every client for a descriptive agent with
#' a way to reach whoever runs it, and answers a request without one with 403 on
#' the busier endpoints. `WikidataQueryServiceR` was removed from CRAN in
#' February 2026 "for policy violation", which is the cheapest possible reminder
#' to send a real one.
#'
#' @return the User-Agent string
#' @seealso <https://foundation.wikimedia.org/wiki/Policy:User-Agent_policy>
#' @keywords internal
wikibase_user_agent <- function() {
  contact <- getOption("codecheck.contact", "https://github.com/codecheckers/codecheck")
  paste0("codecheck-R/", utils::packageVersion("codecheck"),
         " (", contact, ") httr/", utils::packageVersion("httr"))
}

#' How long to wait before repeating a request, or `NA` to give up
#'
#' A MediaWiki install under load does not fail a request outright, it asks the
#' client to come back: `maxlag` when the database replicas are behind,
#' `ratelimited` when the account is writing too fast, 503 with `Retry-After`
#' when the site is overloaded, and `readonly` during maintenance. All four are
#' transient, and all four used to end a bootstrap halfway through. Everything
#' else - a bad token, a duplicate label, a wrong datatype - is a real error and
#' must not be retried.
#'
#' @param result the parsed API response, or `NULL`
#' @param response the `httr` response, or `NULL`
#' @param attempt which attempt this was, 1-based
#' @return seconds to wait, or `NA_real_` if the request should not be repeated
#' @keywords internal
wikibase_retry_after <- function(result, response = NULL, attempt = 1) {
  # Doubling, so a busy instance is not hammered on every attempt, but never
  # more than a minute: a run that stalls silently is worse than one that fails.
  backoff <- function(seconds) min(max(seconds, 1) * 2^(attempt - 1), 60)

  code <- result$error$code
  if (!is.null(code)) {
    if (identical(code, "maxlag")) {
      # The API reports the actual replication lag, which is a better wait than
      # any constant we could pick.
      return(backoff(result$error$lag %||% 5))
    }
    if (code %in% c("ratelimited", "readonly")) return(backoff(5))
    return(NA_real_)
  }

  if (!is.null(response) && httr::status_code(response) %in% c(429L, 503L)) {
    after <- suppressWarnings(as.numeric(httr::headers(response)[["retry-after"]]))
    return(backoff(if (is.na(after)) 5 else after))
  }

  NA_real_
}

#' One Action API request, repeated while the server asks us to come back
#'
#' The single place both reads and writes go through, so the User-Agent, the
#' retry rule and the JSON parsing are decided once.
#'
#' @param method `httr::GET` or `httr::POST`
#' @param params the request parameters
#' @param handle an `httr` handle, or `NULL` for an anonymous request
#' @param what what is being requested, for messages
#' @param attempts how many times to try in total
#' @return the parsed response
#' @keywords internal
wikibase_request <- function(method, params, handle = NULL, what = "the API",
                             attempts = 4) {
  params$format <- "json"
  agent <- httr::user_agent(wikibase_user_agent())

  for (attempt in seq_len(attempts)) {
    response <- if (identical(method, "POST")) {
      httr::POST(WIKIBASE_INSTANCE$api, handle = handle, body = params,
                 encode = "form", agent)
    } else {
      httr::GET(WIKIBASE_INSTANCE$api, handle = handle, query = params, agent)
    }
    result <- httr::content(response, as = "parsed", type = "application/json")

    wait <- wikibase_retry_after(result, response, attempt)
    if (is.na(wait) || attempt == attempts) return(result)
    cli::cli_alert_warning(
      "{what}: {result$error$code %||% httr::status_code(response)}, retrying in {round(wait)}s"
    )
    Sys.sleep(wait)
  }
  result
}

#' Open an authenticated session with the CODECHECK Wikibase
#'
#' Uses the bot password in the `WIKIBASE_USER` and `WIKIBASE_TOKEN`
#' environment variables (see the register's `.env.example`). The returned
#' session carries the login cookies and a CSRF token, both of which every write
#' needs.
#'
#' @return a list with `handle` and `csrf`
#' @keywords internal
wikibase_session <- function() {
  user <- Sys.getenv(WIKIBASE_INSTANCE$user_env)
  token <- Sys.getenv(WIKIBASE_INSTANCE$token_env)
  if (!nzchar(user) || !nzchar(token)) {
    stop("Set ", WIKIBASE_INSTANCE$user_env, " and ", WIKIBASE_INSTANCE$token_env,
         " to a bot password from ", WIKIBASE_INSTANCE$url,
         "/wiki/Special:BotPasswords - see the register's .env.example")
  }

  handle <- httr::handle(WIKIBASE_INSTANCE$api)

  login_token <- wikibase_get(handle, list(
    action = "query", meta = "tokens", type = "login"
  ))$query$tokens$logintoken

  result <- wikibase_request("POST", list(
    action = "login", lgname = user, lgpassword = token, lgtoken = login_token
  ), handle = handle, what = "logging in")
  if (!identical(result$login$result, "Success")) {
    stop("Wikibase login failed: ", result$login$result, " ", result$login$reason %||% "")
  }

  csrf <- wikibase_get(handle, list(
    action = "query", meta = "tokens", type = "csrf"
  ))$query$tokens$csrftoken

  list(handle = handle, csrf = csrf)
}

#' A writing Action API request
#'
#' Every write goes through here: it carries the CSRF token, and it is the one
#' place that turns an API-level error into an R error rather than a silently
#' ignored response. Separated from its callers so a test can see the payload
#' they build without touching the network.
#'
#' @param session a session from [wikibase_session()]
#' @param params the form parameters, `format` and `token` are added
#' @param what what is being written, for the error message
#' @return the parsed response
#' @keywords internal
wikibase_post <- function(session, params, what) {
  params$token <- session$csrf
  # Ask the server to refuse the write rather than add to its load when the
  # replicas are behind; wikibase_retry_after() then waits out the lag it
  # reports. The value Wikimedia recommends for interactive bots.
  params$maxlag <- 5
  result <- wikibase_request("POST", params, handle = session$handle, what = what)
  if (!is.null(result$error)) {
    stop("Could not write ", what, ": ", result$error$code, " - ", result$error$info)
  }
  result
}

#' A read-only Action API request
#'
#' @param handle an `httr` handle, or `NULL` for an anonymous request
#' @param params the query parameters, `format = "json"` is added
#' @return the parsed response
#' @keywords internal
wikibase_get <- function(handle, params) {
  wikibase_request("GET", params, handle = handle, what = "reading the instance")
}

#' Look an entity up by its label
#'
#' The fallback for when resolution by identifier finds nothing: a paper without
#' a DOI, a venue without an ISSN, a person without an ORCID. Deliberately not
#' the primary route - a label match is a guess, an identifier match is not - so
#' callers are expected to confirm what comes back.
#'
#' @param text the label or alias to search for
#' @param type `"item"` or `"property"`
#' @param handle an optional `httr` handle
#' @param limit how many matches to return
#' @return a `data.frame` with columns `id`, `label` and `description`, best
#'   match first, empty when nothing matched
#' @keywords internal
wikibase_search <- function(text, type = c("item", "property"), handle = NULL,
                            limit = 5) {
  type <- match.arg(type)
  hits <- wikibase_get(handle, list(
    action = "wbsearchentities", search = text, type = type,
    language = "en", uselang = "en", limit = limit
  ))$search

  if (length(hits) == 0) {
    return(data.frame(id = character(0), label = character(0),
                      description = character(0), stringsAsFactors = FALSE))
  }
  data.frame(
    id = vapply(hits, function(h) h$id, character(1)),
    label = vapply(hits, function(h) h$label %||% NA_character_, character(1)),
    description = vapply(hits, function(h) h$description %||% NA_character_, character(1)),
    stringsAsFactors = FALSE
  )
}

#' Split identifiers into SPARQL `VALUES` blocks
#'
#' Resolution asks "which of these DOIs already has an item", and the way to ask
#' that is one query per batch of identifiers, not one query per identifier:
#' 132 certificates would otherwise be 132 round trips against a query service
#' that rate limits, which is the mistake the archived `WikidataR` makes.
#'
#' @param values the identifiers
#' @param size how many to put in one query
#' @param quote whether to render each value as a SPARQL string literal
#' @return a character vector of `VALUES` bodies, one per query to run
#' @keywords internal
wikibase_values_chunks <- function(values, size = 50, quote = TRUE) {
  values <- unique(values[!is.na(values) & nzchar(values)])
  if (length(values) == 0) return(character(0))
  rendered <- if (quote) paste0("\"", gsub("\"", "\\\\\"", values), "\"") else values
  chunks <- split(rendered, ceiling(seq_along(rendered) / size))
  vapply(chunks, paste, character(1), collapse = " ")
}

#' Run a SPARQL query against Wikidata or the CODECHECK Wikibase
#'
#' @param query the query text
#' @param endpoint one of [WIKIDATA_ENDPOINTS], by name
#' @return a `data.frame` of the bindings, one column per selected variable
#' @keywords internal
wikibase_sparql <- function(query, endpoint = c("wikibase", "main", "scholarly")) {
  endpoint <- match.arg(endpoint)
  response <- httr::GET(
    WIKIDATA_ENDPOINTS[[endpoint]], query = list(query = query),
    httr::add_headers(Accept = "application/sparql-results+json"),
    httr::user_agent(wikibase_user_agent())
  )
  if (httr::http_error(response)) {
    stop("SPARQL query against ", endpoint, " failed: ",
         httr::http_status(response)$message)
  }
  parsed <- httr::content(response, as = "parsed", type = "application/json")
  bindings <- parsed$results$bindings
  variables <- unlist(parsed$head$vars)
  if (length(bindings) == 0) {
    empty <- as.data.frame(matrix(character(0), ncol = length(variables)),
                           stringsAsFactors = FALSE)
    colnames(empty) <- variables
    return(empty)
  }
  columns <- lapply(variables, function(v) {
    vapply(bindings, function(b) if (is.null(b[[v]])) NA_character_ else b[[v]]$value,
           character(1))
  })
  names(columns) <- variables
  as.data.frame(columns, stringsAsFactors = FALSE)
}

#' Every entity the instance holds, with its Wikidata counterpart
#'
#' Read off the instance rather than from a local file: the instance is the only
#' authority on what it already contains, and a stale local mapping is exactly
#' how a bootstrap creates duplicates.
#'
#' @param session an optional session; the listing works unauthenticated
#' @return a `data.frame` with columns `local_id`, `wikidata_id` and `label`,
#'   one row per entity that carries the mapping property (plus the mapping
#'   property itself, whose `wikidata_id` is `NA`)
#' @keywords internal
wikibase_mapping <- function(session = NULL) {
  handle <- if (is.null(session)) NULL else session$handle
  # Item and Property live in namespaces 120 and 122 on a wikibase.cloud
  # instance, not in the defaults a stock MediaWiki would use.
  ids <- unlist(lapply(c(120, 122), function(ns) {
    pages <- wikibase_get(handle, list(
      action = "query", list = "allpages", apnamespace = ns, aplimit = 500
    ))$query$allpages
    # Titles come back namespace-prefixed ("Item:Q1", "Property:P1"), while
    # wbgetentities wants the bare ids.
    vapply(pages, function(p) sub("^(Item|Property):", "", p$title), character(1))
  }))
  if (length(ids) == 0) {
    return(data.frame(local_id = character(0), wikidata_id = character(0),
                      label = character(0), stringsAsFactors = FALSE))
  }

  mapping_property <- NA_character_
  rows <- list()
  # wbgetentities takes at most 50 ids per request
  for (chunk in split(ids, ceiling(seq_along(ids) / 50))) {
    entities <- wikibase_get(handle, list(
      action = "wbgetentities", ids = paste(chunk, collapse = "|"),
      props = "labels|claims|datatype"
    ))$entities
    for (id in names(entities)) {
      entity <- entities[[id]]
      label <- entity$labels$en$value %||% NA_character_
      if (identical(label, WIKIBASE_MAPPING_PROPERTY$label)) mapping_property <- id
      rows[[length(rows) + 1]] <- data.frame(
        local_id = id, wikidata_id = NA_character_, label = label,
        stringsAsFactors = FALSE
      )
    }
  }
  out <- do.call(rbind, rows)
  if (is.null(out)) {
    return(data.frame(local_id = character(0), wikidata_id = character(0),
                      label = character(0), stringsAsFactors = FALSE))
  }

  # Second pass: now that the mapping property's own id is known, read the
  # Wikidata id off every entity that carries it.
  if (!is.na(mapping_property)) {
    for (chunk in split(out$local_id, ceiling(seq_along(out$local_id) / 50))) {
      entities <- wikibase_get(handle, list(
        action = "wbgetentities", ids = paste(chunk, collapse = "|"), props = "claims"
      ))$entities
      for (id in names(entities)) {
        claims <- entities[[id]]$claims[[mapping_property]]
        if (!is.null(claims) && length(claims) > 0) {
          out$wikidata_id[out$local_id == id] <- claims[[1]]$mainsnak$datavalue$value
        }
      }
    }
  }
  rownames(out) <- NULL
  out
}

#' Plan the entities the CODECHECK Wikibase needs
#'
#' The pure half of [bootstrap_wikibase()]: given what the instance already
#' holds, work out what is missing. Separated so the decision can be tested
#' without touching the network, and so a dry run and a real run cannot disagree
#' about what would be created.
#'
#' @param existing a mapping as returned by [wikibase_mapping()]
#' @return a `data.frame` with columns `kind` (`"property"` or `"item"`),
#'   `wikidata_id`, `label`, `description`, `datatype`, `role` and `action`
#'   (`"create"` or `"present"`)
#' @keywords internal
plan_wikibase_entities <- function(existing) {
  # One local property per Wikidata property, however many places the model
  # uses it: a qualifier or a reference is the same property in another
  # position, not another property.
  properties <- wikidata_properties()
  properties <- properties[!duplicated(properties$property), ]

  planned <- rbind(
    data.frame(
      kind = "property",
      wikidata_id = NA_character_,
      label = WIKIBASE_MAPPING_PROPERTY$label,
      description = WIKIBASE_MAPPING_PROPERTY$description,
      datatype = WIKIBASE_MAPPING_PROPERTY$datatype,
      role = "mapping",
      stringsAsFactors = FALSE
    ),
    data.frame(
      kind = "property",
      wikidata_id = properties$property,
      label = properties$label,
      description = paste0("counterpart of Wikidata ", properties$property),
      datatype = properties$datatype,
      role = properties$role,
      stringsAsFactors = FALSE
    ),
    data.frame(
      kind = "item",
      wikidata_id = unlist(WIKIDATA_ITEMS, use.names = FALSE),
      label = gsub("_", " ", names(WIKIDATA_ITEMS)),
      description = paste0("counterpart of Wikidata ", unlist(WIKIDATA_ITEMS, use.names = FALSE)),
      datatype = NA_character_,
      role = "class item",
      stringsAsFactors = FALSE
    )
  )

  # Wikibase requires property labels to be unique, and the stock seed data
  # ships properties called "instance of" and "subclass of" - exactly the labels
  # the model wants. Rather than deleting somebody else's entities, a colliding
  # property is disambiguated by its Wikidata id, which is the identity that
  # matters here anyway.
  #
  # A property does not collide with itself: on every run after the first, the
  # instance already holds our own property under the label we gave it, and
  # counting that as a collision would rename "title" to "title (P1476)" on the
  # second run and to "title (P1476) (P1476)" on the third. Only an entity with
  # a different Wikidata id - or none, like the seed data - occupies a label.
  collides <- vapply(seq_len(nrow(planned)), function(i) {
    if (planned$kind[i] != "property" || is.na(planned$wikidata_id[i])) return(FALSE)
    others <- existing$label[is.na(existing$wikidata_id) |
                               existing$wikidata_id != planned$wikidata_id[i]]
    planned$label[i] %in% stats::na.omit(others)
  }, logical(1))
  planned$label[collides] <- paste0(planned$label[collides],
                                    " (", planned$wikidata_id[collides], ")")

  # The mapping property has no Wikidata counterpart, so it is matched by label;
  # everything else by the Wikidata id it carries, which is the identity that
  # survives a relabelling.
  planned$action <- ifelse(
    ifelse(is.na(planned$wikidata_id),
           planned$label %in% existing$label,
           planned$wikidata_id %in% stats::na.omit(existing$wikidata_id)),
    "present", "create"
  )
  rownames(planned) <- NULL
  planned
}

#' Create one entity on the CODECHECK Wikibase
#'
#' @param session a session from [wikibase_session()]
#' @param row one row of the plan from [plan_wikibase_entities()]
#' @param mapping_property the local id of the mapping property, or `NA` when
#'   creating the mapping property itself
#' @return the new entity's local id
#' @keywords internal
create_wikibase_entity <- function(session, row, mapping_property) {
  entity <- list(
    labels = list(en = list(language = "en", value = row$label)),
    descriptions = list(en = list(language = "en", value = row$description))
  )
  # A property's datatype is part of the creating request and cannot be changed
  # afterwards, so it has to be right the first time.
  if (identical(row$kind, "property")) entity$datatype <- row$datatype

  is_mapping_property <- is.na(row$wikidata_id)
  if (!is_mapping_property && !is.na(mapping_property)) {
    entity$claims <- list(list(
      mainsnak = list(
        snaktype = "value", property = mapping_property,
        datavalue = list(type = "string", value = row$wikidata_id)
      ),
      type = "statement", rank = "normal"
    ))
  }

  result <- wikibase_edit_entity(
    session, entity, kind = row$kind,
    summary = paste0("create from the CODECHECK model",
                     if (!is_mapping_property) paste0(" (", row$wikidata_id, ")") else ""),
    what = paste0(row$kind, " '", row$label, "'")
  )
  result$entity$id
}

#' Create or update one entity through wbeditentity
#'
#' `new=` mints an entity, `id=` edits the one named - the same call, and the
#' difference between a rerun that converges and a rerun that duplicates. Every
#' edit carries a summary, so the instance's history says why it changed rather
#' than only that it did.
#'
#' @param session a session from [wikibase_session()]
#' @param data the entity data to write
#' @param kind `"item"` or `"property"` when creating, `NULL` when updating
#' @param id the entity to update, `NULL` when creating
#' @param summary the edit summary
#' @param what what is being written, for the error message
#' @return the parsed response
#' @keywords internal
wikibase_edit_entity <- function(session, data, kind = NULL, id = NULL,
                                 summary = NULL, what = "an entity") {
  if (is.null(kind) == is.null(id)) {
    stop("wikibase_edit_entity() creates with a kind or updates with an id, not both")
  }
  params <- list(
    action = "wbeditentity",
    data = jsonlite::toJSON(data, auto_unbox = TRUE),
    summary = summary,
    bot = 1
  )
  if (is.null(id)) params$new <- kind else params$id <- id
  wikibase_post(session, params, what = what)
}

#' Bring an entity that already exists back in line with the model
#'
#' The instance is generated, so a label or description that no longer matches
#' the model is drift, not somebody's edit to preserve. Only what differs is
#' written: an unchanged entity costs no edit at all, which is what makes
#' running the bootstrap again cheap enough to do routinely.
#'
#' @param session a session from [wikibase_session()]
#' @param row one row of the plan, with `local_id` filled in
#' @param existing the mapping from [wikibase_mapping()]
#' @return `TRUE` if an edit was made
#' @keywords internal
reconcile_wikibase_entity <- function(session, row, existing) {
  current <- existing$label[match(row$local_id, existing$local_id)]
  if (length(current) == 0 || is.na(current) || identical(current, row$label)) {
    return(FALSE)
  }
  wikibase_edit_entity(
    session,
    list(labels = list(en = list(language = "en", value = row$label))),
    id = row$local_id,
    summary = "relabel from the CODECHECK model",
    what = paste0(row$kind, " ", row$local_id)
  )
  TRUE
}

#' The wiki page listing everything the bootstrap created
#'
#' The instance is disposable and its P- and Q-numbers are minted locally, so
#' the only readable index of what it holds is one this writes: which local
#' entity stands for which Wikidata property or item, in one page a reviewer can
#' open without querying the API. Generated, and overwritten by every run.
#'
#' @param plan a plan from [plan_wikibase_entities()] with `local_id` filled in
#' @param generated_at the timestamp to stamp the page with
#' @return the page's wikitext
#' @keywords internal
wikibase_report_wikitext <- function(plan, generated_at = Sys.time()) {
  link <- function(id, kind) {
    if (is.na(id)) {
      "''missing''"
    } else {
      paste0("[[", if (kind == "property") "Property:" else "Item:", id, "|", id, "]]")
    }
  }
  wikidata_link <- function(id) {
    if (is.na(id)) "&mdash;"
    else paste0("[https://www.wikidata.org/wiki/",
                if (grepl("^P", id)) "Property:" else "", id, " ", id, "]")
  }

  table <- function(rows, columns) {
    c("{| class=\"wikitable sortable\"",
      paste0("! ", paste(columns, collapse = " !! ")),
      unlist(lapply(rows, function(row) c("|-", paste0("| ", paste(row, collapse = " || "))))),
      "|}")
  }

  properties <- plan[plan$kind == "property", ]
  items <- plan[plan$kind == "item", ]

  c(
    "This page is generated by <code>codecheck::bootstrap_wikibase()</code> from the",
    "data model in <code>R/wikidata.R</code>",
    "([https://github.com/codecheckers/register/issues/50 register#50])",
    "and is overwritten by every run. Do not edit it by hand.",
    "",
    "A Wikibase mints its own property and item numbers, so the identifiers here",
    "are not Wikidata's: each entity carries a \"Wikidata entity\" statement naming",
    "its counterpart, and that mapping is what lets the two sides line up. Nothing",
    "lives only on this instance &mdash; everything below is reproducible from the",
    "register and the model.",
    "",
    "== Properties ==",
    "",
    table(
      lapply(seq_len(nrow(properties)), function(i) c(
        link(properties$local_id[i], "property"),
        properties$label[i],
        properties$datatype[i],
        if (is.na(properties$role[i])) "&mdash;" else properties$role[i],
        wikidata_link(properties$wikidata_id[i])
      )),
      c("Local", "Label", "Datatype", "Role", "Wikidata")
    ),
    "",
    "== Class items ==",
    "",
    table(
      lapply(seq_len(nrow(items)), function(i) c(
        link(items$local_id[i], "item"),
        items$label[i],
        wikidata_link(items$wikidata_id[i])
      )),
      c("Local", "Label", "Wikidata")
    ),
    "",
    paste0("Generated ", format(generated_at, "%Y-%m-%d %H:%M:%S %Z"), "."),
    ""
  )
}

#' Write the listing page onto the instance
#'
#' @param session a session from [wikibase_session()]
#' @param plan a plan with `local_id` filled in
#' @return the page title, invisibly
#' @keywords internal
write_wikibase_report <- function(session, plan) {
  wikibase_post(session, list(
    action = "edit",
    title = WIKIBASE_INSTANCE$report_page,
    text = paste(wikibase_report_wikitext(plan), collapse = "\n"),
    summary = "generated by codecheck::bootstrap_wikibase()",
    bot = 1
  ), what = paste0("page '", WIKIBASE_INSTANCE$report_page, "'"))
  invisible(WIKIBASE_INSTANCE$report_page)
}

#' Build the CODECHECK Wikibase from the model
#'
#' Creates the instance's own properties and class items, one per entry of the
#' model in `R/wikidata.R`, each carrying a "Wikidata entity" statement naming
#' its Wikidata counterpart. Idempotent: what already exists is left alone, so
#' the instance can be rebuilt from empty and a partially failed run can simply
#' be repeated.
#'
#' Dry by default. A real run needs `WIKIBASE_USER` and `WIKIBASE_TOKEN`; see
#' the register's `.env.example`.
#'
#' @param dry_run if `TRUE` (the default) report what would be created without
#'   writing anything
#' @param log_file where to append the edit log, or `NULL` for the
#'   `codecheck.wikibase_log` option (no log by default)
#' @return the plan, invisibly, with a `local_id` column filled in for the
#'   entities that exist afterwards
#' @examples
#' \dontrun{
#' bootstrap_wikibase()                 # what would be created
#' bootstrap_wikibase(dry_run = FALSE)  # create it
#' }
#' @export
bootstrap_wikibase <- function(dry_run = TRUE, log_file = NULL) {
  cli::cli_h2("CODECHECK Wikibase bootstrap {if (dry_run) '(dry run)' else ''}")

  session <- if (dry_run) NULL else wikibase_session()
  existing <- wikibase_mapping(session)
  cli::cli_alert_info("Instance holds {nrow(existing)} entit{?y/ies}")

  plan <- plan_wikibase_entities(existing)
  to_create <- plan[plan$action == "create", ]
  cli::cli_alert_info("{nrow(to_create)} to create, {sum(plan$action == 'present')} already present")

  plan$local_id <- NA_character_
  known <- stats::setNames(existing$local_id, existing$wikidata_id)
  present <- plan$action == "present" & !is.na(plan$wikidata_id)
  plan$local_id[present] <- known[plan$wikidata_id[present]]
  # The mapping property is matched by label rather than by a Wikidata id, so
  # its local id has to be looked up the same way - and consumers need it, since
  # it is the property every other entity is found through.
  by_label <- plan$action == "present" & is.na(plan$wikidata_id)
  if (any(by_label)) {
    plan$local_id[by_label] <- existing$local_id[
      match(plan$label[by_label], existing$label)
    ]
  }

  if (dry_run) {
    for (i in which(plan$action == "create")) {
      cli::cli_alert("create {plan$kind[i]} {.strong {plan$label[i]}}{if (!is.na(plan$datatype[i])) paste0(' (', plan$datatype[i], ')') else ''}{if (!is.na(plan$wikidata_id[i])) paste0(' -> ', plan$wikidata_id[i]) else ''}")
    }
    cli::cli_alert_info("Would write the listing page {.url {paste0(WIKIBASE_INSTANCE$url, '/wiki/', WIKIBASE_INSTANCE$report_page)}}")
    cli::cli_alert_info("Dry run, nothing written. Pass {.code dry_run = FALSE} to create these.")
    return(invisible(plan))
  }

  # The mapping property must exist before anything that refers to it.
  mapping_property <- existing$local_id[
    !is.na(existing$label) & existing$label == WIKIBASE_MAPPING_PROPERTY$label
  ]
  mapping_property <- if (length(mapping_property) > 0) mapping_property[1] else NA_character_

  order <- c(which(is.na(plan$wikidata_id)), which(!is.na(plan$wikidata_id)))
  for (i in order) {
    if (plan$action[i] != "create") next
    id <- create_wikibase_entity(session, plan[i, ], mapping_property)
    plan$local_id[i] <- id
    if (is.na(plan$wikidata_id[i])) {
      mapping_property <- id
      cli::cli_alert_success("mapping property created as {id}")
    } else {
      cli::cli_alert_success("{plan$kind[i]} {plan$label[i]} -> {id} ({plan$wikidata_id[i]})")
    }
    wikibase_log(target = "wikibase", action = "create", kind = plan$kind[i],
                 id = id, label = plan$label[i], status = "done",
                 detail = plan$wikidata_id[i], file = log_file)
  }

  # An entity that was already there but no longer matches the model is brought
  # back in line, so a rerun converges on the model rather than only filling
  # gaps - the instance has to be reproducible, and a label nothing generates
  # any more is exactly the drift that makes it not.
  relabelled <- 0
  for (i in which(plan$action == "present" & !is.na(plan$local_id))) {
    if (reconcile_wikibase_entity(session, plan[i, ], existing)) {
      relabelled <- relabelled + 1
      cli::cli_alert_success("{plan$local_id[i]} relabelled to {plan$label[i]}")
      wikibase_log(target = "wikibase", action = "relabel", kind = plan$kind[i],
                   id = plan$local_id[i], label = plan$label[i], status = "done",
                   detail = plan$wikidata_id[i], file = log_file)
    }
  }
  if (relabelled > 0) cli::cli_alert_info("{relabelled} entit{?y/ies} brought back in line with the model")

  # Written on every run, not only when something was created: it is the index
  # of the instance, and an unchanged instance still deserves a current one.
  write_wikibase_report(session, plan)
  wikibase_log(target = "wikibase", action = "edit", kind = "page",
               id = WIKIBASE_INSTANCE$report_page, label = "listing page",
               status = "done", file = log_file)
  cli::cli_alert_success("Listing page written to {.url {paste0(WIKIBASE_INSTANCE$url, '/wiki/', WIKIBASE_INSTANCE$report_page)}}")

  cli::cli_alert_success("Bootstrap complete")
  invisible(plan)
}
