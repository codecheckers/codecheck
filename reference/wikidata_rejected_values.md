# The values known to be wrong on each existing work

An OpenAlex ID is wrong for a work when its record has been deleted or
describes another DOI - OpenAlex merged the preprint into its published
version (see \[openalex_record_is_work()\]). That covers the ID the
register rejected (\`Rejected OpenAlex\`, see
\[read_register_records()\]) and any ID the item carries already, which
an earlier export may have taken from a record OpenAlex has since
deleted. The venue and the publication date of such a record are the
other work's too.

## Usage

``` r
wikidata_rejected_values(existing, claims, method = "search")
```

## Arguments

- existing:

  the existing items, each a list with \`kind\`, \`item\` and \`row\`

- claims:

  their claims, see \[wikidata_item_claims()\]

- method:

  how to resolve the venues, see \[preview_wikidata_export()\]

## Value

a list parallel to \`existing\`, each a named list of property to values
as \[wikidata_claim_key()\] gives them

## Details

Wrong is not the same as removed: \[wikidata_missing_statements()\] only
removes what the export wrote alone, and never a value the model writes,
so a date the preprint shares with the merged record stays.
