tinytest::using(ttdo)

test_path <- "register/short.csv"
test_register <- read.csv(test_path)
venues_path <- "register/venues.csv"

register_render(register = test_register, filter_by = c("works", "persons"),
                 outputs = c("html", "md", "json"),
                 config = c(system.file("extdata", "config.R", package = "codecheck"),
                            "config/render_html.R"),
                 venues_file = venues_path
)

# 2024-017's paper reference is a DOI (10.3397/IN_2024_3491) - work page exists
work_dir <- "docs/works/10.3397/in_2024_3491"
expect_true(file.exists(file.path(work_dir, "index.html")))
expect_true(file.exists(file.path(work_dir, "register.json")))
# index.json (not stats.json), like a venue page: structured work metadata
expect_true(file.exists(file.path(work_dir, "index.json")))
work_stats <- jsonlite::fromJSON(file.path(work_dir, "index.json"))
expect_equal(work_stats$work$doi, "10.3397/in_2024_3491")
expect_true(grepl("diffusion", work_stats$work$title, ignore.case = TRUE))
# one table (the checks list), so register.md is still published
expect_true(file.exists(file.path(work_dir, "register.md")))

expect_true(file.exists("docs/works/index.html"))
expect_true(file.exists("docs/works/index.json"))

work_html <- xml2::read_html(file.path(work_dir, "index.html"))
work_title <- xml2::xml_text(xml2::xml_find_first(work_html, "//h1"))
expect_true(grepl("diffusion", work_title, ignore.case = TRUE),
            info = "work page h1 shows the paper title, not the bare DOI")

# Schema.org: the work page's own ScholarlyArticle + Review graph
work_jsonld <- xml2::xml_text(xml2::xml_find_all(work_html, "//script[@type='application/ld+json']"))
expect_true(any(grepl('"@type": "ScholarlyArticle"', work_jsonld, fixed = TRUE)))
expect_true(any(grepl('"@type": "Review"', work_jsonld, fixed = TRUE)))
expect_true(any(grepl("10.3397/in_2024_3491", work_jsonld, fixed = TRUE)))

# the certificate's codechecker, Stephen J. Eglen, ORCID 0000-0001-8607-8025
person_dir <- "docs/persons/0000-0001-8607-8025"
expect_true(file.exists(file.path(person_dir, "index.html")))
expect_true(file.exists(file.path(person_dir, "register.json")))
# stats.json (not index.json), like a codechecker page: role counts
expect_true(file.exists(file.path(person_dir, "stats.json")))
person_stats <- jsonlite::fromJSON(file.path(person_dir, "stats.json"))
expect_equal(person_stats$person$orcid, "0000-0001-8607-8025")
expect_true(person_stats$person$checks_conducted >= 1)
# two tables (works authored, checks conducted): no register.md
expect_false(file.exists(file.path(person_dir, "register.md")))

person_html <- xml2::read_html(file.path(person_dir, "index.html"))
person_body <- xml2::xml_text(xml2::xml_find_first(person_html, "//body"))
expect_true(grepl("Works authored", person_body))
expect_true(grepl("Checks conducted", person_body))

# Schema.org: the person page's own Person + Review graph
person_jsonld <- xml2::xml_text(xml2::xml_find_all(person_html, "//script[@type='application/ld+json']"))
expect_true(any(grepl('"@type": "Person"', person_jsonld, fixed = TRUE)))
expect_true(any(grepl("0000-0001-8607-8025", person_jsonld, fixed = TRUE)))

expect_true(file.exists("docs/persons/index.html"))
expect_true(file.exists("docs/persons/index.json"))

# footer: no "Markdown" link on the person page, no CSV links on either
person_footer <- xml2::xml_text(xml2::xml_find_all(person_html, "//p[@class='footer-links']"))
expect_false(grepl("Markdown", person_footer))
expect_false(grepl("CSV", person_footer))

work_footer <- xml2::xml_text(xml2::xml_find_all(work_html, "//p[@class='footer-links']"))
expect_true(grepl("Markdown", work_footer))
expect_false(grepl("CSV", work_footer))

# 404 page (codecheckers/register#150/#123): branded, path-aware, redirects
# a stray /codecheckers/ link, and answers an unchecked DOI without an error
expect_true(file.exists("docs/404.html"))
notfound_html <- paste(readLines("docs/404.html", warn = FALSE), collapse = "\n")
expect_true(grepl("codecheck-navbar", notfound_html, fixed = TRUE))
expect_true(grepl("/codecheckers\\/", notfound_html))
expect_true(grepl("/works/", notfound_html, fixed = TRUE))

# sitemap: works/persons URLs present, no /codecheckers/ URLs
sitemap <- paste(readLines("docs/sitemap.xml", warn = FALSE), collapse = "\n")
expect_true(grepl("/works/10.3397/in_2024_3491/", sitemap, fixed = TRUE))
expect_true(grepl("/persons/0000-0001-8607-8025/", sitemap, fixed = TRUE))
expect_false(grepl("/codecheckers/", sitemap, fixed = TRUE))

# register_update_stats(): the fast path re-derives the same work/person
# stats fields by reading register.json back, without a full render
register_update_stats(docs_dir = "docs", venues_file = venues_path)

work_stats2 <- jsonlite::fromJSON(file.path(work_dir, "index.json"))
expect_equal(work_stats2$work$doi, "10.3397/in_2024_3491")
expect_true(grepl("diffusion", work_stats2$work$title, ignore.case = TRUE))

person_stats2 <- jsonlite::fromJSON(file.path(person_dir, "stats.json"))
expect_equal(person_stats2$person$orcid, "0000-0001-8607-8025")
expect_equal(person_stats2$person$checks_conducted, person_stats$person$checks_conducted)

# clean up
expect_equal(unlink("docs", recursive = TRUE), 0)
