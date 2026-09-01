# Add the \`Work\` grouping column to the register table

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

The register table with a \`Work\` column added
