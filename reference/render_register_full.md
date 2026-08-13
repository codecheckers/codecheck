# Build a full metadata register from the preprocessed register table

Enriches the register with all available fields from each codecheck.yml,
including paper authors, codechecker details, summary, and source.
Writes register-full.json and register-full.csv (addresses register#57).

## Usage

``` r
render_register_full(register_table, output_dir)
```

## Arguments

- register_table:

  The full preprocessed register table

- output_dir:

  The output directory (e.g., "docs/")
