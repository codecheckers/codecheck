# Whether a value is a well-formed constant

A constant names an item, unless it is marked \`pending\`: the item does
not exist yet, and no export emits a statement that depends on it. The
marker is deliberate - a model that quietly dropped such a statement
would hide the fact that something still has to be created.

## Usage

``` r
check_constant_value(value, at)
```

## Arguments

- value:

  a statement or qualifier value definition

- at:

  a prefix describing where the value sits, for the message

## Value

a character vector of problems, empty when the value is fine
