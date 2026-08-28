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
# the identifier of the day. The DOI is the report of certificate 2020-007.
research_equals_link <- codecheck:::get_cert_link("https://doi.org/10.53962/nsys-9a40", "999-030")
expect_true(grepl("^https://researchequals[.]com/api/files/[0-9a-f-]{36}$", research_equals_link),
            info = paste("Unexpected ResearchEquals download link:", research_equals_link))

# The main file of certificate 2026-014 is a document written in the
# ResearchEquals editor which embeds the certificate PDF, so the link must be
# the embedded file rather than the document holding it
blocknote_link <- codecheck:::get_cert_link("https://doi.org/10.53962/pdw8-n5v0", "999-031")
expect_true(grepl("^https://researchequals[.]com/api/files/[0-9a-f-]{36}$", blocknote_link),
            info = paste("Unexpected ResearchEquals download link:", blocknote_link))
expect_false(grepl("949c04ca-90f4-499e-882f-dc17ca9c19d2", blocknote_link),
             info = "Returned the module text document instead of the certificate PDF")
