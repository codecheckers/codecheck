# Retrieve a ResearchEquals version's metadata

Retrieve the metadata of a ResearchEquals module version

## Usage

``` r
get_researchequals_version_metadata(version_id)
```

## Arguments

- version_id:

  the ResearchEquals version ID

## Value

the parsed API response as a list, plus the element \`main_file\`

## Details

The main file is resolved with \[researchequals_main_file()\] and added
as the element \`main_file\`, so that \[researchequals_policy_check()\]
can judge the deposited certificate without doing any network access of
its own.

## Author

Daniel Nuest
