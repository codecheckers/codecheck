# Render a list of typed links as HTML \`\<link\>\` elements

The register is served by GitHub Pages, which cannot set HTTP response
headers, so signposting is expressed entirely through \`\<link\>\`
elements in the page head. The FAIR Signposting profile explicitly
allows this: Level 1 asks for the links "in the HTTP header and/or in
HTML link elements", and names platforms without header control as the
reason for the alternative. What is given up is HEAD-request access to
the links, and any signposting on the PDF itself. Level 2 (a link set
served as \`application/linkset+json\`) is out of reach on GitHub Pages,
which derives media types from file extensions and has none registered
for that type.

## Usage

``` r
signposting_link_tags(links)
```

## Arguments

- links:

  List of \`list(rel, href, type)\` entries; \`type\` may be NULL.
  Entries without a \`href\` are dropped, so callers can pass
  conditional values straight through.

## Value

HTML string of \`\<link\>\` elements, one per line, or \`""\` for none
