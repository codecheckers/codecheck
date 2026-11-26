# Whether an error says a service is unavailable for now

For the clients that do their own HTTP (osfr, gh) and report it only as
an error message: a server error or rate limit by its status, a timeout,
a connection that failed, or an HTML error page where JSON was expected,
as OSF sends during an outage; and a name of a \[CORE_SERVICE_HOSTS\]
that does not resolve. Anything else - a 404, a private node, broken
YAML, a malformed repository specification, another host that does not
resolve - is an answer. A status counts only where it is one, not as any
number in a URL.

## Usage

``` r
is_outage_error(e)
```

## Arguments

- e:

  a condition

## Value

\`TRUE\` for an outage
