# The number of directory levels a directory is below the "docs" folder

The number of directory levels a directory is below the "docs" folder

## Usage

``` r
docs_depth(dir)
```

## Arguments

- dir:

  A directory path containing the "docs" folder, e.g.
  "docs/certs/2024-001", "./docs/" or "/srv/register/docs/statistics".
  The last "docs" counts, so a "docs" folder further up an absolute path
  does not; a relative path without a "docs" folder counts from its
  first component.

## Value

0 for "docs" itself, 2 for "docs/certs/2024-001"
