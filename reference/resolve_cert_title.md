# The title to show for a certificate, protected from transient failures

Resolves this render's platform lookup against what the certificate's
existing \`index.json\` already says, so a Zenodo outage or a rate
limited render cannot silently replace every record title with the
constructed fallback, see
[`resolve_external_field`](http://codecheck.org.uk/codecheck/reference/resolve_external_field.md).

## Usage

``` r
resolve_cert_title(cert_id, report_link, prune_unavailable = FALSE)
```

## Arguments

- cert_id:

  Certificate identifier, e.g. "2020-018"

- report_link:

  The \`report\` field of the certificate's codecheck.yml

- prune_unavailable:

  Passed to
  [`resolve_external_field`](http://codecheck.org.uk/codecheck/reference/resolve_external_field.md)

## Value

The record title, or "CODECHECK Certificate \<ID\>" when none is known
