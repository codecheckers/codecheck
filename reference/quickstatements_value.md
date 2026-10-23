# Render one value as QuickStatements v1 writes it

QuickStatements takes a statement's string value literally between its
enclosing quotes, so a quote inside it must not be escaped: the batch
that created the works stored the backslashes of \`How close is
\\close\\?\` as part of the title (Q141269461). A label or description
is unescaped by QuickStatements - the same item's label came out right -
so those keep the escaping.

## Usage

``` r
quickstatements_value(datatype, value, escape = FALSE)
```

## Arguments

- datatype:

  the property's Wikibase datatype

- value:

  the value

- escape:

  whether to escape double quotes, for labels and descriptions

## Value

the value as a QuickStatements token
