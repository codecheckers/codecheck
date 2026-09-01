# Bring a codechecker list to a common set of columns

The three lists differ: only \`codecheckers.csv\` has \`contact\`,
\`fields\` and \`languages\`, and \`institutional-codecheckers.csv\`
additionally has \`institution\`, which is of no interest here. Missing
columns are filled with \`NA\` rather than treated as an error, so that
a list whose columns change - or a list read before its \`ORCID\` column
landed - degrades to "no profile information" instead of failing the
render.

## Usage

``` r
normalize_codechecker_list(codecheckers)
```

## Arguments

- codecheckers:

  A data frame, or \`NULL\` for an empty one.

## Value

A data frame with exactly the columns of \[CODECHECKER_LIST_COLUMNS\].
