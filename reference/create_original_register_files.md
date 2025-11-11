# Generates original register files in various output formats.

Generates original register files in various output formats.

## Usage

``` r
create_original_register_files(register_table, outputs)
```

## Arguments

- register_table:

  The register table.

- outputs:

  List of the output types (e.g., "csv", "json").

  The function iterates through the provided output types, generates an
  output directory, filters and adjusts the register table, and renders
  the original register files based on the specified formats.
