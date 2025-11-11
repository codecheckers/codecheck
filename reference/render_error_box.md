# Display error box in certificate output

Internal helper function to display a formatted error message box in
LaTeX output.

## Usage

``` r
render_error_box(filename, error_msg)
```

## Arguments

- filename:

  \- Name of the file that caused the error

- error_msg:

  \- The error message to display

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)
