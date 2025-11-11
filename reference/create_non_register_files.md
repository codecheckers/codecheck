# Create Non-Register Files

Processes the register table to create non-register files such as venues
and codecheckers. It applies filters to split the data into separate
tables and generates corresponding HTML and JSON files.

## Usage

``` r
create_non_register_files(register_table, filter_by)
```

## Arguments

- register_table:

  The original register data.

- filter_by:

  A list specifying the filters to apply (e.g., "venues",
  "codecheckers").
