# The data model behind the CODECHECK Wikidata/Wikibase export
# (codecheckers/register#50).
#
# This file is deliberately nothing but a description of the model, plus the
# accessors that read it. No HTTP, no rendering, no QuickStatements: the
# emitters, the identifier resolution and the diffing build on WIKIDATA_MODEL,
# so that the modelling decisions live in one reviewable place rather than
# spread over the code that acts on them.
#
# Two decisions in here are not obvious and are the reason the model is written
# down separately at all:
#
# 1. Every certificate carries "publication type of scholarly work" (P13046).
#    The Wikidata Query Service is split into two graphs, and an entity lives in
#    exactly one of them: cross-graph references resolve to a single marker
#    triple with no label, no type and no identifier, so a query cannot join a
#    certificate to the paper it checks across the split. Membership follows the
#    *direct* P31 value against a fixed list of 49 QIDs, or the presence of any
#    P13046 statement - the P279 hierarchy is not evaluated, which is why a
#    certificate that is transitively a scholarly article still lands in the main
#    graph. P13046 puts it in the scholarly graph, next to the papers, without
#    having to also claim P31 = scholarly article. See
#    https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service/WDQS_graph_split/Rules
#
# 2. The link to the checked paper is "review of" (P6977), not "cites work"
#    (P2860). P6977 is a subproperty of P921 and equivalent to schema.org/review,
#    which is exactly what a certificate page already publishes as a Review with
#    an itemReviewed. P2860 cannot express which of several cited works was the
#    one checked - the single ReScience C article in Wikidata demonstrates the
#    problem, carrying nine P2860 statements among which the replicated paper is
#    indistinguishable. On CODECHECK certificate items P6977 is therefore used
#    *only* for the checked paper.

#' The SPARQL endpoints the resolution step queries
#'
#' The Wikidata Query Service was split in 2025: scholarly articles moved to
#' their own endpoint, everything else stayed on the main one, and an entity is
#' served by exactly one of them. Papers are therefore looked up on
#' `scholarly`, people and venues on `main`; querying the wrong one silently
#' returns no match rather than an error.
#'
#' `wikibase` is the CODECHECK Wikibase instance, which is unsplit.
#'
#' @keywords internal
WIKIDATA_ENDPOINTS <- list(
  main = "https://query.wikidata.org/sparql",
  scholarly = "https://query-scholarly.wikidata.org/sparql",
  wikibase = "https://codecheck.wikibase.cloud/query/sparql"
)

#' The CODECHECK Wikibase instance
#'
#' Deliberately a time-limited platform for testing the deposition code and for
#' demonstrating the result before moving to Wikidata proper, so nothing may
#' live only there: everything the instance holds has to be reproducible from
#' `register.csv` and this model.
#'
#' @keywords internal
WIKIBASE_INSTANCE <- list(
  url = "https://codecheck.wikibase.cloud",
  api = "https://codecheck.wikibase.cloud/w/api.php",
  rest = "https://codecheck.wikibase.cloud/w/rest.php/wikibase/v1",
  quickstatements = "https://codecheck.wikibase.cloud/tools/quickstatements/",
  # Special:BotPasswords credentials, see the register's .env.example
  user_env = "WIKIBASE_USER",
  token_env = "WIKIBASE_TOKEN"
)

#' The Wikidata items the model refers to by name
#'
#' Constants rather than lookups: these identify the classes the certificates
#' are typed against, and a rename on Wikidata must not silently change what the
#' export writes.
#'
#' @keywords internal
WIKIDATA_ITEMS <- list(
  # "CODECHECK", the certificate class, P279 of reproducibility report
  codecheck_certificate = "Q116740091",
  # "Reproducibility Report", P279 of scholarly article, technical report and
  # review - the last of these is what satisfies P6977's type constraint
  reproducibility_report = "Q116740071",
  # "CODECHECK: An open-science initiative for the independent execution of
  # computations underlying research articles", the methods paper
  methods_paper = "Q111935840",
  # "scholarly article", the value the graph split routes on
  scholarly_article = "Q13442814",
  # "preprint" - also a scholarly-graph type (3,151 items carry it there and
  # none in the main graph), so typing a checked preprint this way keeps it
  # beside its certificate rather than moving it out of reach
  preprint = "Q580922",
  # "review", the class P6977 expects its subject to be under
  review = "Q265158",
  # "human", for codechecker items
  human = "Q5",
  # The register itself, as the catalog the certificate identifiers belong to.
  # No such item exists yet: the interim P528 statement below needs one, and it
  # is created together with the first Wikidata batch. Until then the statement
  # is marked pending and no export emits it.
  codecheck_register = NA_character_
)

#' The platforms a certificate itself is published on
#'
#' A certificate is deposited on Zenodo, OSF or ResearchEquals, and that is a
#' different fact from the venue of the paper it checks - the register records
#' the first in the report DOI and the second in its `Venue` column, and both
#' belong in the metadata. Keyed by the names [detect_report_platform()]
#' returns.
#'
#' `P1433` rather than `P123` publisher: both are in use for repository-hosted
#' works, and "published in" is the more common of the two by some margin
#' (roughly 320 against 90 statements pointing at Zenodo when last counted).
#'
#' @keywords internal
WIKIDATA_PLATFORMS <- list(
  zenodo = "Q22661177",
  osf = "Q18691678",
  researchequals = "Q115504497"
)

#' A reference block attached to every statement the export writes
#'
#' Not decoration: it is what distinguishes a statement this pipeline wrote from
#' one a person added by hand, and it gives a reviewer the page to check it
#' against. `S`-prefixed properties are the QuickStatements spelling of a
#' reference.
#'
#' @keywords internal
WIKIDATA_REFERENCE <- list(
  list(property = "S854", label = "reference URL", value = list(kind = "field", field = "Certificate Link")),
  list(property = "S813", label = "retrieved", value = list(kind = "render_date"))
)

#' Build one statement definition
#'
#' @param key internal name of the statement, unique within its entity kind
#' @param property the Wikidata property, e.g. "P31"
#' @param label the property's English label, for the human-readable exports
#' @param value how the value is obtained, see [WIKIDATA_MODEL]
#' @param required whether a certificate without this value is an error rather
#'   than an omission
#' @param note why the statement is modelled this way, shown in the model
#'   documentation and in review
#' @param venue_types optional character vector restricting the statement to
#'   certificates of these venue types
#' @param qualifiers optional list of qualifier definitions, each a list with
#'   `property`, `label` and `value` of the same shape as a statement's own
#' @return a statement definition list
#' @keywords internal
wikidata_statement <- function(key, property, label, value, required = FALSE,
                               note = NULL, venue_types = NULL, qualifiers = NULL) {
  stmt <- list(
    key = key,
    property = property,
    label = label,
    value = value,
    required = required
  )
  if (!is.null(note)) stmt$note <- note
  if (!is.null(venue_types)) stmt$venue_types <- venue_types
  if (!is.null(qualifiers)) stmt$qualifiers <- qualifiers
  stmt
}

#' The CODECHECK Wikidata model
#'
#' One target-neutral description of what a CODECHECK certificate looks like as
#' linked data, read by the export generator, the identifier resolution and the
#' Wikibase bootstrap. Property numbers are the Wikidata ones; the CODECHECK
#' Wikibase carries its own P-numbers and maps them back through a "Wikidata
#' entity" property, so this model stays the single source for both.
#'
#' Each entry describes one kind of entity:
#'
#' \describe{
#'   \item{`label`, `description`}{whisker templates over the register columns}
#'   \item{`resolve`}{how an existing item is found rather than created: the
#'     identifier property, the register column holding the identifier, the
#'     transformation applied to it, and the endpoint that serves that kind of
#'     entity}
#'   \item{`create`}{whether the export may create such an item on each target.
#'     Only certificates are created on Wikidata; papers, people and venues are
#'     resolved there and created only in our own Wikibase, which mirrors
#'     everything.}
#'   \item{`statements`}{the statement definitions, see [wikidata_statement()]}
#' }
#'
#' A statement's `value` is one of:
#'
#' \describe{
#'   \item{`list(kind = "constant", item = "Q…")`}{a fixed item}
#'   \item{`list(kind = "field", field = "…", transform = "…")`}{a register
#'     column, optionally passed through a named transformation}
#'   \item{`list(kind = "entity", entity = "…", field = "…")`}{a reference to
#'     another entity of the model, resolved to a QID before emission; when it
#'     cannot be resolved the statement is omitted rather than guessed}
#'   \item{`list(kind = "switch", field = "…", cases = list(…), default = "Q…")`}{
#'     an item chosen by the value of a register column}
#'   \item{`list(kind = "mapped", field = "…", transform = "…", map = "…")`}{
#'     an item looked up in a named map, after the field has been passed through
#'     the transformation}
#' }
#'
#' The register columns referenced are those of the preprocessed register table,
#' the same ones `render_register_full()` writes to `register-full.json`.
#'
#' @seealso [wikidata_properties()] for the flat property list, and
#'   [validate_wikidata_model()] for the invariants this structure must satisfy
#' @keywords internal
WIKIDATA_MODEL <- list(

  certificate = list(
    label = "CODECHECK Certificate {{`Certificate ID`}}",
    description = "reproducibility check of a paper published in {{Venue}}",
    # The report DOI is the dedup key: every certificate has one, it is stable,
    # and it does not depend on a CODECHECK-specific property existing yet.
    resolve = list(property = "P356", field = "Report", transform = "doi", endpoint = "scholarly"),
    create = list(wikidata = TRUE, wikibase = TRUE),
    statements = list(
      wikidata_statement(
        "instance_of", "P31", "instance of",
        list(
          kind = "switch",
          field = "Venue",
          cases = list(AGILEGIS = WIKIDATA_ITEMS$reproducibility_report),
          default = WIKIDATA_ITEMS$codecheck_certificate
        ),
        required = TRUE,
        note = paste(
          "the identity of the item, kept specific rather than restated as",
          "scholarly article. The AGILE reproducibility reviews are typed as",
          "reproducibility reports rather than CODECHECKs: they follow the same",
          "practice but are not branded as CODECHECKs, and claiming otherwise",
          "in a public knowledge base would misattribute them"
        )
      ),
      wikidata_statement(
        "publication_type", "P13046", "publication type of scholarly work",
        list(kind = "constant", item = WIKIDATA_ITEMS$reproducibility_report),
        required = TRUE,
        note = paste(
          "what puts the item in the scholarly graph, beside the papers it",
          "reviews; without it the certificate lands in the main graph and no",
          "query can join it to its paper"
        )
      ),
      wikidata_statement(
        "title", "P1476", "title",
        list(kind = "field", field = "Title")
      ),
      wikidata_statement(
        "doi", "P356", "DOI",
        list(kind = "field", field = "Report", transform = "doi"),
        required = TRUE,
        note = "uppercased, which is how Wikidata stores DOIs and how a lookup must query them"
      ),
      wikidata_statement(
        "publication_date", "P577", "publication date",
        list(kind = "field", field = "Check date", transform = "date_day"),
        note = "the check date, to day precision"
      ),
      wikidata_statement(
        "author", "P50", "author",
        list(kind = "entity", entity = "person", field = "Codechecker"),
        note = paste(
          "the codechecker; falls back to P2093 author name string when the",
          "person has no item, so a check is never attributed to nobody"
        )
      ),
      wikidata_statement(
        "author_name_string", "P2093", "author name string",
        list(kind = "field", field = "Codechecker", transform = "unresolved_names"),
        note = "only for codecheckers without an item, the fallback of the statement above"
      ),
      wikidata_statement(
        "review_of", "P6977", "review of",
        list(kind = "entity", entity = "paper", field = "Paper reference"),
        note = paste(
          "the checked paper, and on certificate items this property is used",
          "for nothing else - that exclusivity is what makes the relation",
          "queryable at all"
        )
      ),
      wikidata_statement(
        "described_at_url", "P973", "described at URL",
        list(kind = "field", field = "Certificate Link"),
        note = "the register landing page, which is what links Wikidata back to us"
      ),
      wikidata_statement(
        "catalog_code", "P528", "catalog code",
        list(kind = "field", field = "Certificate ID"),
        qualifiers = list(
          list(property = "P972", label = "catalog",
               value = list(kind = "constant",
                            item = WIKIDATA_ITEMS$codecheck_register,
                            pending = "the CODECHECK register catalog item, created with the first batch"))
        ),
        note = paste(
          "the certificate identifier, carried generically until a dedicated",
          "'CODECHECK certificate ID' external identifier property exists;",
          "P528 is meaningless without naming its catalog, hence the P972",
          "qualifier"
        )
      ),
      wikidata_statement(
        "full_work_available_at", "P953", "full work available at URL",
        list(kind = "field", field = "Certificate PDF")
      ),
      wikidata_statement(
        "source_code_repository", "P1324", "source code repository URL",
        list(kind = "field", field = "Repository Link")
      ),
      wikidata_statement(
        "published_in", "P1433", "published in",
        list(kind = "mapped", field = "Report", transform = "report_platform", map = "platforms"),
        note = paste(
          "where the certificate itself is published - Zenodo, OSF or",
          "ResearchEquals - which is not the venue of the paper it checks;",
          "that one sits on the paper item, where it belongs"
        )
      ),
      wikidata_statement(
        "described_by_source", "P1343", "described by source",
        list(kind = "constant", item = WIKIDATA_ITEMS$methods_paper),
        note = "the CODECHECK methods paper, as the existing certificate item already records"
      )
    )
  ),

  paper = list(
    label = "{{Title}}",
    description = NULL,
    resolve = list(property = "P356", field = "Paper reference", transform = "doi", endpoint = "scholarly"),
    # Papers are ordinary scholarly articles and are created on Wikidata through
    # WikiProject Source MetaData tooling, not by this pipeline.
    create = list(wikidata = FALSE, wikibase = TRUE),
    statements = list(
      wikidata_statement(
        "instance_of", "P31", "instance of",
        list(
          kind = "switch",
          field = "Venue",
          cases = list(preprint = WIKIDATA_ITEMS$preprint),
          default = WIKIDATA_ITEMS$scholarly_article
        ),
        required = TRUE,
        note = paste(
          "the register's `preprint` venue is the codechecker stating that the",
          "checked work is a preprint, which is a fact about the paper rather",
          "than about a venue - unlike the publication itself, which is read",
          "from the paper's own record. A Crossref type of `posted-content`",
          "corroborates it"
        )
      ),
      wikidata_statement(
        "doi", "P356", "DOI",
        list(kind = "field", field = "Paper reference", transform = "doi"),
        required = TRUE
      ),
      wikidata_statement(
        "title", "P1476", "title",
        list(kind = "field", field = "Title")
      ),
      wikidata_statement(
        "published_in", "P1433", "published in",
        list(kind = "entity", entity = "venue", field = "Paper reference"),
        note = paste(
          "the publication the checked article appeared in, resolved from the",
          "paper's own record rather than from the register's Venue column. A",
          "register venue names the conference or journal as an institution,",
          "and that is not the same thing as the publication: AGILE papers",
          "appear in AGILE: GIScience Series (Q126264390) today but earlier",
          "years of the same conference were published in Springer LNCS",
          "(Q924044), so a venue-derived value would be wrong for the older",
          "ones. Papers without a publication ISSN - preprints, reports -",
          "simply get no statement"
        )
      )
    )
  ),

  person = list(
    label = "{{name}}",
    description = NULL,
    resolve = list(property = "P496", field = "orcid", transform = "orcid", endpoint = "main"),
    create = list(wikidata = FALSE, wikibase = TRUE),
    statements = list(
      wikidata_statement(
        "instance_of", "P31", "instance of",
        list(kind = "constant", item = WIKIDATA_ITEMS$human),
        required = TRUE
      ),
      wikidata_statement(
        "orcid", "P496", "ORCID iD",
        list(kind = "field", field = "orcid", transform = "orcid"),
        required = TRUE
      )
    )
  ),

  venue = list(
    label = "{{longname}}",
    description = NULL,
    # Resolved by the ISSN of the publication a paper actually appeared in,
    # taken from the paper's own record, not by the register's venue name: one
    # register venue can span several publications over the years, and a
    # conference is not a publication at all. venues.csv identifiers (ISSN,
    # ROR) are a cross-check for the venues the register itself shows, not the
    # authority for what a given paper was published in.
    resolve = list(
      property = "P236",
      field = "issn",
      transform = "issn",
      endpoint = "main"
    ),
    create = list(wikidata = FALSE, wikibase = TRUE),
    statements = list(
      wikidata_statement(
        "issn", "P236", "ISSN",
        list(kind = "field", field = "identifiers", transform = "issn")
      ),
      wikidata_statement(
        "official_website", "P856", "official website",
        list(kind = "field", field = "website_url")
      )
    )
  )
)

#' The CODECHECK Wikidata model
#'
#' The description of how a CODECHECK certificate, and the paper, person and
#' venue it refers to, are represented as linked data. Exported so the model can
#' be inspected and reviewed on its own, without running an export.
#'
#' @return the model, a named list of entity kinds; see [WIKIDATA_MODEL] for the
#'   structure
#' @examples
#' names(wikidata_model())
#' vapply(wikidata_model()$certificate$statements, function(s) s$property, character(1))
#' @export
wikidata_model <- function() {
  WIKIDATA_MODEL
}

#' The entity kinds of the model
#'
#' @return a character vector, e.g. `c("certificate", "paper", ...)`
#' @export
wikidata_entity_kinds <- function() {
  names(WIKIDATA_MODEL)
}

#' The statement definitions of one entity kind
#'
#' @param kind one of [wikidata_entity_kinds()]
#' @return a list of statement definitions
#' @export
wikidata_statements <- function(kind) {
  if (!kind %in% names(WIKIDATA_MODEL)) {
    stop("Unknown entity kind: ", kind, ". Known kinds: ",
         paste(names(WIKIDATA_MODEL), collapse = ", "))
  }
  WIKIDATA_MODEL[[kind]]$statements
}

#' Every property the model uses, as a flat table
#'
#' The list a reviewer wants to see, and the input the CODECHECK Wikibase
#' bootstrap needs: it creates one local property per row and records the
#' Wikidata counterpart on it.
#'
#' @return a `data.frame` with columns `entity`, `key`, `property`, `label`,
#'   `value_kind`, `required` and `note`, one row per statement definition
#' @examples
#' wikidata_properties()[, c("entity", "property", "label")]
#' @export
wikidata_properties <- function() {
  rows <- lapply(names(WIKIDATA_MODEL), function(kind) {
    statements <- WIKIDATA_MODEL[[kind]]$statements
    data.frame(
      entity = rep(kind, length(statements)),
      key = vapply(statements, function(s) s$key, character(1)),
      property = vapply(statements, function(s) s$property, character(1)),
      label = vapply(statements, function(s) s$label, character(1)),
      value_kind = vapply(statements, function(s) s$value$kind, character(1)),
      required = vapply(statements, function(s) isTRUE(s$required), logical(1)),
      note = vapply(statements, function(s) if (is.null(s$note)) NA_character_ else s$note, character(1)),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' The SPARQL endpoint serving a kind of entity
#'
#' @param kind one of [wikidata_entity_kinds()]
#' @param target `"wikidata"` (the default) or `"wikibase"`; the CODECHECK
#'   Wikibase is unsplit, so every kind is served by the same endpoint there
#' @return the endpoint URL
#' @examples
#' wikidata_endpoint("paper")
#' wikidata_endpoint("person")
#' @export
wikidata_endpoint <- function(kind, target = c("wikidata", "wikibase")) {
  target <- match.arg(target)
  if (target == "wikibase") {
    return(WIKIDATA_ENDPOINTS$wikibase)
  }
  if (!kind %in% names(WIKIDATA_MODEL)) {
    stop("Unknown entity kind: ", kind, ". Known kinds: ",
         paste(names(WIKIDATA_MODEL), collapse = ", "))
  }
  WIKIDATA_ENDPOINTS[[WIKIDATA_MODEL[[kind]]$resolve$endpoint]]
}

#' Whether the export may create this kind of entity on a target
#'
#' Only certificates are created on Wikidata: the papers, people and venues they
#' refer to are resolved there and created by the communities that own them. Our
#' own Wikibase mirrors everything, since it has no notability rules to respect.
#'
#' @param kind one of [wikidata_entity_kinds()]
#' @param target `"wikidata"` or `"wikibase"`
#' @return `TRUE` if the export may create such an item on that target
#' @examples
#' wikidata_creates("certificate", "wikidata")
#' wikidata_creates("paper", "wikidata")
#' @export
wikidata_creates <- function(kind, target = c("wikidata", "wikibase")) {
  target <- match.arg(target)
  if (!kind %in% names(WIKIDATA_MODEL)) {
    stop("Unknown entity kind: ", kind, ". Known kinds: ",
         paste(names(WIKIDATA_MODEL), collapse = ", "))
  }
  isTRUE(WIKIDATA_MODEL[[kind]]$create[[target]])
}

#' Whether a value is a well-formed constant
#'
#' A constant names an item, unless it is marked `pending`: the item does not
#' exist yet, and no export emits a statement that depends on it. The marker is
#' deliberate - a model that quietly dropped such a statement would hide the
#' fact that something still has to be created.
#'
#' @param value a statement or qualifier value definition
#' @param at a prefix describing where the value sits, for the message
#' @return a character vector of problems, empty when the value is fine
#' @keywords internal
check_constant_value <- function(value, at) {
  if (!identical(value$kind, "constant")) {
    return(character(0))
  }
  if (!is.null(value$pending)) {
    if (!is.character(value$pending) || !nzchar(value$pending)) {
      return(paste0(at, "pending marker must say what is still missing"))
    }
    return(character(0))
  }
  item <- value$item
  if (is.null(item) || is.na(item) || !grepl("^Q[0-9]+$", item)) {
    return(paste0(at, "constant value is not an item id"))
  }
  character(0)
}

#' The statements waiting on an item that does not exist yet
#'
#' Emitters skip these, so this is the list of things still to create before the
#' export is complete. Currently the interim `P528` catalog code, which needs an
#' item for the register itself.
#'
#' @return a `data.frame` with columns `entity`, `key`, `property` and `pending`
#' @examples
#' wikidata_pending()
#' @export
wikidata_pending <- function() {
  rows <- list()
  for (kind in names(WIKIDATA_MODEL)) {
    for (statement in WIKIDATA_MODEL[[kind]]$statements) {
      values <- c(list(statement$value), lapply(statement$qualifiers, function(q) q$value))
      pending <- Filter(Negate(is.null), lapply(values, function(v) v$pending))
      for (reason in pending) {
        rows[[length(rows) + 1]] <- data.frame(
          entity = kind, key = statement$key, property = statement$property,
          pending = reason, stringsAsFactors = FALSE
        )
      }
    }
  }
  if (length(rows) == 0) {
    return(data.frame(entity = character(0), key = character(0),
                      property = character(0), pending = character(0),
                      stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Check the model's invariants
#'
#' Run by the tests, and worth running after any edit to [WIKIDATA_MODEL]: the
#' model is data, so a typo in it is not a syntax error anywhere and would first
#' show up as a wrong statement on a public Wikidata item.
#'
#' @param model the model to check, the package's own by default
#' @return `TRUE` invisibly if the model is consistent; otherwise a character
#'   vector of the problems found
#' @examples
#' validate_wikidata_model()
#' @export
validate_wikidata_model <- function(model = WIKIDATA_MODEL) {
  problems <- character(0)
  known_value_kinds <- c("constant", "field", "entity", "render_date", "switch", "mapped")
  known_maps <- c("platforms")

  for (kind in names(model)) {
    entity <- model[[kind]]
    where <- paste0(kind, ": ")

    if (is.null(entity$resolve$property) || is.null(entity$resolve$endpoint)) {
      problems <- c(problems, paste0(where, "resolve needs both a property and an endpoint"))
    } else if (!entity$resolve$endpoint %in% names(WIKIDATA_ENDPOINTS)) {
      problems <- c(problems, paste0(where, "unknown endpoint '", entity$resolve$endpoint, "'"))
    }

    if (!all(c("wikidata", "wikibase") %in% names(entity$create))) {
      problems <- c(problems, paste0(where, "create must name both targets"))
    }

    keys <- vapply(entity$statements, function(s) s$key, character(1))
    if (anyDuplicated(keys) > 0) {
      problems <- c(problems, paste0(where, "duplicate statement key(s): ",
                                     paste(unique(keys[duplicated(keys)]), collapse = ", ")))
    }

    for (statement in entity$statements) {
      at <- paste0(where, statement$key, ": ")
      if (!grepl("^P[0-9]+$", statement$property)) {
        problems <- c(problems, paste0(at, "'", statement$property, "' is not a property id"))
      }
      if (!statement$value$kind %in% known_value_kinds) {
        problems <- c(problems, paste0(at, "unknown value kind '", statement$value$kind, "'"))
      }
      problems <- c(problems, check_constant_value(statement$value, at))

      for (qualifier in statement$qualifiers) {
        qual_at <- paste0(at, "qualifier ", qualifier$property, ": ")
        if (!grepl("^P[0-9]+$", qualifier$property)) {
          problems <- c(problems, paste0(qual_at, "not a property id"))
        }
        if (!qualifier$value$kind %in% known_value_kinds) {
          problems <- c(problems, paste0(qual_at, "unknown value kind '", qualifier$value$kind, "'"))
        }
        problems <- c(problems, check_constant_value(qualifier$value, qual_at))
      }

      # A catalog code says nothing without naming its catalog, and Wikidata's
      # own distinctness check on P528 is evaluated per P972 value.
      if (statement$property == "P528") {
        qualifier_properties <- vapply(statement$qualifiers, function(q) q$property, character(1))
        if (!"P972" %in% qualifier_properties) {
          problems <- c(problems, paste0(at, "P528 needs a P972 catalog qualifier"))
        }
      }
      if (statement$value$kind == "field" && is.null(statement$value$field)) {
        problems <- c(problems, paste0(at, "field value without a field"))
      }
      if (statement$value$kind == "switch") {
        if (is.null(statement$value$field)) {
          problems <- c(problems, paste0(at, "switch value without a field"))
        }
        items <- c(unlist(statement$value$cases), statement$value$default)
        if (length(items) == 0 || !all(grepl("^Q[0-9]+$", items))) {
          problems <- c(problems, paste0(at, "switch cases and default must all be item ids"))
        }
      }
      if (statement$value$kind == "mapped") {
        if (is.null(statement$value$field)) {
          problems <- c(problems, paste0(at, "mapped value without a field"))
        }
        if (is.null(statement$value$map) || !statement$value$map %in% known_maps) {
          problems <- c(problems, paste0(at, "mapped value names no known map"))
        }
      }
      if (statement$value$kind == "entity") {
        if (is.null(statement$value$entity)) {
          problems <- c(problems, paste0(at, "entity value without an entity"))
        } else if (!statement$value$entity %in% names(model)) {
          problems <- c(problems, paste0(at, "reference to unknown entity kind '",
                                         statement$value$entity, "'"))
        }
      }
    }
  }

  # The two decisions this model exists to record, asserted rather than assumed:
  # a certificate that loses either of them is in the wrong graph, or its
  # relation to the checked paper is no longer expressible.
  certificate_properties <- vapply(model$certificate$statements,
                                   function(s) s$property, character(1))
  if (!"P13046" %in% certificate_properties) {
    problems <- c(problems, "certificate: P13046 is missing, the item would land in the main graph")
  }
  if (!"P6977" %in% certificate_properties) {
    problems <- c(problems, "certificate: P6977 is missing, the checked paper would not be linked")
  }
  if ("P2860" %in% certificate_properties) {
    problems <- c(problems, "certificate: P2860 cannot express which cited work was checked, use P6977")
  }

  # Both venues have to survive: where the certificate itself was published, and
  # where the paper it checks appeared. They are different facts on different
  # items, and an export that keeps only one of them loses information the
  # register has.
  certificate_venue <- Filter(function(s) s$property == "P1433", model$certificate$statements)
  if (length(certificate_venue) != 1 || !identical(certificate_venue[[1]]$value$kind, "mapped")) {
    problems <- c(problems, "certificate: P1433 must carry the platform the certificate is published on")
  }
  paper_venue <- Filter(function(s) s$property == "P1433", model$paper$statements)
  if (length(paper_venue) != 1 || !identical(paper_venue[[1]]$value$entity, "venue")) {
    problems <- c(problems, "paper: P1433 must carry the venue of the checked article")
  }

  if (length(problems) > 0) {
    return(problems)
  }
  invisible(TRUE)
}
