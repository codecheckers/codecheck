# Generate redirect page for /certs/ directory

Creates an index.html at docs/certs/ that redirects visitors to the main
register page. This handles the case where someone visits
/register/certs/ without specifying a certificate ID.

## Usage

``` r
generate_certs_redirect()
```

## See also

<https://github.com/codecheckers/register/issues/166>
