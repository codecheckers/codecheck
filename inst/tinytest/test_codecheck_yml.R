tinytest::using(ttdo)

# valid codecheck.yml ----
expect_silent(validate_codecheck_yml("yaml/codecheck.yml"))
expect_true(validate_codecheck_yml("yaml/codecheck.yml"))

# certificate ID ----
expect_error(validate_codecheck_yml("yaml/certificate_id_missing/codecheck.yml"),
             pattern = "'' is missing or invalid")
expect_error(validate_codecheck_yml("yaml/certificate_id_invalid/codecheck1.yml"),
             pattern = "'20XX-000' is missing or invalid")
expect_error(validate_codecheck_yml("yaml/certificate_id_invalid/codecheck2.yml"),
             pattern = "'2025-99' is missing or invalid")
expect_error(validate_codecheck_yml("yaml/certificate_id_invalid/codecheck3.yml"),
             pattern = "'' is missing or invalid")
# manifest ----
expect_error(validate_codecheck_yml("yaml/manifest_missing/codecheck.yml"),
             pattern = "root-level node 'manifest'")

# report DOI ----
expect_error(validate_codecheck_yml("yaml/report_doi_invalid/codecheck.yml"),
             pattern = "not a valid DOI")

# ORCIDs ----
expect_error(validate_codecheck_yml("yaml/orcids/invalid_checker.yml"),
             pattern = "checker's ORCID '0000-abcd-0000-000X'")
expect_error(validate_codecheck_yml("yaml/orcids/invalid.yml"),
             pattern = "author's ORCID '0000-not-an-orcid'")
expect_error(validate_codecheck_yml("yaml/orcids/with_url_prefix.yml"),
             pattern = "author's ORCID 'https://orcid.org/0000")

# names ----
expect_error(validate_codecheck_yml("yaml/author_name_missing/codecheck.yml"),
             pattern = "authors must have a 'name'")
expect_error(validate_codecheck_yml("yaml/codechecker_name_missing/codecheck.yml"),
             pattern = "codecheckers must have a 'name'")

# repository/ies ----
expect_error(validate_codecheck_yml("yaml/repository_url_invalid/codecheck.yml"),
             pattern = "URL returns error")
expect_error(validate_codecheck_yml("yaml/repository_url_invalid/codecheck-with-list.yml"),
             pattern = "URL returns error")
expect_error(validate_codecheck_yml("yaml/repository_url_invalid/codecheck-with-list.yml"),
             pattern = "does_not_exist")
expect_silent(validate_codecheck_yml("yaml/repository_url_invalid/codecheck-valid.yml"))
expect_true(validate_codecheck_yml("yaml/repository_url_invalid/codecheck-valid.yml"))
