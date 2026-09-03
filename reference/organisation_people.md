# The people an organisation is on the register through

The people an organisation is on the register through

## Usage

``` r
organisation_people(register_table)
```

## Arguments

- register_table:

  The organisation's exploded rows, with a \`Person\` (ORCID) column.

## Value

A list of \`name\`/\`url\`/\`last\` lists, ready for whisker (\`last\`
marks the final entry so the template can omit its separator).
