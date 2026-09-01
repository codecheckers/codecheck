# Check the model's invariants

Run by the tests, and worth running after any edit to
\[WIKIDATA_MODEL\]: the model is data, so a typo in it is not a syntax
error anywhere and would first show up as a wrong statement on a public
Wikidata item.

## Usage

``` r
validate_wikidata_model(model = WIKIDATA_MODEL)
```

## Arguments

- model:

  the model to check, the package's own by default

## Value

\`TRUE\` invisibly if the model is consistent; otherwise a character
vector of the problems found

## Examples

``` r
validate_wikidata_model()
```
