# The identifier an entity kind is resolved on

The model already says how to turn a register field into the value
Wikidata holds - a DOI out of a URL, an ORCID out of a profile link -
and the lookup has to be keyed on the same value the resolution was.

## Usage

``` r
wikidata_lookup_key(kind, value)
```

## Arguments

- kind:

  an entity kind from \[wikidata_entity_kinds()\]

- value:

  the register's value

## Value

the identifier, or \`NA_character\_\`
