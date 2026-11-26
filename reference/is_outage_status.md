# Whether an HTTP status says the service is unavailable for now

A server error or a rate limit, as opposed to an answer: a 404 or a 400
will be the same next time. See \[record_lookup_failure()\].

## Usage

``` r
is_outage_status(status)
```

## Arguments

- status:

  an HTTP status code

## Value

\`TRUE\` for 429 and 5xx
