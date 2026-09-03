# Write a page's Schema.org metadata as a standalone JSON-LD document

The same JSON-LD is inlined in the page's \`\<script\>\` element;
writing it to \`index.jsonld\` next to the page gives the signposting
\`describedby\` link a real target. The extension matters: GitHub Pages
derives media types from file extensions and serves \`.jsonld\` as
\`application/ld+json\`, so the document arrives correctly typed without
any header control.

## Usage

``` r
write_schema_org_jsonld(schema_org_jsonld, output_dir)
```

## Arguments

- schema_org_jsonld:

  The JSON-LD string, or \`""\` for a page that has none

- output_dir:

  Directory of the page

## Value

\`TRUE\` if a document was written, \`FALSE\` otherwise
