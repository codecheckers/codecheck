# Read one codechecker list, fresh from GitHub once per session

The lists change whenever somebody registers or adds an account, so they
are read from GitHub again in every R session rather than kept in the
cache indefinitely: a copy memoized before the \`fediverse\` column was
added kept every account off the person pages until the cache was
cleared by hand (register#217). Within a session the list is read once,
so the many profile lookups of a render do not each make a request;
\[register_render()\] reads all three lists up front via
\[load_codechecker_lists()\], so that the forked render workers inherit
them.

## Usage

``` r
fetch_codechecker_list(
  url,
  refresh = FALSE,
  fetch = fetch_codechecker_list_uncached
)
```

## Arguments

- url:

  Raw URL of the CSV.

- refresh:

  Read the list from GitHub even if this session already has.

- fetch:

  Function of the URL returning the list or \`NULL\`, for tests.

## Value

A data frame with the columns of \[CODECHECKER_LIST_COLUMNS\].

## Details

Every successful fetch is also written to the cache, and only used when
a later fetch fails, with a warning: a render without network access
still shows the profiles as last seen, and only without any copy does it
produce pages without the profile panel. A list that does not (yet)
carry every column is fine either way, see
\[normalize_codechecker_list()\].
