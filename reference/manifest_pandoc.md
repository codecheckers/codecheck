# Find pandoc for converting manifest files

Internal helper returning the command and leading arguments to run
pandoc: the pandoc rmarkdown finds (which includes the one Quarto
bundles), else \`quarto pandoc\`.

## Usage

``` r
manifest_pandoc()
```

## Value

A list with \`cmd\` and \`args\`, or NULL if no pandoc is available
