# Regenerate all statistics files from existing register.json files

Fast alternative to a full re-render when only the stats computation has
changed. Reads the already-generated register.json files under \`docs/\`
and rewrites \`docs/statistics.json\` (the main register's file, read by
\[render_statistics_page()\]) and every sub-register's \`stats.json\`
(\`index.json\` for a venue, which also gets its structured venue
metadata), with up-to-date statistics (including annual and cumulative
breakdowns for the main file).

## Usage

``` r
register_update_stats(
  docs_dir = "docs",
  config = system.file("extdata", "config.R", package = "codecheck"),
  venues_file = "venues.csv"
)
```

## Arguments

- docs_dir:

  Path to the docs output directory (default: "docs")

- config:

  Path to the config.R file

- venues_file:

  Path to the venues.csv file containing venue names, labels and
  optional metadata (logo_url, website_url, policy_url, publisher)

## Author

Daniel Nuest
