# Generate Output Directory Path

Generates the directory path for saving files based on info in the
register table and the filter name. Creates the output directory if it
does not already exist

## Usage

``` r
generate_output_dir(filter, table_details = list())
```

## Arguments

- filter:

  The filter name (e.g., "venues", "codecheckers").

- table_details:

  List containing details such as the table name, subcat name.

## Value

A string representing the directory path for saving files.
