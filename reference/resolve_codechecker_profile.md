# Resolve a codechecker page identifier (ORCID or GitHub handle) to a profile

Shared lookup used by both the HTML and YAML renderings of the
codechecker metadata panel (register#75), so both agree on the same
ORCID/GitHub handle.

## Usage

``` r
resolve_codechecker_profile(identifier)
```

## Arguments

- identifier:

  The codechecker page identifier: an ORCID or a GitHub username (see
  \`table_details\[\["name"\]\]\` / \`is_github_username\` in
  \[generate_table_details()\]).

## Value

A profile list (see \[get_codechecker_profile()\]), or \`NULL\` if not
found.
