# Whether a checked work is a preprint or an article

The type of the referenced DOI's own record, as the certificate page
shows it, decides. The register's \`preprint\` venue says only that the
check was made at the preprint stage: three certificates with it
reference the journal article published since (2023-012, 2024-001,
2026-023), and sixteen preprints were checked for other venues. It is
the fallback for a reference without a typed DOI record.

## Usage

``` r
paper_kind(reference_type, venue)
```

## Arguments

- reference_type:

  the reference's type, e.g. "Preprint" or "Journal article", or \`NA\`

- venue:

  the register's \`Venue\`

## Value

\`"preprint"\` or \`"article"\`, per element
