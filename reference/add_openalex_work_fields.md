# Add the publication facts behind each OpenAlex ID (register#50)

Part of the same enrichment: an OpenAlex ID is a pointer, and the record
it points at is the only place that says which publication a checked
work appeared in and when. Both are needed to describe the work as
linked data - the register's own \`Venue\` column names the venue that
commissioned the check, which is a different fact and, for a conference
running over several years, a different publication.

## Usage

``` r
add_openalex_work_fields(register_table)
```

## Arguments

- register_table:

  The register table, with an \`OpenAlex\` column

## Value

The register table with added "Paper ISSN", "Paper venue" and "Paper
publication date" columns

## Details

Costs one cached request per work that has an ID, and nothing at all for
one that does not.
