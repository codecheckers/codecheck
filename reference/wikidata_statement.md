# Build one statement definition

Build one statement definition

## Usage

``` r
wikidata_statement(
  key,
  property,
  label,
  value,
  required = FALSE,
  note = NULL,
  venue_types = NULL,
  qualifiers = NULL
)
```

## Arguments

- key:

  internal name of the statement, unique within its entity kind

- property:

  the Wikidata property, e.g. "P31"

- label:

  the property's English label, for the human-readable exports

- value:

  how the value is obtained, see \[WIKIDATA_MODEL\]

- required:

  whether a certificate without this value is an error rather than an
  omission

- note:

  why the statement is modelled this way, shown in the model
  documentation and in review

- venue_types:

  optional character vector restricting the statement to certificates of
  these venue types

- qualifiers:

  optional list of qualifier definitions, each a list with \`property\`,
  \`label\` and \`value\` of the same shape as a statement's own

## Value

a statement definition list
