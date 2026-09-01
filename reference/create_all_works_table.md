# Create the "all works" overview table (docs/works/index.html)

Mirrors \[create_all_codecheckers_table()\]: one row per distinct
DOI-keyed work, with its title and its check count. A certificate with
no DOI (see \[normalize_work_key()\]) simply has no work and contributes
no row here, per \#150.

## Usage

``` r
create_all_works_table(register_table)
```

## Arguments

- register_table:

  The register table, with a \`Work\` column.

## Value

A list with a single element, the works table.
