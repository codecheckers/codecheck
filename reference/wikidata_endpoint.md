# The SPARQL endpoint serving a kind of entity

The SPARQL endpoint serving a kind of entity

## Usage

``` r
wikidata_endpoint(kind, target = c("wikidata", "wikibase"))
```

## Arguments

- kind:

  one of \[wikidata_entity_kinds()\]

- target:

  \`"wikidata"\` (the default) or \`"wikibase"\`; the CODECHECK Wikibase
  is unsplit, so every kind is served by the same endpoint there

## Value

the endpoint URL

## Examples

``` r
wikidata_endpoint("paper")
#> [1] "https://query-scholarly.wikidata.org/sparql"
wikidata_endpoint("person")
#> [1] "https://query.wikidata.org/sparql"
```
