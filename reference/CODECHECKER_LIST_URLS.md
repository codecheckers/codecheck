# The codechecker lists in the codecheckers/codecheckers repository

Three CSVs record who conducts CODECHECKs, and a codechecker can appear
in more than one of them:

## Usage

``` r
CODECHECKER_LIST_URLS
```

## Details

\- \`codecheckers.csv\` - the volunteers who signed up via the
registration issue. Carries \`contact\`, \`fields\` and \`languages\` as
well. - \`institutional-codecheckers.csv\` - people who codecheck as
part of their job, onboarded with their institution rather than through
the sign-up. - \`agile-codecheckers.csv\` - reviewers of the
Reproducible AGILE initiative, who check AGILE conference submissions
rather than as volunteers.

The register identifies a codechecker by the ORCID in \`codecheck.yml\`,
so the two non-volunteer lists only became usable here once they carried
an \`ORCID\` column - before that, an AGILE or institutional
codechecker's page showed neither avatar nor GitHub link, however well
known their handle was.
