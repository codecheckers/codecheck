# Wikidata's Action API

Used to look an item up by a statement it carries. The search index
behind it picks up a new item within minutes, where the query service
can take hours - which matters because the export creates items and then
has to find them again before the next batch can refer to them.

## Usage

``` r
WIKIDATA_API
```
