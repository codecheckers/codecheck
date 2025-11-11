# Creates a temporary CSV register with a "Codechecker" column.

The function flattens the "Codechecker" column and saves the resulting
table as a temporary CSV file. This tempeorary CSV is needed to filter
the registers b by codecheckers.

## Usage

``` r
create_temp_register_with_codechecker(register_table)
```

## Arguments

- register_table:

  The register table with a "Codechecker" column.
