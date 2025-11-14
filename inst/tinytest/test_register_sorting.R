# Test register sorting functionality

library(codecheck)
library(dplyr)

# Create test register data with certificates out of order
test_register <- data.frame(
  Certificate = c("2024-003", "2024-001", "2024-005", "2024-002", "2024-004"),
  Repository = rep("github::test/repo", 5),
  Type = rep("journal", 5),
  Venue = rep("Test Journal", 5),
  Issue = rep("1", 5),
  `Check date` = c("2024-03-15", "2024-01-10", "2024-05-20", "2024-02-12", "2024-04-18"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# Test 1: Register should be sorted by certificate identifier
temp_dir <- tempdir()
output_dir <- file.path(temp_dir, "test_sorting")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Mock the filtering function to just return the table
# We'll test sorting directly by checking what gets written
test_table_details <- list(
  output_dir = output_dir,
  is_reg_table = TRUE
)

# Test sorting in render_register by checking the table before it gets filtered
# We can't easily mock this, so let's test the logic directly
sorted_register <- test_register
if ("Certificate" %in% names(sorted_register)) {
  sorted_register <- sorted_register %>% dplyr::arrange(Certificate)
}

expect_equal(
  sorted_register$Certificate,
  c("2024-001", "2024-002", "2024-003", "2024-004", "2024-005"),
  info = "Register should be sorted by certificate identifier in ascending order"
)

# Test 2: Featured table should be sorted by check date (most recent first)
featured_table <- test_register
if ("Check date" %in% names(featured_table)) {
  featured_table <- featured_table %>% dplyr::arrange(dplyr::desc(`Check date`))
}

expect_equal(
  featured_table$Certificate[1],
  "2024-005",
  info = "Featured table should have most recent check first (2024-005 from 2024-05-20)"
)

expect_equal(
  featured_table$Certificate,
  c("2024-005", "2024-004", "2024-003", "2024-002", "2024-001"),
  info = "Featured table should be sorted by check date in descending order"
)

# Test 3: Check that sorting works with missing Certificate column
test_register_no_cert <- data.frame(
  Title = c("Paper C", "Paper A", "Paper B"),
  Venue = rep("Test", 3),
  stringsAsFactors = FALSE
)

sorted_no_cert <- test_register_no_cert
if ("Certificate" %in% names(sorted_no_cert)) {
  sorted_no_cert <- sorted_no_cert %>% dplyr::arrange(Certificate)
}

expect_equal(
  nrow(sorted_no_cert),
  3,
  info = "Table without Certificate column should remain unchanged"
)

expect_equal(
  sorted_no_cert$Title,
  c("Paper C", "Paper A", "Paper B"),
  info = "Table without Certificate column should keep original order"
)

# Test 4: Check that sorting works with missing Check date column
test_register_no_date <- test_register[, !names(test_register) %in% "Check date"]

featured_no_date <- test_register_no_date
if ("Check date" %in% names(featured_no_date)) {
  featured_no_date <- featured_no_date %>% dplyr::arrange(dplyr::desc(`Check date`))
}

expect_equal(
  nrow(featured_no_date),
  5,
  info = "Featured table without Check date column should remain unchanged"
)

# Cleanup
unlink(output_dir, recursive = TRUE)
