# Generate the human-readable pages of the validation rules

Writes one page per rules file to
\`\<output_dir\>/rules/\<version\>/index.html\`, for example
\`docs/rules/2.0/index.html\`. The pages are reachable by direct URL
only: there is no \`rules/index.html\`, nothing links to them from the
navigation, and they are neither in the sitemap nor indexed
(\`noindex\`).

## Usage

``` r
generate_rules_pages(output_dir = "docs", rules_dir = ".")
```

## Arguments

- output_dir:

  Output directory (default: "docs")

- rules_dir:

  Directory searched for \`rules-\<version\>.yml\` before the bundled
  copies (default: the working directory, i.e. the register)

## Value

Invisibly returns the paths of the generated pages

## Details

The rules files are read from \`rules_dir\` first, because the register
repository holds the authoritative copies, and only fall back to the
copy bundled with the package, which can lag behind.
