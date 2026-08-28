# Render the register-wide statistics dashboard page

Builds \`docs/statistics/index.html\` from the already-written
\`docs/statistics.json\` (addresses register#33, register#48): a
checks-over-time timeline, a platform-per-year breakdown, a venue grid
(grouped by type, with logo/link metadata from \`venues.csv\` where
available) and a publisher summary table. Must run after
\`docs/statistics.json\` has been written (i.e. after
\[create_register_files()\] or \[register_update_stats()\]), since it
only reads that file - it does not recompute statistics itself.

## Usage

``` r
render_statistics_page(docs_dir = "docs")
```

## Arguments

- docs_dir:

  Path to the docs output directory (default: "docs")

## Author

Daniel Nuest
