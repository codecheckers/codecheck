# Get the full zenodo record using the record number stored in the metadata.

Get the full Zenodo record from the metadata

## Usage

``` r
get_zenodo_record(zenodo, metadata = codecheck_metadata(getwd()))
```

## Arguments

- zenodo:

  An object from zen4R to connect with Zenodo

- metadata:

  A codecheck configuration (list). Defaults to loading from
  codecheck.yml in the current working directory using
  `codecheck_metadata(getwd())`.

## Value

The Zenodo record, or NULL.

## Details

Retrieve the Zenodo record, if one exists. By default, loads metadata
from codecheck.yml in the current working directory. If no record number
is currently listed in the metadata (i.e. the "FIXME" tag is still
there) then the code returns NULL and an empty record should be created.

## Author

Stephen Eglen
