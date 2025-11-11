# Render JSON file for certificate output

Internal helper function to render JSON files with pretty-printing.

## Usage

``` r
render_manifest_json(path, comment, max_lines = 50)
```

## Arguments

- path:

  \- Path to the JSON file

- comment:

  \- Comment describing the file

- max_lines:

  \- Maximum number of lines to display (default: 50)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)
