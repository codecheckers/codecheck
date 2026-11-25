# The type of each checked work, asking the registry where the render has none

A render whose registry lookup failed leaves the type out of the
certificate's JSON, as it does for a DOI without a record, and
\[paper_kind()\] would then type the work by the register's venue: a
wrong \`P31\` to write, or a right one to remove. So the export asks
again, through the same cache, and stops if the registry still cannot be
asked.

## Usage

``` r
registry_reference_types(certificates)
```

## Arguments

- certificates:

  the certificates of \[read_register_records()\]

## Value

the \`Paper reference type\` column, filled where the registry knows it
