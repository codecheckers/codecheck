# Cached version of get_cert_record_title, with the lookup status

Same lookup as
[`get_cert_record_title`](http://codecheck.org.uk/codecheck/reference/get_cert_record_title.md),
but returns the full \`status, value\` result so a caller can tell a
platform that conclusively has no title apart from one that could not be
reached, see
[`resolve_external_field`](http://codecheck.org.uk/codecheck/reference/resolve_external_field.md).

## Usage

``` r
get_cert_record_title_cached_result(report_link, cert_id)
```

## Arguments

- report_link:

  The \`report\` field of the certificate's codecheck.yml, a DOI or
  platform URL

- cert_id:

  Certificate identifier, used for logging and warnings

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`
