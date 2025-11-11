# Render unsupported file type for certificate output

Internal helper function to handle unsupported file types.

## Usage

``` r
render_manifest_unsupported(path, comment)
```

## Arguments

- path:

  \- Path to the file

- comment:

  \- Comment describing the file

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)
