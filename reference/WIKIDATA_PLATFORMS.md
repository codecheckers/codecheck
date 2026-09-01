# The platforms a certificate itself is published on

A certificate is deposited on Zenodo, OSF or ResearchEquals, and that is
a different fact from the venue of the paper it checks - the register
records the first in the report DOI and the second in its \`Venue\`
column, and both belong in the metadata. Keyed by the names
\[detect_report_platform()\] returns.

## Usage

``` r
WIKIDATA_PLATFORMS
```

## Details

\`P1433\` rather than \`P123\` publisher: both are in use for
repository-hosted works, and "published in" is the more common of the
two by some margin (roughly 320 against 90 statements pointing at Zenodo
when last counted).
