# Generate the work metadata HTML panel (DOI, OpenAlex, venues, authors)

Renders a \`venue-metadata\`-style panel for a work's own page: the DOI
and OpenAlex identifiers, the venue(s) it was checked at, and its
authors - each ORCID-bearing author linked to their own
\`/persons/\<ORCID\>/\` page (codecheckers/register#150's "we can link
authors ... if we have the ORCID"; unlike \#150's original text, which
only linked authors who were \*also\* a codechecker, every ORCID-bearing
author gets a link now that \#123 gives every ORCID its own page).

## Usage

``` r
generate_work_metadata_html(table_details, register_table)
```

## Arguments

- table_details:

  List containing details such as the table name (the DOI).

- register_table:

  See \[get_work_metadata_fields()\].

## Value

An HTML string (never \`""\` - the DOI row always renders).
