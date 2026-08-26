# Download a Single Library File

Downloads to a temporary file and only moves it into place when the
request succeeded, so that an HTTP error page is never stored as a
library file.

## Usage

``` r
download_library_file(url, dest_file, progress = FALSE)
```

## Arguments

- url:

  URL to download from

- dest_file:

  Destination path

- progress:

  Whether to show a progress bar

## Value

\`TRUE\` if the file was downloaded successfully
