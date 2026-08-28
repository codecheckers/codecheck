# Resolve a certificate ID or ResearchEquals reference to a version ID

Resolve a certificate ID or ResearchEquals reference to a version ID

## Usage

``` r
resolve_researchequals_version_id(x, register_dir = getwd())
```

## Arguments

- x:

  certificate ID (e.g. "2026-023"), ResearchEquals version ID, DOI or
  URL

- register_dir:

  directory holding \`register.csv\`, defaults to the working directory

## Value

the ResearchEquals version ID as a string

## Details

Accepts a ResearchEquals version ID, a ResearchEquals DOI or URL, or a
CODECHECK certificate ID. A certificate ID is resolved via
\`register.csv\` in \`register_dir\` to the repository spec, and from
there via the repository's \`codecheck.yml\` \`report\` field to the
ResearchEquals module.

## Author

Daniel Nuest
