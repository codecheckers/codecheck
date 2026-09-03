# A work's publication date, from its OpenAlex record

Delegates to \[get_openalex_work_fields_cached_result()\], which reads
the same record for the ISSN of the publication the work appeared in
(register#50). One request and one cache entry per work, rather than two
of each for two fields of the same document.

## Usage

``` r
get_openalex_publication_date_cached(openalex_id)
```

## Arguments

- openalex_id:

  An OpenAlex work URL or ID, e.g. "https://openalex.org/W3014157798"

## Value

The publication date as a character string, or \`NA_character\_\`
