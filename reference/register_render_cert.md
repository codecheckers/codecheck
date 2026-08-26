# Render a single certificate page by its ID

Re-renders the HTML page and JSON metadata for one specific certificate
without modifying any index or list pages. Useful for updating a single
certificate after its PDF or metadata has changed, without a full
register re-render.

## Usage

``` r
register_render_cert(
  cert_id,
  register = read.csv("register.csv", as.is = TRUE, comment.char = "#"),
  config = c(system.file("extdata", "config.R", package = "codecheck")),
  venues_file = "venues.csv",
  force_download = TRUE,
  download_and_convert = TRUE,
  verbose = FALSE
)
```

## Arguments

- cert_id:

  Character string with the certificate identifier (e.g., "2024-017").

- register:

  A `data.frame` of the register, or a path to the register CSV file.
  Defaults to reading `"register.csv"` from the working directory.

- config:

  A character vector of configuration file paths to source. Defaults to
  the package's built-in `config.R`.

- venues_file:

  Path to the venues.csv file containing venue names and labels.

- force_download:

  Logical; if TRUE, forces re-download of certificate PDF even if it
  already exists locally. Defaults to TRUE.

- download_and_convert:

  Logical; if TRUE, downloads and converts the certificate PDF to PNG
  images. Defaults to TRUE.

- verbose:

  Logical; if TRUE, shows detailed output including pandoc commands from
  rmarkdown::render(). Defaults to FALSE.

## Value

The certificate ID (invisibly).

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  register_render_cert("2024-017")
  register_render_cert("2024-017", force_download = FALSE)
} # }
```
