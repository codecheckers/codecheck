# The certificate page's "Other references" paragraph

The paper's further references (\`paper.reference-other\`, see
\[get_reference_other()\]) in the style of the authors line: a DOI links
to its own work page, its DOI icon to doi.org, and a web address links
out.

## Usage

``` r
paper_reference_other_html(config_yml)
```

## Arguments

- config_yml:

  The parsed \`codecheck.yml\`

## Value

An HTML string, \`""\` when there are no further references
