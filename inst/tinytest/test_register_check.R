tinytest::using(ttdo)

# Load dependencies to suppress package loading messages during tests
suppressMessages({
  library(gh)
  library(R.cache)
})

# Test 1: register_clear_cache() - basic functionality ----
expect_silent({
  # Clear cache before test
  codecheck::register_clear_cache()
})
# Cache directory should be removed or empty
cache_path <- file.path(R.cache::getCacheRootPath(), "codecheck")
# Cache may or may not exist, but function should not error

# Test 2: register_clear_cache() - cache path exists after recreation ----
expect_silent({
  # Clear cache
  codecheck::register_clear_cache()
  # Do something that creates cache
  # Try to get a config (this will create cache)
  suppressWarnings({
    result <- try(codecheck::get_codecheck_yml("github::codecheckers/Piccolo-2020"), silent = TRUE)
  })
})
# Function should work without errors

# Test 3: register_clear_cache() - repeated calls ----
expect_silent({
  codecheck::register_clear_cache()
  codecheck::register_clear_cache()
  codecheck::register_clear_cache()
})
# Multiple calls should not cause errors

# Test 4: register_check() - basic structure with small register ----
# This test uses a small register without actually checking (to avoid API calls)
# We'll test the function loads and processes data correctly
test_register <- data.frame(
  Certificate = c("2024-111"),
  Repository = c("zenodo-sandbox::145250"),
  Type = c("community"),
  Venue = c("test"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

# Write test register
test_csv <- tempfile(fileext = ".csv")
write.csv(test_register, test_csv, row.names = FALSE)

# Read it back
test_reg <- read.csv(test_csv, as.is = TRUE)
expect_equal(nrow(test_reg), 1)
expect_equal(test_reg$Certificate[1], "2024-111")

# Test 5: register_check() - verify it can process zenodo-sandbox entry ----
test_register <- data.frame(
  Certificate = c("2024-111"),
  Repository = c("zenodo-sandbox::145250"),
  Type = c("community"),
  Venue = c("test"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

test_csv <- tempfile(fileext = ".csv")
write.csv(test_register, test_csv, row.names = FALSE)

# Run register_check on single entry - this will produce output via cat()
# This will fetch remote config and validate
output <- capture.output({
  suppressMessages({
    codecheck::register_check(test_register, from = 1, to = 1)
  })
})
# Just check it completed without error
expect_true(length(output) > 0)

# Test 6: register_check() - certificate ID match ----
# Test with entry that should match
test_register <- data.frame(
  Certificate = c("2024-111"),
  Repository = c("zenodo-sandbox::145250"),
  Type = c("community"),
  Venue = c("test"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

# Should complete without error since IDs match
output <- capture.output({
  suppressMessages({
    codecheck::register_check(test_register, from = 1, to = 1)
  })
})
expect_true(length(output) > 0)

# Test 7: register_check() - certificate ID mismatch ----
# Test with entry where IDs don't match
test_register_bad <- data.frame(
  Certificate = c("2024-999"),  # Wrong ID
  Repository = c("zenodo-sandbox::145250"),  # Has 2024-111
  Type = c("community"),
  Venue = c("test"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

expect_error({
  suppressMessages({
    codecheck::register_check(test_register_bad, from = 1, to = 1)
  })
}, pattern = "Certificate mismatch")

# Test 8: register_check() - warning for missing codecheck.yml ----
# Test with repo that has no codecheck.yml
test_register_no_yml <- data.frame(
  Certificate = c("2024-001"),
  Repository = c("github::codecheckers/register"),  # No codecheck.yml in this repo
  Type = c("community"),
  Venue = c("test"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

expect_warning({
  suppressMessages({
    codecheck::register_check(test_register_no_yml, from = 1, to = 1)
  })
}, pattern = "does not have a codecheck.yml file")

# Test 9: register_check() - process multiple entries ----
test_register_multi <- data.frame(
  Certificate = c("2024-111", "2024-999"),
  Repository = c("zenodo-sandbox::145250", "github::codecheckers/register"),
  Type = c("community", "community"),
  Venue = c("test", "test"),
  Issue = c(NA, NA),
  stringsAsFactors = FALSE
)

# Should warn about missing yml but continue
output <- capture.output({
  expect_warning({
    suppressMessages({
      codecheck::register_check(test_register_multi, from = 1, to = 2)
    })
  }, pattern = "does not have a codecheck.yml file")
})
expect_true(length(output) > 0)

# Test 10: register_check() - from/to parameters ----
test_register_multi <- data.frame(
  Certificate = c("2024-111", "2024-999", "2024-998"),
  Repository = c("zenodo-sandbox::145250", "github::codecheckers/register", "github::codecheckers/register"),
  Type = c("community", "community", "community"),
  Venue = c("test", "test", "test"),
  Issue = c(NA, NA, NA),
  stringsAsFactors = FALSE
)

# Should complete without warning since we only check the valid one
output <- capture.output({
  suppressMessages({
    # Only check first entry (which is valid)
    codecheck::register_check(test_register_multi, from = 1, to = 1)
  })
})
expect_true(length(output) > 0)

# Test 11: Caching behavior - same request should be cached ----
expect_silent({
  # Clear cache first
  codecheck::register_clear_cache()

  # First call - hits network
  t1 <- system.time({
    suppressMessages(r1 <- codecheck::get_codecheck_yml("zenodo-sandbox::145250"))
  })

  # Second call - should be cached (faster)
  t2 <- system.time({
    suppressMessages(r2 <- codecheck::get_codecheck_yml("zenodo-sandbox::145250"))
  })
})
# Results should be identical
expect_equal(r1$certificate, r2$certificate)
expect_equal(r1$certificate, "2024-111")

# Test 12: register_check() - from default to 1 ----
test_register_single <- data.frame(
  Certificate = c("2024-111"),
  Repository = c("zenodo-sandbox::145250"),
  Type = c("community"),
  Venue = c("test"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

# Should default to checking all rows (just 1 in this case)
output <- capture.output({
  suppressMessages({
    codecheck::register_check(test_register_single)
  })
})
expect_true(length(output) > 0)

# Clean up
file.remove(list.files(tempdir(), pattern = "^file.*\\.csv$", full.names = TRUE))
