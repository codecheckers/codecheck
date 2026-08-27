# Check that a repository advertises the "codecheck" topic tag

The community workflow asks codecheckers to tag the checked repository
with the \`codecheck\` topic, see codecheckers/codecheck#14 and
\<https://github.com/search?q=topic A missing topic is informational
only, not a defect, so this reports via \`cli::cli_alert_info()\` rather
than \`warning()\`, matching \`check_repository_badge()\`.

## Usage

``` r
check_repository_topic(entry, spec)
```

## Arguments

- entry:

  The registry entry

- spec:

  The parsed repository spec, see \`parse_repository_spec()\`

## Value

None
