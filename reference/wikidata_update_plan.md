# Plan the additions to items that already exist on Wikidata

Plan the additions to items that already exist on Wikidata

## Usage

``` r
wikidata_update_plan(
  records,
  method = c("search", "sparql"),
  origin = TRUE,
  log_file = NULL
)
```

## Arguments

- records:

  the output of \[read_register_records()\]

- method:

  how to resolve against Wikidata, see \[preview_wikidata_export()\]

- origin:

  whether to look up who created each item, one request per item

- log_file:

  the edit log, to recognise the export's own batches

## Value

a \`data.frame\` with one row per statement the model would add or that
differs: \`kind\`, \`key\`, \`item\`, \`origin\`, \`created_by\`,
\`property\`, \`proposed\`, \`current\`, \`action\` and \`command\`
