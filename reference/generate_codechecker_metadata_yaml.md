# Generate the codechecker metadata YAML frontmatter block for register.md

Renders the same ORCID/GitHub/contributed-venues information as
\[generate_codechecker_metadata_html()\], but as YAML lines for
register.md's frontmatter header rather than an HTML block in the body -
same split as \[generate_venue_metadata_yaml()\], since register.md is a
plain markdown/API text file, not HTML.

## Usage

``` r
generate_codechecker_metadata_yaml(identifier, register_table = NULL)
```

## Arguments

- identifier:

  See \[resolve_codechecker_profile()\].

- register_table:

  See \[get_codechecker_venues()\]. \`NULL\` (the default) omits the
  \`venues\` field.

## Value

A YAML string (ending in a newline), or \`""\` if nothing to add.
