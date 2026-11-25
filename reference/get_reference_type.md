# The type of work a DOI's registry record states, e.g. "Preprint"

Read from the record at the DOI's registration agency, which is the one
source that types a preprint as such: OpenAlex merges a preprint into
its published version, so looking up the preprint's DOI there answers
with the journal article's record (see \[openalex_record_is_work()\]).

## Usage

``` r
get_reference_type(reference)
```

## Arguments

- reference:

  A paper reference; anything that is not a DOI has no type

## Value

A list with \`type\` (a display label, \`NA\` when unknown), \`agency\`
("Crossref", "DataCite" or \`NA\`) and \`status\`: \`"found"\`,
\`"absent"\` when there is no DOI or no record, or \`"failed"\` when the
registry could not be asked - a type that is unknown for now, not one
that is not there
