# Resolve identifiers against Wikidata, remembering the answers

\[wikidata_resolve()\] asks Wikidata about every identifier it is given,
every time. Rendering the register would then repeat 124 work lookups
and 65 ORCID lookups on every run, and a test suite would do it on every
file. This asks only about identifiers no previous run has asked about,
in one batch, and remembers each answer - including a confirmed "no
item", which is an answer too.

## Usage

``` r
wikidata_resolve_cached(kind, keys)
```

## Arguments

- kind:

  an entity kind from \[wikidata_entity_kinds()\]

- keys:

  the identifiers, as \[wikidata_lookup_key()\] produces

## Value

a named character vector, identifier to QID, holding only what exists

## Details

Cached with \[R.cache\] under \`codecheck/wikidata_items\`, alongside
the other external lookups; clear it with \[register_clear_cache()\].
