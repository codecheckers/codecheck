# Audit a ResearchEquals certificate against the CODECHECK curation policy

Audit a published ResearchEquals module against the CODECHECK curation
policy

## Usage

``` r
check_researchequals_record(record, register_dir = getwd(), venue = NULL)
```

## Arguments

- record:

  certificate ID, ResearchEquals version ID, DOI or URL

- register_dir:

  directory holding \`register.csv\`, used to resolve a certificate ID
  and its venue, defaults to the working directory

- venue:

  the register venue of the certificate, e.g. "AGILEGIS"; looked up in
  \`register.csv\` when \`record\` is a certificate ID. Without it a
  venue-specific collection, i.e. Reproducible AGILE, is not checked.

## Value

invisibly, the data.frame returned by \[researchequals_policy_check()\]

## Details

Read-only: fetches the module version and the collections a certificate
must be part of, and reports which requirements of the CODECHECK
curation policy the certificate meets, including its membership in those
collections, see \[get_researchequals_collections()\].

## Author

Daniel Nuest
