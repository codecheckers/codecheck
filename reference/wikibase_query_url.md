# A link that opens a query in a query service

The graphical query service lives at the endpoint's own host, one
directory up from the SPARQL path, and takes its query in the URL
fragment.

## Usage

``` r
wikibase_query_url(query, endpoint = "wikibase")
```

## Arguments

- query:

  the rendered query lines

- endpoint:

  the endpoint name, a key of \[WIKIDATA_ENDPOINTS\]

## Value

the URL
