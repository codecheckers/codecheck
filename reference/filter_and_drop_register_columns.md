# Filter and Drop Columns from Register Table

This function filters and drops columns from the register table based on
the specified filter type. Removes any columns that are flagged for
dropping based on the filter and CONFIG\$FILTER_COLUMN_NAMES_TO_DROP

## Usage

``` r
filter_and_drop_register_columns(register_table, filter, file_type)
```

## Arguments

- register_table:

  The register table

- filter:

  A string specifying the filter to apply (e.g., "venues",
  "codecheckers").

- file_type:

  The type of file we need to render the register for. The columns to
  keep depend on the file type

## Value

The filtered register table with only the necessary columns retained.
