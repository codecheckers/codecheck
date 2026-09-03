# Read and write the register's record of the people on Wikidata

Resolved by ORCID rather than curated by hand, but written down all the
same: the file is what a render reads before asking Wikidata anything,
so a clone of the register renders the same links without network
access, and a person whose item appears is visible in the register's own
history rather than only in a cache directory.

## Usage

``` r
sync_persons_file(persons_file, resolved)
```

## Arguments

- persons_file:

  path to the CSV, or \`NULL\` to neither read nor write

- resolved:

  the ORCID-to-QID mapping this render resolved

## Value

the merged mapping
