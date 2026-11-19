# Add the \`Work\` grouping columns to the register table

One row per certificate, so the same DOI checked by several certificates
repeats the same key - \`create_register_files()\`'s existing group-by
machinery then puts them on one work page automatically.

## Usage

``` r
add_work_key(register_table, register)
```

## Arguments

- register_table:

  The register table

- register:

  The register from register.csv

## Value

The register table with \`Work\` and \`Work other\` columns added

## Details

The certificate's further references (\`paper.reference-other\`, see
\[get_reference_other()\]) go into the \`Work other\` list column, each
DOI with its own OpenAlex ID and publication date (see
\[get_other_reference_fields()\]), so that \[explode_work_records()\]
can list the certificate on those DOIs' work pages too. Which work pages
are one work is stored in \`CONFIG\$WORK_RELATIONS\` (see
\[build_work_relations()\]), for the pages of certificates and works to
link to each other, with the type of each related DOI (see
\[add_reference_types()\]).
