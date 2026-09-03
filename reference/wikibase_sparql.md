# Run a SPARQL query against Wikidata or the CODECHECK Wikibase

Run a SPARQL query against Wikidata or the CODECHECK Wikibase

## Usage

``` r
wikibase_sparql(query, endpoint = c("wikibase", "main", "scholarly"))
```

## Arguments

- query:

  the query text

- endpoint:

  one of \[WIKIDATA_ENDPOINTS\], by name

## Value

a \`data.frame\` of the bindings, one column per selected variable
