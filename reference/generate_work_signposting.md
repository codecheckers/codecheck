# Signposting links for a work page

A work page is about a checked paper, which has a DOI, so it is the one
non-certificate page that can carry a \`cite-as\`. The register is a
third party to that paper - \`cite-as\` here states the PID of the thing
the page describes, which is what an aggregator landing page is expected
to do, and does not claim to be the publisher's landing page.

## Usage

``` r
generate_work_signposting(doi, register_table, has_jsonld = FALSE)
```

## Arguments

- doi:

  The work's DOI (\`table_details\[\["name"\]\]\` on a work page)

- register_table:

  See
  [`get_work_metadata_fields`](http://codecheck.org.uk/codecheck/reference/get_work_metadata_fields.md)

- has_jsonld:

  Whether \`index.jsonld\` was written next to the page

## Value

HTML string of \`\<link\>\` elements, one per line
