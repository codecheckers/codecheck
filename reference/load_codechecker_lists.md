# Read all codechecker lists fresh from GitHub

Called at the start of \[register_render()\], so that every render uses
the lists as they are now, also when run twice in one R session.

## Usage

``` r
load_codechecker_lists()
```

## Value

The number of lists read, invisibly.
