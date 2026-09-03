# Signposting links for a certificate page

A certificate page is a scholarly object's landing page, so it carries
the full FAIR Signposting Level 1 link set. \`cite-as\` is the
certificate's own archived DOI, never the checked paper's: the paper has
its own landing page at its own PID, and it is linked as
\`itemReviewed\` in the Schema.org metadata instead, for the same reason
the Highwire tags describe the certificate only, see
[`generate_cert_citation_meta`](http://codecheck.org.uk/codecheck/reference/generate_cert_citation_meta.md).

## Usage

``` r
generate_cert_signposting(
  cert_id,
  config_yml,
  has_pdf = FALSE,
  has_jsonld = FALSE
)
```

## Arguments

- cert_id:

  Certificate ID (e.g. "2020-018")

- config_yml:

  Parsed codecheck.yml configuration

- has_pdf:

  Whether \`cert.pdf\` exists next to the page, i.e. whether a
  \`citation_pdf_url\` can be offered

- has_jsonld:

  Whether \`index.jsonld\`, the Schema.org metadata as a standalone
  document, was written next to the page

## Value

HTML string of \`\<link\>\` elements, one per line

## Details

Relations that cannot be stated truthfully are omitted rather than
guessed: \`cite-as\` has cardinality 1 and is dropped when the
certificate has no report DOI, and \`item\` is dropped when no PDF sits
next to the page.
