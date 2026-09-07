# The instance's SPARQL examples page.
#
# The certificates are on Wikidata; this instance is the staging copy. A page of
# example queries is therefore mostly a page about Wikidata: the examples run
# against the Wikidata Query Service, with Wikidata's own property numbers, and
# what somebody learns from them is usable anywhere. A short second section asks
# this instance the questions Wikidata cannot answer yet - the codechecker link
# lives only here.
#
# The instance-side examples are written against the *model*, Wikidata ids in
# double braces, and the local numbers are substituted when the page is written,
# from the same plan that created the entities: a Wikibase mints its own
# numbering, so `P31` here is not Wikidata's `P31`, and a renumbered instance
# has to rewrite the page rather than have somebody remember which query said
# which number.

#' The prefixes an instance query declares
#'
#' The query service answers with `wd:` and `wdt:` bound to Wikidata, not to
#' this instance, so a query that does not rebind them silently returns nothing.
#' Rebinding the familiar names rather than inventing new ones keeps the queries
#' recognisable to anybody who has written one against Wikidata.
#'
#' @keywords internal
WIKIBASE_QUERY_PREFIXES <- c(
  "PREFIX wd: <{{url}}/entity/>",
  "PREFIX wdt: <{{url}}/prop/direct/>"
)

#' Example queries against Wikidata
#'
#' What the certificates are for: they are on Wikidata, in the scholarly graph,
#' and these are the questions the modelling was chosen to make askable. Written
#' with Wikidata's own ids and run on the Wikidata Query Service, so nothing here
#' depends on this instance existing.
#'
#' `endpoint` names the graph the query runs on, from [WIKIDATA_ENDPOINTS]: the
#' certificates and the papers they check are in the scholarly graph, while the
#' items they point at - the classes, the platforms, the journals - are in the
#' main one, which is why several of these federate to it rather than reading a
#' label that is not there.
#'
#' @keywords internal
WIKIDATA_QUERY_EXAMPLES <- list(
  list(
    title = "Every CODECHECK certificate",
    endpoint = "scholarly",
    why = paste(
      "The starting point: every certificate, with its identifier, its report",
      "DOI and the day the check was done. Certificates are found by their",
      "publication type rather than by <code>instance of</code>, which is what",
      "makes this one list rather than two &mdash; see \"CODECHECKs and",
      "reproducibility reports\" below."
    ),
    query = c(
      "SELECT ?id ?certificate ?certificateLabel ?date ?doi WHERE {",
      "  ?certificate wdt:P13046 wd:Q116740071 ; # publication type: reproducibility report",
      "               wdt:P528 ?id ; # catalog code: the certificate id",
      "               wdt:P356 ?doi ; # DOI of the report",
      "               wdt:P577 ?date . # publication date: the check date",
      "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\". }",
      "}",
      "ORDER BY DESC(?id)"
    )
  ),

  list(
    title = "Checks of papers published in a journal",
    endpoint = "scholarly",
    why = paste(
      "The join the model exists for: a certificate is a <code>review of</code> a",
      "paper, and the paper carries the publication it appeared in. The journal",
      "itself is a main-graph item, so its name and ISSN are asked for by",
      "federating to the main query service from within the scholarly one."
    ),
    query = c(
      "SELECT DISTINCT ?id ?certificate ?workLabel ?journalName WHERE {",
      "  ?certificate wdt:P13046 wd:Q116740071 ;",
      "               wdt:P528 ?id ;",
      "               wdt:P6977 ?work . # review of: the checked paper",
      "  ?work wdt:P31 wd:Q13442814 ; # instance of scholarly article",
      "        wdt:P1433 ?journal . # published in",
      "  SERVICE <https://query.wikidata.org/sparql> {",
      "    ?journal wdt:P236 ?issn ; # ISSN",
      "             rdfs:label ?journalName .",
      "    FILTER(LANG(?journalName) = \"en\")",
      "  }",
      "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\". }",
      "}",
      "ORDER BY ?id"
    ),
    note = paste(
      "Requiring an ISSN is what keeps this to publications, but an ISSN does",
      "not say \"journal\": arXiv and the AGILE: GIScience Series have one too.",
      "Dropping the <code>instance of</code> line adds the checked preprints;",
      "dropping the ISSN adds the papers whose venue has none."
    )
  ),

  list(
    title = "Venues by number of checks",
    endpoint = "scholarly",
    why = paste(
      "The same join, aggregated: which publications the checked papers appeared",
      "in, most-checked first. A journal often has more than one ISSN &mdash;",
      "print and online &mdash; so they are collected rather than multiplying the",
      "rows."
    ),
    query = c(
      "SELECT ?journalName (COUNT(DISTINCT ?certificate) AS ?checks)",
      "       (GROUP_CONCAT(DISTINCT ?issn; separator=\", \") AS ?issns) WHERE {",
      "  ?certificate wdt:P13046 wd:Q116740071 ;",
      "               wdt:P6977 ?work .",
      "  ?work wdt:P1433 ?journal .",
      "  SERVICE <https://query.wikidata.org/sparql> {",
      "    ?journal rdfs:label ?journalName . FILTER(LANG(?journalName) = \"en\")",
      "    OPTIONAL { ?journal wdt:P236 ?issn }",
      "  }",
      "}",
      "GROUP BY ?journalName",
      "ORDER BY DESC(?checks) ?journalName"
    )
  ),

  list(
    title = "CODECHECKs and reproducibility reports",
    endpoint = "scholarly",
    why = paste(
      "Not every check is branded a CODECHECK: the AGILE conference",
      "reproducibility reviews follow the same practice under their own name and",
      "are typed as reproducibility reports. Both are checks, and this is the",
      "split. The count is taken first and the class named afterwards, because a",
      "federated label inside an aggregate multiplies what it counts."
    ),
    query = c(
      "SELECT ?class ?className ?certificates WHERE {",
      "  {",
      "    SELECT ?class (COUNT(DISTINCT ?certificate) AS ?certificates) WHERE {",
      "      ?certificate wdt:P13046 wd:Q116740071 ;",
      "                   wdt:P31 ?class . # instance of",
      "    }",
      "    GROUP BY ?class",
      "  }",
      "  SERVICE <https://query.wikidata.org/sparql> {",
      "    ?class rdfs:label ?className . FILTER(LANG(?className) = \"en\")",
      "  }",
      "}",
      "ORDER BY DESC(?certificates)"
    ),
    note = paste(
      "This is why the other queries match on publication type: asking for",
      "<code>instance of</code> CODECHECK answers a narrower question than most",
      "people mean, and does so silently."
    )
  ),

  list(
    title = "Where the certificates themselves are published",
    endpoint = "scholarly",
    why = paste(
      "A certificate is deposited on Zenodo, OSF or ResearchEquals, which is a",
      "different fact from where the checked paper appeared &mdash; the same",
      "property on a different item."
    ),
    query = c(
      "SELECT ?platform ?platformName ?certificates WHERE {",
      "  {",
      "    SELECT ?platform (COUNT(DISTINCT ?certificate) AS ?certificates) WHERE {",
      "      ?certificate wdt:P13046 wd:Q116740071 ;",
      "                   wdt:P1433 ?platform . # published in",
      "    }",
      "    GROUP BY ?platform",
      "  }",
      "  SERVICE <https://query.wikidata.org/sparql> {",
      "    ?platform rdfs:label ?platformName . FILTER(LANG(?platformName) = \"en\")",
      "  }",
      "}",
      "ORDER BY DESC(?certificates)"
    )
  ),

  list(
    title = "Checks per year",
    endpoint = "scholarly",
    why = "How the practice has grown, from the check dates.",
    query = c(
      "SELECT ?year (COUNT(?certificate) AS ?checks) WHERE {",
      "  ?certificate wdt:P13046 wd:Q116740071 ;",
      "               wdt:P577 ?date .",
      "  BIND(YEAR(?date) AS ?year)",
      "}",
      "GROUP BY ?year",
      "ORDER BY ?year"
    )
  ),

  list(
    title = "How long after publication a paper was checked",
    endpoint = "scholarly",
    why = paste(
      "Two dates from two items: the paper's own publication date and the day",
      "the check was done. Subtracting two <code>xsd:dateTime</code> values gives",
      "a number of days."
    ),
    query = c(
      "SELECT ?id ?workLabel ?published ?checked ?days WHERE {",
      "  ?certificate wdt:P13046 wd:Q116740071 ;",
      "               wdt:P528 ?id ;",
      "               wdt:P577 ?checked ;",
      "               wdt:P6977 ?work .",
      "  ?work wdt:P577 ?published .",
      "  BIND(xsd:integer(?checked - ?published) AS ?days)",
      "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\". }",
      "}",
      "ORDER BY DESC(?days)",
      "LIMIT 10"
    ),
    note = paste(
      "The top of this list is checks of classic papers rather than late checks",
      "of new ones &mdash; a reproduction of a 1982 paper is a decades-long gap",
      "by this measure."
    )
  ),

  list(
    title = "The preprints that have been checked",
    endpoint = "scholarly",
    why = paste(
      "A checked work is typed a preprint when the register says so, which is",
      "the codechecker stating a fact about the paper rather than about a venue."
    ),
    query = c(
      "SELECT ?id ?workLabel ?doi WHERE {",
      "  ?certificate wdt:P13046 wd:Q116740071 ;",
      "               wdt:P528 ?id ;",
      "               wdt:P6977 ?work .",
      "  ?work wdt:P31 wd:Q580922 ; # instance of preprint",
      "        wdt:P356 ?doi .",
      "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\". }",
      "}",
      "ORDER BY ?id"
    )
  ),

  list(
    title = "Where the checked code lives",
    endpoint = "scholarly",
    why = paste(
      "Every certificate records the repository the check ran from. The host is",
      "not modelled, so it is taken out of the URL &mdash; the sort of thing a",
      "query can do and a data model should not."
    ),
    query = c(
      "SELECT ?host (COUNT(?certificate) AS ?checks) WHERE {",
      "  ?certificate wdt:P13046 wd:Q116740071 ;",
      "               wdt:P1324 ?repository . # source code repository URL",
      "  BIND(REPLACE(STR(?repository), \"^https?://([^/]+)/.*$\", \"$1\") AS ?host)",
      "}",
      "GROUP BY ?host",
      "ORDER BY DESC(?checks)"
    )
  ),

  list(
    title = "Everything recorded about one certificate",
    endpoint = "scholarly",
    why = paste(
      "Every statement on one certificate item, with the property named rather",
      "than numbered. The property registry and half the values are main-graph",
      "items, so the names come from there and fall back to the scholarly graph",
      "for the checked paper."
    ),
    query = c(
      "SELECT ?propertyName ?value ?valueName WHERE {",
      "  ?certificate wdt:P528 \"2020-016\" ;",
      "               wdt:P13046 wd:Q116740071 ;",
      "               ?p ?value .",
      "  SERVICE <https://query.wikidata.org/sparql> {",
      "    ?property wikibase:directClaim ?p ;",
      "              rdfs:label ?propertyName .",
      "    FILTER(LANG(?propertyName) = \"en\")",
      "    OPTIONAL { ?value rdfs:label ?mainName . FILTER(LANG(?mainName) = \"en\") }",
      "  }",
      "  OPTIONAL { ?value rdfs:label ?scholarlyName . FILTER(LANG(?scholarlyName) = \"en\") }",
      "  BIND(COALESCE(?mainName, ?scholarlyName, STR(?value)) AS ?valueName)",
      "}",
      "ORDER BY ?propertyName"
    )
  )
)

#' Example queries against this instance
#'
#' Short, and only what Wikidata cannot answer: the codechecker link exists here
#' and nowhere else, because people are resolved on Wikidata rather than created
#' there, and the certificates on Wikidata carry no `author` statement.
#'
#' Entity ids are written as the Wikidata ids the model names, in double braces,
#' and resolved to this instance's numbers by [render_wikibase_query()].
#'
#' @keywords internal
WIKIBASE_QUERY_EXAMPLES <- list(
  list(
    title = "Every check on this instance",
    why = paste(
      "The same starting point as on Wikidata, in this instance's numbering, and",
      "the shortest way to see that the two hold the same certificates."
    ),
    query = c(
      "SELECT ?id ?check ?checkLabel ?date WHERE {",
      "  ?check wdt:{{P13046}} wd:{{Q116740071}} ; # publication type",
      "         wdt:{{P528}} ?id ; # the certificate id",
      "         wdt:{{P577}} ?date . # the check date",
      "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\". }",
      "}",
      "ORDER BY DESC(?id)"
    )
  ),

  list(
    title = "Codecheckers, by number of checks",
    why = paste(
      "A codechecker is the author of the certificate. This is the question the",
      "instance exists to answer: on Wikidata the certificates carry no",
      "<code>author</code> statement, because a person item is linked there and",
      "never created by this pipeline."
    ),
    query = c(
      "SELECT ?codecheckerLabel ?orcid (COUNT(?check) AS ?checks) WHERE {",
      "  ?check wdt:{{P13046}} wd:{{Q116740071}} ;",
      "         wdt:{{P50}} ?codechecker . # author: the codechecker",
      "  OPTIONAL { ?codechecker wdt:{{P496}} ?orcid }",
      "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\". }",
      "}",
      "GROUP BY ?codecheckerLabel ?orcid",
      "ORDER BY DESC(?checks) ?codecheckerLabel"
    )
  ),

  list(
    title = "Codecheckers who have checked papers across venues",
    why = paste(
      "Both halves at once &mdash; certificate to codechecker, certificate to",
      "paper to venue &mdash; which is the sort of question neither the register's",
      "own pages nor Wikidata can answer today."
    ),
    query = c(
      "SELECT ?codecheckerLabel (COUNT(DISTINCT ?venue) AS ?venues) WHERE {",
      "  ?check wdt:{{P13046}} wd:{{Q116740071}} ;",
      "         wdt:{{P50}} ?codechecker ;",
      "         wdt:{{P6977}} ?paper . # review of",
      "  ?paper wdt:{{P1433}} ?venue . # published in",
      "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\". }",
      "}",
      "GROUP BY ?codecheckerLabel",
      "HAVING (COUNT(DISTINCT ?venue) > 1)",
      "ORDER BY DESC(?venues)"
    )
  )
)

#' The instance's local id for each Wikidata id
#'
#' @param plan a plan from [plan_wikibase_entities()] with `local_id` filled in
#' @return a named character vector, Wikidata id to local id
#' @keywords internal
wikibase_local_ids <- function(plan) {
  known <- !is.na(plan$wikidata_id) & !is.na(plan$local_id)
  stats::setNames(plan$local_id[known], plan$wikidata_id[known])
}

#' Substitute this instance's ids into an example query
#'
#' @param query the query lines, with Wikidata ids in double braces
#' @param ids a mapping from [wikibase_local_ids()]
#' @return the query lines with the local ids substituted
#' @keywords internal
render_wikibase_query <- function(query, ids) {
  rendered <- vapply(query, function(line) {
    placeholders <- regmatches(line, gregexpr("\\{\\{[PQ][0-9]+\\}\\}", line))[[1]]
    for (placeholder in unique(placeholders)) {
      wikidata_id <- gsub("[{}]", "", placeholder)
      local_id <- ids[wikidata_id]
      if (is.na(local_id)) {
        stop("Example query refers to ", wikidata_id,
             ", which the model does not create on the instance")
      }
      line <- gsub(placeholder, local_id, line, fixed = TRUE)
    }
    line
  }, character(1), USE.NAMES = FALSE)

  align_wikibase_query_comments(rendered)
}

#' Line up the comments in a query
#'
#' A placeholder is longer than the local id it becomes, so comments written
#' straight in the model come out ragged once substituted. They are the labels
#' that make an unfamiliar property number readable, so they are aligned here
#' rather than by hand.
#'
#' @param query the query lines
#' @return the lines with their comments aligned
#' @keywords internal
align_wikibase_query_comments <- function(query) {
  # Only a `#` outside a string literal starts a comment; a query that filters
  # on a URL fragment would otherwise be cut in half.
  split_at <- vapply(query, function(line) {
    hashes <- gregexpr("#", line, fixed = TRUE)[[1]]
    if (hashes[1] == -1) return(NA_integer_)
    for (at in hashes) {
      before <- substr(line, 1, at - 1)
      quotes <- lengths(regmatches(before, gregexpr("\"", before, fixed = TRUE)))
      if (quotes %% 2 == 0) return(as.integer(at))
    }
    NA_integer_
  }, integer(1), USE.NAMES = FALSE)

  commented <- !is.na(split_at)
  if (!any(commented)) return(query)

  code <- trimws(substr(query, 1, ifelse(commented, split_at - 1, nchar(query))), "right")
  column <- max(nchar(code[commented])) + 2
  padded <- paste0(code, strrep(" ", pmax(column - nchar(code), 1)))
  ifelse(commented, paste0(padded, substring(query, split_at)), query)
}

#' A link that opens a query in a query service
#'
#' The graphical query service lives at the endpoint's own host, one directory
#' up from the SPARQL path, and takes its query in the URL fragment.
#'
#' @param query the rendered query lines
#' @param endpoint the endpoint name, a key of [WIKIDATA_ENDPOINTS]
#' @return the URL
#' @keywords internal
wikibase_query_url <- function(query, endpoint = "wikibase") {
  gui <- sub("sparql$", "#", WIKIDATA_ENDPOINTS[[endpoint]])
  paste0(gui, utils::URLencode(paste(query, collapse = "\n"), reserved = TRUE))
}

#' The instance's example-queries page
#'
#' The certificates are on Wikidata, so most of the page is Wikidata queries:
#' what a reader learns from them works anywhere, and nothing in them depends on
#' this instance. The instance's own section is short and covers what Wikidata
#' cannot answer, where two things a visitor cannot guess have to be said: the
#' local property numbers are not Wikidata's, and the query service binds `wdt:`
#' to Wikidata rather than to the instance, so a query copied from Wikidata
#' returns an empty table and no error. Those queries are generated from the same
#' plan that created the entities, so their ids cannot drift from the instance.
#'
#' @param plan a plan from [plan_wikibase_entities()] with `local_id` filled in
#' @param generated_at the timestamp to stamp the page with
#' @return the page's wikitext
#' @keywords internal
wikibase_examples_wikitext <- function(plan, generated_at = Sys.time()) {
  ids <- wikibase_local_ids(plan)
  prefixes <- gsub("{{url}}", WIKIBASE_INSTANCE$url, WIKIBASE_QUERY_PREFIXES, fixed = TRUE)

  section <- function(item, query, endpoint) {
    c(
      paste0("=== ", item$title, " ==="),
      "",
      item$why,
      "",
      "<syntaxhighlight lang=\"sparql\">",
      query,
      "</syntaxhighlight>",
      "",
      paste0("[", wikibase_query_url(query, endpoint), " Run this query]"),
      if (!is.null(item$note)) c("", paste0("''", item$note, "''")),
      ""
    )
  }

  wikidata_example <- function(item) {
    section(item, align_wikibase_query_comments(item$query), item$endpoint)
  }
  wikibase_example <- function(item) {
    section(item, c(prefixes, "", render_wikibase_query(item$query, ids)), "wikibase")
  }

  c(
    "This page is generated by <code>codecheck::bootstrap_wikibase()</code> and is",
    "overwritten by every run. Do not edit it by hand &mdash; add an example to",
    "<code>R/wikibase_queries.R</code> in the",
    "[https://github.com/codecheckers/codecheck codecheck R package] instead.",
    "",
    "'''The queries below run against Wikidata, not against this instance.''' The",
    "CODECHECK certificates are items on Wikidata, and that is where a question",
    "about them should be asked: the answers are the real record, the ids are the",
    "ones to cite, and nothing you learn here depends on this staging instance",
    "still existing. Each query has a link that opens it in the Wikidata Query",
    "Service, ready to run and to edit.",
    "",
    paste0("A short [[#Queries on this instance|second section]] does use this ",
           "instance's own endpoint at <code>", WIKIDATA_ENDPOINTS$wikibase, "</code>, ",
           "for the one thing Wikidata cannot answer today: who did the checking. ",
           "Codecheckers are people, and this pipeline links a person on Wikidata ",
           "but never creates one, so the certificates there carry no ",
           "<code>author</code> statement while the items here do."),
    "",
    "== Wikidata's split graph ==",
    "",
    "Wikidata's query service is split in two, and a query has to be sent to the",
    "right half:",
    "",
    paste0("* '''The scholarly graph''', [https://query-scholarly.wikidata.org/ ",
           "query-scholarly.wikidata.org], holds the scholarly articles and the ",
           "certificates that review them. Every query below starts here."),
    paste0("* '''The main graph''', [https://query.wikidata.org/ query.wikidata.org], ",
           "holds everything else &mdash; the journals, the platforms, the classes and ",
           "the property registry itself."),
    "",
    "A statement joining the two is written on the scholarly side, so the item it",
    "points at is a bare Q-number there: the label service will not name a journal,",
    "and <code>wdt:P236</code> will not find its ISSN. The queries that need those",
    "reach across with <code>SERVICE &lt;https://query.wikidata.org/sparql&gt;</code>,",
    "which is federation, not a copy &mdash; and one to keep outside an aggregate,",
    "where it multiplies what is being counted.",
    "",
    "== Queries on Wikidata ==",
    "",
    unlist(lapply(WIKIDATA_QUERY_EXAMPLES, wikidata_example), use.names = FALSE),
    "== Queries on this instance ==",
    "",
    "Two things differ here from a query written against Wikidata, and both fail",
    "silently &mdash; an empty result, not an error:",
    "",
    paste0("* '''The numbers are this instance's own.''' A Wikibase mints its own ",
           "property and item ids, so <code>P31</code> here is not Wikidata's ",
           "<code>P31</code>. Every entity carries a \"Wikidata entity\" statement naming ",
           "its counterpart; [[", WIKIBASE_INSTANCE$report_page, "]] is the table of both."),
    paste0("* '''<code>wd:</code> and <code>wdt:</code> point at Wikidata.''' The query ",
           "service does not rebind them for the local instance, so each query below ",
           "declares its own prefixes. Keep those two lines when you copy one."),
    "",
    paste0("The model these queries are written against is described on [[",
           WIKIBASE_INSTANCE$report_page, "]], and the certificates themselves are listed on [[",
           WIKIBASE_INSTANCE$certificates_page, "]]. The register remains the authority: ",
           "an answer that looks wrong is a question for ",
           "[https://github.com/codecheckers/register/issues codecheckers/register]."),
    "",
    unlist(lapply(WIKIBASE_QUERY_EXAMPLES, wikibase_example), use.names = FALSE),
    paste0("Generated ", format(generated_at, "%Y-%m-%d %H:%M:%S %Z"), "."),
    ""
  )
}

#' Write the example-queries page onto the instance
#'
#' @param session a session from [wikibase_session()]
#' @param plan a plan with `local_id` filled in
#' @return the page title, invisibly
#' @keywords internal
write_wikibase_examples_page <- function(session, plan) {
  wikibase_post(session, list(
    action = "edit",
    title = WIKIBASE_INSTANCE$queries_page,
    text = paste(wikibase_examples_wikitext(plan), collapse = "\n"),
    summary = "generated by codecheck::bootstrap_wikibase()",
    bot = 1
  ), what = paste0("page '", WIKIBASE_INSTANCE$queries_page, "'"))
  invisible(WIKIBASE_INSTANCE$queries_page)
}
