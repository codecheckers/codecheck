# Curate all Zenodo records of a register

Curate all Zenodo records of a register against the curation policy

## Usage

``` r
curate_register_zenodo_records(
  register_table,
  zenodo = NULL,
  fields = c("title", "publisher", "language", "resource_type", "identifiers", "reviews",
    "repository"),
  dry_run = TRUE,
  register_dir = getwd()
)
```

## Arguments

- register_table:

  a register \`data.frame\` with columns \`Certificate\`, \`Report\` and
  \`Repository\`

- zenodo:

  a \`zen4R\` ZenodoManager, only needed when \`dry_run = FALSE\`

- fields:

  which classes of correction to consider, see
  \[curate_zenodo_record()\]

- dry_run:

  if TRUE (the default) only report what would change

- register_dir:

  directory holding \`register.csv\`

## Value

a data.frame with one row per record: \`certificate\`, \`record_id\`,
\`applied\` (the corrections), \`manual\` (findings needing a human),
\`error\`

## Details

Runs \[curate_zenodo_record()\] over every register entry whose report
is a Zenodo DOI. Intended for the mechanical corrections, whose target
values follow from the certificate ID or from \`codecheck.yml\`;
\`fields\` therefore defaults to everything except "creators", which
needs a human because splitting a name is wrong for group entries.

One record failing does not stop the run: its error is recorded in the
result and the loop continues.

## Author

Daniel Nuest
