# Resolve a ResearchEquals report reference to a version ID

A ResearchEquals DOI redirects to the page of one version of an output,
\`https://researchequals.com/en-US/versions/\<version id\>\`, and the
API is keyed by that version ID, see \[get_researchequals_cert_link()\].

## Usage

``` r
get_researchequals_version_id(report_link)
```

## Arguments

- report_link:

  a ResearchEquals DOI, DOI URL, version URL or version ID

## Value

the version ID as a string, or NULL if it cannot be resolved
