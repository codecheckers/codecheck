# Add the OpenAlex API key to a request URL

OpenAlex authenticates with an \`api_key\` query parameter. The URL is
returned unchanged when no key is configured, requests then use the free
anonymous quota.

## Usage

``` r
openalex_url_with_key(url)
```

## Arguments

- url:

  The OpenAlex API URL, with or without existing query parameters

## Value

The URL, with the API key appended when one is configured
