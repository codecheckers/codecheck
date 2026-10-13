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
#> 1 rules-2.0.yml          2.0    62 557e9eaab155f4821feedbba0d6537b38373a386
#> 2 rules-1.0.yml          1.0    59 557e9eaab155f4821feedbba0d6537b38373a386
#>                commit_date                retrieved
#> 1 2026-10-13T10:15:10+0000 2026-10-13T12:15:36+0200
#> 2 2026-10-13T10:15:10+0000 2026-10-13T12:15:36+0200
#>                                                            source
#> 1 https://raw.githubusercontent.com/codecheckers/register/master/
#> 2 https://raw.githubusercontent.com/codecheckers/register/master/
#>                       via                              md5
#> 1 local register checkout a042015a9b914cd6553e76f045a3f34f
#> 2 local register checkout 22980765fe96918fc8cf1f67e71c5b44
```
