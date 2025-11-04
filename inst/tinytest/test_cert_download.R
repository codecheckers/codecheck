tinytest::using(ttdo)

config_path <- system.file("extdata", "config.R", package = "codecheck")
if (config_path == "" || !file.exists(config_path)) {
  exit_file("Package not installed properly")
}
source(config_path)

tmp <- tempdir()
CONFIG$CERTS_DIR[["cert"]] <- tmp

expect_silent({ result <- codecheck:::download_cert_pdf("https://doi.org/10.17605/osf.io/CSB7R", "9999-000") })
expect_equal(result, 1)
expect_true(file.exists(file.path(tmp, "9999-000", "cert.pdf")))
expect_true(file.size(file.path(tmp, "9999-000", "cert.pdf")) > 300000)

expect_silent({ result <- codecheck:::download_cert_pdf("https://doi.org/10.5281/zenodo.15630442", "9999-001") })
expect_equal(result, 1)
expect_true(file.exists(file.path(tmp, "9999-001", "cert.pdf")))
expect_true(  file.size(file.path(tmp, "9999-001", "cert.pdf")) > 500000)

expect_silent({ result <- codecheck:::download_cert_pdf("https://doi.org/10.53962/wgtb-cagt", "9999-002") })
expect_equal(result, 1)
expect_true(file.exists(file.path(tmp, "9999-002", "cert.pdf")))
expect_true(  file.size(file.path(tmp, "9999-002", "cert.pdf")) > 200000)
