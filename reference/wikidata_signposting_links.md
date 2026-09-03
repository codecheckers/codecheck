# The signposting links naming an entity's Wikidata record

\`describedby\`, not \`cite-as\`: a certificate's persistent identifier
is the DOI of its report, and \`cite-as\` has a cardinality of one. The
Wikidata item is another description of the same object, which is what
\`describedby\` means, and \`Special:EntityData\` serves it as JSON.

## Usage

``` r
wikidata_signposting_links(qid)
```

## Arguments

- qid:

  the QID, or \`NULL\`

## Value

a list of link entries for \[signposting_link_tags()\]
