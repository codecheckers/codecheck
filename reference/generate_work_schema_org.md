# Generate Schema.org JSON-LD for a work page (codecheckers/register#150)

The \`ScholarlyArticle\` counterpart of \[generate_venue_schema_org()\]:
the checked paper is the primary \`@graph\` entity (\`@id\` its DOI
URL), carrying its title, \`sameAs\` its OpenAlex work ID, and an
\`author\` array of \`Person\` nodes - \`@id\`'d by ORCID where known,
so a search engine or a data consumer can follow straight from the paper
to the person page (mirrors what the paper author links on the
certificate page and the work page's own metadata panel already do in
HTML - see \[generate_work_metadata_html()\]). One \`Review\` per
certificate that checked it references the article back via
\`itemReviewed\`.

## Usage

``` r
generate_work_schema_org(doi, register_table)
```

## Arguments

- doi:

  The work's DOI (\`table_details\[\["name"\]\]\` on a work page).

- register_table:

  A data frame of all certificates for this DOI, needs \`Certificate\`,
  \`Repository\` and \`Check date\` columns.

## Value

JSON-LD string with Schema.org metadata using \`@graph\`.
