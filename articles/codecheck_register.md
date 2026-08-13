# codecheck: Render the register

## Installing the package

The latest version of the package can be installed using:

``` r

remotes::install_github("codecheckers/codecheck")
```

## Configure the OpenAlex API key

Rendering looks up an OpenAlex ID and an abstract for every paper in the
register. Without an API key these requests share a small anonymous
daily quota, which a single render of the full register uses up. Once
the quota is gone OpenAlex answers with HTTP 429 and the affected
certificates are rendered without their OpenAlex ID, and possibly
without their abstract. A free key raises the quota tenfold, see the
[OpenAlex documentation](https://help.openalex.org/api) for how to get
one.

The key is read from the `OPENALEX_API_KEY` environment variable, most
conveniently set in your `~/.Renviron`:

    OPENALEX_API_KEY=your-key-here

Restart R afterwards, then check that the key is picked up:

``` r

nchar(Sys.getenv("OPENALEX_API_KEY")) > 0
```

Rendering works without a key, it is only slower to recover: lookups
that did not succeed are not cached, so each render retries them until
they work.

In the [register repository](https://github.com/codecheckers/register)
the key can also be put into a git-ignored `.env` file, which the
`Makefile` passes on to R, see `.env.example` there. Do not put it into
a `.Renviron` next to the register, R reads only the first `.Renviron`
it finds and a local one hides the settings in your `~/.Renviron`, such
as your `GITHUB_PAT`.

## Render the register

``` r

codecheck::register_render(); warnings()
```

## Check the register

``` r

codecheck::register_check(); warnings()
```

## Clear the cache

Renders cache the `codecheck.yml` files and the metadata looked up for
them, namely OpenAlex IDs and abstracts, so that repeated renders
neither wait for nor exhaust the quotas of these APIs. Only conclusive
answers are cached: a request that failed is retried by the next render
instead of leaving a permanent gap in the register.

Clear the cache to pick up metadata that changed at the source, such as
a corrected `codecheck.yml` or an abstract added after publication:

``` r

codecheck::register_clear_cache();
```
