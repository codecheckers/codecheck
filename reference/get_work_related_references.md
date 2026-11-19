# The other references of a work, with their types, for a work page

The other references of a work, with their types, for a work page

## Usage

``` r
get_work_related_references(doi)
```

## Arguments

- doi:

  The work page's DOI

## Value

A list of lists, one per row of the work's relations in
\`CONFIG\$WORK_RELATIONS\` (see \[add_work_key()\]): \`url\`, \`doi\`
(\`NA\` for a web address), \`is_reference\`, \`type\` and \`agency\`;
empty when the work has no other references
