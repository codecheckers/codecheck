# Was a time of day recorded with the check time?

\`check_time\` in a \`codecheck.yml\` is written with whatever precision
the codechecker had at hand: some entries are a bare day, others a full
timestamp. Readers only ever see the day (register#219), so the
precision matters solely for the machine-readable exports, which keep
it.

## Usage

``` r
check_time_has_time_of_day(x)
```

## Arguments

- x:

  The raw \`check_time\` value from a codecheck.yml

## Value

TRUE if \`x\` carries a time of day
