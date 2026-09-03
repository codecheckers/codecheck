# The Wikibase datatypes the model uses

Wikidata knows a property's datatype already; the CODECHECK Wikibase
does not, and a property created with the wrong one cannot be changed
afterwards - it has to be deleted and recreated. The datatype is
therefore part of the model rather than something the bootstrap guesses.

## Usage

``` r
WIKIBASE_DATATYPES
```
