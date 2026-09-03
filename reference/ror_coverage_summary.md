# Summarise ROR coverage over the register

Reports the share of persons with a current ROR and with a ROR held at
the publication date, both per (certificate, person, role) record and
per unique person - a handful of prolific codecheckers dominate the
record counts, so the two numbers answer different questions.

## Usage

``` r
ror_coverage_summary(coverage, quiet = FALSE)
```

## Arguments

- coverage:

  The data frame returned by \[register_ror_coverage()\]

- quiet:

  When \`FALSE\` (the default), print the summary

## Value

Invisibly, a data frame with one row per unit and role and the columns
\`unit\`, \`role\`, \`n\`, \`has_current_ror\`, \`pct_current_ror\`,
\`matched_at_date\` and \`pct_matched_at_date\`
