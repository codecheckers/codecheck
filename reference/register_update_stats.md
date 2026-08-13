# Regenerate all stats.json files from existing register.json files

Fast alternative to a full re-render when only the stats computation has
changed. Reads the already-generated register.json files under \`docs/\`
and rewrites every stats.json with up-to-date statistics (including
annual and cumulative breakdowns).

## Usage

``` r
register_update_stats(
  docs_dir = "docs",
  config = system.file("extdata", "config.R", package = "codecheck")
)
```

## Arguments

- docs_dir:

  Path to the docs output directory (default: "docs")

- config:

  Path to the config.R file

## Author

Daniel Nuest
