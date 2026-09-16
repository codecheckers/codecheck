# A person's fediverse account

persons.csv first, since the register's own record of a person wins,
then the codechecker lists.

## Usage

``` r
person_fediverse(orcid = NULL, profile = NULL)
```

## Arguments

- orcid:

  The person's ORCID, or \`NULL\`.

- profile:

  The person's codechecker profile, see
  \[resolve_codechecker_profile()\], or \`NULL\`.

## Value

\`@user@instance\`, or \`NULL\`.
