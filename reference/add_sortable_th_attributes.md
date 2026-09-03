# Adds data-sort hints to \<th\> cells so stupidtable.js (see table-sort-init.js) knows which columns are sortable and how to compare their values.

stupidtable.js treats a \<th\> with no data-sort attribute as
unsortable, so this only needs to opt sortable columns in: "string" for
plain text/ISO dates (which already sort correctly lexicographically),
"int" for the known numeric count columns, and nothing at all for
Report/Work, whose cells hold titles/links rather than sortable values,
or "Check types" (register#92), whose cells hold a stacked bar with no
comparable value.

## Usage

``` r
add_sortable_th_attributes(html_file_path)
```

## Arguments

- html_file_path:

  The path to the rendered index.html file.
