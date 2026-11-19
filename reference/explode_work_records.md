# Explode the register table into one row per certificate and work

A certificate is listed on the work page of its \`reference\` and on the
work page of every DOI in its \`reference-other\`, with the \`Referenced
as\` column saying which. The OpenAlex ID and publication date of a row
for another reference are that DOI's own (see \[add_work_key()\]), not
those of the certificate's \`reference\`.

## Usage

``` r
explode_work_records(register_table)
```

## Arguments

- register_table:

  The register table, with \`Work\` and \`Work other\` columns (see
  \[add_work_key()\])

## Value

The register table, one row per certificate and work DOI, with a
\`Referenced as\` column; certificates without any DOI are left out
