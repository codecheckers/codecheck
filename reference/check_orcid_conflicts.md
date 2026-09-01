# Check for ORCIDs and names used inconsistently across the register

Surfaces the two shapes of data-entry error a person page would
otherwise make visible only by an odd-looking page
(codecheckers/register#123): the same ORCID attached to two different
people's names (typically one certificate's data copied from another and
only the name changed), or the same name attached to two different
ORCIDs (typically a typo in the ORCID). Deliberately a warning, not a
stop - the source \`codecheck.yml\` files are fixed by hand, separately,
this only needs to point at them.

## Usage

``` r
check_orcid_conflicts(certs, orcids, names)
```

## Arguments

- certs, orcids, names:

  Character vectors, same length/order: one row per (certificate,
  ORCID-bearing person) pair, from either a paper author or a
  codechecker (see \[add_person_records()\], whose per-row logic this
  mirrors for the whole register at once).

## Value

None; a \`warning()\` per conflict found.
