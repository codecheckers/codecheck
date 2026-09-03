# The Zenodo record behind a record id

Its own function so that a test can serve a record instead of reaching
for Zenodo, the way \[is_zenodo_concept_doi()\] takes a
\`fetch_record\`. Zenodo being slow or rate-limiting is not a reason for
a test of this package's own logic to fail.

## Usage

``` r
zenodo_record(x, sandbox = FALSE)
```

## Arguments

- x:

  the Zenodo record id

- sandbox:

  connect with the Zenodo Sandbox instead of the real service

## Value

the record, or \`NULL\`
