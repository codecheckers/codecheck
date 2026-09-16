# Refresh what is cached about some certificates, see \[register_clear_cache()\]

Refresh what is cached about some certificates, see
\[register_clear_cache()\]

## Usage

``` r
clear_certificate_cache(certificates, register = "register.csv")
```

## Arguments

- certificates:

  Certificate identifiers, e.g. \`"2025-009"\`. \`NULL\`, the default,
  clears the whole cache.

- register:

  The register as a data frame, or a path to \`register.csv\`, used to
  find each certificate's repository.

## Value

The number of cache entries removed.
