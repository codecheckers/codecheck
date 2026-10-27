# The statements an existing item is missing, and those it should lose

Compares the commands the model would write on an item with the claims
the item has. A statement whose value is there already is dropped; one
whose property the item does not carry at all is an addition; one whose
property it carries with other values is a difference, reported but
never written.

## Usage

``` r
wikidata_missing_statements(
  commands,
  claims,
  item = NULL,
  properties = character(0),
  rejected = list(),
  author_names = character(0)
)
```

## Arguments

- commands:

  the commands for the item, from \[quickstatements_for_entity()\] with
  its QID

- claims:

  the item's claims, as \`wbgetentities\` returns them

- item:

  the item's QID, needed for removals

- properties:

  the properties the model writes on this kind of item; empty for no
  removals

- rejected:

  a named list, property to the values (as \[wikidata_claim_key()\]
  gives them) known to be wrong for this item

- author_names:

  the names (labels and aliases) of the item's authors as items
  (\`P50\`), see \[wikidata_item_names()\]: a name string (\`P2093\`)
  that is one of them is an author the item has already

## Value

a \`data.frame\` with \`property\`, \`proposed\`, \`current\`,
\`action\` (\`"add"\`, \`"differs"\`, \`"remove"\` or \`"shared"\`) and
\`command\`

## Details

Given the item and the model's properties, it also looks the other way,
at the claims the export wrote alone (see
\[wikidata_claim_provenance()\]). One of those is a removal when its
value is known to be wrong - listed in \`rejected\`, such as an OpenAlex
ID whose record turned out to be another work's - or when the model now
writes another value for the property, such as a corrected title. A
property the model writes nothing for is left as it is: that the
register no longer knows a value does not make the value wrong. The
removed claim no longer counts as carried, so its replacement is an
addition rather than a difference. A claim the export wrote together
with somebody else is reported as \`"shared"\` and left alone.
