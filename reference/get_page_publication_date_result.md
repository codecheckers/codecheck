# Look up a work's publication date directly from its own landing page

Fallback for when OpenAlex has no record for a work at all (an arXiv
preprint, a conference proceedings entry, an institutional repository
item, ...): tries, in order, HTML \`citation\_\*\` meta tags, schema.org
\`datePublished\` JSON-LD, and - for a reference that is itself a PDF
with no separate landing page - the PDF's own \`Created\` metadata via
\`pdftools::pdf_info()\`.

## Usage

``` r
get_page_publication_date_result(url)
```

## Arguments

- url:

  The paper reference URL (typically the same URL used for the OpenAlex
  lookup)

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`, an
ISO "YYYY-MM-DD" string or NA_character\_
