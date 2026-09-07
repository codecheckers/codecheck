tinytest::using(ttdo)

source("mocks.R")

# The certificates are on Wikidata, so most of the examples page is Wikidata
# queries; the instance's own section covers what Wikidata cannot answer. Both
# ways of getting an instance query wrong - the local numbering and the prefixes
# bound to Wikidata - fail with an empty table rather than an error, which is
# what these tests exist to keep from happening.

empty <- data.frame(local_id = character(0), wikidata_id = character(0),
                    label = character(0), stringsAsFactors = FALSE)
plan <- codecheck:::plan_wikibase_entities(empty)
plan$local_id <- paste0(ifelse(plan$kind == "property", "P", "Q"), seq_len(nrow(plan)))
ids <- codecheck:::wikibase_local_ids(plan)

# The Wikidata examples ----

# They are written with Wikidata's own ids, so nothing in them is substituted
# and nothing depends on this instance existing.
for (example in codecheck:::WIKIDATA_QUERY_EXAMPLES) {
  query <- paste(example$query, collapse = "\n")
  expect_false(grepl("{{", query, fixed = TRUE), info = example$title)
  expect_true(nchar(example$title) > 0)
  expect_true(nchar(example$why) > 0)
  # The graph a query is sent to is part of the example: the wrong half of the
  # split answers with an empty table.
  expect_true(example$endpoint %in% names(codecheck:::WIKIDATA_ENDPOINTS), info = example$title)
  expect_true(grepl("wdt:P13046 wd:Q116740071", query, fixed = TRUE) ||
                grepl("wdt:P528", query, fixed = TRUE), info = example$title)
}
expect_true(length(codecheck:::WIKIDATA_QUERY_EXAMPLES) > length(codecheck:::WIKIBASE_QUERY_EXAMPLES))

# The instance examples ----

# A placeholder naming an entity the bootstrap does not create would render as
# a query that silently returns nothing, so it is an error here instead.
for (example in codecheck:::WIKIBASE_QUERY_EXAMPLES) {
  rendered <- paste(codecheck:::render_wikibase_query(example$query, ids), collapse = "\n")
  expect_false(grepl("{{", rendered, fixed = TRUE), info = example$title)
  expect_true(nchar(example$why) > 0)
}

# The substituted ids are this instance's, not Wikidata's - the whole reason
# these queries are generated rather than written out.
rendered <- paste(codecheck:::render_wikibase_query(
  codecheck:::WIKIBASE_QUERY_EXAMPLES[[1]]$query, ids), collapse = "\n")
expect_true(grepl(paste0("wd:", ids[codecheck:::WIKIDATA_ITEMS$reproducibility_report]),
                  rendered, fixed = TRUE))
expect_false(grepl("wd:Q116740071", rendered, fixed = TRUE))

expect_error(codecheck:::render_wikibase_query("?x wdt:{{P99999}} ?y", ids),
             "P99999")

# Comments line up after substitution ----

# A placeholder is longer than the id it becomes, so comments written straight
# in the model come out ragged: they are the labels that make an unfamiliar
# property number readable.
aligned <- codecheck:::align_wikibase_query_comments(
  c("SELECT ?x WHERE {", "  ?a b c ; # one", "         d e . # two", "}")
)
expect_equal(regexpr("#", aligned[2], fixed = TRUE),
             regexpr("#", aligned[3], fixed = TRUE))
expect_equal(aligned[c(1, 4)], c("SELECT ?x WHERE {", "}"))

# A hash inside a string literal is part of the query, not a comment.
literal <- "  FILTER(CONTAINS(STR(?url), \"#fragment\")) # a real comment"
expect_true(grepl("\"#fragment\"", codecheck:::align_wikibase_query_comments(literal), fixed = TRUE))
expect_true(endsWith(codecheck:::align_wikibase_query_comments(literal), "# a real comment"))

# Run links point at the endpoint the query is for ----

expect_true(startsWith(codecheck:::wikibase_query_url("SELECT * {}", "scholarly"),
                       "https://query-scholarly.wikidata.org/#"))
expect_true(startsWith(codecheck:::wikibase_query_url("SELECT * {}", "main"),
                       "https://query.wikidata.org/#"))
expect_true(startsWith(codecheck:::wikibase_query_url("SELECT * {}"),
                       "https://codecheck.wikibase.cloud/query/#"))

# The page ----

page <- codecheck:::wikibase_examples_wikitext(
  plan, generated_at = as.POSIXct("2026-09-07 12:00:00", tz = "UTC")
)
text <- paste(page, collapse = "\n")

expect_true(grepl("bootstrap_wikibase()", text, fixed = TRUE))
expect_true(grepl("2026-09-07 12:00:00", text, fixed = TRUE))
# The intro says which endpoint the reader is being sent to, and why there is a
# second section at all.
expect_true(grepl("run against Wikidata, not against this instance", text, fixed = TRUE))
expect_true(grepl("query-scholarly.wikidata.org", text, fixed = TRUE))
expect_true(grepl("== Queries on Wikidata ==", text, fixed = TRUE))
expect_true(grepl("== Queries on this instance ==", text, fixed = TRUE))

examples <- c(codecheck:::WIKIDATA_QUERY_EXAMPLES, codecheck:::WIKIBASE_QUERY_EXAMPLES)
# One highlighted block and one run link per example.
expect_equal(length(gregexpr("<syntaxhighlight lang=\"sparql\">", text, fixed = TRUE)[[1]]),
             length(examples))
expect_equal(length(gregexpr(" Run this query]", text, fixed = TRUE)[[1]]),
             length(examples))
for (example in examples) {
  expect_true(grepl(paste0("=== ", example$title, " ==="), text, fixed = TRUE))
}

# Only the instance queries carry prefixes: a Wikidata query needs none, and an
# instance query without them resolves wdt: against Wikidata and answers with an
# empty table.
expect_equal(length(gregexpr("PREFIX wdt: <https://codecheck.wikibase.cloud/prop/direct/>",
                             text, fixed = TRUE)[[1]]),
             length(codecheck:::WIKIBASE_QUERY_EXAMPLES))
wikidata_section <- strsplit(text, "== Queries on this instance ==", fixed = TRUE)[[1]][1]
expect_false(grepl("PREFIX", wikidata_section, fixed = TRUE))
expect_true(grepl("[[Project:Data model]]", text, fixed = TRUE))

# The run links open the query that is shown, not another one.
links <- regmatches(text, gregexpr("https://[^ ]+/#[^ ]+", text))[[1]]
expect_equal(length(links), length(examples))
expect_true(all(grepl("SELECT", vapply(links, utils::URLdecode, character(1)), fixed = TRUE)))
expect_true(sum(startsWith(links, "https://query-scholarly.wikidata.org/#")) ==
              length(codecheck:::WIKIDATA_QUERY_EXAMPLES))
expect_true(sum(startsWith(links, "https://codecheck.wikibase.cloud/query/#")) ==
              length(codecheck:::WIKIBASE_QUERY_EXAMPLES))

# A leading space is preformatted text in MediaWiki - except inside the
# highlighted blocks, where the queries are indented on purpose.
in_query <- cumsum(grepl("^<syntaxhighlight", page)) > cumsum(grepl("^</syntaxhighlight>", page))
expect_false(any(grepl("^[ \t]", page[!in_query])))

# Writing it ----

sent <- list()
with_mocked_codecheck(list(wikibase_post = function(session, params, what) {
  sent[[length(sent) + 1L]] <<- params
  list(edit = list(result = "Success"))
}), {
  written <- codecheck:::write_wikibase_examples_page(NULL, plan)
})
expect_equal(length(sent), 1L)
expect_equal(sent[[1]]$title, "Project:Example queries")
expect_equal(sent[[1]]$action, "edit")
expect_equal(sent[[1]]$bot, 1)
expect_equal(written, "Project:Example queries")
