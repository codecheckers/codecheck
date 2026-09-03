# Record the certificates' Wikidata items in register.csv

The QID is the one fact about a certificate that only Wikidata can tell
us, and it is what a landing page needs to link the record it exported.
Nothing in the pipeline can re-derive it offline, so it is written back
into the register - the register is the authority, and a fact that lives
only in a query result is a fact the next render loses.

## Usage

``` r
update_register_wikidata(dir, verified)
```

## Arguments

- dir:

  the register repository holding \`register.csv\`

- verified:

  the table \[verify_wikidata_export()\] built, needing its
  \`certificate\` and \`item\` columns

## Value

the number of rows changed, invisibly

## Details

Edited line by line rather than read and rewritten as a table:
\`register.csv\` holds a commented-out row (a check that was withdrawn),
and a \`read.csv()\`/\`write.csv()\` round trip would silently drop it
along with any other comment.

Only cells with a QID are filled: a certificate not yet on Wikidata
keeps an empty cell rather than losing one it already had.
