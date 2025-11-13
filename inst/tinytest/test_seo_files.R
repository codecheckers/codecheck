tinytest::using(ttdo)

test_path <- "register/short.csv"
test_register <- read.csv(test_path)
venues_path <- "register/venues.csv"

# Clean up any existing docs directory from previous tests
if (dir.exists("docs")) {
  unlink("docs", recursive = TRUE)
}

# Test complete rendering with SEO files ----
capture.output({
  table <- register_render(
    register = test_register,
    filter_by = c("venues", "codecheckers"),
    outputs = c("html", "md", "json"),
    venues_file = venues_path
  )
}, type = "message")

# Test sitemap.xml generation ----
expect_true(file.exists("docs/sitemap.xml"), info = "sitemap.xml should be generated")

sitemap_content <- readLines("docs/sitemap.xml")

# Check XML structure
expect_true(
  any(grepl('<?xml version="1.0" encoding="UTF-8"?>', sitemap_content, fixed = TRUE)),
  info = "sitemap.xml should have XML declaration"
)
expect_true(
  any(grepl('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">', sitemap_content, fixed = TRUE)),
  info = "sitemap.xml should have urlset element with namespace"
)
expect_true(
  any(grepl('</urlset>', sitemap_content, fixed = TRUE)),
  info = "sitemap.xml should close urlset element"
)

# Check main register page is included
expect_true(
  any(grepl('<loc>https://codecheck.org.uk/register/</loc>', sitemap_content, fixed = TRUE)),
  info = "sitemap.xml should include main register page"
)

# Check priority is set for main page
main_page_idx <- grep('<loc>https://codecheck.org.uk/register/</loc>', sitemap_content, fixed = TRUE)
expect_true(
  any(grepl('<priority>1.0</priority>', sitemap_content[(main_page_idx):(main_page_idx + 5)], fixed = TRUE)),
  info = "Main register page should have priority 1.0"
)

# Check venues overview page
expect_true(
  any(grepl('<loc>https://codecheck.org.uk/register/venues/</loc>', sitemap_content, fixed = TRUE)),
  info = "sitemap.xml should include venues overview page"
)

# Check codecheckers overview page
expect_true(
  any(grepl('<loc>https://codecheck.org.uk/register/codecheckers/</loc>', sitemap_content, fixed = TRUE)),
  info = "sitemap.xml should include codecheckers overview page"
)

# Check certificate pages are included
expect_true(
  any(grepl('<loc>https://codecheck.org.uk/register/certs/', sitemap_content, fixed = TRUE)),
  info = "sitemap.xml should include certificate pages"
)

# Check lastmod is present
expect_true(
  any(grepl('<lastmod>', sitemap_content, fixed = TRUE)),
  info = "sitemap.xml should include lastmod dates"
)

# Check changefreq is present
expect_true(
  any(grepl('<changefreq>', sitemap_content, fixed = TRUE)),
  info = "sitemap.xml should include changefreq"
)

# Test robots.txt generation ----
expect_true(file.exists("docs/robots.txt"), info = "robots.txt should be generated")

robots_content <- readLines("docs/robots.txt")

# Check robots.txt allows all agents
expect_true(
  any(grepl('User-agent: *', robots_content, fixed = TRUE)),
  info = "robots.txt should allow all user agents"
)

# Check robots.txt allows crawling
expect_true(
  any(grepl('Allow: /', robots_content, fixed = TRUE)),
  info = "robots.txt should allow crawling"
)

# Check sitemap reference
expect_true(
  any(grepl('Sitemap: https://codecheck.org.uk/register/sitemap.xml', robots_content, fixed = TRUE)),
  info = "robots.txt should reference sitemap.xml"
)

# Test standalone sitemap generation with minimal register table ----
# Create a minimal register table for testing
minimal_register <- data.frame(
  `Certificate ID` = c("2020-001", "2020-002"),
  Repository = c("github::org/repo1", "github::org/repo2"),
  Type = c("journal", "conference"),
  Venue = c("TestJournal", "TestConf"),
  check.names = FALSE
)

unlink("docs/test", recursive = TRUE)
dir.create("docs/test", recursive = TRUE, showWarnings = FALSE)

sitemap_path <- generate_sitemap(
  minimal_register,
  filter_by = c("venues"),
  output_dir = "docs/test"
)

expect_true(file.exists(sitemap_path), info = "Standalone sitemap generation should work")
expect_equal(sitemap_path, "docs/test/sitemap.xml", info = "Sitemap path should be correct")

sitemap_content <- readLines(sitemap_path)
expect_true(length(sitemap_content) > 10, info = "Sitemap should have content")

# Test standalone robots.txt generation ----
robots_path <- generate_robots_txt(output_dir = "docs/test")

expect_true(file.exists(robots_path), info = "Standalone robots.txt generation should work")
expect_equal(robots_path, "docs/test/robots.txt", info = "Robots.txt path should be correct")

robots_content <- readLines(robots_path)
expect_true(length(robots_content) > 3, info = "robots.txt should have content")

# Test custom base URL ----
custom_sitemap_path <- generate_sitemap(
  minimal_register,
  filter_by = c("venues"),
  output_dir = "docs/test",
  base_url = "https://example.com/register/"
)

custom_sitemap_content <- readLines(custom_sitemap_path)
expect_true(
  any(grepl('<loc>https://example.com/register/', custom_sitemap_content, fixed = TRUE)),
  info = "Custom base URL should be used in sitemap"
)

custom_robots_path <- generate_robots_txt(
  output_dir = "docs/test",
  base_url = "https://example.com/register/"
)

custom_robots_content <- readLines(custom_robots_path)
expect_true(
  any(grepl('Sitemap: https://example.com/register/sitemap.xml', custom_robots_content, fixed = TRUE)),
  info = "Custom base URL should be used in robots.txt"
)

# Test lastmod parameter ----
custom_date <- "2025-01-15"
custom_sitemap_path <- generate_sitemap(
  minimal_register,
  filter_by = c("venues"),
  output_dir = "docs/test",
  lastmod = custom_date
)

custom_sitemap_content <- readLines(custom_sitemap_path)
expect_true(
  any(grepl(paste0('<lastmod>', custom_date, '</lastmod>'), custom_sitemap_content, fixed = TRUE)),
  info = "Custom lastmod date should be used in sitemap"
)

# Test sitemap URL count from full rendering ----
# Read the sitemap from the full rendering
full_sitemap_content <- readLines("docs/sitemap.xml")
url_count <- sum(grepl('<url>', full_sitemap_content, fixed = TRUE))

# Should include:
# 1. Main register
# 2. Venues overview
# 3. Codecheckers overview
# 4. Venue type pages (at least 1)
# 5. Individual venues (at least 1)
# 6. Individual codecheckers (at least 1)
# 7. Certificate pages (number of certs in test register)

expected_min_urls <- 1 + 1 + 1 + nrow(test_register)  # Main + Venues + Codecheckers + Certs
expect_true(
  url_count >= expected_min_urls,
  info = paste("Sitemap should have at least", expected_min_urls, "URLs, got", url_count)
)

# Clean up
expect_equal(unlink("docs", recursive = TRUE), 0)
