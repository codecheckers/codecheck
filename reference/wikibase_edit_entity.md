# Create or update one entity through wbeditentity

\`new=\` mints an entity, \`id=\` edits the one named - the same call,
and the difference between a rerun that converges and a rerun that
duplicates. Every edit carries a summary, so the instance's history says
why it changed rather than only that it did.

## Usage

``` r
wikibase_edit_entity(
  session,
  data,
  kind = NULL,
  id = NULL,
  summary = NULL,
  what = "an entity",
  clear = FALSE
)
```

## Arguments

- session:

  a session from \[wikibase_session()\]

- data:

  the entity data to write

- kind:

  \`"item"\` or \`"property"\` when creating, \`NULL\` when updating

- id:

  the entity to update, \`NULL\` when creating

- summary:

  the edit summary

- what:

  what is being written, for the error message

- clear:

  when updating, replace the entity's content instead of merging into it

## Value

the parsed response
