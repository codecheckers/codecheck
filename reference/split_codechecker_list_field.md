# Split a free-text \`fields\` or \`languages\` entry into its items

Codecheckers fill in both columns of \`codecheckers.csv\` by hand, as a
comma-separated list whose items may carry a comment in parentheses -
which may itself contain commas: \`R (expert, package dev)\` or
\`functional languages (Haskell, ML, LISP)\`. So a comma separates items
only outside parentheses. The items are kept as written otherwise,
levels and all, since there is no controlled vocabulary to normalise
them to (register#168).

## Usage

``` r
split_codechecker_list_field(text)
```

## Arguments

- text:

  The column value, possibly \`NULL\`, \`NA\` or \`""\`.

## Value

A character vector of trimmed, non-empty items; \`character(0)\` if
there are none.
