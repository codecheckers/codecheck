# Normalize person fields of a codecheck.yml to lists of persons

The spec requires \`codechecker\` and \`paper\$authors\` to be lists of
persons, but a single person is often written as a plain mapping, which
yaml parses into a named character vector instead of a list of lists.
Wrap such cases so consumers can always iterate over persons and use
\`\$name\`/\`\$ORCID\`.

## Usage

``` r
normalize_person_lists(config_yml)
```

## Arguments

- config_yml:

  the parsed codecheck.yml, may be NULL

## Value

the codecheck.yml with normalized person lists
