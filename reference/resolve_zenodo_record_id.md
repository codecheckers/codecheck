# Resolve a certificate ID or Zenodo reference to a Zenodo record ID

Resolve a certificate ID or Zenodo record reference to a Zenodo record
ID

## Usage

``` r
resolve_zenodo_record_id(x, register_dir = getwd())
```

## Arguments

- x:

  certificate ID (e.g. "2026-023"), Zenodo record ID, or Zenodo DOI

- register_dir:

  directory holding \`register.csv\`, defaults to the working directory

## Value

the Zenodo record ID as integer

## Details

Accepts a Zenodo record ID, a Zenodo DOI, or a CODECHECK certificate ID.
A certificate ID is resolved via \`register.csv\` in \`register_dir\` to
the repository spec, and from there via the repository's
\`codecheck.yml\` \`report\` field to the Zenodo record.

## Author

Daniel Nuest
