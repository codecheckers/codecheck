# Report ResearchEquals curation policy findings

Report the register's ResearchEquals policy findings on the console

## Usage

``` r
report_researchequals_policy_findings(result)
```

## Arguments

- result:

  the data.frame from \[check_register_researchequals_policy()\]

## Value

the result, invisibly

## Details

Prints the result of \[check_register_researchequals_policy()\] as a
\`cli\` section: a line per certificate with findings, then a tally.
Certificates that comply with no findings at all are covered by the
tally only.

## Author

Daniel Nuest
