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
#> 1 rules-2.0.yml          2.0    58 101d109e3e872fd721569736a456c7a1e46f9009
#> 2 rules-1.0.yml          1.0    55 101d109e3e872fd721569736a456c7a1e46f9009
#>                commit_date                retrieved
#> 1 2026-09-19T19:11:34+0000 2026-09-21T11:16:52+0200
#> 2 2026-09-19T19:11:34+0000 2026-09-21T11:16:52+0200
#>                                                            source
#> 1 https://raw.githubusercontent.com/codecheckers/register/master/
#> 2 https://raw.githubusercontent.com/codecheckers/register/master/
#>                       via                              md5
#> 1 local register checkout fea4abd9612153c63de3b675c98c72eb
#> 2 local register checkout d777433e8ecf1589b4e28f1f7551f8f8
```
