# Fetch a \`codecheck.yml\` without aborting the whole render

The register is rendered from 130+ \`codecheck.yml\` files spread over
GitHub, OSF, GitLab and Zenodo, and every one of them is a chance for a
rate limit, an outage or a moved repository. A single such failure must
degrade the one entry it concerns, not stop the render of all the
others - so every enrichment loop below goes through this wrapper, which
turns the error into a warning naming the certificate
(\`register_render()\` collects and reports those at the end) and
returns \`NULL\`, the same value the loops already handle for a
repository without a \`codecheck.yml\`.

## Usage

``` r
get_codecheck_yml_or_null(repo, cert_id = NULL)
```

## Arguments

- repo:

  The repository specification, i.e. the \`Repository\` column

- cert_id:

  The certificate identifier, for the warning message

## Value

The parsed \`codecheck.yml\`, or \`NULL\` if it could not be retrieved
