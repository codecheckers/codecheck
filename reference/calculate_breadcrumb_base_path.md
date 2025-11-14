# Calculate base path for breadcrumb links

Determines the relative path to the register root based on page depth.

## Usage

``` r
calculate_breadcrumb_base_path(filter = NA, table_details = list())
```

## Arguments

- filter:

  The filter type

- table_details:

  List containing page metadata

## Value

Relative path string (e.g., ".", "..", "../..")
