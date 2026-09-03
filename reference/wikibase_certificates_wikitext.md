# The wiki page listing the certificates on the instance

A certificate is an item, and an item is found by its number - which
says nothing to a person looking for certificate 2020-001. This is the
index that does: one row per certificate, from its local item to the
register page it came from. Generated, and overwritten by every load.

## Usage

``` r
wikibase_certificates_wikitext(
  written,
  certificates,
  generated_at = Sys.time()
)
```

## Arguments

- written:

  the table \[load_wikibase_register()\] built

- certificates:

  the certificate rows, for the fields the table shows

- generated_at:

  the timestamp to stamp the page with

## Value

the page's wikitext
