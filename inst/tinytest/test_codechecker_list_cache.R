tinytest::using(ttdo)

# Reading the codechecker lists: fresh once per session, with the last
# successful fetch in the cache only as a fallback (register#217)

# keep the cache of this test out of the user's real cache, restored at the end
# of this file (on.exit() would run immediately, it is not inside a function)
cache_root <- file.path(tempfile("codecheck_cache"))
dir.create(cache_root, recursive = TRUE)
old_root <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(cache_root)

fetch_list <- codecheck:::fetch_codechecker_list
url <- paste0("https://example.org/test-", as.numeric(Sys.time()), "/codecheckers.csv")

calls <- 0
fetch_returning <- function(records) {
  function(url) {
    calls <<- calls + 1
    records
  }
}
without_fediverse <- data.frame(name = "A Person", handle = "@aperson",
                                ORCID = "0000-0000-0000-0001",
                                stringsAsFactors = FALSE)
with_fediverse <- within(without_fediverse, fediverse <- "@aperson@example.social")

# The first read fetches, and returns the normalised list
records <- fetch_list(url, fetch = fetch_returning(without_fediverse))
expect_equal(names(records), codecheck:::CODECHECKER_LIST_COLUMNS)
expect_true(is.na(records$fediverse))
expect_equal(calls, 1)

# Within the session the list is not fetched again
records <- fetch_list(url, fetch = fetch_returning(with_fediverse))
expect_true(is.na(records$fediverse))
expect_equal(calls, 1)

# A refresh, as every render does, fetches again and sees a new column, which
# a list memoized before the column was added never did
records <- fetch_list(url, refresh = TRUE, fetch = fetch_returning(with_fediverse))
expect_equal(records$fediverse, "@aperson@example.social")
expect_equal(calls, 2)

# A failed fetch falls back to the last successful one, with a warning
expect_warning(
  records <- fetch_list(url, refresh = TRUE, fetch = fetch_returning(NULL)),
  "cached copy of codecheckers.csv"
)
expect_equal(records$fediverse, "@aperson@example.social")

# ... and the fallback is kept for the session, so it is not retried per lookup
records <- fetch_list(url, fetch = fetch_returning(without_fediverse))
expect_equal(records$fediverse, "@aperson@example.social")
expect_equal(calls, 3)

# Without any cached copy a failed fetch is an empty list, not an error
other_url <- sub("codecheckers.csv", "agile-codecheckers.csv", url, fixed = TRUE)
records <- fetch_list(other_url, fetch = fetch_returning(NULL))
expect_equal(nrow(records), 0)
expect_equal(names(records), codecheck:::CODECHECKER_LIST_COLUMNS)

# nothing of this test may end up in the cache the renders use
rm(list = c(url, other_url), envir = codecheck:::codechecker_list_session)
R.cache::setCacheRootPath(old_root)
expect_true(is.null(R.cache::findCache(key = list(url), dirs = codecheck:::CODECHECKER_LIST_CACHE_DIRS)))
