# Poppler (via pdftools) reports PDF parsing problems by printing "PDF error: ..." lines directly to R's message connection rather than raising a condition on them, so they bypass ordinary error handling and, uncaptured, flood the console - one line per malformed glyph or object, sometimes hundreds per certificate. This splits captured poppler output into messages that mean the PDF is genuinely broken (unparsable, not really a PDF) versus cosmetic rendering quirks that poppler recovers from on its own (e.g. malformed embedded fonts) and that don't affect the resulting page images.

Poppler (via pdftools) reports PDF parsing problems by printing "PDF
error: ..." lines directly to R's message connection rather than raising
a condition on them, so they bypass ordinary error handling and,
uncaptured, flood the console - one line per malformed glyph or object,
sometimes hundreds per certificate. This splits captured poppler output
into messages that mean the PDF is genuinely broken (unparsable, not
really a PDF) versus cosmetic rendering quirks that poppler recovers
from on its own (e.g. malformed embedded fonts) and that don't affect
the resulting page images.

## Usage

``` r
classify_poppler_log(lines)
```

## Arguments

- lines:

  Character vector of captured message-stream output; only lines
  starting with "PDF error" are considered, everything else is ignored.

## Value

A list with \`fatal\` (unique messages indicating the PDF could not
really be parsed, character(0) if none) and \`cosmetic_count\` (number
of suppressed non-fatal poppler messages).
