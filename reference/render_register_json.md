# Renders register json for a single register_table

Renders register json for a single register_table

## Usage

``` r
render_register_json(
  register_table,
  table_details,
  filter,
  full_register_table = NULL
)
```

## Arguments

- register_table:

  The register table

- table_details:

  List containing details such as the table name, subcat name.

- filter:

  The filter

- full_register_table:

  Optional full preprocessed register table for computing annual
  statistics (only used for the main register stats.json)
