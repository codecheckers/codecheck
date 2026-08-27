# Check that a repository is archived

The checked repository should be archived (read-only) once the check is
complete, see codecheckers/codecheck#25. Only applies to GitHub/GitLab
repositories; a lookup failure degrades to a no-op rather than aborting
the whole register check.

## Usage

``` r
check_repository_archived(entry, spec)
```

## Arguments

- entry:

  The registry entry

- spec:

  The parsed repository spec, see \`parse_repository_spec()\`

## Value

None
