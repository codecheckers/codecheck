# Compute annual statistics from the register table

Computes per-year breakdowns of checks, venues, codecheckers, and report
platforms. Used to enrich statistics.json (addresses register#144).

## Usage

``` r
compute_annual_stats(register_table, context = NULL)
```

## Arguments

- register_table:

  The full preprocessed register table (before column filtering)

- context:

  Optional description of the page, e.g. \`"works page 10.1234/abc"\`,
  used in the error message

## Value

A list of annual statistics

## Details

A page with no certificate that has both a check date and a type gets
empty per-type counts rather than an error (codecheckers/register#241).
Any other error is re-raised with \`context\` and the page's
certificates and check dates in its message, so a failed render names
the page.
