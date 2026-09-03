# Which entities the instance already holds, by identifier

The counterpart of \[wikibase_mapping()\] for the data: an item is found
by the identifier the model resolves it on - a DOI, an ORCID, an ISSN -
because that is the only thing about it that cannot change. Built once
from the Action API rather than queried per entity, and updated in
memory as entities are created, so the query service's lag behind a
write cannot cause a duplicate.

## Usage

``` r
wikibase_identifier_index(local, handle = NULL)
```

## Arguments

- local:

  a named vector mapping Wikidata property ids to local ones

- handle:

  an optional \`httr\` handle

## Value

a named character vector, \`"\<property\>=\<value\>"\` to local id
