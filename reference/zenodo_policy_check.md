# Check Zenodo record metadata against the CODECHECK curation policy

Check Zenodo record metadata against the CODECHECK curation policy

## Usage

``` r
zenodo_policy_check(
  record_metadata,
  files = NULL,
  record = NULL,
  configuration = NULL
)
```

## Arguments

- record_metadata:

  list of record metadata

- files:

  character vector of file names in the deposit, optional; needed for
  the checks on the certificate PDF, its name, and the certificate
  source.

- record:

  the full record as returned by the InvenioRDM API (i.e. the \`record\`
  element of \[get_zenodo_record_metadata()\]'s return value), optional;
  needed for the community membership check, see \#20. Community
  membership lives outside \`metadata\` (under \`parent\$communities\`),
  so this check is only added when \`record\` is supplied.

- configuration:

  the parsed \`codecheck.yml\` of the certificate, optional; needed to
  check that the record's certificate ID, codechecker names and ORCIDs
  match it, see \[get_codecheck_yml()\].

## Value

a data.frame with columns \`check\`, \`status\` (one of "pass", "warn",
"fail") and \`detail\`, one row per policy requirement.

## Details

Pure function: it evaluates a record's metadata against the CODECHECK
community curation policy, see
\<https://zenodo.org/communities/codecheck/curation-policy\>, and does
not touch the network. Pass the \`metadata\` element of a record as
returned by the Zenodo InvenioRDM API
(\`https://zenodo.org/api/records/\<ID\>\` with the
\`application/vnd.inveniordm.v1+json\` representation) or of a
\`ZenodoRecord\`.

## Author

Daniel Nuest
