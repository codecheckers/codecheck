# Evaluate one value definition against a register row

Returns zero, one or several values: zero when the row has nothing to
say (the statement is then simply not written, which is how a paper
without a venue gets no \`published in\`), several when the field holds
several - a certificate with three codecheckers gets three \`author\`
statements.

## Usage

``` r
evaluate_model_value(value, row, resolve = NULL)
```

## Arguments

- value:

  a value definition from the model

- row:

  a one-row \`data.frame\` or list of register fields

- resolve:

  a function \`(entity_kind, key) -\> local id or NA\`, used for
  \`entity\` values; \`NULL\` resolves nothing

## Value

a character vector of values, empty when the statement does not apply
