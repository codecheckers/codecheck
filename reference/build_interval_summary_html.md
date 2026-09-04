# Build the "time from work publication to check" summary stat line

Deliberately not framed as a speed metric: a fast turnaround and a check
of a decades-old work are both notable, not "good vs. bad" - so this
describes the spread, never phrasing it as something "completed within"
a target time.

## Usage

``` r
build_interval_summary_html(interval_summary, n, excluded)
```

## Arguments

- interval_summary:

  The \`interval_summary\` list from statistics.json
  (\`pct_before_publication\`, \`pct_within_6mo\`, \`max_years\`), or
  NULL

- n:

  Number of certificates the summary covers

- excluded:

  Number of certificates excluded (missing a date)

## Value

An HTML string, or "" if no summary is available
