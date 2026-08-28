# The file a ResearchEquals module version actually offers for download

A module's main file is usually the deposited file itself,
\`content_s3\` with the media type \`content_mediatype\`. It can also be
a document written in ResearchEquals' own editor,
\`application/x-blocknote\`, which is a JSON array of blocks that may
\*contain\* the certificate PDF rather than be it, as for certificate
2026-014:

## Usage

``` r
researchequals_main_file(version, cert_id = NULL)
```

## Arguments

- version:

  version metadata as returned by the ResearchEquals API

- cert_id:

  ID of the certificate, used for warnings, optional

## Value

a list with \`url\`, \`mediatype\` and \`name\` (NULL unless the file
came from a BlockNote block), or NULL when the version has no main file

## Details

“\`
\["type":"pdf","props":"url":".../api/files/\<key\>","name":"...pdf","children":\[\]\]
“\`

Returning the BlockNote document as the certificate download means
saving that JSON as \`cert.pdf\`, so this resolves one level further and
returns the embedded PDF. Blocks nest, so the document is walked
recursively.

Needs the network only for a BlockNote main file; when that fetch fails
the unresolved main file is returned, which is what the caller would
have used anyway.
