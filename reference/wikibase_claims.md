# The statements one entity kind contributes for one row

Every statement carries the reference block from the model, which is
what distinguishes a statement this pipeline wrote from one somebody
added by hand.

## Usage

``` r
wikibase_claims(kind, row, local, resolve = NULL)
```

## Arguments

- kind:

  an entity kind from \[wikidata_entity_kinds()\]

- row:

  the register row

- local:

  a named vector mapping Wikidata property ids to local ones

- resolve:

  a function \`(entity_kind, key) -\> local id\`

## Value

a list of claims for \`wbeditentity\`
