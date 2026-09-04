# Extract a schema.org \`datePublished\` from a page's JSON-LD

Reads every \`\<script type="application/ld+json"\>\` block and returns
the first \`datePublished\` found, at the top level or inside a
\`@graph\` array (the shape some publishing platforms, e.g. IIEP-UNESCO,
use).

## Usage

``` r
extract_schema_org_date_published(html_text)
```

## Arguments

- html_text:

  The page's HTML source

## Value

A date string (typically ISO 8601), or NA_character\_ if none present
