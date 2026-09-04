# Marks the lower-priority columns of the register tables so the stylesheet can hide them on a phone (see codecheck-register.css).

The tables have more columns than fit on a narrow screen, and the ones
listed below carry the least: a Report or DOI link whose target is
reachable from the row's own certificate or work page, a Type that
repeats what the Venue label already says, an ORCID next to a name that
links to the same person page, a Check types bar with no textual value.
Everything stays in the markup - and in the JSON, CSV and Markdown
exports, which this does not touch - so widening the window brings the
columns back.

## Usage

``` r
add_column_priority_classes(html_file_path)
```

## Arguments

- html_file_path:

  The path to the rendered index.html file.

## Details

A table whose header row has none of these columns is left untouched.
