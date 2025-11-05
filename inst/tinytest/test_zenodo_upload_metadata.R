# Tests for codecheck::upload_zenodo_metadata() with mocked Zenodo API
# Tests compliance with CODECHECK Zenodo curation policy

library(tinytest)

# Setup - create mock Zenodo record object ----
create_mock_record <- function() {
  record <- new.env(parent = emptyenv())

  record$metadata <- list()
  record$links <- list(self_html = "https://zenodo.org/deposit/123456")
  record$id <- 123456
  record$calls <- list()

  # Mock setTitle method
  record$setTitle <- function(title) {
    record$calls <- c(record$calls, list(list(method = "setTitle", value = title)))
    record$metadata$title <- title
    invisible(record)
  }

  # Mock addLanguage method
  record$addLanguage <- function(language) {
    record$calls <- c(record$calls, list(list(method = "addLanguage", value = language)))
    if (is.null(record$metadata$language)) {
      record$metadata$language <- language
    }
    invisible(record)
  }

  # Mock setLicense method
  record$setLicense <- function(license) {
    record$calls <- c(record$calls, list(list(method = "setLicense", value = license)))
    record$metadata$license <- license
    invisible(record)
  }

  # Mock addCreator method
  record$addCreator <- function(name, orcid = NULL) {
    record$calls <- c(record$calls, list(list(method = "addCreator", name = name, orcid = orcid)))
    creator <- list(name = name)
    if (!is.null(orcid)) creator$orcid <- orcid
    if (is.null(record$metadata$creators)) {
      record$metadata$creators <- list()
    }
    record$metadata$creators <- c(record$metadata$creators, list(creator))
    invisible(record)
  }

  # Mock setPublicationDate method
  record$setPublicationDate <- function(date) {
    record$calls <- c(record$calls, list(list(method = "setPublicationDate", value = date)))
    record$metadata$publication_date <- date
    invisible(record)
  }

  # Mock setPublisher method
  record$setPublisher <- function(publisher) {
    record$calls <- c(record$calls, list(list(method = "setPublisher", value = publisher)))
    record$metadata$publisher <- publisher
    invisible(record)
  }

  # Mock setResourceType method
  record$setResourceType <- function(type) {
    record$calls <- c(record$calls, list(list(method = "setResourceType", value = type)))
    record$metadata$resource_type <- type
    invisible(record)
  }

  # Mock setDescription method
  record$setDescription <- function(description) {
    record$calls <- c(record$calls, list(list(method = "setDescription", value = description)))
    record$metadata$description <- description
    invisible(record)
  }

  # Mock setSubjects method
  record$setSubjects <- function(subjects) {
    record$calls <- c(record$calls, list(list(method = "setSubjects", value = subjects)))
    record$metadata$subjects <- subjects
    invisible(record)
  }

  # Mock setNotes method
  record$setNotes <- function(notes) {
    record$calls <- c(record$calls, list(list(method = "setNotes", value = notes)))
    record$metadata$notes <- notes
    invisible(record)
  }

  # Mock addRelatedIdentifier method - matches zen4R API signature
  record$addRelatedIdentifier <- function(identifier, scheme, relation_type, resource_type = NULL) {
    record$calls <- c(record$calls, list(list(
      method = "addRelatedIdentifier",
      identifier = identifier,
      scheme = scheme,
      relation_type = relation_type,
      resource_type = resource_type
    )))
    if (is.null(record$metadata$related_identifiers)) {
      record$metadata$related_identifiers <- list()
    }
    rel_id <- list(identifier = identifier, scheme = scheme, relation = relation_type)
    if (!is.null(resource_type)) rel_id$resource_type <- resource_type
    record$metadata$related_identifiers <- c(
      record$metadata$related_identifiers,
      list(rel_id)
    )
    invisible(record)
  }

  class(record) <- c("MockZenodoRecord", "list")
  return(record)
}

# Mock Zenodo manager
create_mock_zenodo <- function() {
  zenodo <- new.env(parent = emptyenv())
  zenodo$depositRecord <- function(record) {
    return(record)
  }
  class(zenodo) <- c("MockZenodo", "list")
  return(zenodo)
}

# Helper to find method calls
find_call <- function(record, method_name) {
  calls <- Filter(function(c) c$method == method_name, record$calls)
  if (length(calls) > 0) return(calls[[1]]) else return(NULL)
}

find_all_calls <- function(record, method_name) {
  Filter(function(c) c$method == method_name, record$calls)
}

# Test 1: POLICY - Correct publisher and resource type ----
test_metadata <- list(
  certificate = "2024-001",
  summary = "This is a test summary",
  paper = list(
    title = "Test Paper",
    reference = "https://doi.org/10.1234/test.5678"
  ),
  codechecker = list(
    list(name = "Test Checker", ORCID = "0000-0001-2345-6789")
  ),
  repository = "https://github.com/test/repo",
  check_time = "2024-01-15 10:00:00"
)

mock_record <- create_mock_record()
mock_zenodo <- create_mock_zenodo()

result <- suppressMessages(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record, test_metadata)
)

# Check POLICY requirements
publisher_call <- find_call(result, "setPublisher")
expect_equal(publisher_call$value, "CODECHECK Community on Zenodo",
             info = "POLICY: Publisher must be 'CODECHECK Community on Zenodo'")

resource_call <- find_call(result, "setResourceType")
expect_equal(resource_call$value, "publication-report",
             info = "POLICY: Resource type must be 'publication-report'")

# Test 2: POLICY - Related identifiers with correct parameters ----
related_calls <- find_all_calls(result, "addRelatedIdentifier")
expect_equal(length(related_calls), 2,
            info = "POLICY: Should add 2 related identifiers (paper, repo; cert is in alternate_identifiers)")

# Check paper relation ("reviews")
paper_call <- Filter(function(c) c$relation_type == "reviews", related_calls)
expect_equal(length(paper_call), 1, info = "POLICY: Must have 'reviews' relation for paper")
expect_equal(paper_call[[1]]$scheme, "doi", info = "Paper identifier scheme must be 'doi'")
expect_true(grepl("10.1234/test.5678", paper_call[[1]]$identifier),
            info = "Paper DOI must be correctly extracted")
expect_equal(paper_call[[1]]$resource_type, "publication-article",
            info = "Paper resource type must be 'publication-article'")

# Check repository relation ("issupplementedby")
repo_call <- Filter(function(c) c$relation_type == "issupplementedby", related_calls)
expect_equal(length(repo_call), 1, info = "POLICY: Must have 'issupplementedby' relation for repo")
expect_equal(repo_call[[1]]$scheme, "url", info = "Repository identifier scheme must be 'url'")
expect_equal(repo_call[[1]]$identifier, "https://github.com/test/repo",
             info = "Repository URL must be correct")
expect_equal(repo_call[[1]]$resource_type, "software",
            info = "Repository resource type must be 'software' for GitHub")

# Check certificate alternate identifiers (POLICY REQUIREMENT)
# Must have TWO alternate identifiers: URL schema and Other schema
alt_ids <- result$metadata$alternate_identifiers
expect_equal(length(alt_ids), 2, info = "POLICY: Must have 2 alternate identifiers for certificate")

# Check URL schema alternate identifier
url_alt <- alt_ids[[1]]
expect_equal(url_alt$scheme, "url", info = "First alternate identifier scheme must be 'url'")
expect_equal(url_alt$identifier, "http://cdchck.science/register/certs/2024-001",
             info = "URL alternate identifier must be correct")

# Check Other schema alternate identifier
other_alt <- alt_ids[[2]]
expect_equal(other_alt$scheme, "other", info = "Second alternate identifier scheme must be 'other'")
expect_equal(other_alt$identifier, "cdchck.science/register/certs/2024-001",
             info = "Other alternate identifier must be correct (without protocol)")

# Test 3: POLICY - Description includes summary ----
desc_call <- find_call(result, "setDescription")
expect_true(grepl("This is a test summary", desc_call$value),
            info = "POLICY: Description must include certificate summary")
expect_true(grepl("Test Paper", desc_call$value),
            info = "Description should include paper title")

# Test 4: Multiple codecheckers ----
test_metadata_multi <- test_metadata
test_metadata_multi$codechecker <- list(
  list(name = "Checker One", ORCID = "0000-0001-1111-1111"),
  list(name = "Checker Two", ORCID = "0000-0002-2222-2222")
)

mock_record2 <- create_mock_record()
result2 <- suppressMessages(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record2, test_metadata_multi)
)

creator_calls <- find_all_calls(result2, "addCreator")
expect_equal(length(creator_calls), 2, info = "Should add all codecheckers as creators")
expect_equal(creator_calls[[1]]$name, "Checker One")
expect_equal(creator_calls[[2]]$name, "Checker Two")

# Test 5: Missing summary warning ----
test_metadata_no_summary <- test_metadata
test_metadata_no_summary$summary <- NULL

mock_record3 <- create_mock_record()
expect_warning(
  result3 <- codecheck::upload_zenodo_metadata(mock_zenodo, mock_record3, test_metadata_no_summary),
  pattern = "summary is missing",
  info = "Should warn when summary is missing per POLICY"
)

# Test 6: Non-DOI paper reference ----
test_metadata_non_doi <- test_metadata
test_metadata_non_doi$paper$reference <- "http://example.com/paper.pdf"

mock_record4 <- create_mock_record()
result4 <- suppressMessages(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record4, test_metadata_non_doi)
)

related_calls4 <- find_all_calls(result4, "addRelatedIdentifier")
paper_calls4 <- Filter(function(c) c$relation_type == "reviews", related_calls4)
expect_equal(length(paper_calls4), 0,
             info = "Should not add 'reviews' relation for non-DOI reference")

# Should still have repository identifier (certificate is in alternate_identifiers, not related)
expect_equal(length(related_calls4), 1,
             info = "Should still add repository identifier")

# Should still have alternate identifiers for certificate
expect_equal(length(result4$metadata$alternate_identifiers), 2,
             info = "Should have 2 alternate identifiers for certificate")

# Test 7: DOI extraction from URL ----
test_metadata_doi_url <- test_metadata
test_metadata_doi_url$paper$reference <- "https://doi.org/10.5555/example.1234"

mock_record5 <- create_mock_record()
result5 <- suppressMessages(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record5, test_metadata_doi_url)
)

related_calls5 <- find_all_calls(result5, "addRelatedIdentifier")
paper_calls5 <- Filter(function(c) c$relation_type == "reviews", related_calls5)
expect_true(grepl("10\\.5555/example\\.1234", paper_calls5[[1]]$identifier),
            info = "Should extract clean DOI from doi.org URL")

# Test 8: NULL repository ----
test_metadata_no_repo <- test_metadata
test_metadata_no_repo$repository <- NULL

mock_record6 <- create_mock_record()
result6 <- suppressMessages(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record6, test_metadata_no_repo)
)

related_calls6 <- find_all_calls(result6, "addRelatedIdentifier")
repo_calls6 <- Filter(function(c) c$relation_type == "issupplementedby", related_calls6)
expect_equal(length(repo_calls6), 0,
             info = "Should not add repository relation when NULL")
# Should still have paper identifier (certificate is in alternate_identifiers)
expect_equal(length(related_calls6), 1,
             info = "Should still add paper identifier")

# Should still have alternate identifiers for certificate
expect_equal(length(result6$metadata$alternate_identifiers), 2,
             info = "Should have 2 alternate identifiers for certificate")

# Test 9: Missing certificate ID ----
test_metadata_no_cert <- test_metadata
test_metadata_no_cert$certificate <- NULL

mock_record7 <- create_mock_record()
expect_error(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record7, test_metadata_no_cert),
  pattern = "Certificate ID is required",
  info = "POLICY: Certificate ID is required"
)

# Test 10: Empty certificate ID ----
test_metadata_empty_cert <- test_metadata
test_metadata_empty_cert$certificate <- ""

mock_record8 <- create_mock_record()
expect_error(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record8, test_metadata_empty_cert),
  pattern = "Certificate ID is required",
  info = "POLICY: Certificate ID cannot be empty"
)

# Test 11: All metadata fields properly set ----
expect_equal(result$metadata$title, "CODECHECK certificate 2024-001",
             info = "Title format should be correct")
expect_equal(result$metadata$license, "cc-by-4.0", info = "License should be CC-BY 4.0")
expect_equal(result$metadata$publication_date, "2024-01-15",
             info = "Publication date should be extracted from check_time")
expect_true("CODECHECK" %in% result$metadata$subjects,
            info = "CODECHECK should be in subjects")
expect_true(!is.null(result$metadata$notes), info = "Notes should be set")

# Test 12: Resource type overrides ----
test_metadata_override <- test_metadata
mock_record9 <- create_mock_record()

# Override resource types (note: certificate uses alternate_identifiers, not related_identifiers)
custom_types <- list(
  paper = "publication-preprint",
  repository = "dataset"
)

result9 <- suppressMessages(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record9, test_metadata_override,
                                    resource_types = custom_types)
)

related_calls9 <- find_all_calls(result9, "addRelatedIdentifier")
paper_call9 <- Filter(function(c) c$relation_type == "reviews", related_calls9)
repo_call9 <- Filter(function(c) c$relation_type == "issupplementedby", related_calls9)

expect_equal(paper_call9[[1]]$resource_type, "publication-preprint",
            info = "Custom paper resource type should be used")
expect_equal(repo_call9[[1]]$resource_type, "dataset",
            info = "Custom repository resource type should be used")

# Certificate should still have alternate identifiers
expect_equal(length(result9$metadata$alternate_identifiers), 2,
             info = "Should have 2 alternate identifiers for certificate")

# Test 13: Repository auto-detection for GitLab ----
test_metadata_gitlab <- test_metadata
test_metadata_gitlab$repository <- "https://gitlab.com/user/project"

mock_record10 <- create_mock_record()
result10 <- suppressMessages(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record10, test_metadata_gitlab)
)

related_calls10 <- find_all_calls(result10, "addRelatedIdentifier")
repo_call10 <- Filter(function(c) c$relation_type == "issupplementedby", related_calls10)
expect_equal(repo_call10[[1]]$resource_type, "software",
            info = "GitLab repository should be detected as 'software'")

# Test 14: Repository auto-detection for Zenodo dataset ----
test_metadata_zenodo_data <- test_metadata
test_metadata_zenodo_data$repository <- "https://doi.org/10.5281/zenodo.123456"

mock_record11 <- create_mock_record()
result11 <- suppressMessages(
  codecheck::upload_zenodo_metadata(mock_zenodo, mock_record11, test_metadata_zenodo_data)
)

related_calls11 <- find_all_calls(result11, "addRelatedIdentifier")
repo_call11 <- Filter(function(c) c$relation_type == "issupplementedby", related_calls11)
expect_equal(repo_call11[[1]]$resource_type, "dataset",
            info = "Zenodo DOI should be detected as 'dataset'")
