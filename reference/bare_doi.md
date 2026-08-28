# A DOI without its resolver prefix

\`citation_doi\` takes the bare DOI, while the \`report\` field of a
codecheck.yml is usually a DOI URL.

## Usage

``` r
bare_doi(x)
```

## Arguments

- x:

  A DOI, DOI URL or \`doi:\` reference

## Value

The bare DOI, or NULL if \`x\` is not a DOI
