tinytest::using(ttdo)

config_path <- system.file("extdata", "config.R", package = "codecheck")
if (config_path == "" || !file.exists(config_path)) {
  exit_file("Package not installed properly")
}
source(config_path)

expect_equal(codecheck:::get_cert_link("https://doi.org/10.17605/osf.io/CSB7R", "999-010"),
             "https://osf.io/download/36nsb/")
expect_equal(codecheck:::get_cert_link("https://doi.org/10.5281/zenodo.15630442", "999-020"),
             "https://zenodo.org/api/records/15630442/files/CODECHECK_report_FBM.pdf/content")
# ResearchEquals resolves the DOI to a version UUID, and the API answers with
# the key of the deposited file - neither is derived from the DOI suffix, and
# both change when a new version is deposited, so assert the shape rather than
# the identifier of the day
research_equals_link <- codecheck:::get_cert_link("https://doi.org/10.53962/wgtb-cagt", "999-030")
expect_true(grepl("^https://researchequals[.]com/api/files/[0-9a-f-]{36}$", research_equals_link),
            info = paste("Unexpected ResearchEquals download link:", research_equals_link))
