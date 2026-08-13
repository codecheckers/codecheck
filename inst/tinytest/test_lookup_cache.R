tinytest::using(ttdo)

config_path <- system.file("extdata", "config.R", package = "codecheck")
if (config_path == "" || !file.exists(config_path)) {
  exit_file("Package not installed properly")
}
source(config_path)

# keep the cache of this test out of the user's real cache, restored at the end
# of this file (on.exit() would run immediately, it is not inside a function)
cache_root <- file.path(tempfile("codecheck_cache"))
dir.create(cache_root, recursive = TRUE)
old_root <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(cache_root)

dirs <- c("codecheck", "test_lookup_cache")

calls <- 0
lookup_with <- function(status, value) {
  function() {
    calls <<- calls + 1
    list(status = status, value = value)
  }
}

# a found value is cached, so the lookup runs only once
key_found <- list("found", Sys.time())
expect_equal(codecheck:::cached_lookup(key_found, dirs, lookup_with("found", "A")), "A")
expect_equal(codecheck:::cached_lookup(key_found, dirs, lookup_with("found", "B")), "A")
expect_equal(calls, 1)

# a confirmed absence is cached too, it is a real answer
calls <- 0
key_absent <- list("absent", Sys.time())
expect_true(is.null(codecheck:::cached_lookup(key_absent, dirs, lookup_with("absent", NULL))))
expect_true(is.null(codecheck:::cached_lookup(key_absent, dirs, lookup_with("absent", NULL))))
expect_equal(calls, 1)

# a failed request is NOT cached, so the next render retries it, this is what
# kept certificates from silently losing their OpenAlex ID (register#185)
calls <- 0
key_failed <- list("failed", Sys.time())
expect_true(is.na(codecheck:::cached_lookup(key_failed, dirs, lookup_with("failed", NA_character_))))
expect_equal(codecheck:::cached_lookup(key_failed, dirs, lookup_with("found", "recovered")), "recovered")
expect_equal(calls, 2)

# and once it succeeds the value is cached
expect_equal(codecheck:::cached_lookup(key_failed, dirs, lookup_with("found", "other")), "recovered")
expect_equal(calls, 2)

# nothing of this test may end up in the cache the renders use
expect_true(!dir.exists(file.path(old_root, "codecheck", "test_lookup_cache")))
R.cache::setCacheRootPath(old_root)
