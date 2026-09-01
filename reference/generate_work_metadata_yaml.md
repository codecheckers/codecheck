# Generate the work metadata YAML frontmatter block for register.md

Same fields as \[generate_work_metadata_html()\] and the JSON \`work\`
field, as YAML lines for register.md's frontmatter header rather than an
HTML block in the body (see \[generate_venue_metadata_yaml()\]).

## Usage

``` r
generate_work_metadata_yaml(table_details, register_table)
```

## Arguments

- table_details, register_table:

  See \[get_work_metadata_fields()\].

## Value

A YAML string (ending in a newline), or \`""\` if there is nothing to
add.
