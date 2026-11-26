# Run a lookup, recording the outages it hit only if it ends without a value

Run a lookup, recording the outages it hit only if it ends without a
value

## Usage

``` r
collect_outages(expr, failed = function(value) FALSE)
```

## Arguments

- expr:

  the lookup

- failed:

  function of the lookup's value, \`TRUE\` if it has no value; a lookup
  that raises an error has none either

## Value

the lookup's value; its error is raised again
