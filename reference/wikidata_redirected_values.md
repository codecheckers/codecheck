# The OpenAlex IDs on each existing work that OpenAlex merged into its record

An ID that now redirects to the record the export writes is not wrong,
it is out of date: the convention on Wikidata keeps such an identifier
with deprecated rank and the reason "redirect" (P2241 = Q45403344),
rather than removing it (2025-019: W4415061882, merged into
W4411175514).

## Usage

``` r
wikidata_redirected_values(existing, claims)
```

## Arguments

- existing:

  the existing items, each a list with \`kind\`, \`item\` and \`row\`

- claims:

  their claims, see \[wikidata_item_claims()\]

## Value

a list parallel to \`existing\`, each a named list of property to
values, as \`wikidata_rejected_values()\` returns them
