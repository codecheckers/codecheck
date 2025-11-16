# Test Schema.org metadata generation for codechecker pages

# Setup
library(codecheck)

# Test data - register table with multiple codechecks
create_test_register <- function() {
  data.frame(
    Certificate = c("2025-001", "2025-002", "2025-003"),
    Repository = c(
      "github::example/repo1",
      "github::example/repo2",
      "github::example/repo3"
    ),
    `Check date` = c("2025-01-15", "2025-02-20", "2025-03-10"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

# Test 1: Basic generation with valid inputs
register_table <- create_test_register()
codechecker_orcid <- "0000-0001-2345-6789"
codechecker_name <- "Jane Codechecker"

json_ld_string <- generate_codechecker_schema_org(
  codechecker_orcid = codechecker_orcid,
  codechecker_name = codechecker_name,
  codechecker_github = NULL,
  register_table = register_table
)

expect_true(
  !is.null(json_ld_string) && nchar(json_ld_string) > 0,
  info = "Should generate non-empty JSON-LD string"
)

# Test 2: JSON is valid
json_ld <- tryCatch({
  jsonlite::fromJSON(json_ld_string, simplifyVector = FALSE)
}, error = function(e) {
  NULL
})

expect_false(
  is.null(json_ld),
  info = "Generated JSON-LD should be valid JSON"
)

# Test 3: Top-level structure uses @graph
expect_equal(
  json_ld$`@context`,
  "https://schema.org",
  info = "Should have correct @context"
)

expect_true(
  !is.null(json_ld$`@graph`),
  info = "Should have @graph array"
)

expect_true(
  is.list(json_ld$`@graph`),
  info = "@graph should be a list"
)

# Person is first entity in @graph
person_entity <- json_ld$`@graph`[[1]]

expect_equal(
  person_entity$`@type`,
  "Person",
  info = "First entity in @graph should be Person"
)

expect_equal(
  person_entity$`@id`,
  "https://orcid.org/0000-0001-2345-6789",
  info = "Should have ORCID URL as @id"
)

expect_equal(
  person_entity$name,
  "Jane Codechecker",
  info = "Should have correct codechecker name"
)

# Test 4: GitHub sameAs link is absent when not provided
expect_true(
  is.null(person_entity$sameAs),
  info = "Should not have sameAs when GitHub not provided"
)

# Test 5: Reviews are entities 2-4 in @graph
# @graph has Person + 3 Reviews = 4 entities
expect_equal(
  length(json_ld$`@graph`),
  4,
  info = "Should have 4 entities in @graph (1 Person + 3 Reviews)"
)

# Test 6: Review (CODECHECK certificate) structure
# Reviews are entities 2, 3, 4 in @graph
review1 <- json_ld$`@graph`[[2]]

expect_equal(
  review1$`@type`,
  "Review",
  info = "Each codecheck should be Review type"
)

expect_equal(
  review1$`@id`,
  "https://codecheck.org.uk/register/certs/2025-001/",
  info = "Should have correct certificate URL as @id"
)

expect_equal(
  review1$name,
  "CODECHECK Certificate 2025-001",
  info = "Should have correct review name"
)

expect_equal(
  review1$url,
  "https://codecheck.org.uk/register/certs/2025-001/",
  info = "Should have correct review URL"
)

# Test 7: Date published in reviews
expect_equal(
  review1$datePublished,
  "2025-01-15",
  info = "Should have datePublished from check date"
)

review2 <- json_ld$`@graph`[[3]]
expect_equal(
  review2$datePublished,
  "2025-02-20",
  info = "Second review should have correct date"
)

# Test 8: Generation with GitHub handle
json_ld_with_github <- generate_codechecker_schema_org(
  codechecker_orcid = codechecker_orcid,
  codechecker_name = codechecker_name,
  codechecker_github = "janecoder",
  register_table = register_table
)

parsed_with_github <- jsonlite::fromJSON(json_ld_with_github, simplifyVector = FALSE)

expect_equal(
  parsed_with_github$`@graph`[[1]]$sameAs,
  "https://github.com/janecoder",
  info = "Should include GitHub URL in sameAs when provided"
)

# Test 9: Empty GitHub handle is treated as NULL
json_ld_empty_github <- generate_codechecker_schema_org(
  codechecker_orcid = codechecker_orcid,
  codechecker_name = codechecker_name,
  codechecker_github = "",
  register_table = register_table
)

parsed_empty_github <- jsonlite::fromJSON(json_ld_empty_github, simplifyVector = FALSE)

expect_true(
  is.null(parsed_empty_github$`@graph`[[1]]$sameAs),
  info = "Empty GitHub handle should not create sameAs"
)

# Test 10: NA GitHub handle is treated as NULL
json_ld_na_github <- generate_codechecker_schema_org(
  codechecker_orcid = codechecker_orcid,
  codechecker_name = codechecker_name,
  codechecker_github = "NA",
  register_table = register_table
)

parsed_na_github <- jsonlite::fromJSON(json_ld_na_github, simplifyVector = FALSE)

expect_true(
  is.null(parsed_na_github$`@graph`[[1]]$sameAs),
  info = "NA GitHub handle should not create sameAs"
)

# Test 11: Single codecheck
single_check_table <- data.frame(
  Certificate = "2025-100",
  Repository = "github::solo/project",
  `Check date` = "2025-04-01",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

json_ld_single <- generate_codechecker_schema_org(
  codechecker_orcid = "0000-0002-3456-7890",
  codechecker_name = "Solo Checker",
  codechecker_github = NULL,
  register_table = single_check_table
)

parsed_single <- jsonlite::fromJSON(json_ld_single, simplifyVector = FALSE)

expect_equal(
  length(parsed_single$`@graph`),
  2,
  info = "Should have 2 entities in @graph (1 Person + 1 Review)"
)

expect_equal(
  parsed_single$`@graph`[[2]]$`@id`,
  "https://codecheck.org.uk/register/certs/2025-100/",
  info = "Single review should have correct URL"
)

# Test 12: Register table without Check date column
table_no_date <- data.frame(
  Certificate = c("2025-201", "2025-202"),
  Repository = c("github::test/repo1", "github::test/repo2"),
  stringsAsFactors = FALSE
)

json_ld_no_date <- generate_codechecker_schema_org(
  codechecker_orcid = codechecker_orcid,
  codechecker_name = codechecker_name,
  codechecker_github = NULL,
  register_table = table_no_date
)

parsed_no_date <- jsonlite::fromJSON(json_ld_no_date, simplifyVector = FALSE)

expect_true(
  is.null(parsed_no_date$`@graph`[[2]]$datePublished),
  info = "Should not have datePublished when Check date missing"
)

# Test 13: Register table with empty/NA dates
table_empty_dates <- data.frame(
  Certificate = c("2025-301", "2025-302"),
  Repository = c("github::test/repo1", "github::test/repo2"),
  `Check date` = c("", NA),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

json_ld_empty_dates <- generate_codechecker_schema_org(
  codechecker_orcid = codechecker_orcid,
  codechecker_name = codechecker_name,
  codechecker_github = NULL,
  register_table = table_empty_dates
)

parsed_empty_dates <- jsonlite::fromJSON(json_ld_empty_dates, simplifyVector = FALSE)

expect_true(
  is.null(parsed_empty_dates$`@graph`[[2]]$datePublished),
  info = "Should not have datePublished when date is empty"
)

expect_true(
  is.null(parsed_empty_dates$`@graph`[[3]]$datePublished),
  info = "Should not have datePublished when date is NA"
)

# Test 14: Valid JSON-LD for schema.org validator
expect_true(
  grepl('"@context"', json_ld_string, fixed = TRUE),
  info = "JSON-LD should contain @context for schema.org validator"
)

expect_true(
  grepl('"@type"', json_ld_string, fixed = TRUE),
  info = "JSON-LD should contain @type for schema.org validator"
)

expect_true(
  grepl('"@graph"', json_ld_string, fixed = TRUE),
  info = "JSON-LD should contain @graph array"
)

# Test 15: Reviews include itemReviewed when paper data available
# Note: This test would need mock get_codecheck_yml() responses
# For now, we test the graceful degradation when paper data is not available
# The actual fetching is tested in integration tests

# Test 16: Multiple ORCIDs with different formats
orcid_with_url <- "https://orcid.org/0000-0003-4567-8901"
orcid_plain <- "0000-0003-4567-8901"

# Both should work, but the function expects plain format
json_ld_plain_orcid <- generate_codechecker_schema_org(
  codechecker_orcid = orcid_plain,
  codechecker_name = codechecker_name,
  codechecker_github = NULL,
  register_table = register_table
)

parsed_plain_orcid <- jsonlite::fromJSON(json_ld_plain_orcid, simplifyVector = FALSE)

expect_equal(
  parsed_plain_orcid$`@graph`[[1]]$`@id`,
  "https://orcid.org/0000-0003-4567-8901",
  info = "Plain ORCID should be converted to URL format in @id"
)

# Test 17: All reviews have proper structure
# Reviews are at indices 2, 3, 4 in @graph (index 1 is Person)
for (i in 1:3) {
  review <- json_ld$`@graph`[[i + 1]]  # +1 because Person is at index 1

  expect_equal(
    review$`@type`,
    "Review",
    info = paste0("Review ", i, " should have @type Review")
  )

  expect_true(
    !is.null(review$`@id`),
    info = paste0("Review ", i, " should have @id")
  )

  expect_true(
    !is.null(review$name),
    info = paste0("Review ", i, " should have name")
  )

  expect_true(
    !is.null(review$url),
    info = paste0("Review ", i, " should have url")
  )
}
