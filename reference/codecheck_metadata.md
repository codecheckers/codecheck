# Return the metadata for the codecheck project in root folder of project

Return the metadata for the codecheck project in root folder of project

## Usage

``` r
codecheck_metadata(root = getwd())
```

## Arguments

- root:

  Path to the root folder of the project, defaults to current working
  directory

## Value

A list containing the metadata found in the codecheck.yml file

## Details

Loads and parses the codecheck.yml file from the specified directory. If
the file doesn't exist, stops with a clear error message.

## Author

Stephen Eglen
