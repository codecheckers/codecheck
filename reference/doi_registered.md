# Whether a DOI resolves

Asks the DOI resolver's handle API, which answers 200 for a registered
DOI and 404 for one that is not, without following the DOI to its
landing page.

## Usage

``` r
doi_registered(doi)
```

## Arguments

- doi:

  the DOI, bare

## Value

\`TRUE\`, \`FALSE\`, or \`NA\` when the resolver could not be asked
