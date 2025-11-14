# Format Report column for display by creating markdown links with shortened text

Removes "https://" from the display text to save space while keeping
full URLs in links. This is only called during rendering; the Report
column remains as plain URLs in the data.

## Usage

``` r
add_report_hyperlinks_reg(register_table)
```

## Arguments

- register_table:

  The register table with Report column containing plain URLs

## Value

The register table with Report column formatted as markdown links
