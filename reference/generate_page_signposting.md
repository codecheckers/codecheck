# Signposting links for any non-certificate register page

Dispatches on the same \`filter\`/\`table_details\` pair the Schema.org
generation in
[`render_html`](http://codecheck.org.uk/codecheck/reference/render_html.md)
already switches on, so the two descriptions of a page cannot drift
apart.

## Usage

``` r
generate_page_signposting(
  filter,
  table_details,
  register_table = NULL,
  has_jsonld = FALSE
)
```

## Arguments

- filter:

  The filter name (\`NA\` for the main register, else "venues", "works",
  "persons", "codecheckers", ...)

- table_details:

  List containing details such as the table name and subcat name

- register_table:

  The page's register rows, needed for a work page's author ORCIDs

- has_jsonld:

  Whether \`index.jsonld\` was written next to the page

## Value

HTML string of \`\<link\>\` elements, one per line
