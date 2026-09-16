# Refresh the bundled CODECHECK validation rules

Copies the rule files from the register into this package's sources and
records where they came from, see \[codecheck_rules_provenance()\]. This
is a maintenance function: it writes into a source checkout of the
package, not into an installed one, and the refreshed files are meant to
be committed.

## Usage

``` r
update_codecheck_rules(
  path = ".",
  from = NULL,
  spec_versions = codecheck_spec_versions()
)
```

## Arguments

- path:

  Root of the package source checkout to write into.

- from:

  The register to take the files from. A path to a local register
  checkout, or \`NULL\` to download from the register on GitHub.

- spec_versions:

  Specification versions to fetch, defaulting to the versions this
  package knows about.

## Value

Invisibly, the provenance data frame that was written.

## See also

\[codecheck_rules()\], \[codecheck_rules_provenance()\]

## Examples

``` r
if (FALSE) { # \dontrun{
update_codecheck_rules()
update_codecheck_rules(from = "../register")
} # }
```
