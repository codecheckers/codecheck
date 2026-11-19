# Whisker data for a list of references, linking DOIs to their work pages

Shared by the certificate page's "Other references" and the work page's
"Same work as": a DOI links to its work page and, by its DOI icon, to
doi.org; a web address that is not a DOI has no work page and links out.

## Usage

``` r
reference_list_data(references, works_base)
```

## Arguments

- references:

  A list of lists with \`url\`, \`doi\` and, optionally,
  \`type\`/\`agency\` (see \[get_reference_type()\])

- works_base:

  The relative path from the page to the \`works/\` directory, ending in
  "/"

## Value

A list of lists for a whisker section, the last one marked \`last\`
