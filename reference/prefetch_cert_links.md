# Resolves every certificate's PDF link up front, in parallel

The links are needed by add_cert_pdf_links() when the main register.json
is written, one HTTP round trip each. Resolving them there, one after
another, was the single slowest step of a render on a cold cache. Doing
it here means the requests run concurrently and the results are in the
caches before any page is rendered; get_cert_link() then answers from
memory or disk.

## Usage

``` r
prefetch_cert_links(register_table, parallel = FALSE, ncores = NULL)
```

## Arguments

- register_table:

  The preprocessed register table

- parallel:

  Whether to resolve the links in parallel

- ncores:

  Number of workers, defaults to one less than the machine has

## Value

Invisibly, the number of links resolved

## Details

Failures are ignored: a link that cannot be resolved now is simply
resolved again (and reported) where it is used.
