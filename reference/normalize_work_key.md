# Normalize a paper reference to a DOI-based work key

The register identifies a "work" (issue codecheckers/register#150) by
its DOI. DOIs are case-insensitive, so the key must be lowercased or two
certificates citing the same DOI in different case would render as two
work directories - the same class of bug fixed for venue names in
codecheckers/register#192.

## Usage

``` r
normalize_work_key(paper_reference)
```

## Arguments

- paper_reference:

  The \`Paper reference\` / \`config_yml\$paper\$reference\` value,
  expected to be a DOI URL (\`https://doi.org/10...\`) for a work page
  to exist at all; anything else (a PDF URL, a non-DOI landing page)
  yields \`NA\` - such a certificate simply has no work page, per \#150.

## Value

The lowercased bare DOI, or \`NA\` if \`paper_reference\` is not a DOI
