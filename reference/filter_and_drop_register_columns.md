# Filter and Drop Columns from Register Table

This function filters and drops columns from the register table based on
the specified filter type. Uses hierarchical column configuration from
CONFIG\$REGISTER_COLUMNS with filter-specific overrides.

## Usage

``` r
filter_and_drop_register_columns(register_table, filter, file_type)
```

## Arguments

- register_table:

  The register table

- filter:

  A string specifying the filter to apply (e.g., "venues",
  "codecheckers"). Use NA for the default/main register.

- file_type:

  The type of file we need to render the register for. The columns to
  keep depend on the file type and filter

## Value

The filtered register table with only the necessary columns retained and
ordered.
