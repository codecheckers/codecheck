# Check a ResearchEquals module against the CODECHECK curation policy

Check a ResearchEquals module against the CODECHECK curation policy

## Usage

``` r
researchequals_policy_check(version, collections = NULL, venue = NULL)
```

## Arguments

- version:

  list of version metadata as returned by the ResearchEquals API

- collections:

  named list of collection issues as returned by
  \[get_researchequals_collections()\], optional; needed for the
  collection membership checks. A single collection issue is accepted as
  well.

- venue:

  the register venue of the certificate, e.g. "AGILEGIS", optional; a
  venue-specific collection is skipped when the venue is unknown

## Value

a data.frame with columns \`check\`, \`status\` (one of "pass", "warn",
"info", "fail") and \`detail\`, one row per policy requirement.

## Details

Pure function: it evaluates the metadata of a ResearchEquals module
version against the CODECHECK curation policy, see
\<https://zenodo.org/communities/codecheck/curation-policy\>, whose
requirements apply to certificates on any platform, and does not touch
the network. Pass a version as returned by the ResearchEquals API
(\`https://researchequals.com/api/versions/\<version id\>\`).

The counterpart of the Zenodo community membership requirement is
membership in the collections a certificate must be part of on
ResearchEquals, see \[get_researchequals_collections()\]. Every
certificate must be in the CODECHECK collection; the Reproducible AGILE
collection is only required for certificates of the AGILEGIS venue, so
it is checked only when \`venue\` says the certificate belongs to it.
Membership is not part of the version metadata, so a collection is only
checked when it is passed in \`collections\`, and each one is reported
as its own row, \`collection: \<name\>\`.

## Author

Daniel Nuest
