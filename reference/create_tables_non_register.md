# Create Non-Register Tables

Generates tables based on the filter type provided, such as venues or
codecheckers. It creates tables for further processing and rendering
into different formats.

## Usage

``` r
create_tables_non_register(register_table, filter)
```

## Arguments

- register_table:

  The original register data.

- filter:

  A string specifying the filter to apply (e.g., "venues",
  "codecheckers").

## Value

A list of tables generated based on the specified filter. The keys are
the table names and the values are the tables themselves.
