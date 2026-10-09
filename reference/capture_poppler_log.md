# Evaluates an expression that uses poppler (via pdftools) and captures poppler's diagnostics from R's message connection instead of printing them, see \[classify_poppler_log()\]. Errors are caught and returned, not raised.

Evaluates an expression that uses poppler (via pdftools) and captures
poppler's diagnostics from R's message connection instead of printing
them, see \[classify_poppler_log()\]. Errors are caught and returned,
not raised.

## Usage

``` r
capture_poppler_log(expr)
```

## Arguments

- expr:

  The expression to evaluate.

## Value

A list with \`value\` (the value of \`expr\`, \`NULL\` on error),
\`error\` (the caught error message, or \`NULL\`), and \`fatal\` and
\`cosmetic_count\` as returned by \[classify_poppler_log()\].
