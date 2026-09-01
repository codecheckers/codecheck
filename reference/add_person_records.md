# Add the \`Person\` grouping column to the register table

Builds, for every certificate, the union of its paper authors and its
codecheckers that carry an ORCID - name-only entries are dropped, per
\#123's explicit "we are not going down the rabbit hole of matching
names, disambiguation, etc." A person who is both author and codechecker
on the same certificate legitimately gets two records, distinguished by
\`role\`, so their person page can show the certificate under both
headings.

## Usage

``` r
add_person_records(register_table, register)
```

## Arguments

- register_table:

  The register table

- register:

  The register from register.csv

## Value

The register table with a \`Person\` list column added, each element a
list of \`list(orcid=, name=, role=)\` records ("author" or
"codechecker")

## Details

Also fills \`CONFIG\$DICT_ORCID_ID_NAME\` for authors that are not
already a known codechecker, so an author-only person page has a name to
title itself with. The codechecker list is authoritative when both
exist - \[add_codechecker()\] already populates it and always runs
first, in \[preprocess_register()\].
