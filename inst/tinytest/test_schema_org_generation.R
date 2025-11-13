# Test Schema.org metadata generation for certificate pages

# Setup
library(codecheck)

# Test data structures mimicking codecheck.yml
create_test_config <- function() {
  list(
    certificate = "2025-028",
    paper = list(
      title = "Example Research Paper on Computational Methods",
      authors = list(
        list(name = "Jane Doe", ORCID = "0000-0001-2345-6789"),
        list(name = "John Smith", ORCID = "0000-0002-3456-7890"),
        list(name = "No ORCID Author", ORCID = NULL)
      ),
      reference = "https://doi.org/10.1234/example.2025"
    ),
    codechecker = list(
      list(name = "Alice Checker", ORCID = "0000-0003-4567-8901"),
      list(name = "Bob Verifier", ORCID = "0000-0004-5678-9012")
    ),
    summary = "This CODECHECK verified the computational reproducibility of the analysis.",
    check_time = "2025-01-15 14:30:00",
    report = "https://doi.org/10.5281/zenodo.123456"
  )
}

# Test 1: Basic generation with all fields
config_yml <- create_test_config()
abstract_data <- list(
  text = "This paper presents a novel computational method for analyzing large datasets.",
  source = "CrossRef"
)

json_ld_string <- generate_cert_schema_org("2025-028", config_yml, abstract_data)

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

# Test 3: Top-level structure
expect_equal(
  json_ld$`@context`,
  "https://schema.org",
  info = "Should have correct @context"
)

expect_equal(
  json_ld$`@type`,
  "Review",
  info = "Certificate should be represented as Review"
)

expect_equal(
  json_ld$`@id`,
  "https://codecheck.org.uk/register/certs/2025-028/",
  info = "Should have correct @id URL"
)

expect_equal(
  json_ld$name,
  "CODECHECK Certificate 2025-028",
  info = "Should have correct name"
)

expect_equal(
  json_ld$url,
  "https://codecheck.org.uk/register/certs/2025-028/",
  info = "Should have correct url"
)

# Test 4: Authors (codecheckers) structure
expect_true(
  is.list(json_ld$author),
  info = "Author (codecheckers) should be a list"
)

expect_equal(
  length(json_ld$author),
  2,
  info = "Should have 2 codecheckers"
)

expect_equal(
  json_ld$author[[1]]$`@type`,
  "Person",
  info = "Codechecker should be Person type"
)

expect_equal(
  json_ld$author[[1]]$name,
  "Alice Checker",
  info = "Should have correct codechecker name"
)

expect_equal(
  json_ld$author[[1]]$`@id`,
  "https://orcid.org/0000-0003-4567-8901",
  info = "Codechecker should have ORCID URL as @id"
)

# Test 5: itemReviewed (paper) structure
expect_true(
  !is.null(json_ld$itemReviewed),
  info = "Should have itemReviewed field"
)

expect_equal(
  json_ld$itemReviewed$`@type`,
  "ScholarlyArticle",
  info = "Paper should be ScholarlyArticle type"
)

expect_equal(
  json_ld$itemReviewed$name,
  "Example Research Paper on Computational Methods",
  info = "Paper should have correct title"
)

# Test 6: Paper authors structure
expect_true(
  is.list(json_ld$itemReviewed$author),
  info = "Paper authors should be a list"
)

expect_equal(
  length(json_ld$itemReviewed$author),
  3,
  info = "Should have 3 paper authors"
)

expect_equal(
  json_ld$itemReviewed$author[[1]]$`@type`,
  "Person",
  info = "Paper author should be Person type"
)

expect_equal(
  json_ld$itemReviewed$author[[1]]$name,
  "Jane Doe",
  info = "Should have correct paper author name"
)

expect_equal(
  json_ld$itemReviewed$author[[1]]$`@id`,
  "https://orcid.org/0000-0001-2345-6789",
  info = "Paper author with ORCID should have @id"
)

# Test 7: Author without ORCID
expect_true(
  is.null(json_ld$itemReviewed$author[[3]]$`@id`),
  info = "Author without ORCID should not have @id"
)

expect_equal(
  json_ld$itemReviewed$author[[3]]$name,
  "No ORCID Author",
  info = "Author without ORCID should still have name"
)

# Test 8: Abstract
expect_equal(
  json_ld$itemReviewed$abstract,
  "This paper presents a novel computational method for analyzing large datasets.",
  info = "Paper should have abstract"
)

# Test 9: Paper URL and sameAs (DOI)
expect_equal(
  json_ld$itemReviewed$url,
  "https://doi.org/10.1234/example.2025",
  info = "Paper should have URL"
)

expect_equal(
  json_ld$itemReviewed$sameAs,
  "https://doi.org/10.1234/example.2025",
  info = "Paper with DOI should have sameAs"
)

# Test 10: Review body (summary)
expect_equal(
  json_ld$reviewBody,
  "This CODECHECK verified the computational reproducibility of the analysis.",
  info = "Review should have reviewBody with summary"
)

# Test 11: Date published
expect_equal(
  json_ld$datePublished,
  "2025-01-15",
  info = "Should have datePublished in ISO 8601 date format"
)

# Test 12: Associated media (certificate PDF)
expect_true(
  !is.null(json_ld$associatedMedia),
  info = "Should have associatedMedia field"
)

expect_equal(
  json_ld$associatedMedia$`@type`,
  "MediaObject",
  info = "Certificate PDF should be MediaObject type"
)

expect_equal(
  json_ld$associatedMedia$encodingFormat,
  "application/pdf",
  info = "Should specify PDF encoding format"
)

expect_equal(
  json_ld$associatedMedia$url,
  "https://doi.org/10.5281/zenodo.123456",
  info = "Should have certificate PDF URL"
)

# Test 13: Generation without abstract
config_no_abstract <- create_test_config()
json_ld_no_abstract <- generate_cert_schema_org("2025-028", config_no_abstract, NULL)
parsed_no_abstract <- jsonlite::fromJSON(json_ld_no_abstract, simplifyVector = FALSE)

expect_true(
  is.null(parsed_no_abstract$itemReviewed$abstract),
  info = "Should not include abstract field when not provided"
)

# Test 14: Generation without summary
config_no_summary <- create_test_config()
config_no_summary$summary <- NULL
json_ld_no_summary <- generate_cert_schema_org("2025-028", config_no_summary, abstract_data)
parsed_no_summary <- jsonlite::fromJSON(json_ld_no_summary, simplifyVector = FALSE)

expect_true(
  is.null(parsed_no_summary$reviewBody),
  info = "Should not include reviewBody field when summary not provided"
)

# Test 15: Paper reference without DOI
config_non_doi <- create_test_config()
config_non_doi$paper$reference <- "https://example.com/paper"
json_ld_non_doi <- generate_cert_schema_org("2025-028", config_non_doi, abstract_data)
parsed_non_doi <- jsonlite::fromJSON(json_ld_non_doi, simplifyVector = FALSE)

expect_equal(
  parsed_non_doi$itemReviewed$url,
  "https://example.com/paper",
  info = "Non-DOI reference should be in url"
)

expect_true(
  is.null(parsed_non_doi$itemReviewed$sameAs),
  info = "Non-DOI reference should not have sameAs"
)

# Test 16: Empty abstract text
abstract_empty <- list(text = "", source = "CrossRef")
json_ld_empty_abstract <- generate_cert_schema_org("2025-028", config_yml, abstract_empty)
parsed_empty_abstract <- jsonlite::fromJSON(json_ld_empty_abstract, simplifyVector = FALSE)

expect_true(
  is.null(parsed_empty_abstract$itemReviewed$abstract),
  info = "Empty abstract text should not be included"
)

# Test 17: Date parsing with different formats
config_alt_date <- create_test_config()
config_alt_date$check_time <- "2025-03-20"
json_ld_alt_date <- generate_cert_schema_org("2025-028", config_alt_date, abstract_data)
parsed_alt_date <- jsonlite::fromJSON(json_ld_alt_date, simplifyVector = FALSE)

expect_equal(
  parsed_alt_date$datePublished,
  "2025-03-20",
  info = "Should parse ISO date format correctly"
)

# Test 18: Single author and single codechecker
config_single <- list(
  certificate = "2025-001",
  paper = list(
    title = "Single Author Paper",
    authors = list(list(name = "Solo Author", ORCID = "0000-0001-1111-1111")),
    reference = "https://doi.org/10.1234/single"
  ),
  codechecker = list(list(name = "Solo Checker", ORCID = "0000-0002-2222-2222")),
  check_time = "2025-02-01"
)

json_ld_single <- generate_cert_schema_org("2025-001", config_single, NULL)
parsed_single <- jsonlite::fromJSON(json_ld_single, simplifyVector = FALSE)

expect_equal(
  length(parsed_single$author),
  1,
  info = "Should handle single codechecker"
)

expect_equal(
  length(parsed_single$itemReviewed$author),
  1,
  info = "Should handle single paper author"
)

# Test 19: Certificate without report URL
config_no_report <- create_test_config()
config_no_report$report <- NULL
json_ld_no_report <- generate_cert_schema_org("2025-028", config_no_report, abstract_data)
parsed_no_report <- jsonlite::fromJSON(json_ld_no_report, simplifyVector = FALSE)

expect_true(
  is.null(parsed_no_report$associatedMedia),
  info = "Should not include associatedMedia when report URL not provided"
)

# Test 20: Valid JSON-LD for schema.org validator
# The generated JSON-LD should be embeddable in HTML
expect_true(
  grepl('"@context"', json_ld_string, fixed = TRUE),
  info = "JSON-LD should contain @context for schema.org validator"
)

expect_true(
  grepl('"@type"', json_ld_string, fixed = TRUE),
  info = "JSON-LD should contain @type for schema.org validator"
)

expect_true(
  grepl('"itemReviewed"', json_ld_string, fixed = TRUE),
  info = "JSON-LD should contain itemReviewed relationship"
)
