# Creates index postfix, prefix and the header

Creates index postfix, prefix and the header

## Usage

``` r
create_index_section_files(
  output_dir,
  filter,
  table_details,
  schema_org_jsonld = "",
  signposting = ""
)
```

## Arguments

- output_dir:

  The output directory of the section files

- filter:

  The filter name

- table_details:

  List containing details such as the table name, subcat name.

- schema_org_jsonld:

  Optional Schema.org JSON-LD string to include in header (default: "")

- signposting:

  Optional FAIR Signposting \`\<link\>\` elements for the page, see
  \[generate_page_signposting()\] (default: "")
