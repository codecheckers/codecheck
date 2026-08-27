# Check that a repository is in the codecheckers/cdchck organisation

A pure string check on the repository spec, no network call: registry
policy requires the checked repository to live in the \`codecheckers\`
GitHub organisation or the \`cdchck\` GitLab group (the same rule
already enforced for Zenodo records, see
\`check_register_zenodo_policy()\`). A violation stops the check for
this entry, it is not a hint to fix later.

## Usage

``` r
check_repository_org(entry, spec)
```

## Arguments

- entry:

  The registry entry

- spec:

  The parsed repository spec, see \`parse_repository_spec()\`

## Value

None
