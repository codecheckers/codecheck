# Add the publication facts behind each OpenAlex ID (register#50)

Part of the same enrichment: an OpenAlex ID is a pointer, and the record
it points at is the only place that says which publication a checked
work appeared in and when. Both are needed to describe the work as
linked data - the register's own \`Venue\` column names the venue that
commissioned the check, which is a different fact and, for a conference
running over several years, a different publication.

## Usage

``` r
add_openalex_work_fields(register_table, paper_references = NULL)
```

## Arguments

- register_table:

  The register table, with an \`OpenAlex\` column

- paper_references:

  Optional character vector, same length and order as
  \`register_table\`'s rows, of each work's \`paper.reference\` URL from
  its \`codecheck.yml\`. Used only as a fallback (see below); pass
  NULL/omit to skip it (e.g. for a per-certificate re-render with a
  one-row table).

## Value

The register table with added "Paper ISSN", "Paper venue" and "Work
publication date" columns

## Details

Costs one cached request per work that has an ID, and nothing at all for
one that does not.
