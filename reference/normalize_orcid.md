# Normalize an ORCID to its canonical form

ORCIDs are case-insensitive only in the trailing checksum character,
which the ORCID registry itself always renders as uppercase X. Two
records that differ only in that case must resolve to the same person
page.

## Usage

``` r
normalize_orcid(orcid)
```

## Arguments

- orcid:

  The ORCID string, with or without a URL prefix

## Value

The normalized ORCID (\`NNNN-NNNN-NNNN-NNNX\` form), or \`NA\` if not
well-formed
