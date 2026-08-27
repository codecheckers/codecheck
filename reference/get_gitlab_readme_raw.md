# Retrieve the README of a GitLab.com project, as raw text

Tries the \`main\` branch first, then falls back to \`master\`.

## Usage

``` r
get_gitlab_readme_raw(repo)
```

## Arguments

- repo:

  the project path, e.g. \`cdchck/Piccolo-2020\`

## Value

the README text, or \`NULL\` if none was found

## Author

Daniel Nuest
