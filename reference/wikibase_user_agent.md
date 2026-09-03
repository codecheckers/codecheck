# How this client identifies itself

Wikimedia's User-Agent policy asks every client for a descriptive agent
with a way to reach whoever runs it, and answers a request without one
with 403 on the busier endpoints. \`WikidataQueryServiceR\` was removed
from CRAN in February 2026 "for policy violation", which is the cheapest
possible reminder to send a real one.

## Usage

``` r
wikibase_user_agent()
```

## Value

the User-Agent string

## See also

\<https://foundation.wikimedia.org/wiki/Policy:User-Agent_policy\>
