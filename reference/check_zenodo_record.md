# Audit a Zenodo record against the CODECHECK curation policy

Audit a published Zenodo record against the CODECHECK curation policy

## Usage

``` r
check_zenodo_record(record, register_dir = getwd())
```

## Arguments

- record:

  certificate ID, Zenodo record ID, or Zenodo DOI

- register_dir:

  directory holding \`register.csv\`, used to resolve a certificate ID,
  defaults to the working directory

## Value

invisibly, the data.frame returned by \[zenodo_policy_check()\]

## Details

Read-only: fetches the record and reports which requirements of the
CODECHECK community curation policy it meets, see
\<https://zenodo.org/communities/codecheck/curation-policy\>.

## Author

Daniel Nuest
