# Removes the temporary files a page render writes into its output directory

Meant for on.exit(), so the files are also removed when
rmarkdown::render() fails. This includes the page's own libs/ folder,
except for a page in the "docs" folder itself, whose libs/ is the shared
"docs/libs".

## Usage

``` r
remove_render_temp_files(output_dir)
```

## Arguments

- output_dir:

  The output directory of the page.
