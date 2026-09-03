# Every entity the instance holds, with its Wikidata counterpart

Read off the instance rather than from a local file: the instance is the
only authority on what it already contains, and a stale local mapping is
exactly how a bootstrap creates duplicates.

## Usage

``` r
wikibase_mapping(session = NULL)
```

## Arguments

- session:

  an optional session; the listing works unauthenticated

## Value

a \`data.frame\` with columns \`local_id\`, \`wikidata_id\` and
\`label\`, one row per entity that carries the mapping property (plus
the mapping property itself, whose \`wikidata_id\` is \`NA\`)
