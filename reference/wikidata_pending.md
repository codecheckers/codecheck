# The statements waiting on an item that does not exist yet

Emitters skip these, so this is the list of things still to create
before the export is complete. Currently the interim \`P528\` catalog
code, which needs an item for the register itself.

## Usage

``` r
wikidata_pending()
```

## Value

a \`data.frame\` with columns \`entity\`, \`key\`, \`property\` and
\`pending\`

## Examples

``` r
wikidata_pending()
#>        entity          key property
#> 1 certificate catalog_code     P528
#>                                                             pending
#> 1 the CODECHECK register catalog item, created with the first batch
```
