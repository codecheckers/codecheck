# Generate redirect pages for every person with a GitHub handle

Iterates every ORCID-identified person in the register (author or
codechecker, see \[add_person_records()\]) and creates a
\`docs/persons/\<handle\>/\` redirect for those whose ORCID resolves to
a known GitHub handle via \[resolve_codechecker_profile()\] - the same
lookup used for the codechecker panel, so "known" here means "listed in
one of the codecheckers/codecheckers CSVs", which in practice means
every such person is also a codechecker (there is no equivalent list of
paper authors' GitHub handles).

## Usage

``` r
generate_person_redirects(register_table)
```

## Arguments

- register_table:

  The preprocessed register table, with a \`Person\` list column.

## Value

Invisibly returns the count of redirect pages created.
