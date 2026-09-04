# What to say when the register's report DOI is not version-specific

Following the redirect is right for the run at hand, but a DOI that
resolves to whatever the latest version happens to be is not a stable
reference to a published certificate. The message therefore names the
version-specific DOI to record in its place.

## Usage

``` r
zenodo_version_doi_message(id, current)
```

## Arguments

- id:

  The record id the register points at

- current:

  The record id it redirects to

## Value

The warning text
