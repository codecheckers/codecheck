# The PDF blocks of a BlockNote document

Walks the blocks recursively, \`children\` included, and returns those
that carry a downloadable PDF.

## Usage

``` r
blocknote_pdf_blocks(blocks)
```

## Arguments

- blocks:

  a parsed BlockNote document, or the \`children\` of one block

## Value

a list of lists with \`url\` and \`name\`
