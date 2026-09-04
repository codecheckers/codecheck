# Warn when a certificate's paper reference is a plain PDF link

A direct PDF link (no DOI, no publisher/repository landing page) carries
no machine-readable publication metadata for the OpenAlex/page-scrape
lookups to read, and such links are also prone to rotting (see
register#219 and the 2020-008/2020-009 CMMID reports, both 404 as of
writing). Surfaced during every render as a nudge to fix the source
\`codecheck.yml\`, per the guidance added to the community workflow
spec: prefer a DOI or landing page, and if a PDF is genuinely the only
option, use a https://web.archive.org/ snapshot URL rather than the live
one.

## Usage

``` r
warn_if_pdf_reference(cert_id, paper_reference)
```

## Arguments

- cert_id:

  The certificate ID, for the warning message

- paper_reference:

  The paper reference URL, or NA

## Value

Invisibly TRUE if a warning was issued, FALSE otherwise
