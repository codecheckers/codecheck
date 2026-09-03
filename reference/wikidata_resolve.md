# Which of these identifiers already have items on Wikidata

Batched with \`VALUES\`: one query per 60 identifiers rather than one
per identifier, and against the endpoint that actually serves the kind -
the query service was split in 2025 and asking the wrong one returns no
match rather than an error.

## Usage

``` r
wikidata_resolve(kind, keys, method = c("search", "sparql"))
```

## Arguments

- kind:

  an entity kind from \[wikidata_entity_kinds()\]

- keys:

  the identifier values, as the model's resolve transform produces

## Value

a named character vector, identifier to QID, holding only what exists
