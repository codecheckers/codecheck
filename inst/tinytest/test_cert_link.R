tinytest::using(ttdo)

source(system.file("extdata", "config.R", package = "codecheck"))

expect_equal(codecheck:::get_cert_link("https://doi.org/10.17605/osf.io/CSB7R", "999-010"),
             "https://osf.io/download/36nsb/")
expect_equal(codecheck:::get_cert_link("https://doi.org/10.5281/zenodo.15630442", "999-020"),
             "https://zenodo.org/api/records/15630442/files/CODECHECK_report_FBM.pdf/content")
expect_equal(codecheck:::get_cert_link("https://doi.org/10.53962/wgtb-cagt", "999-030"),
             "https://www.researchequals.com/api/modules/main/wgtb-cagt")
