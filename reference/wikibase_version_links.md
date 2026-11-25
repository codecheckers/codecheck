# Link each preprint to its article, and back

A certificate whose reference is a preprint and that names the article
in \`reference-other\` - or the other way round - makes the preprint a
"version of" the article and the article one that "has version" the
preprint, the convention on Wikidata (P629 on 156 preprints, P747 on 64
articles). The certificate's "review of" stays with the work it checked.

## Usage

``` r
wikibase_version_links(papers, certificates)
```

## Arguments

- papers:

  the paper rows

- certificates:

  the certificates, with \`Paper kind\` and \`Paper reference other\`

## Value

\`papers\` with list columns \`Version of\` and \`Has version\`, DOI
URLs
