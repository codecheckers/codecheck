# A writing Action API request

Every write goes through here: it carries the CSRF token, and it is the
one place that turns an API-level error into an R error rather than a
silently ignored response. Separated from its callers so a test can see
the payload they build without touching the network.

## Usage

``` r
wikibase_post(session, params, what)
```

## Arguments

- session:

  a session from \[wikibase_session()\]

- params:

  the form parameters, \`format\` and \`token\` are added

- what:

  what is being written, for the error message

## Value

the parsed response
