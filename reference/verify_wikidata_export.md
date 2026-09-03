# Check what actually arrived on Wikidata

The step after a batch has run, and the one that proves the model's
central decision worked: a certificate and the work it reviews have to
be in the \*same\* graph of the split query service, or a query cannot
join them. The search index says whether an item exists; only SPARQL
says whether it is reachable from the graph its certificate lives in.

## Usage

``` r
verify_wikidata_export(
  dir = "../register",
  records = NULL,
  update_register = FALSE
)
```

## Arguments

- dir:

  the register repository to read from

- records:

  already-read records, as from \[read_register_records()\]

- update_register:

  whether to write the items found back into \`register.csv\`, see
  \[update_register_wikidata()\]. Off by default: this is a check, and
  editing the register is a separate decision.

## Value

a \`data.frame\` with one row per certificate, invisibly: its
certificate ID, its report DOI, its item if it has one, whether the
query service can see it, and the work it states \`review of\` on

## Details

Run it after the query service has caught up - hours rather than
minutes, and the scholarly endpoint is the slower of the two. An item
that exists but is not yet visible here is a lag, not a failure; the
same result days later is a failure.

## Examples

``` r
if (FALSE) { # \dontrun{
verify_wikidata_export("../register")
} # }
```
