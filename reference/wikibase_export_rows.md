# The rows each entity kind contributes, deduplicated

A person is one item however many certificates they checked, and a paper
one item however many times it was checked - so the register is turned
into one row per entity before anything is written, and the identifier
is what decides sameness.

## Usage

``` r
wikibase_export_rows(records)
```

## Arguments

- records:

  the output of \[read_register_records()\]

## Value

a named list of \`data.frame\`s, one per entity kind
