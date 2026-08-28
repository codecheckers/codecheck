# Assemble the values the shared page header template is rendered with

The template switches optional blocks on explicit \`has\_\*\` flags
rather than on the values themselves: whisker treats the empty string as
\*true\*, so a page without an og:image or without Schema.org metadata
would otherwise emit an empty \`\<meta property="og:image"
content=""\>\` and an empty \`\<script
type="application/ld+json"\>\</script\>\` instead of nothing and the
generic website metadata.

## Usage

``` r
header_template_data(
  page_metadata,
  meta_generator,
  base_path,
  schema_org_jsonld = ""
)
```

## Arguments

- page_metadata:

  Page-level values, from
  [`register_page_header_data`](http://codecheck.org.uk/codecheck/reference/register_page_header_data.md)
  or, for a certificate page,
  [`generate_cert_opengraph`](http://codecheck.org.uk/codecheck/reference/generate_cert_opengraph.md)
  plus its citation metadata

- meta_generator:

  Content of the generator meta tag

- base_path:

  Relative path from the page to the docs root

- schema_org_jsonld:

  Schema.org JSON-LD, or "" for none

## Value

Named list ready for \`whisker.render()\`
