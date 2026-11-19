# The type label of a DataCite record

arXiv registers its preprints at DataCite as \`Text\`/\`Article\`, not
as \`Preprint\`, so its records are recognised by their publisher and
DOI prefix.

## Usage

``` r
datacite_reference_type(attributes)
```

## Arguments

- attributes:

  The \`data\$attributes\` of a DataCite DOI response

## Value

A display label, or \`NA\` for a type not shown on the register
