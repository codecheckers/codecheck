# Whether a proposed value is one the item carries already

Keys as \[quickstatements_token_key()\] and \[wikidata_claim_key()\]
give them, compared as the property's values mean the same: a title
regardless of a trailing full stop, a date at the precision the item
stores it with - 1982-04-01 is in 1982-04, which Wikidata keeps as
\`1982-04-00\` - and a name string as a name (see
\[wikidata_name_key()\]).

## Usage

``` r
wikidata_value_present(property, proposed, current)
```

## Arguments

- property:

  the property

- proposed:

  one proposed key

- current:

  the keys the item has for the property

## Value

\`TRUE\` if one of \`current\` is the proposed value
