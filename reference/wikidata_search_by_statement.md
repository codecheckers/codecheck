# Find items by a statement they carry, through the search index

The query service is not the right tool immediately after a batch has
run: its updater can be hours behind, and the scholarly endpoint is the
slower of the two, so a work created ten minutes ago is invisible there
and would be created a second time. The Action API's \`haswbstatement\`
search indexes the same fact within minutes and does not care which
graph an item ended up in.

## Usage

``` r
wikidata_search_by_statement(property, values, size = 20)
```

## Arguments

- property:

  the Wikidata property to match on, e.g. \`"P356"\`

- values:

  the identifier values

- size:

  how many values to put in one search

## Value

a named character vector, value to QID, holding only what exists

## Details

Values are searched in batches - \`haswbstatement\` ORs them with
\`\|\` - and the matches are then read back with \`wbgetentities\`,
since a search result says which items matched but not which value each
one matched on.
