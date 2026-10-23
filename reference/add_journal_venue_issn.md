# Fill in the publication of a journal's own works that OpenAlex cannot place

The publication normally comes from the work's OpenAlex record and never
from the register's \`Venue\` column, because a conference venue spans
several publications over the years. A journal is the exception: a check
of type \`journal\` is of a work submitted to that journal, so the venue
\*is\* the publication. Lifecycle Journal is the case this exists for:
CrossRef registers its articles as posted content without an ISSN, so
OpenAlex has no source for them and the works got no "published in"
statement (codecheckers/register#50).

## Usage

``` r
add_journal_venue_issn(register_table, venues)
```

## Arguments

- register_table:

  The register table, with \`Type\`, \`Venue\`, \`OpenAlex\`, \`Paper
  ISSN\` and \`Paper venue\` columns

- venues:

  The venues table from \`venues.csv\`, with \`name\`, \`longname\` and
  \`identifiers\`; \`NULL\` leaves the table unchanged

## Value

The register table, with \`Paper ISSN\` and \`Paper venue\` filled in
from the venue where that applies

## Details

Only a work OpenAlex knows but cannot place - an OpenAlex ID, and
neither an ISSN nor a source name - is filled in. A work whose record
names a source, such as a preprint server, keeps what OpenAlex says.
