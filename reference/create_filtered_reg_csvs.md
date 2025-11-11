# Creates filtered CSV files from a register based on specified filters.

The function processes the register by applying filters specified in
\`filter_by\`. For "codecheckers", a temporary CSV is loaded and
processed as the original register.csv does not have the codechecker
column. The register is then grouped by the filter column, and for each
group, a CSV file is generated.

## Usage

``` r
create_filtered_reg_csvs(register, filter_by)
```

## Arguments

- register:

  The register to be filtered.

- filter_by:

  List of filters to apply (e.g., "venues", "codecheckers").
