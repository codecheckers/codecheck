# Look up the ROR-identified affiliations on a public ORCID record

Reads the \`employments\`, \`educations\` and \`qualifications\`
sections of an ORCID record from the public, unauthenticated ORCID API
(<https://pub.orcid.org>) - the same API \[get_orcid_name_public()\]
uses, and the only one that works for other people's records.

## Usage

``` r
get_orcid_affiliations_result(orcid)
```

## Arguments

- orcid:

  An ORCID identifier (NNNN-NNNN-NNNN-NNNX).

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`, a
data frame with one row per affiliation and the columns \`section\`,
\`organization\`, \`ror\` (the bare ROR id, \`NA\` when not
ROR-identified), \`start\` and \`end\` (the raw ORCID date lists, see
\[orcid_date_covered()\]).

## Details

An affiliation's organisation is only counted as ROR-identified when
ORCID itself records \`disambiguation-source: ROR\`. Most affiliations
are disambiguated against RINGGOLD, GRID or FundRef instead, or not at
all; mapping those to a ROR would be a guess, and register#53 needs to
know what the profiles actually assert.
