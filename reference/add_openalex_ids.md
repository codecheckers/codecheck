# Add OpenAlex work IDs to the register table (addresses register#185)

Unlike the per-certificate index.json (rendered via
[`resolve_external_field`](http://codecheck.org.uk/codecheck/reference/resolve_external_field.md)),
this table feeds the aggregate outputs (docs/register.json and the
venue-filtered json/csv) directly, so it needs the same protection: a
lookup that merely failed this run (rate limit, network blip) must fall
back to the certificate's existing index.json rather than overwrite a
previously-known-good ID with NA - the same regression
[`resolve_external_field`](http://codecheck.org.uk/codecheck/reference/resolve_external_field.md)
exists to prevent, just reached through a different render path.

## Usage

``` r
add_openalex_ids(register_table, register)
```

## Arguments

- register_table:

  The register table

- register:

  The register from the register.csv file

## Value

The register table with added "OpenAlex" column
