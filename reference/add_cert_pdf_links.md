# Add certificate PDF download URLs to the register table

Resolves report DOIs to direct PDF download URLs using get_cert_link().

## Usage

``` r
add_cert_pdf_links(register_table)
```

## Arguments

- register_table:

  The register table (must have "Report" and "Certificate ID" columns)

## Value

Register table with added "Certificate PDF" column
