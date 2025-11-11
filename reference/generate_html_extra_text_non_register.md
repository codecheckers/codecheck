# Generates the extra text of the HTML pages for non registers. This extra text is to be placed under the table. There is only extra text for the codecheckers HTML page to explain the reason for discrepancy between total_codechecks != SUM(no.of codechecks)

Generates the extra text of the HTML pages for non registers. This extra
text is to be placed under the table. There is only extra text for the
codecheckers HTML page to explain the reason for discrepancy between
total_codechecks != SUM(no.of codechecks)

## Usage

``` r
generate_html_extra_text_non_register(filter)
```

## Arguments

- filter:

  A string specifying the filter applied (e.g., "venues",
  "codecheckers").

## Value

The extra text to place under the table
