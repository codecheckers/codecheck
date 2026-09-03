# Whether the export may create this kind of entity on a target

Only certificates are created on Wikidata: the papers, people and venues
they refer to are resolved there and created by the communities that own
them. Our own Wikibase mirrors everything, since it has no notability
rules to respect.

## Usage

``` r
wikidata_creates(kind, target = c("wikidata", "wikibase"))
```

## Arguments

- kind:

  one of \[wikidata_entity_kinds()\]

- target:

  \`"wikidata"\` or \`"wikibase"\`

## Value

\`TRUE\` if the export may create such an item on that target

## Examples

``` r
wikidata_creates("certificate", "wikidata")
#> [1] TRUE
wikidata_creates("paper", "wikidata")
#> [1] TRUE
```
