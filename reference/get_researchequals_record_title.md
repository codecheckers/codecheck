# The title of a ResearchEquals module version

Only the version metadata is fetched, not the deposited file that
\[get_researchequals_version_metadata()\] additionally resolves.

## Usage

``` r
get_researchequals_record_title(report_link)
```

## Arguments

- report_link:

  A ResearchEquals DOI, DOI URL, version URL or version ID

## Value

The version title, or \`NULL\` if the version carries none
