# Check for certificates that likely check the same paper without a shared work key

codecheckers/register#150's flagship case (#133/#149, certificates
2024-017/2024-025): two certificates for the same paper, but one's
\`Paper reference\` is a DOI and the other's is a preprint PDF URL, so
\[normalize_work_key()\] gives them different (or missing) keys and they
never land on the same \`/works/\` page. This is intentionally \*not\*
resolved automatically - see the "Grouping" decision in the \#150/#123
implementation plan (group by DOI only, report near-duplicates) - a
title match is exactly the kind of ambiguous signal that should be
reviewed by hand, not merged silently.

## Usage

``` r
check_near_duplicate_works(certs, work_keys, titles)
```

## Arguments

- certs:

  Character vector of certificate IDs.

- work_keys:

  Character vector of normalized work keys (see
  \[normalize_work_key()\]), same length/order as \`certs\`.

- titles:

  Character vector of paper titles, same length/order.

## Value

None; a \`warning()\` per group of near-duplicates found.
