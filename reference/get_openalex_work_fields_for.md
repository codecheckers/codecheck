# The publication facts of a work, if its OpenAlex record is the work's own

\[get_openalex_work_fields_cached_result()\] for a work and its
reference: when the record describes another work (see
\[openalex_record_is_work()\]), the ISSN, venue and publication date are
those of that other work and are returned as \`NA\`, so the callers fall
back as they would for a work without a record.

## Usage

``` r
get_openalex_work_fields_for(openalex_id, paper_reference)
```

## Arguments

- openalex_id:

  The OpenAlex work URL or ID

- paper_reference:

  The paper reference from the register

## Value

A list with \`status\` and \`value\`, as the cached lookup
