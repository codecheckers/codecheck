# Read a record title and report whether the answer is conclusive

Same lookup as
[`get_cert_record_title`](http://codecheck.org.uk/codecheck/reference/get_cert_record_title.md)
without the caching, and with the information needed to decide whether
the result may be cached: a report link on a platform the register
cannot query is a conclusive "no title" and is cached, a platform that
could not be reached is not.

## Usage

``` r
get_cert_record_title_result(report_link, cert_id)
```

## Arguments

- report_link:

  The \`report\` field of the certificate's codecheck.yml, a DOI or
  platform URL

- cert_id:

  Certificate identifier, used for logging and warnings

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`
