# Every property the model uses, as a flat table

The list a reviewer wants to see, and the input the CODECHECK Wikibase
bootstrap needs: it creates one local property per row and records the
Wikidata counterpart on it.

## Usage

``` r
wikidata_properties()
```

## Value

a \`data.frame\` with columns \`entity\`, \`key\`, \`property\`,
\`label\`, \`value_kind\`, \`required\` and \`note\`, one row per
statement definition

## Examples

``` r
wikidata_properties()[, c("entity", "property", "label")]
#>         entity property                              label
#> 1  certificate      P31                        instance of
#> 2  certificate   P13046 publication type of scholarly work
#> 3  certificate    P1476                              title
#> 4  certificate     P356                                DOI
#> 5  certificate     P577                   publication date
#> 6  certificate      P50                             author
#> 7  certificate    P2093                 author name string
#> 8  certificate    P6977                          review of
#> 9  certificate     P973                   described at URL
#> 10 certificate     P528                       catalog code
#> 11 certificate     P953         full work available at URL
#> 12 certificate    P1324         source code repository URL
#> 13 certificate    P1433                       published in
#> 14 certificate    P1343                described by source
#> 15       paper      P31                        instance of
#> 16       paper     P356                                DOI
#> 17       paper    P1476                              title
#> 18       paper    P1433                       published in
#> 19      person      P31                        instance of
#> 20      person     P496                           ORCID iD
#> 21       venue     P236                               ISSN
#> 22       venue     P856                   official website
```
