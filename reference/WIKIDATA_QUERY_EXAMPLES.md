# Example queries against Wikidata

What the certificates are for: they are on Wikidata, in the scholarly
graph, and these are the questions the modelling was chosen to make
askable. Written with Wikidata's own ids and run on the Wikidata Query
Service, so nothing here depends on this instance existing.

## Usage

``` r
WIKIDATA_QUERY_EXAMPLES
```

## Details

\`endpoint\` names the graph the query runs on, from
\[WIKIDATA_ENDPOINTS\]: the certificates and the papers they check are
in the scholarly graph, while the items they point at - the classes, the
platforms, the journals - are in the main one, which is why several of
these federate to it rather than reading a label that is not there.
