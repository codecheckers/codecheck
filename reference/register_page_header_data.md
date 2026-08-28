# The page-level metadata of a register page

The defaults the shared header template is filled with, describing the
register as a whole. Certificate pages override them with
[`generate_cert_opengraph`](http://codecheck.org.uk/codecheck/reference/generate_cert_opengraph.md)
and add their citation metadata, see
[`generate_cert_citation_meta`](http://codecheck.org.uk/codecheck/reference/generate_cert_citation_meta.md).

## Usage

``` r
register_page_header_data()
```

## Value

Named list of template values
