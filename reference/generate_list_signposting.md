# Signposting links for a listing or overview page

Listing pages are not scholarly objects, so they are outside the FAIR
Signposting profile and carry no \`cite-as\`. They do get the same
vocabulary of typed links, which is what makes the register's JSON and
CSV exports discoverable from the HTML rather than only from the
documentation.

## Usage

``` r
generate_list_signposting(
  is_main_register = FALSE,
  has_register_files = TRUE,
  has_index_json = FALSE
)
```

## Arguments

- is_main_register:

  Whether this is the unfiltered register page, which is the only one
  with the full CSV and JSON exports next to it

- has_register_files:

  Whether \`register.json\` and \`register.md\` sit next to the page;
  false for the overview pages that only list subpages

- has_index_json:

  Whether \`index.json\` sits next to the page, which is the case for
  the overview pages but not for the main register page

## Value

HTML string of \`\<link\>\` elements, one per line

## Details

They deliberately carry no \`item\` links to their member certificates:
\`item\` means a content resource of the described object - on a
certificate page, the PDF - and reusing it for list membership would
make those links ambiguous. Enumerating members is what a Level 2 link
set is for, which GitHub Pages cannot serve conformantly, see
[`signposting_link_tags`](http://codecheck.org.uk/codecheck/reference/signposting_link_tags.md).
