# The certificates and checked works the instance holds, as the load reports them

What \[load_wikibase_register()\] returns about the entities it wrote,
rebuilt from the instance itself, so the certificate index can be
written without loading anything.

## Usage

``` r
wikibase_loaded_entities(records, mapping, handle = NULL)
```

## Arguments

- records:

  the output of \[read_register_records()\]

- mapping:

  the output of \[wikibase_mapping()\]

- handle:

  an optional \`httr\` handle

## Value

a \`data.frame\` with columns \`kind\`, \`key\`, \`action\` and \`id\`,
one row per paper and certificate found on the instance
