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
Certificates that comply are covered by the tally only.

## Author

Daniel Nuest
