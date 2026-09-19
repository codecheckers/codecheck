# Function for clearing the register cache

Removes everything cached below the R.cache root: the codecheck.yml
files, the codecheckers table, and the looked up OpenAlex IDs and
abstracts. Use it to pick up metadata that has changed at the source,
the lookups themselves never cache a failed request.

## Usage

``` r
register_clear_cache(certificates = NULL, register = "register.csv")
```

## Arguments

- certificates:

  Certificate identifiers, e.g. \`"2025-009"\`. \`NULL\`, the default,
  clears the whole cache.

- register:

  The register as a data frame, or a path to \`register.csv\`, used to
  find each certificate's repository.

## Value

0 for success, 1 for failure, invisibly (see \`unlink\`); with
\`certificates\`, invisibly the number of cache entries removed

## Details

With \`certificates\`, only what is cached about those certificates is
refreshed, and the rest of the cache - which takes minutes of API
requests to rebuild - is kept: the certificate's \`codecheck.yml\` is
fetched again, and its abstract, OpenAlex ID, certificate PDF link,
report platform and Zenodo or ResearchEquals policy record are removed,
so the next render or check looks them up anew. Entries shared with
other certificates, such as a person's ORCID affiliations, are kept.

## Author

Daniel Nuest
