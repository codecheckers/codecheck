# Creates filtered CSV files from a register based on specified filters.

The function processes the preprocessed register table by applying
filters specified in \`filter_by\`. For "codecheckers", a temporary CSV
is loaded and processed as the original register.csv does not have the
codechecker column. The register is then grouped by the filter column,
and for each group, a CSV file is generated. CSV files include all
fields that JSON files have (Repository Link, Title, Paper reference).

## Usage

``` r
create_filtered_reg_csvs(register_table, filter_by)
```

## Arguments

- register_table:

  The preprocessed register table with enriched columns.

- filter_by:

  List of filters to apply (e.g., "venues", "codecheckers").
