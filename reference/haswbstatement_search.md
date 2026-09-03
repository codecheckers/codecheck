# The search string that asks for any of these statement values

One \`haswbstatement\` keyword with the values OR'd inside it. Repeating
the keyword instead ANDs the terms, and no item carries two of these
identifiers at once, so that form quietly finds almost nothing - it
returned 3 of 33 known works before this was written the right way
round.

## Usage

``` r
haswbstatement_search(property, values)
```

## Arguments

- property:

  the property to match on

- values:

  the values, any of which may match

## Value

the \`srsearch\` string
