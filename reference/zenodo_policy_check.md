# Check Zenodo record metadata against the CODECHECK curation policy

Check Zenodo record metadata against the CODECHECK curation policy

## Usage

``` r
zenodo_policy_check(record_metadata, files = NULL)
```

## Arguments

- record_metadata:

  list of record metadata

- files:

  character vector of file names in the deposit, optional; needed for
  the checks on the certificate PDF and the machine-readable source.

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
