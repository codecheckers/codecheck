# Where a Wikidata item is addressed

Two URLs for the same item, and the difference matters. The entity URI
is what Schema.org \`sameAs\` wants: the identity of the thing.
\`Special:EntityData\` is what signposting's \`describedby\` wants: a
document \*about\* it, which Wikidata serves as JSON.

## Usage

``` r
wikidata_entity_url(qid)

wikidata_entitydata_url(qid)
```

## Arguments

- qid:

  a Wikidata item, e.g. "Q42"

## Value

the URL
