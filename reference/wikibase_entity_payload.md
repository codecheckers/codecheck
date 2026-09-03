# Everything wbeditentity needs for one entity

Everything wbeditentity needs for one entity

## Usage

``` r
wikibase_entity_payload(kind, row, local, resolve = NULL)
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

a list with \`labels\`, \`descriptions\` and \`claims\`
