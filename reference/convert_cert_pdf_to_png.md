# Converts each page of a certificate PDF to PNG images, saving them in the specified certificate directory.

Captures poppler's PDF parsing diagnostics (see
\[classify_poppler_log()\]) instead of letting them print raw to the
console, and returns a compact, structured status instead of throwing -
so a caller running this inside a parallel worker (where a plain
\`warning()\` never reaches the coordinating process) still gets an
accurate, actionable signal back through the ordinary return value.

## Usage

``` r
convert_cert_pdf_to_png(cert_id)
```

## Arguments

- cert_id:

  The certificate identifier. This ID is used to locate the PDF and save
  the resulting images.

## Value

A list with \`success\` (logical), \`pages\` (page count, \`NA\` on
failure), \`error\` (the caught error message, or \`NULL\`), \`fatal\`
(unique fatal poppler messages, \`character(0)\` if none) and
\`cosmetic_count\` (number of suppressed cosmetic poppler messages).
