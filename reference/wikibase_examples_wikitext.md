# The instance's example-queries page

The certificates are on Wikidata, so most of the page is Wikidata
queries: what a reader learns from them works anywhere, and nothing in
them depends on this instance. The instance's own section is short and
covers what Wikidata cannot answer, where two things a visitor cannot
guess have to be said: the local property numbers are not Wikidata's,
and the query service binds \`wdt:\` to Wikidata rather than to the
instance, so a query copied from Wikidata returns an empty table and no
error. Those queries are generated from the same plan that created the
entities, so their ids cannot drift from the instance.

## Usage

``` r
wikibase_examples_wikitext(plan, generated_at = Sys.time())
```

## Arguments

- plan:

  a plan from \[plan_wikibase_entities()\] with \`local_id\` filled in

- generated_at:

  the timestamp to stamp the page with

## Value

the page's wikitext
