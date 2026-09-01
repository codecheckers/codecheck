# Extract a work's structured metadata fields

The shared source of truth for the work landing page's metadata panel
(\`generate_work_metadata_html()\`), its YAML frontmatter
(\`generate_work_metadata_yaml()\`) and its JSON representation
(\`render_register_json()\`), the same three-way split used for venues
(see \[get_venue_metadata_fields()\]).

## Usage

``` r
get_work_metadata_fields(doi, register_table)
```

## Arguments

- doi:

  The work's DOI (\`table_details\[\["name"\]\]\` on a work page).

- register_table:

  The work's filtered register rows (one per certificate that checked
  this DOI), still carrying \`Repository\`, \`Paper Title\`,
  \`OpenAlex\`, \`Venue\`, \`Check date\`.

## Value

A list with \`title\`, \`doi\`, \`openalex\` (\`NA_character\_\` if
none), \`venues\` (unique, comma-joined), \`check_count\`,
\`first_check_date\`, \`last_check_date\`, and \`authors\` (a list of
\`name\`/\`orcid\` lists, \`orcid\` \`NULL\` when not known - possibly
an empty list).

## Details

Authors are fetched once, from the first certificate's \`codecheck.yml\`
(via the same cache every other lookup in the render uses) - a work's
author list does not vary by which certificate checked it, so refetching
per certificate would only mean more requests for the same answer.
