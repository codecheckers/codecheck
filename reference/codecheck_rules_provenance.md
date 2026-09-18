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
#> 1 rules-2.0.yml          2.0    58 cbe34cbd4a0d294a6e6e8cb2f3b4cd1d10ad121c
#> 2 rules-1.0.yml          1.0    55 cbe34cbd4a0d294a6e6e8cb2f3b4cd1d10ad121c
#>            commit_date                retrieved
#> 1 2026-09-09T12:42:35Z 2026-09-11T16:54:36+0200
#> 2 2026-09-09T12:42:35Z 2026-09-11T16:54:36+0200
#>                                                            source      via
#> 1 https://raw.githubusercontent.com/codecheckers/register/master/ download
#> 2 https://raw.githubusercontent.com/codecheckers/register/master/ download
#>                                md5
#> 1 4d4694e82f7b3a8ed9280f7c1b4630c4
#> 2 2a372677d688f24b3faa4ef40684e2e8
```
