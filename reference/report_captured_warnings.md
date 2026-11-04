# Print the warnings collected during a render as structured log entries

Each unique warning is shown once, prefixed with \`\[xN\]\` when it was
raised more than once.

## Usage

``` r
report_captured_warnings(captured_warnings, failed = FALSE)
```

## Arguments

- captured_warnings:

  Character vector of warning messages

- failed:

  Whether the render stopped with an error; the heading then says these
  are the warnings raised before the failure

## Value

Invisibly, \`captured_warnings\`
