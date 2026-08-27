# Retrieve a person's name from the public ORCID API

Looks up the name on an ORCID record via the public, unauthenticated
ORCID API (<https://pub.orcid.org>). This works for any record whose
name is publicly visible and requires no ORCID token, unlike
[`orcid_person`](https://rdrr.io/pkg/rorcid/man/orcid_person.html),
whose personal-authentication tokens are only valid for reading the
authenticated user's own record.

## Usage

``` r
get_orcid_name_public(orcid_id)
```

## Arguments

- orcid_id:

  Character. An ORCID identifier (NNNN-NNNN-NNNN-NNNX).

## Value

Character name, or `NULL` if the record or name is not publicly
available or the request fails.
