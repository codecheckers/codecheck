# Detect the publication platform from a report URL

Extracts a human-readable platform name from the report URL's domain.
For doi.org URLs, resolves the DOI to determine the actual hosting
platform.

## Usage

``` r
detect_report_platform(url)
```

## Arguments

- url:

  A report URL string

## Value

A lowercase platform name (e.g., "zenodo", "osf", "researchequals")
