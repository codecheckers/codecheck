# Generate the OpenGraph and Twitter card tags of a certificate page

The shared page header describes the register as a whole, which on a
certificate page means every certificate advertised itself as "CODECHECK
Register" at the register's own URL. These tags describe the certificate
itself, and are read by Zotero's Embedded Metadata translator as well as
by the social previews they are named for.

## Usage

``` r
generate_cert_opengraph(
  cert_id,
  config_yml,
  cert_title = NULL,
  has_preview = FALSE
)
```

## Arguments

- cert_id:

  Certificate ID (e.g. "2020-018")

- config_yml:

  Parsed codecheck.yml configuration

- cert_title:

  Title of the certificate's record on the platform it is published on,
  see
  [`resolve_cert_title`](http://codecheck.org.uk/codecheck/reference/resolve_cert_title.md);
  falls back to the constructed "CODECHECK Certificate \<ID\>" when not
  given

- has_preview:

  Whether \`cert_1.png\`, the first page of the certificate PDF, exists
  next to the page and can be used as the preview image

## Value

Named list with \`og_title\`, \`og_url\`, \`og_description\`,
\`og_type\` and \`og_image\`, ready to render into the header template
