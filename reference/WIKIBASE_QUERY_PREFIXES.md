# The prefixes an instance query declares

The query service answers with \`wd:\` and \`wdt:\` bound to Wikidata,
not to this instance, so a query that does not rebind them silently
returns nothing. Rebinding the familiar names rather than inventing new
ones keeps the queries recognisable to anybody who has written one
against Wikidata.

## Usage

``` r
WIKIBASE_QUERY_PREFIXES
```
