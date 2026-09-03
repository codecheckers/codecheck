# How long to wait before repeating a request, or \`NA\` to give up

A MediaWiki install under load does not fail a request outright, it asks
the client to come back: \`maxlag\` when the database replicas are
behind, \`ratelimited\` when the account is writing too fast, 503 with
\`Retry-After\` when the site is overloaded, and \`readonly\` during
maintenance. All four are transient, and all four used to end a
bootstrap halfway through. Everything else - a bad token, a duplicate
label, a wrong datatype - is a real error and must not be retried.

## Usage

``` r
wikibase_retry_after(result, response = NULL, attempt = 1)
```

## Arguments

- result:

  the parsed API response, an error condition, or \`NULL\`

- response:

  the \`httr\` response, or \`NULL\`

- attempt:

  which attempt this was, 1-based

## Value

seconds to wait, or \`NA_real\_\` if the request should not be repeated
