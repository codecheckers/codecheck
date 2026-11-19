# The works that are one work, from the references of all certificates

A certificate's \`reference\` and its \`reference-other\` DOIs are
references to the same work, so their work pages link to each other. Two
certificates that share any DOI join their groups, including across
several steps: A's reference lists X as another reference, and B's
reference is X with Y as another reference, makes A's DOI, X and Y one
work.

## Usage

``` r
build_work_relations(certs, work_keys, other_refs)
```

## Arguments

- certs:

  Character vector of certificate IDs

- work_keys:

  Character vector of each certificate's normalized reference DOI (see
  \[normalize_work_key()\]), \`NA\` where it is not a DOI

- other_refs:

  List of data frames, each certificate's further references (see
  \[get_reference_other()\])

## Value

A named list, one element per DOI, each a data frame of the other
references of that work with the columns \`url\`, \`doi\` (\`NA\` for a
web address) and \`is_reference\` (whether some certificate has that DOI
as its \`reference\`). DOIs without related references are left out.

## Details

Web addresses that are not DOIs have no work page, but are shown on the
work pages of the group the certificate belongs to.
