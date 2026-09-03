# Bring an entity that already exists back in line with the model

The instance is generated, so a label or description that no longer
matches the model is drift, not somebody's edit to preserve. Only what
differs is written: an unchanged entity costs no edit at all, which is
what makes running the bootstrap again cheap enough to do routinely.

## Usage

``` r
reconcile_wikibase_entity(session, row, existing)
```

## Arguments

- session:

  a session from \[wikibase_session()\]

- row:

  one row of the plan, with \`local_id\` filled in

- existing:

  the mapping from \[wikibase_mapping()\]

## Value

\`TRUE\` if an edit was made
