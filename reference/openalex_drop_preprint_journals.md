# An OpenAlex work without the journal sources of a preprint

A preprint did not appear in a journal, whatever source OpenAlex gives
its locations (2024-016: a Zenodo preprint naming the journal it was
submitted to). Such a source is dropped, as if the location had none,
unless the location is the published version: a record OpenAlex merged
from a preprint and its article may be typed a preprint, and the article
keeps its journal.

## Usage

``` r
openalex_drop_preprint_journals(data)
```

## Arguments

- data:

  An OpenAlex work, as parsed from the API

## Value

\`data\` with those sources set to \`NULL\`
