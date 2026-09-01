# The CODECHECK Wikidata model

The description of how a CODECHECK certificate, and the paper, person
and venue it refers to, are represented as linked data. Exported so the
model can be inspected and reviewed on its own, without running an
export.

## Usage

``` r
wikidata_model()
```

## Value

the model, a named list of entity kinds; see \[WIKIDATA_MODEL\] for the
structure

## Examples

``` r
names(wikidata_model())
#> [1] "certificate" "paper"       "person"      "venue"      
vapply(wikidata_model()$certificate$statements, function(s) s$property, character(1))
#>  [1] "P31"    "P13046" "P1476"  "P356"   "P577"   "P50"    "P2093"  "P6977" 
#>  [9] "P973"   "P528"   "P953"   "P1324"  "P1433"  "P1343" 
```
