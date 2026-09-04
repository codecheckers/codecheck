# The check time for machine-readable output, at the recorded precision

ISO 8601 with the time of day where the codecheck.yml recorded one, the
bare day where it did not - a \`00:00:00\` invented by the parser would
claim a precision that was never there.

## Usage

``` r
format_check_time_iso(x)
```

## Arguments

- x:

  The raw \`check_time\` value from a codecheck.yml

## Value

An ISO 8601 date or date-time, or NA if \`x\` is missing or unparseable
