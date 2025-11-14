# Generate Schema.org JSON-LD for Certificate Page

Creates Schema.org JSON-LD metadata representing a CODECHECK certificate
as a Review of a ScholarlyArticle. The structure follows schema.org best
practices with the certificate (Review) as the main entity and the paper
(ScholarlyArticle) nested as the itemReviewed.

## Usage

``` r
generate_cert_schema_org(cert_id, config_yml, abstract_data = NULL)
```

## Arguments

- cert_id:

  Certificate ID (e.g., "2025-028")

- config_yml:

  Parsed codecheck.yml configuration

- abstract_data:

  Abstract data from get_abstract() with text and source fields

## Value

JSON-LD string ready to be embedded in HTML \<script
type="application/ld+json"\>
