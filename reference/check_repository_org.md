# Check that a repository is in an allowed organisation/group

A pure string check on the repository spec, no network call: registry
policy requires the checked repository to live in one of the GitHub
organisations or GitLab groups listed in \`CONFIG\$ALLOWED_REPO_ORGS\`
(the \`codecheckers\` org and \`cdchck\` group by default, see the same
rule enforced for Zenodo records in \`check_register_zenodo_policy()\`).
Add further trusted orgs/groups by extending
\`CONFIG\$ALLOWED_REPO_ORGS\` in \`config.R\`. A violation stops the
check for this entry, it is not a hint to fix later.

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
