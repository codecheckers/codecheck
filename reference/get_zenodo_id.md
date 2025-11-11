# Extract the Zenodo record number from the report URL

Extract the Zenodo record number from the report URL

## Usage

``` r
get_zenodo_id(report)
```

## Arguments

- report:

  \- string containing the report URL on Zenodo.

## Value

the Zenodo record number (a number with at least 7 digits).

## Details

The report paramater should contain a URL like:
http://doi.org/10.5281/zenodo.3750741 where the final part of the URL is
zenodo.X where X is a number containing at least 7 digits. X is
returned. If we cannot extract the number X, we return an error, in
which case the function create_zenodo_record() can be run to create a
new record. Alternatively, the report URL is pre-assigned a DOI when
manually creating the record.

## Author

Stephen Eglen
