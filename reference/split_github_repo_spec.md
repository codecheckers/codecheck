# Split a GitHub repo spec into org, repo and an optional sub-path

Repository specs from \`register.csv\` are \`org/repo\` or
\`org/repo\|path\` (the latter used when the \`codecheck.yml\` lives in
a sub-directory). Repo metadata (archived status, README, license)
applies to the whole repo, so callers that only need \`org\`/\`repo\`
can drop the \`path\` piece.

## Usage

``` r
split_github_repo_spec(x)
```

## Arguments

- x:

  the \`org/repo\` or \`org/repo\|path\` spec

## Value

a named list with \`org\` and \`repo\`
