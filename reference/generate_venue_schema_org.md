# Generate Schema.org JSON-LD for venue pages

Creates structured metadata using \`@graph\` to represent the venue
(journal, conference, community or institution) as an
appropriately-typed Schema.org entity - a \`Periodical\` for a journal,
an \`EventSeries\` for a conference, \`Organization\` otherwise,
carrying the same metadata as the venue's landing page panel (name, url,
description, logo, identifiers as \`PropertyValue\`s, via
\[get_venue_metadata_fields()\]) - together with a \`Review\` per
checked paper, whose \`itemReviewed\` \`ScholarlyArticle\` links back to
the venue via \`isPartOf\`. Mirrors
\[generate_codechecker_schema_org()\]. Addresses register#183.

## Usage

``` r
generate_venue_schema_org(venue_name, venue_type, register_table)
```

## Arguments

- venue_name:

  The venue's name (register.csv \`Venue\` column / venues.csv \`name\`)

- venue_type:

  The venue's type (register.csv \`Type\` column)

- register_table:

  A data frame of all codechecks for this venue, needs \`Certificate\`,
  \`Repository\` and \`Check date\` columns

## Value

JSON-LD string with Schema.org metadata using \`@graph\`
