# The configured OpenAlex API key

Read from the \`OPENALEX_API_KEY\` environment variable, which can be
set in \`~/.Renviron\` or passed in by the register Makefile.

## Usage

``` r
openalex_api_key()
```

## Value

The API key, or an empty string when none is configured

## Details

Requests without a key share a small daily quota that a single register
render exhausts, after which OpenAlex answers 429 and certificates are
rendered without their OpenAlex ID. A free key raises that quota
tenfold, see https://help.openalex.org/api.
