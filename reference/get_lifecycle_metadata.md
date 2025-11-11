# Retrieve metadata from Lifecycle Journal

Retrieve metadata from Lifecycle Journal via CrossRef API

## Usage

``` r
get_lifecycle_metadata(identifier)
```

## Arguments

- identifier:

  Either a Lifecycle Journal submission ID (e.g., "10", "7") or a full
  DOI (e.g., "10.71240/lcyc.355146"). If the identifier doesn't contain
  a dot, it's treated as a submission ID and converted to a DOI.

## Value

A list containing parsed metadata with elements:

- title:

  Article title

- authors:

  List of authors, each with `name` and optionally `ORCID`

- abstract:

  Article abstract (if available)

- reference:

  The DOI URL

- date:

  Publication date

## Details

Fetches article metadata from the Lifecycle Journal using either a
submission ID or a DOI. The metadata includes title, authors with
ORCIDs, abstract, and publication date.

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # Using submission ID
  meta <- get_lifecycle_metadata("10")

  # Using full DOI
  meta <- get_lifecycle_metadata("10.71240/lcyc.355146")
} # }
```
