# The OpenAlex ID and publication date of another reference's DOI

Looked up by the DOI alone: the title and author search that backs up
the lookup of a certificate's own reference would find the very work the
certificate references, not this version of it. An OpenAlex record that
describes another work (a preprint merged into its published version) is
not this DOI's, so its ID is not used, and the date comes from the DOI's
own registry record or landing page instead.

## Usage

``` r
get_other_reference_fields(url)
```

## Arguments

- url:

  The DOI as a URL

## Value

A list with \`openalex\` and \`publication_date\`, each possibly \`NA\`
