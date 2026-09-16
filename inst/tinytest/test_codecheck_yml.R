tinytest::using(ttdo)

# validate_codecheck_yml() runs the rules of R/rules_checks.R, so its messages
# name the rule that rejected the file, see test_rules_validate.R for the rules
# themselves.

source("mocks.R")

# valid codecheck.yml ----
expect_silent(validate_codecheck_yml("yaml/codecheck.yml"))
expect_true(validate_codecheck_yml("yaml/codecheck.yml"))

# certificate ID ----
expect_error(validate_codecheck_yml("yaml/certificate_id_missing/codecheck.yml"),
             pattern = "CC-CFG-025 certificate-present")
expect_error(validate_codecheck_yml("yaml/certificate_id_invalid/codecheck1.yml"),
             pattern = "CC-CFG-026 certificate-id-format: '20XX-000'")
expect_error(validate_codecheck_yml("yaml/certificate_id_invalid/codecheck2.yml"),
             pattern = "CC-CFG-026 certificate-id-format: '2025-99'")
expect_error(validate_codecheck_yml("yaml/certificate_id_invalid/codecheck3.yml"),
             pattern = "CC-CFG-025 certificate-present")
# manifest ----
expect_error(validate_codecheck_yml("yaml/manifest_missing/codecheck.yml"),
             pattern = "CC-CFG-004 manifest-present")

# YAML document marker '---' ----
expect_error(validate_codecheck_yml("yaml/missing_document_marker/codecheck.yml"),
             pattern = "CC-CFG-002 explicit-document")

# UTF-8 encoding ----
expect_error(validate_codecheck_yml("yaml/invalid_utf8/codecheck.yml"),
             pattern = "CC-CFG-001 yaml-parses: the file is not valid UTF-8 encoded")

# codechecker must have at least one entry ----
expect_error(validate_codecheck_yml("yaml/codechecker_empty/codecheck.yml"),
             pattern = "CC-CFG-008 codechecker-present")

# report DOI ----
expect_error(validate_codecheck_yml("yaml/report_doi_invalid/codecheck.yml"),
             pattern = "not a valid DOI")

# report DOI - Zenodo concept DOI is rejected, see #36 ----
expect_error(validate_codecheck_yml("yaml/report_doi_concept/codecheck.yml"),
             pattern = "is a Zenodo concept DOI")

# ORCIDs ----
expect_error(validate_codecheck_yml("yaml/orcids/invalid_checker.yml"),
             pattern = "CC-MET-001 orcid-format: .*0000-abcd-0000-000X")
expect_error(validate_codecheck_yml("yaml/orcids/invalid.yml"),
             pattern = "CC-MET-001 orcid-format: .*0000-not-an-orcid")
expect_error(validate_codecheck_yml("yaml/orcids/with_url_prefix.yml"),
             pattern = "CC-MET-001 orcid-format: .*orcid.org/0000")

# names ----
expect_error(validate_codecheck_yml("yaml/author_name_missing/codecheck.yml"),
             pattern = "CC-CFG-019 paper-author-name")
expect_error(validate_codecheck_yml("yaml/codechecker_name_missing/codecheck.yml"),
             pattern = "CC-CFG-009 codechecker-name")

# repository/ies ----
# the repository URLs are answered by a mock: whether a given URL is reachable
# is not what is under test here, and one unreachable archive used to abort the
# whole file
with_mocked_codecheck(list(codecheck_GET = mock_codecheck_GET()), {
  expect_error(validate_codecheck_yml("yaml/repository_url_invalid/codecheck.yml"),
               pattern = "URL returns error")
  expect_error(validate_codecheck_yml("yaml/repository_url_invalid/codecheck-with-list.yml"),
               pattern = "URL returns error")
  expect_error(validate_codecheck_yml("yaml/repository_url_invalid/codecheck-with-list.yml"),
               pattern = "does_not_exist")
  expect_silent(validate_codecheck_yml("yaml/repository_url_invalid/codecheck-valid.yml"))
  expect_true(validate_codecheck_yml("yaml/repository_url_invalid/codecheck-valid.yml"))
})
