# Apply a model transform to a register value

The transforms the model's value definitions name. Each is small, and
each exists because the register stores something in the shape a human
reads and Wikidata stores it in the shape a query matches.

## Usage

``` r
wikidata_transform(x, transform = NULL)
```

## Arguments

- x:

  the raw value

- transform:

  the transform name, or \`NULL\` for none

## Value

the transformed value, \`NA\` when there is nothing to transform
