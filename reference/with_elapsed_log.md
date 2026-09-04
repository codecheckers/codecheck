# Prefix every log line with the time elapsed since the render started

\`verbose = TRUE\` reports how long each page took, but not when
anything happened, so a phase that takes a minute between two summary
lines is invisible unless the whole process is piped through a stamping
filter. The handler below does that inside R: each message - which is
how cli writes its output - is re-emitted with an elapsed-seconds
prefix.

## Usage

``` r
with_elapsed_log(expr, enabled = TRUE, start = Sys.time())
```

## Arguments

- expr:

  The expression to evaluate (lazily, inside the handler)

- enabled:

  Whether to stamp at all; FALSE evaluates \`expr\` unchanged

- start:

  Time the elapsed seconds are counted from

## Value

The value of \`expr\`

## Details

Forked workers inherit the calling handlers of the process they were
forked from, so pages rendered in parallel are stamped as well.
