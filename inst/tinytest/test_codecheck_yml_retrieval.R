tinytest::using(ttdo)

# Invalid or unsupported ----
expect_error(get_codecheck_yml("unsupported::repo/spec"),
             pattern = "Unsupported repository type 'unsupported")
expect_error(get_codecheck_yml("github::not_org_and_repo"),
             pattern = "Incomplete repo specification for type 'github'(.*)'not_org_and_repo'")

expect_warning(get_codecheck_yml("github::codecheckers/register"),
               pattern = "codecheck.yml not found (.*)codecheckers/register")
expect_warning(get_codecheck_yml("osf::6K5FH"),
               pattern = "codecheck.yml not found (.*)https://osf.io/6K5FH")
expect_warning(get_codecheck_yml("gitlab::nuest/sensebox-binder"),
               pattern = "codecheck.yml not found (.*)nuest/sensebox-binder")

# GitHub ----
expect_silent({ piccolo <- get_codecheck_yml("github::codecheckers/Piccolo-2020") })
expect_equal(piccolo$report, "http://doi.org/10.5281/zenodo.3674056")

# GitHub nested ----
expect_silent({ agile03 <- get_codecheck_yml("github::reproducible-agile/reviews-2024|reports/03") })
expect_equal(agile03$certificate, "2024-013")
expect_silent({ agile21 <- get_codecheck_yml("github::reproducible-agile/reviews-2024|reports/21") })
expect_equal(agile21$certificate, "2024-011")

# OSF ----
expect_silent({ agile <- get_codecheck_yml("osf::5SVMT") })
expect_equal(agile$report, "https://doi.org/10.17605/OSF.IO/5SVMT")

# GitLab.com ----
expect_silent({ gigabyte <- get_codecheck_yml("gitlab::cdchck/community-codechecks/2022-svaRetro-svaNUMT") })
expect_equal(gigabyte$report, "https://doi.org/10.5281/zenodo.7084333")

# Zenodo ----
# https://sandbox.zenodo.org/records/145250 contains inst/tinytest/yaml/zenodo-sandbox/codecheck.yml
expect_silent({ zenodo <- get_codecheck_yml("zenodo-sandbox::145250") })
expect_equal(zenodo$report, "https://doi.org/10.5072/zenodo.145250")
expect_equal(zenodo$certificate, "2024-111")
expect_warning(get_codecheck_yml("zenodo::8385350"),
               pattern = "codecheck.yml not found in record 8385350")

# Backup of raw Zenodo record:
# {
#   "created": "2024-12-20T12:28:35.025592+00:00",
#   "modified": "2024-12-20T12:28:35.125175+00:00",
#   "id": 145250,
#   "conceptrecid": "145248",
#   "doi": "10.5072/zenodo.145250",
#   "conceptdoi": "10.5072/zenodo.145248",
#   "doi_url": "https://handle.stage.datacite.org/10.5072/zenodo.145250",
#   "metadata": {
#     "title": "CODECHECK Certificate 2024-111",
#     "doi": "10.5072/zenodo.145250",
#     "publication_date": "2024-12-20",
#     "description": "<p>The basics of integration testing</p>",
#     "access_right": "open",
#     "creators": [
#       {
#         "name": "Carberry, Josiah",
#         "affiliation": null
#       }
#     ],
#     "resource_type": {
#       "title": "Other",
#       "type": "publication",
#       "subtype": "other"
#     },
#     "license": {
#       "id": "cc-by-4.0"
#     },
#     "relations": {
#       "version": [
#         {
#           "index": 1,
#           "is_last": true,
#           "parent": {
#             "pid_type": "recid",
#             "pid_value": "145248"
#           }
#         }
#       ]
#     }
#   },
#   "title": "CODECHECK Certificate 2024-111",
#   "links": {
#     "self": "https://sandbox.zenodo.org/api/records/145250",
#     "self_html": "https://sandbox.zenodo.org/records/145250",
#     "doi": "https://handle.stage.datacite.org/10.5072/zenodo.145250",
#     "self_doi": "https://handle.stage.datacite.org/10.5072/zenodo.145250",
#     "self_doi_html": "https://sandbox.zenodo.org/doi/10.5072/zenodo.145250",
#     "parent": "https://sandbox.zenodo.org/api/records/145248",
#     "parent_html": "https://sandbox.zenodo.org/records/145248",
#     "parent_doi": "https://handle.stage.datacite.org/10.5072/zenodo.145248",
#     "parent_doi_html": "https://sandbox.zenodo.org/doi/10.5072/zenodo.145248",
#     "self_iiif_manifest": "https://sandbox.zenodo.org/api/iiif/record:145250/manifest",
#     "self_iiif_sequence": "https://sandbox.zenodo.org/api/iiif/record:145250/sequence/default",
#     "files": "https://sandbox.zenodo.org/api/records/145250/files",
#     "media_files": "https://sandbox.zenodo.org/api/records/145250/media-files",
#     "archive": "https://sandbox.zenodo.org/api/records/145250/files-archive",
#     "archive_media": "https://sandbox.zenodo.org/api/records/145250/media-files-archive",
#     "latest": "https://sandbox.zenodo.org/api/records/145250/versions/latest",
#     "latest_html": "https://sandbox.zenodo.org/records/145250/latest",
#     "versions": "https://sandbox.zenodo.org/api/records/145250/versions",
#     "draft": "https://sandbox.zenodo.org/api/records/145250/draft",
#     "reserve_doi": "https://sandbox.zenodo.org/api/records/145250/draft/pids/doi",
#     "access_links": "https://sandbox.zenodo.org/api/records/145250/access/links",
#     "access_grants": "https://sandbox.zenodo.org/api/records/145250/access/grants",
#     "access_users": "https://sandbox.zenodo.org/api/records/145250/access/users",
#     "access_request": "https://sandbox.zenodo.org/api/records/145250/access/request",
#     "access": "https://sandbox.zenodo.org/api/records/145250/access",
#     "communities": "https://sandbox.zenodo.org/api/records/145250/communities",
#     "communities-suggestions": "https://sandbox.zenodo.org/api/records/145250/communities-suggestions",
#     "requests": "https://sandbox.zenodo.org/api/records/145250/requests"
#   },
#   "updated": "2024-12-20T12:28:35.125175+00:00",
#   "recid": "145250",
#   "revision": 4,
#   "files": [
#     {
#       "id": "010d55bf-48dc-44d6-a615-a4433898c6b5",
#       "key": "codecheck.yml",
#       "size": 568,
#       "checksum": "md5:e48fd855e7baad53b1461cd003d00361",
#       "links": {
#         "self": "https://sandbox.zenodo.org/api/records/145250/files/codecheck.yml/content"
#       }
#     }
#   ],
#   "swh": {},
#   "owners": [
#     {
#       "id": "31762"
#     }
#   ],
#   "status": "published",
#   "stats": {
#     "downloads": 0,
#     "unique_downloads": 0,
#     "views": 0,
#     "unique_views": 0,
#     "version_downloads": 0,
#     "version_unique_downloads": 0,
#     "version_unique_views": 0,
#     "version_views": 0
#   },
#   "state": "done",
#   "submitted": true
# }
