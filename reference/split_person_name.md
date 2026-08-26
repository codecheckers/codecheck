# Split a person name into given and family name

Split a person name into given and family name

## Usage

``` r
split_person_name(name)
```

## Arguments

- name:

  a single character string

## Value

list with elements \`given\` and \`family\`; \`family\` is NULL if the
name could not be split.

## Details

Accepts both "Family, Given" and "Given Middle Family" spellings, which
are both in use in the \`codechecker\` entries of \`codecheck.yml\`
files. When no sensible split is possible (a single token, e.g. a group
name), \`family\` is NULL and the caller should fall back to recording
an organisation.

## Author

Daniel Nuest
