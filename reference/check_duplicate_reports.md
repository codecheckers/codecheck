# Check for certificates that share a report DOI

Two certificates for two different papers, both naming the same archived
record (certificates 2025-009/2025-010 and OSF record \`gv2z4\`). The
register renders both perfectly well, so this is invisible there, but
the report DOI is what identifies a certificate everywhere else: it is
the dedup key for the Wikidata and Wikibase export, so two certificates
sharing one collapse into a single item and whichever is written second
silently wins. Almost always the cause is a second certificate deposited
into the first one's record by mistake.

## Usage

``` r
check_duplicate_reports(certs, reports)
```

## Arguments

- certs:

  Character vector of certificate IDs.

- reports:

  Character vector of report DOIs/URLs, same length/order.

## Value

None; a \`warning()\` per group of certificates sharing a report.
