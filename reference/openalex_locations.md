# The locations of an OpenAlex work that carry a DOI

A location without a DOI (an OAI-PMH harvest, a repository landing page)
identifies no copy that \`paper.reference\` or \`reference-other\` could
name, so it is left out.

## Usage

``` r
openalex_locations(locations)
```

## Arguments

- locations:

  The \`locations\` of an OpenAlex work

## Value

A list of lists with \`doi\` (a \`https://doi.org/\` URL), \`issn\` and
\`venue\`
