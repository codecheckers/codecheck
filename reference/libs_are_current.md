# Check Whether the Local External Libraries Are Up To Date

The local copies are considered current when every expected file exists
and is of a plausible size, and when \`PROVENANCE.csv\` records exactly
the libraries and versions of the current specification.

## Usage

``` r
libs_are_current(libs_dir, libraries = external_library_specs())
```

## Arguments

- libs_dir:

  Libraries directory

- libraries:

  Library specifications, see \[external_library_specs()\]

## Value

\`TRUE\` if no download is needed, \`FALSE\` otherwise
