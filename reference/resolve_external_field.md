# Resolve an externally enriched field, protecting it from transient failures

Every render re-fetches externally enriched fields (currently the
OpenAlex ID and the CrossRef/OpenAlex abstract) from scratch, and
`docs/` is fully regenerated each time - so a lookup that merely failed
this run (rate limiting, a network blip) would otherwise overwrite a
previously-known-good value with nothing, once per output format that
looks the value up. This function is the single place that decides what
a certificate's rendered output should show for such a field, given this
run's lookup outcome and whatever the certificate's existing
\`index.json\` already says (register#185, and the further regression
that motivated this function).

## Usage

``` r
resolve_external_field(
  cert_id,
  json_key_path,
  status,
  value,
  empty_value = NULL,
  prune_unavailable = FALSE
)
```

## Arguments

- cert_id:

  Certificate identifier, used to find the previous value

- json_key_path:

  Character vector naming the nested keys where this field lives in the
  certificate's \`index.json\`, e.g. \`c("paper", "openalex")\`

- status:

  This run's lookup status: \`"found"\`, \`"absent"\` or \`"failed"\`

- value:

  This run's lookup value (used only when \`status\` is \`"found"\`)

- empty_value:

  Value to return when neither this run nor the previous render has
  anything - the field's own "nothing here" shape, e.g.
  \`NA_character\_\` for the OpenAlex ID or \`list(source = NULL, text =
  NULL)\` for the abstract

- prune_unavailable:

  Logical; if \`TRUE\`, a confirmed \`"absent"\` result actually removes
  a previously-present value instead of keeping it. Defaults to
  \`FALSE\`. Set via \`register_render(prune_unavailable_metadata =
  TRUE)\`.

## Value

The resolved value to render for this certificate

## Details

\- \`"found"\`: the new value always wins. - \`"absent"\` (the API
conclusively has no such data): the previous value is kept unless
\`prune_unavailable\` is \`TRUE\` - DOIs and abstracts are not expected
to be retracted, so a confirmed absence is more often a query problem
than a real removal, and removing it is a deliberate, explicit action
rather than something a routine render does silently. - \`"failed"\` (no
conclusive answer - network error, rate limit): the previous value is
always kept, regardless of \`prune_unavailable\`. A non-response is
never treated as confirmation that the data is gone.
