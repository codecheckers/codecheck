# Was an ORCID affiliation held at a given date?

A missing start date is treated as unbounded in the past and a missing
end date as ongoing, which is how ORCID itself presents an affiliation
without an end date.

## Usage

``` r
orcid_date_covered(start, end, at)
```

## Arguments

- start, end:

  ORCID date lists (\`year\`/\`month\`/\`day\`), or NULL

- at:

  The \`Date\` to test

## Value

\`TRUE\` when the affiliation covers \`at\`
