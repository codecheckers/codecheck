# Read a previously rendered certificate's value at a JSON key path

The per-certificate \`index.json\` written by
[`generate_cert_json`](http://codecheck.org.uk/codecheck/reference/generate_cert_json.md)
is the closest thing the register has to a durable record of externally
enriched fields (OpenAlex ID, abstract): unlike the on-disk lookup
cache, it is committed to the repository and survives
[`register_clear_cache`](http://codecheck.org.uk/codecheck/reference/register_clear_cache.md).
[`resolve_external_field`](http://codecheck.org.uk/codecheck/reference/resolve_external_field.md)
reads it as the fallback when this render's live lookup did not produce
a usable answer.

## Usage

``` r
read_previous_cert_field(cert_id, json_key_path)
```

## Arguments

- cert_id:

  Certificate identifier, e.g. "2020-018"

- json_key_path:

  Character vector naming the nested keys to read, e.g. \`c("paper",
  "openalex")\`

## Value

The value at that path, or \`NULL\` if the file, or the path within it,
does not exist
