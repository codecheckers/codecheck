# Signposting links for a venue page

Venues have persistent identifiers too: \`venues.csv\` carries a
\`wikidata\` column, and a Wikidata entity URI is the one PID that
exists for every venue type, which is what \`cite-as\` needs given its
cardinality of 1. The ISSNs in the \`identifiers\` column stay where
they are, in the Schema.org \`sameAs\`. A venue without a Wikidata item
simply gets no \`cite-as\`.

## Usage

``` r
generate_venue_signposting(venue_name, venue_type, has_jsonld = FALSE)
```

## Arguments

- venue_name:

  The venue's name (\`venues.csv\` \`name\` column)

- venue_type:

  The venue's type, mapped to a Schema.org class by
  [`venue_schema_org_type`](http://codecheck.org.uk/codecheck/reference/venue_schema_org_type.md)

- has_jsonld:

  Whether \`index.jsonld\` was written next to the page

## Value

HTML string of \`\<link\>\` elements, one per line

## Details

Some rows of \`venues.csv\` are not venues but publication states -
"preprint", "in press" - and their \`wikidata\` value is a class item
the Wikidata data model types checked works with (Q580922, "preprint"),
not an identifier of the venue. Those get no \`cite-as\` either:
\`cite-as\` states the PID \*of the thing the page is about\*, and a
class shared across the register is not it. They are recognised by
looking the value up in \[WIKIDATA_ITEMS\].
