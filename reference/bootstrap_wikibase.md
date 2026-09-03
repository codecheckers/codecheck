# Build the CODECHECK Wikibase from the model

Creates the instance's own properties and class items, one per entry of
the model in \`R/wikidata.R\`, each carrying a "Wikidata entity"
statement naming its Wikidata counterpart. Idempotent: what already
exists is left alone, so the instance can be rebuilt from empty and a
partially failed run can simply be repeated.

## Usage

``` r
bootstrap_wikibase(dry_run = TRUE, log_file = NULL)
```

## Arguments

- dry_run:

  if \`TRUE\` (the default) report what would be created without writing
  anything

- log_file:

  where to append the edit log, or \`NULL\` for the
  \`codecheck.wikibase_log\` option (no log by default)

## Value

the plan, invisibly, with a \`local_id\` column filled in for the
entities that exist afterwards

## Details

Dry by default. A real run needs \`WIKIBASE_USER\` and
\`WIKIBASE_TOKEN\`; see the register's \`.env.example\`.

## Examples

``` r
if (FALSE) { # \dontrun{
bootstrap_wikibase()                 # what would be created
bootstrap_wikibase(dry_run = FALSE)  # create it
} # }
```
