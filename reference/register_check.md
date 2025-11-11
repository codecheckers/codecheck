# Function for checking all entries in the register

This functions starts of a \`data.frame\` read from the local register
file.

## Usage

``` r
register_check(
  register = read.csv("register.csv", as.is = TRUE, comment.char = "#"),
  from = 1,
  to = nrow(register)
)
```

## Arguments

- register:

  A \`data.frame\` with all required information for the register's view

- from:

  The first register entry to check

- to:

  The last register entry to check

## Details

\*\*Note\*\*: The validation of \`codecheck.yml\` files happens in
function \`validate_codecheck_yml()\`.

Further test ideas:

\- Does the repo have a LICENSE?

## Author

Daniel Nüst
