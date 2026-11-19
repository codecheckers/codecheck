# Where the bundled rules came from

The rule files are copied into this package from the register repository
by \[update_codecheck_rules()\], which records what it fetched. Without
that record a bundled copy is an undated snapshot, and a rule that
changed in the register cannot be told apart from one that never did.

## Usage

``` r
codecheck_rules_provenance()
```

## Value

A data frame with one row per bundled rule file and the columns
\`file\`, \`spec_version\`, \`rules\` (how many the file holds),
\`commit\` (the register commit the file was taken from),
\`commit_date\`, \`retrieved\` (when \[update_codecheck_rules()\] ran),
\`source\`, \`via\` and \`md5\`. \`commit\` and \`commit_date\` are
\`NA\` when the register's history was not reachable at the time.
\`via\` says whether the files were downloaded or taken from a local
register checkout.

## See also

\[codecheck_rules()\], \[update_codecheck_rules()\]

## Examples

``` r
codecheck_rules_provenance()
#>            file spec_version rules                                   commit
#> 1 rules-2.0.yml          2.0    65 5dda297b0009195be43c867ecc301ca54fac2cc8
#> 2 rules-1.0.yml          1.0    60 65c7d224e0a529036357400367adcd4441c1531d
#>                commit_date                retrieved
#> 1 2026-11-19T11:22:23+0000 2026-11-19T12:29:47+0100
#> 2 2026-10-20T08:50:04+0000 2026-11-19T12:29:47+0100
#>                                                            source
#> 1 https://raw.githubusercontent.com/codecheckers/register/master/
#> 2 https://raw.githubusercontent.com/codecheckers/register/master/
#>                       via                              md5
#> 1 local register checkout 0505809908d3c86469984553b92dede1
#> 2 local register checkout dcf4dc70de9880866aff21247e145bd1
```
