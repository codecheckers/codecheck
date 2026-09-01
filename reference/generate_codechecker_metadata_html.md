# Generate the codechecker metadata HTML panel (avatar + ORCID + GitHub + venues)

Renders a \`venue-metadata\`-style panel for a codechecker's own page: a
GitHub avatar (a plain \`https://github.com/\<handle\>.png\` image -
GitHub serves this directly, so no API call or caching is needed, unlike
OpenAlex/CrossRef lookups elsewhere), a property list with the
codechecker's ORCID and GitHub profile link (register#75), and the
contributed-venues list (register#74/#189/#83) as a further row in the
same list, rather than as separate text above the panel. Reuses the
\`.venue-metadata\`/\`.venue-metadata-label\` CSS classes already used
by the venue panel.

## Usage

``` r
generate_codechecker_metadata_html(
  identifier,
  register_table = NULL,
  table_details = NULL
)
```

## Arguments

- identifier:

  See \[resolve_codechecker_profile()\].

- register_table, table_details:

  See \[generate_contributed_venues_html()\]. \`NULL\` (the default)
  omits the contributed-venues row.

## Value

An HTML string, or \`""\` if there is nothing to show (no ORCID, no
GitHub handle, and no contributed venues).
