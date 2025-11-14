# Set "Title" and "Paper reference" columns for CSV files

Extracts plain text title and paper reference URL from the preprocessed
register table. If the table has a "Paper Title" column (hyperlinked),
extracts from that. Otherwise, fetches from codecheck.yml files.

## Usage

``` r
set_paper_title_references_csv(register_table)
```

## Arguments

- register_table:

  The register table

## Value

Updated register table including "Title" and "Paper reference" columns
