# Fetch metadata of a published Zenodo record

Fetch the metadata of a published Zenodo record

## Usage

``` r
get_zenodo_record_metadata(id, sandbox = FALSE)
```

## Arguments

- id:

  Zenodo record ID

- sandbox:

  use the Zenodo sandbox instance

## Value

list with elements \`metadata\` and \`files\` (file names)

## Details

Uses the InvenioRDM representation of the Zenodo REST API, which is the
one the curation policy checks apply to. No authentication needed for
open records, but an authenticated request gets a much higher Zenodo
rate limit, so ZENODO_TOKEN is sent when set.

## Author

Daniel Nuest
