# Parse the repository specification in the column "Repo" in the register CSV file

Based roughly on
\[\`remotes::parse_one_extra\`\](https://github.com/r-lib/remotes/blob/master/R/deps.R#L519)

## Usage

``` r
parse_repository_spec(x)
```

## Arguments

- x:

  the repository specification to parse

## Value

a named character vector with the items \`type\` and \`repo\`

## Details

Supported variants:

\- \`osf::ABC12\` - \`github::codecheckers/Piccolo-2020\` -
\`gitlab::cdchck/Piccolo-2020\`

## Author

Daniel Nüst
