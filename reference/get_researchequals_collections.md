# Retrieve the collections a certificate must be part of

Retrieve the collections a CODECHECK certificate must be part of

## Usage

``` r
get_researchequals_collections(definitions = RESEARCHEQUALS_COLLECTIONS)
```

## Arguments

- definitions:

  list of collection definitions, each a list with \`name\`, \`id\`,
  \`issue_id\` and \`venues\`; defaults to
  \`RESEARCHEQUALS_COLLECTIONS\`

## Value

a named list of collection issues, the names being the collections'
short names, with the collection \`id\` kept as the attribute
\`collection_id\` on each element

## Details

Fetches every collection in \`definitions\`, by default the CODECHECK
collection,
\<https://researchequals.com/collections/720ac28c-07a1-40c3-a098-c77443e5de96\>,
which every certificate must be part of, and the Reproducible AGILE
collection,
\<https://researchequals.com/collections/aad8e6af-bd94-47f3-b215-c68d31687c74\>,
which only certificates for papers of the AGILEGIS venue must be part
of.

A collection that cannot be fetched is skipped with a warning rather
than aborting the whole audit: \[researchequals_policy_check()\] then
does not report on it, which is preferable to reporting every
certificate as missing from a collection that merely could not be read.

## Author

Daniel Nuest
