# The title of a certificate's record on its publication platform

Reads the record title from Zenodo, OSF or ResearchEquals, whichever the
\`report\` link of the certificate points at. Cached on disk, because
every certificate is rendered into markdown, HTML and JSON and each of
those asks for the title again; only conclusive results are cached, so a
rate limited request is retried on the next render instead of persisting
a gap, see
[`cached_lookup`](http://codecheck.org.uk/codecheck/reference/cached_lookup.md).

## Usage

``` r
get_cert_record_title(report_link, cert_id)
```

## Arguments

- report_link:

  The \`report\` field of the certificate's codecheck.yml, a DOI or
  platform URL

- cert_id:

  Certificate identifier, used for logging and warnings

## Value

The record title as a string, or \`NULL\` when there is none to be had
