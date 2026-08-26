# Custom HTTP GET that retries transient failures

Wraps
[`codecheck_GET()`](http://codecheck.org.uk/codecheck/reference/codecheck_GET.md)
and retries when the server rate limits the request (HTTP 429) or
reports a server error, honouring a Retry-After header when one is sent.
A whole register render makes thousands of requests to the same few
APIs, so without backing off a short burst of 429 responses turns into
missing metadata in the rendered register.

## Usage

``` r
codecheck_GET_retry(url, ..., max_attempts = 4, max_wait = 30)
```

## Arguments

- url:

  The URL to request

- ...:

  Additional arguments passed to
  [`codecheck_GET()`](http://codecheck.org.uk/codecheck/reference/codecheck_GET.md)

- max_attempts:

  Maximum number of attempts, including the first one

- max_wait:

  Longest wait between attempts, in seconds

## Value

An `httr` response object, or NULL if every attempt errored

## Details

Waiting only helps for a short burst. OpenAlex, for example, enforces a
daily quota and answers with a Retry-After of several hours once it is
used up, and no render can wait that long. When the required wait is
longer than \`max_wait\` the response is returned as it is, so the
caller can report the lookup as failed and the next render retries it.
