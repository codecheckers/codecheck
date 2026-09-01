# The SPARQL endpoints the resolution step queries

The Wikidata Query Service was split in 2025: scholarly articles moved
to their own endpoint, everything else stayed on the main one, and an
entity is served by exactly one of them. Papers are therefore looked up
on \`scholarly\`, people and venues on \`main\`; querying the wrong one
silently returns no match rather than an error.

## Usage

``` r
WIKIDATA_ENDPOINTS
```

## Details

\`wikibase\` is the CODECHECK Wikibase instance, which is unsplit.
