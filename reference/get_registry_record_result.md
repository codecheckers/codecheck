# What a DOI's registration agency records about the work

One request to doi.org for the agency, one to Crossref or DataCite for
the record. The record answers more than one question - when the work
was made public (see \[get_registry_publication_date_result()\]) and
what type of work it is (see \[get_reference_type()\]) - so it is
fetched, and cached, once.

## Usage

``` r
get_registry_record_result(reference)
```

## Arguments

- reference:

  The paper reference; anything that is not a DOI is absent

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`, a
list with \`agency\`, \`publication_date\` (as the record states it, see
\[crossref_publication_date()\]) and \`type\` (see
\[crossref_reference_type()\]), or \`NULL\`
