# Generate Highwire citation meta tags for a certificate page

Builds the \`citation\_\*\` meta tags that make a certificate page
citable by Google Scholar and identifiable by Zotero
(codecheckers/register#52).

## Usage

``` r
generate_cert_citation_meta(
  cert_id,
  config_yml,
  cert_title = NULL,
  cert_venue = NULL,
  has_pdf = FALSE
)
```

## Arguments

- cert_id:

  Certificate ID (e.g. "2020-018")

- config_yml:

  Parsed codecheck.yml configuration

- cert_title:

  Title of the certificate's record on the platform it is published on,
  see
  [`resolve_cert_title`](http://codecheck.org.uk/codecheck/reference/resolve_cert_title.md);
  falls back to the constructed "CODECHECK Certificate \<ID\>" when not
  given

- cert_venue:

  Venue name of the certificate, added to the keywords

- has_pdf:

  Whether \`cert.pdf\` exists next to the page, i.e. whether a
  \`citation_pdf_url\` can be offered

## Value

HTML string of \`\<meta\>\` tags, one per line

## Details

The tags describe the \*\*certificate\*\*, not the paper that was
checked: the paper has its own landing page at its DOI, and describing
it here would make Scholar treat the certificate page as a duplicate of
the paper and make Zotero save the wrong item. The link to the checked
paper is expressed in the schema.org metadata instead, as the
\`itemReviewed\` of the review, see
[`generate_cert_schema_org`](http://codecheck.org.uk/codecheck/reference/generate_cert_schema_org.md).

Only the Highwire scheme is emitted, not Dublin Core: Google Scholar
calls DC a last resort that "works poorly for journal papers", and
Zotero's Embedded Metadata translator derives the item type from the
Highwire tags - \`citation_technical_report_institution\` is what makes
a certificate a \`report\` rather than an untyped web page.
