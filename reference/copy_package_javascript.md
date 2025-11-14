# Copy Package JavaScript Files to Output Directory

Copies JavaScript files from the package's inst/extdata/js directory to
the output directory's libs/codecheck subdirectory. This ensures
consistent JavaScript library versions across all generated pages.

## Usage

``` r
copy_package_javascript(output_dir = "docs")
```

## Arguments

- output_dir:

  Base output directory (default: "docs")

## Details

Currently copies: - citation.js: Citation formatting library -
cert-utils.js: Certificate page utilities (content display, image
slider) - cert-citation.js: Citation generator functions
