# Dynamically generates the index_header.html from a template file

Dynamically generates the index_header.html from a template file

## Usage

``` r
create_index_header_html(
  output_dir,
  schema_org_jsonld = "",
  include_version_in_meta = TRUE
)
```

## Arguments

- output_dir:

  The output directory

- schema_org_jsonld:

  Optional Schema.org JSON-LD string to include in header (default: "")

- include_version_in_meta:

  Whether to include version info in meta generator tag (default: TRUE).
  Set to FALSE for individual detail pages (will use "codecheck" only).
