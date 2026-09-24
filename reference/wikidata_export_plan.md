# Resolve the register against Wikidata

The part of \[preview_wikidata_export()\] that only reads: which checked
works and certificates exist on Wikidata, and the QuickStatements
commands that would create the rest. Shared with
\[publish_wikibase_pages()\], which needs the same answer without
writing any batch files.

## Usage

``` r
wikidata_export_plan(records, method = c("search", "sparql"))
```

## Arguments

- records:

  the output of \[read_register_records()\]

- method:

  how to resolve against Wikidata, see \[preview_wikidata_export()\]

## Value

a \`data.frame\` with one row per entity - \`kind\`, \`key\`,
\`wikidata\`, \`action\` and \`commands\` - with the batches attached as
\`"batches"\` and the resolved items as \`"known"\`
