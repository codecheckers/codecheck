# The certificates' Wikidata items as the register records them

\`register.json\` does not carry the column, so it is read from
\`register.csv\` directly, skipping the commented-out rows the file
holds.

## Usage

``` r
read_register_wikidata(dir)
```

## Arguments

- dir:

  the register repository holding \`register.csv\`

## Value

a named character vector, certificate ID to QID, only for the
certificates that have one; empty when there is no register or no column
