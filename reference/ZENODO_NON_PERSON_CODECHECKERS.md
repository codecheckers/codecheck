# Register entries that name a group rather than an individual

\[build_zenodo_contributors()\] must not credit a group of people as if
it were one contributor, so a \`codechecker\` name known to refer to a
group - rather than an unresolved individual - is excluded by this
explicit, documented list instead of some heuristic (e.g. "no ORCID and
no GitHub handle") that would also catch individuals who simply lack
both.

## Usage

``` r
ZENODO_NON_PERSON_CODECHECKERS
```

## Details

\- "Delft 2024-05 participants" (register#58): the collective name used
in \`codecheck.yml\` for a group check during a 2024 Delft workshop, not
a single person.
