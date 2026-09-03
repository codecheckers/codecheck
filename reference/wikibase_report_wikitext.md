# The wiki page listing everything the bootstrap created

The instance is disposable and its P- and Q-numbers are minted locally,
so the only readable index of what it holds is one this writes: which
local entity stands for which Wikidata property or item, in one page a
reviewer can open without querying the API. Generated, and overwritten
by every run.

## Usage

``` r
wikibase_report_wikitext(plan, generated_at = Sys.time())
```

## Arguments

- plan:

  a plan from \[plan_wikibase_entities()\] with \`local_id\` filled in

- generated_at:

  the timestamp to stamp the page with

## Value

the page's wikitext
