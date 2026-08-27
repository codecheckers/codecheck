# Whether a \`from\`/\`to\` range covers a whole register, in either direction

\`register_render()\`'s \`register\[(from:to),\]\` accepts
\`from\`/\`to\` in either direction (newest-first or oldest-first, as
\`register_check()\` also supports, see codecheckers/codecheck#79), so a
full run is either \`from = 1, to = n\` or \`from = n, to = 1\` -
checking only the first would wrongly treat a newest-first full run as
partial and skip \[prune_libs()\].

## Usage

``` r
is_full_register_run(from, to, n)
```

## Arguments

- from:

  The \`from\` argument as passed to \`register_render()\`

- to:

  The \`to\` argument as passed to \`register_render()\`

- n:

  Number of rows in the (unsubset) register

## Value

\`TRUE\` if \`from\`/\`to\` covers every row of the register
