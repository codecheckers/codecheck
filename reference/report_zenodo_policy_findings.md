# Report curation policy findings

Report the register's curation policy findings on the console

## Usage

``` r
report_zenodo_policy_findings(result)
```

## Arguments

- result:

  the data.frame from \[check_register_zenodo_policy()\]

## Value

the result, invisibly

## Details

Prints the result of \[check_register_zenodo_policy()\] as a \`cli\`
section: a line per certificate with findings, then a tally.
Certificates that comply with no findings at all are covered by the
tally only; a compliant certificate that has an "info" finding (e.g. a
creator recorded as an organisation) is still surfaced, as information
rather than as an error.

## Author

Daniel Nuest
