# Split identifiers into SPARQL \`VALUES\` blocks

Resolution asks "which of these DOIs already has an item", and the way
to ask that is one query per batch of identifiers, not one query per
identifier: 132 certificates would otherwise be 132 round trips against
a query service that rate limits, which is the mistake the archived
\`WikidataR\` makes.

## Usage

``` r
wikibase_values_chunks(values, size = 50, quote = TRUE)
```

## Arguments

- values:

  the identifiers

- size:

  how many to put in one query

- quote:

  whether to render each value as a SPARQL string literal

## Value

a character vector of \`VALUES\` bodies, one per query to run
