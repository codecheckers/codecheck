# Fail a render that could not look everything up

Lists every failed lookup, then stops with a short error: R cuts an
error message off at 1000 characters, and a lookup's key can be a whole
title. With \`options(codecheck.fail_on_outages = FALSE)\` it warns
instead, for a test that renders with live services and is not about
this.

## Usage

``` r
stop_on_lookup_failures(failures)
```

## Arguments

- failures:

  the failed lookups, see \[stop_lookup_failures()\]

## Value

nothing; an error if there are failures
