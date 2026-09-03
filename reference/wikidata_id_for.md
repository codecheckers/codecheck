# The Wikidata item for one entity, or \`NULL\`

\`NULL\` rather than \`NA\` so that the link builders drop the entry the
way they already drop every other absent link.

## Usage

``` r
wikidata_id_for(kind, key)
```

## Arguments

- kind:

  "certificate", "paper" or "person"

- key:

  the certificate ID, the work's DOI, or the person's ORCID

## Value

the QID, or \`NULL\` when the register does not know one
