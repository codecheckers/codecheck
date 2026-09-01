# The CODECHECK Wikidata model

One target-neutral description of what a CODECHECK certificate looks
like as linked data, read by the export generator, the identifier
resolution and the Wikibase bootstrap. Property numbers are the Wikidata
ones; the CODECHECK Wikibase carries its own P-numbers and maps them
back through a "Wikidata entity" property, so this model stays the
single source for both.

## Usage

``` r
WIKIDATA_MODEL
```

## Details

Each entry describes one kind of entity:

- \`label\`, \`description\`:

  whisker templates over the register columns

- \`resolve\`:

  how an existing item is found rather than created: the identifier
  property, the register column holding the identifier, the
  transformation applied to it, and the endpoint that serves that kind
  of entity

- \`create\`:

  whether the export may create such an item on each target. Only
  certificates are created on Wikidata; papers, people and venues are
  resolved there and created only in our own Wikibase, which mirrors
  everything.

- \`statements\`:

  the statement definitions, see \[wikidata_statement()\]

A statement's \`value\` is one of:

- \`list(kind = "constant", item = "Q…")\`:

  a fixed item

- \`list(kind = "field", field = "…", transform = "…")\`:

  a register column, optionally passed through a named transformation

- \`list(kind = "entity", entity = "…", field = "…")\`:

  a reference to another entity of the model, resolved to a QID before
  emission; when it cannot be resolved the statement is omitted rather
  than guessed

- \`list(kind = "switch", field = "…", cases = list(…), default =
  "Q…")\`:

  an item chosen by the value of a register column

- \`list(kind = "mapped", field = "…", transform = "…", map = "…")\`:

  an item looked up in a named map, after the field has been passed
  through the transformation

The register columns referenced are those of the preprocessed register
table, the same ones \`render_register_full()\` writes to
\`register-full.json\`.

## See also

\[wikidata_properties()\] for the flat property list, and
\[validate_wikidata_model()\] for the invariants this structure must
satisfy
