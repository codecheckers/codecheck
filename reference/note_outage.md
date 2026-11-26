# Note that a service was down for a request

Inside \[collect_outages()\] the outage is held until the lookup ends;
outside any, it is recorded right away.

## Usage

``` r
note_outage(what)
```

## Arguments

- what:

  the request and what went wrong

## Value

nothing
