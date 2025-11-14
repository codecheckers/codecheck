tinytest::using(ttdo)

# Load dependencies
suppressMessages({
  library(gh)
  library(R.cache)
})

source(system.file("extdata", "config.R", package = "codecheck"))

# Test 1: register_render() - empty register (0 rows) ----
empty_register <- data.frame(
  Certificate = character(0),
  Repository = character(0),
  Type = character(0),
  Venue = character(0),
  Issue = character(0),
  stringsAsFactors = FALSE
)

# This should handle empty input gracefully
expect_error({
  test_dir <- file.path(tempdir(), "test_empty_register")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir, recursive = TRUE)
  dir.create(file.path(test_dir, "docs"), recursive = TRUE)
  setwd(test_dir)
  suppressMessages({
    result <- codecheck::register_render(
      register = empty_register,
      outputs = c("json"),
      from = 1,
      to = 0
    )
  })
  unlink(test_dir, recursive = TRUE)
}, pattern = "Malformed")
# Empty register should error or handle gracefully

# Test 2: register_render() - single entry register ----
single_register <- data.frame(
  Certificate = c("2024-111"),
  Repository = c("zenodo-sandbox::145250"),
  Type = c("community"),
  Venue = c("test"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

test_dir <- file.path(tempdir(), "test_single_register")
if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
dir.create(test_dir, recursive = TRUE)
dir.create(file.path(test_dir, "docs"), recursive = TRUE)
setwd(test_dir)

# Create venues.csv for this test
writeLines("name,longname,label\ntest,Test Venue,community", "venues.csv")

suppressMessages({
  result <- codecheck::register_render(
    register = single_register,
    outputs = c("json"),
    from = 1,
    to = 1,
    venues_file = "venues.csv"
  )
})

expect_inherits(result, "data.frame")
expect_equal(nrow(result), 1)
unlink(test_dir, recursive = TRUE)

# Test 3: register_render() - verify JSON output structure ----
test_register <- data.frame(
  Certificate = c("2024-111"),
  Repository = c("zenodo-sandbox::145250"),
  Type = c("community"),
  Venue = c("test venue"),
  Issue = c(999),
  stringsAsFactors = FALSE
)

expect_silent({
  test_dir <- file.path(tempdir(), "test_json_output")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir, recursive = TRUE)
  dir.create(file.path(test_dir, "docs"), recursive = TRUE)
  setwd(test_dir)

  # Create venues.csv for this test
  writeLines("name,longname,label\ntest venue,Test Venue,community", "venues.csv")

  suppressMessages({
    result <- codecheck::register_render(
      register = test_register,
      outputs = c("json"),
      from = 1,
      to = 1,
      venues_file = "venues.csv"
    )
  })

})
# Check if JSON file was created
json_file <- file.path(test_dir, "docs", "register.json")
if (file.exists(json_file)) {
  json_data <- jsonlite::fromJSON(json_file)
  # jsonlite::fromJSON returns data.frame for tabular JSON
  expect_true(inherits(json_data, "list") || inherits(json_data, "data.frame"))
}
unlink(test_dir, recursive = TRUE)

# Test 4: UTF-8 characters in venue names ----
utf8_register <- data.frame(
  Certificate = c("2024-111"),
  Repository = c("zenodo-sandbox::145250"),
  Type = c("conference"),
  Venue = c("Café Scïence Tëst"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

expect_silent({
  test_dir <- file.path(tempdir(), "test_utf8")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir, recursive = TRUE)
  dir.create(file.path(test_dir, "docs"), recursive = TRUE)
  setwd(test_dir)

  # Create venues.csv for this test
  writeLines("name,longname,label\nCafé Scïence Tëst,Café Science Test,conference", "venues.csv")

  suppressMessages({
    result <- codecheck::register_render(
      register = utf8_register,
      outputs = c("json"),
      from = 1,
      to = 1,
      venues_file = "venues.csv"
    )
  })

})
expect_inherits(result, "data.frame")
unlink(test_dir, recursive = TRUE)

# Test 5: Special characters in repository names ----
special_char_register <- data.frame(
  Certificate = c("2024-111"),
  Repository = c("zenodo-sandbox::145250"),
  Type = c("community"),
  Venue = c("Test & Demo"),
  Issue = c(NA),
  stringsAsFactors = FALSE
)

expect_silent({
  test_dir <- file.path(tempdir(), "test_special_chars")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir, recursive = TRUE)
  dir.create(file.path(test_dir, "docs"), recursive = TRUE)
  setwd(test_dir)

  # Create venues.csv for this test
  writeLines("name,longname,label\nTest & Demo,Test and Demo,community", "venues.csv")

  suppressMessages({
    result <- codecheck::register_render(
      register = special_char_register,
      outputs = c("json"),
      from = 1,
      to = 1,
      venues_file = "venues.csv"
    )
  })

})
expect_inherits(result, "data.frame")
unlink(test_dir, recursive = TRUE)

# Test 6: Multiple entries from different platforms ----
multi_platform_register <- data.frame(
  Certificate = c("2021-010", "2022-018", "2024-017", "2024-111"),
  Repository = c("osf::bdu28",
                 "gitlab::cdchck/community-codechecks/2022-svaRetro-svaNUMT",
                 "github::codecheckers/Inter_Noise2024_Codes_Acoustics_Diffusion_Equation",
                 "zenodo-sandbox::145250"),
  Type = c("conference", "journal", "community", "community"),
  Venue = c("AGILEGIS", "GigaByte", "codecheck NL", "codecheck"),
  Issue = c(38, 44, 133, 999),
  stringsAsFactors = FALSE
)

expect_warning({
  test_dir <- file.path(tempdir(), "test_multi_platform")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir, recursive = TRUE)
  dir.create(file.path(test_dir, "docs"), recursive = TRUE)
  setwd(test_dir)

  # Create venues.csv for this test
  writeLines("name,longname,label\nAGILEGIS,AGILE Conference,conference\nGigaByte,GigaByte,journal\ncodecheck NL,CODECHECK NL,check-nl\ncodecheck,CODECHECK,community", "venues.csv")

  suppressMessages({
    result <- codecheck::register_render(
      register = multi_platform_register,
      outputs = c("json"),
      from = 1,
      to = 4,
      venues_file = "venues.csv"
    )
  })

}, "codechecker ORCID and GitHub username missing")
expect_inherits(result, "data.frame")
expect_equal(nrow(result), 4)
unlink(test_dir, recursive = TRUE)

# Test 7: Register with NA Issue numbers ----
na_issue_register <- data.frame(
  Certificate = c("2024-111", "2024-112"),
  Repository = c("zenodo-sandbox::145250", "zenodo-sandbox::145250"),
  Type = c("community", "community"),
  Venue = c("test", "test"),
  Issue = c(NA, NA),
  stringsAsFactors = FALSE
)

expect_silent({
  test_dir <- file.path(tempdir(), "test_na_issues")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir, recursive = TRUE)
  dir.create(file.path(test_dir, "docs"), recursive = TRUE)
  setwd(test_dir)

  # Create venues.csv for this test
  writeLines("name,longname,label\ntest,Test Venue,community", "venues.csv")

  suppressMessages({
    result <- codecheck::register_render(
      register = na_issue_register,
      outputs = c("json"),
      from = 1,
      to = 2,
      venues_file = "venues.csv"
    )
  })

})
expect_inherits(result, "data.frame")
unlink(test_dir, recursive = TRUE)

# Test 8: Register with mixed Issue types (numeric and NA) ----
mixed_issue_register <- data.frame(
  Certificate = c("2024-111", "2024-112", "2024-113"),
  Repository = c("zenodo-sandbox::145250", "zenodo-sandbox::145250", "zenodo-sandbox::145250"),
  Type = c("community", "community", "community"),
  Venue = c("test", "test", "test"),
  Issue = c(123, NA, 456),
  stringsAsFactors = FALSE
)

expect_silent({
  test_dir <- file.path(tempdir(), "test_mixed_issues")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir, recursive = TRUE)
  dir.create(file.path(test_dir, "docs"), recursive = TRUE)
  setwd(test_dir)

  # Create venues.csv for this test
  writeLines("name,longname,label\ntest,Test Venue,community", "venues.csv")

  suppressMessages({
    result <- codecheck::register_render(
      register = mixed_issue_register,
      outputs = c("json"),
      from = 1,
      to = 3,
      venues_file = "venues.csv"
    )
  })

})
expect_inherits(result, "data.frame")
expect_equal(nrow(result), 3)
unlink(test_dir, recursive = TRUE)

# Test 9: Register with from/to subsetting ----
large_register <- data.frame(
  Certificate = sprintf("2024-%03d", 1:10),
  Repository = rep("zenodo-sandbox::145250", 10),
  Type = rep("community", 10),
  Venue = rep("test", 10),
  Issue = rep(NA, 10),
  stringsAsFactors = FALSE
)

expect_silent({
  test_dir <- file.path(tempdir(), "test_subsetting")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir, recursive = TRUE)
  dir.create(file.path(test_dir, "docs"), recursive = TRUE)
  setwd(test_dir)

  # Create venues.csv for this test
  writeLines("name,longname,label\ntest,Test Venue,community", "venues.csv")

  suppressMessages({
    # Only process entries 3-5
    result <- codecheck::register_render(
      register = large_register,
      outputs = c("json"),
      from = 3,
      to = 5,
      venues_file = "venues.csv"
    )
  })

})
expect_inherits(result, "data.frame")
expect_equal(nrow(result), 3)  # Should only have 3 rows
# Check Certificate ID column (plain text) instead of Certificate (markdown link)
expect_equal(result$`Certificate ID`[1], "2024-003")
expect_equal(result$`Certificate ID`[3], "2024-005")
unlink(test_dir, recursive = TRUE)

# Test 10: Different venue types ----
venue_types_register <- data.frame(
  Certificate = sprintf("2024-%03d", 1:4),
  Repository = rep("zenodo-sandbox::145250", 4),
  Type = c("journal", "conference", "community", "institution"),
  Venue = c("TestJournal", "TestConf", "TestComm", "TestInst"),
  Issue = rep(NA, 4),
  stringsAsFactors = FALSE
)

expect_silent({
  test_dir <- file.path(tempdir(), "test_venue_types")
  if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)
  dir.create(test_dir, recursive = TRUE)
  dir.create(file.path(test_dir, "docs"), recursive = TRUE)
  setwd(test_dir)

  # Create venues.csv for this test
  writeLines("name,longname,label\nTestJournal,Test Journal,journal\nTestConf,Test Conference,conference\nTestComm,Test Community,community\nTestInst,Test Institution,institution", "venues.csv")

  suppressMessages({
    result <- codecheck::register_render(
      register = venue_types_register,
      outputs = c("json"),
      from = 1,
      to = 4,
      venues_file = "venues.csv"
    )
  })

})
expect_inherits(result, "data.frame")
expect_equal(nrow(result), 4)
# Verify all types are present
expect_true(all(c("journal", "conference", "community", "institution") %in% result$Type))
unlink(test_dir, recursive = TRUE)

# Clean up any remaining test directories
test_dirs <- list.files(tempdir(), pattern = "^test_(single|json|utf8|special|multi|na_|mixed|subsetting|venue)", full.names = TRUE)
for (d in test_dirs) {
  if (dir.exists(d)) unlink(d, recursive = TRUE)
}
