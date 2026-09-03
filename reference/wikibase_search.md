# Look an entity up by its label

The fallback for when resolution by identifier finds nothing: a paper
without a DOI, a venue without an ISSN, a person without an ORCID.
Deliberately not the primary route - a label match is a guess, an
identifier match is not - so callers are expected to confirm what comes
back.

## Usage

``` r
wikibase_search(text, type = c("item", "property"), handle = NULL, limit = 5)
```

## Arguments

- text:

  the label or alias to search for

- type:

  \`"item"\` or \`"property"\`

- handle:

  an optional \`httr\` handle

- limit:

  how many matches to return

## Value

a \`data.frame\` with columns \`id\`, \`label\` and \`description\`,
best match first, empty when nothing matched
