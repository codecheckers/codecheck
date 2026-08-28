# Reading a certificate's title from the platform it is published on, see
# codecheckers/register#52. Certificates are archived on Zenodo, OSF and
# ResearchEquals, and the record title differs between them, so it is read from
# the platform rather than constructed from the certificate ID.

library(codecheck)
source("mocks.R")
source(system.file("extdata", "config.R", package = "codecheck"))

result <- function(report_link, cert_id = "2025-028") {
  codecheck:::get_cert_record_title_result(report_link, cert_id)
}

# --- platform dispatch --------------------------------------------------------
# Mirrors get_cert_link_uncached(), so a certificate's title and its PDF are
# always read from the same platform.

with_mocked_codecheck(
  list(
    get_zenodo_record_title = function(link) "CODECHECK Certificate 2025-028",
    get_osf_record_title = function(link) "An OSF project title",
    get_researchequals_record_title = function(link) "A ResearchEquals module title"
  ),
  {
    expect_equal(result("https://doi.org/10.5281/zenodo.123456"),
                 list(status = "found", value = "CODECHECK Certificate 2025-028"),
                 info = "a Zenodo DOI is read from Zenodo")

    expect_equal(result("https://zenodo.org/records/123456")$value,
                 "CODECHECK Certificate 2025-028",
                 info = "a Zenodo record URL is read from Zenodo")

    expect_equal(result("https://osf.io/abc12/")$value, "An OSF project title",
                 info = "an OSF link is read from OSF")

    expect_equal(result("https://doi.org/10.53962/abcd-1234")$value,
                 "A ResearchEquals module title",
                 info = "the LibSci DOI prefix is read from ResearchEquals")

    expect_equal(result("https://researchequals.com/en-US/versions/xyz")$value,
                 "A ResearchEquals module title",
                 info = "a ResearchEquals URL is read from ResearchEquals")

    # a platform the register cannot query is conclusive: there is no record
    # title to be read, now or on a later render
    expect_equal(result("https://example.com/reports/42"),
                 list(status = "absent", value = NULL),
                 info = "an unknown platform is absent, not failed")

    expect_equal(result(NA)$status, "absent")
    expect_equal(result("")$status, "absent")
    expect_equal(result(NULL)$status, "absent")
  }
)

# --- a platform that cannot be reached is inconclusive ------------------------
# Caching a failure here would replace the record title with the constructed
# fallback until the cache is cleared, which is the regression register#185
# fixed for OpenAlex IDs.

with_mocked_codecheck(
  list(get_zenodo_record_title = function(link) stop("Zenodo says 429")),
  expect_equal(suppressWarnings(result("https://doi.org/10.5281/zenodo.123456"))$status,
               "failed",
               info = "an unreachable platform is failed, so it is retried and not cached")
)

with_mocked_codecheck(
  list(get_zenodo_record_title = function(link) stop("Zenodo says 429")),
  expect_warning(result("https://doi.org/10.5281/zenodo.123456"),
                 "Could not read the record title")
)

# a record that carries no title at all is a conclusive answer
with_mocked_codecheck(
  list(get_zenodo_record_title = function(link) NULL),
  expect_equal(result("https://doi.org/10.5281/zenodo.123456")$status, "absent")
)

with_mocked_codecheck(
  list(get_zenodo_record_title = function(link) "   "),
  expect_equal(result("https://doi.org/10.5281/zenodo.123456")$status, "absent",
               info = "a blank title is no title")
)

with_mocked_codecheck(
  list(get_zenodo_record_title = function(link) "  Padded Title  "),
  expect_equal(result("https://doi.org/10.5281/zenodo.123456")$value, "Padded Title")
)

# --- the OSF reader -----------------------------------------------------------
# The register already reads an OSF node's files to find the certificate PDF;
# the title comes from the node itself.

osf_node_response <- function(title) {
  function(url, ...) {
    structure(list(url = url, status_code = 200L, headers = list(),
                   all_headers = list(), content = charToRaw(
                     paste0('{"data":{"attributes":{"title":', jsonlite::toJSON(title, auto_unbox = TRUE), '}}}')
                   )),
              class = "response")
  }
}

with_mocked_codecheck(
  list(codecheck_GET_retry = osf_node_response("CODECHECK of Example et al.")),
  expect_equal(codecheck:::get_osf_record_title("https://osf.io/abc12/"),
               "CODECHECK of Example et al.")
)

with_mocked_codecheck(
  list(codecheck_GET_retry = function(url, ...) NULL),
  expect_error(codecheck:::get_osf_record_title("https://osf.io/abc12/"),
               "Could not access the OSF API",
               info = "an OSF outage is an error, i.e. an inconclusive lookup")
)

# --- resolving against the previously rendered value --------------------------
# A render must never replace a known record title with the constructed fallback
# just because this run's lookup did not answer.

previous_json <- function(cert_id, title) {
  dir <- file.path(CONFIG$CERTS_DIR[["cert"]], cert_id)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    list(certificate = list(id = cert_id, title = title)),
    file.path(dir, "index.json"), auto_unbox = TRUE
  )
}

work_dir <- file.path(tempdir(), "cert-title-resolution")
dir.create(work_dir, showWarnings = FALSE)
old_wd <- setwd(work_dir)

previous_json("2025-028", "A title from an earlier render")

with_mocked_codecheck(
  list(get_cert_record_title_cached_result = function(report_link, cert_id) {
    list(status = "failed", value = NULL)
  }),
  expect_equal(codecheck:::resolve_cert_title("2025-028", "https://doi.org/10.5281/zenodo.1"),
               "A title from an earlier render",
               info = "a failed lookup keeps the previously rendered title")
)

with_mocked_codecheck(
  list(get_cert_record_title_cached_result = function(report_link, cert_id) {
    list(status = "absent", value = NULL)
  }),
  expect_equal(codecheck:::resolve_cert_title("2025-028", "https://doi.org/10.5281/zenodo.1"),
               "A title from an earlier render",
               info = "an absent lookup keeps it too, unless pruning was asked for")
)

with_mocked_codecheck(
  list(get_cert_record_title_cached_result = function(report_link, cert_id) {
    list(status = "absent", value = NULL)
  }),
  expect_equal(codecheck:::resolve_cert_title("2025-028", "https://doi.org/10.5281/zenodo.1",
                                              prune_unavailable = TRUE),
               "CODECHECK Certificate 2025-028",
               info = "pruning falls back to the constructed title")
)

with_mocked_codecheck(
  list(get_cert_record_title_cached_result = function(report_link, cert_id) {
    list(status = "found", value = "The current record title")
  }),
  expect_equal(codecheck:::resolve_cert_title("2025-028", "https://doi.org/10.5281/zenodo.1"),
               "The current record title",
               info = "a found title always wins")
)

# a certificate rendered for the first time has nothing to fall back on
with_mocked_codecheck(
  list(get_cert_record_title_cached_result = function(report_link, cert_id) {
    list(status = "failed", value = NULL)
  }),
  expect_equal(codecheck:::resolve_cert_title("2025-099", "https://doi.org/10.5281/zenodo.1"),
               "CODECHECK Certificate 2025-099")
)

setwd(old_wd)
unlink(work_dir, recursive = TRUE)
