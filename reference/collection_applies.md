# Does a collection apply to a certificate from this venue?

A collection without a \`venues\` restriction applies to every
certificate. One with a restriction, like Reproducible AGILE, applies
only to the venues it names, and cannot be judged at all when the venue
is unknown.

## Usage

``` r
collection_applies(issue, venue)
```

## Arguments

- issue:

  a collection issue as returned by \[get_researchequals_collection()\]

- venue:

  the register venue of the certificate, may be NULL

## Value

TRUE if membership in the collection is required
