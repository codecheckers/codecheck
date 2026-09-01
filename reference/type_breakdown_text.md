# The hover text shared by the check-type bar and donut

Lists \*every\* type with its count and share, not just the one under
the pointer, so a single hover explains the whole visualisation - which
is what lets the donut (register#207) do without a legend. The type the
pointer is actually over is marked; the others are indented by two
spaces so the list stays aligned.

## Usage

``` r
type_breakdown_text(counts, highlight = NULL)
```

## Arguments

- counts:

  A named integer vector of checks per venue type, already ordered by
  \[order_type_counts()\].

- highlight:

  The type to mark, or \`NULL\` to mark none.

## Value

A single string with \`\` between lines.
