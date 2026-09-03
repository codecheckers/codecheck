# Every property the model uses, as a flat table

The list a reviewer wants to see, and the input the CODECHECK Wikibase
bootstrap needs: it creates one local property per row and records the
Wikidata counterpart on it.

## Usage

``` r
wikidata_properties()
```

## Value

a \`data.frame\` with columns \`entity\`, \`key\`, \`role\`,
\`property\`, \`label\`, \`datatype\`, \`value_kind\`, \`required\` and
\`note\`, one row per statement, qualifier and reference property. A
reference belongs to every statement rather than to one entity kind, so
its \`entity\` is \`NA\`.

## Details

Qualifiers and references are listed alongside the statements, because a
Wikibase needs a property for each of them just as much: a \`P528\`
catalog code cannot be written without its \`P972\` catalog qualifier,
and no statement can carry its reference without \`P854\` and \`P813\`.
The model writes reference properties in QuickStatements' \`S\` form;
they are property ids like any other and are reported as such.

## Examples

``` r
wikidata_properties()[, c("entity", "role", "property", "label")]
#>         entity      role property                              label
#> 1  certificate statement      P31                        instance of
#> 2  certificate statement   P13046 publication type of scholarly work
#> 3  certificate statement    P1476                              title
#> 4  certificate statement     P356                                DOI
#> 5  certificate statement     P577                   publication date
#> 6  certificate statement      P50                             author
#> 7  certificate statement    P2093                 author name string
#> 8  certificate statement    P6977                          review of
#> 9  certificate statement     P973                   described at URL
#> 10 certificate statement     P528                       catalog code
#> 11 certificate qualifier     P972                            catalog
#> 12 certificate statement     P953         full work available at URL
#> 13 certificate statement    P1324         source code repository URL
#> 14 certificate statement    P1433                       published in
#> 15 certificate statement    P1343                described by source
#> 16       paper statement      P31                        instance of
#> 17       paper statement     P356                                DOI
#> 18       paper statement    P1476                              title
#> 19       paper statement    P2093                 author name string
#> 20       paper statement   P10283                        OpenAlex ID
#> 21       paper statement     P577                   publication date
#> 22       paper statement    P1433                       published in
#> 23      person statement      P31                        instance of
#> 24      person statement     P496                           ORCID iD
#> 25       venue statement     P236                               ISSN
#> 26       venue statement     P856                   official website
#> 27        <NA> reference     P854                      reference URL
#> 28        <NA> reference     P813                          retrieved
```
