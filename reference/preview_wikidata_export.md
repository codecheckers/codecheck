# Preview the export to Wikidata

Resolves every checked work and certificate against Wikidata, works out
what exists and what would be created, and writes the QuickStatements
batches a person would paste in. Nothing is sent: Wikidata is written by
hand, and this is what makes that hand-work reviewable beforehand.

## Usage

``` r
preview_wikidata_export(
  dir = "../register",
  out_dir = ".",
  log_file = NULL,
  records = NULL,
  publish = FALSE,
  method = c("search", "sparql"),
  force = FALSE
)
```

## Arguments

- dir:

  the register repository to read from

- out_dir:

  where to write the \`.qs\` batches

- log_file:

  where to append the edit log, or \`NULL\` for the option

- records:

  already-read records, as from \[read_register_records()\]

- publish:

  also write the preview onto the CODECHECK Wikibase, as
  \`Project:Wikidata export\`; needs
  \`WIKIBASE_USER\`/\`WIKIBASE_TOKEN\`

- method:

  how to resolve against Wikidata: \`"search"\` (the default) asks the
  Action API, which indexes a new item within minutes and sees every
  graph; \`"sparql"\` asks the query service, which is hours behind and
  only sees the graph the entity kind is served from

- force:

  write a batch of creates even when the log says a batch of the same
  name was already submitted - see \[wikidata_batch_conflict()\]

## Value

a \`data.frame\` with one row per entity, invisibly, saying whether it
exists on Wikidata and how many commands it contributes

## Details

Two batches, in order. The checked works come first, because
QuickStatements can only refer to an item it just created as \`LAST\`,
so a certificate can only name a work that already has a QID. After the
works batch has run, generate the preview again: the works then resolve,
and the certificates get their \`review of\` statements.

## Examples

``` r
if (FALSE) { # \dontrun{
preview_wikidata_export("../register")
} # }
```
