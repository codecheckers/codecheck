# Check that a repository advertises the CODECHECK badge

The community workflow asks codecheckers to add a CODECHECK badge to the
original repository, see codecheckers/codecheck#75. A missing badge is
informational only, not a defect, so this reports via
\`cli::cli_alert_info()\` rather than \`warning()\`.

## Usage

``` r
check_repository_badge(entry, spec)
```

## Arguments

- entry:

  The registry entry

- spec:

  The parsed repository spec, see \`parse_repository_spec()\`

## Value

None
