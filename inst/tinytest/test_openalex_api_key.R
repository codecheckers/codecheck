tinytest::using(ttdo)

config_path <- system.file("extdata", "config.R", package = "codecheck")
if (config_path == "" || !file.exists(config_path)) {
  exit_file("Package not installed properly")
}
source(config_path)

old_key <- Sys.getenv("OPENALEX_API_KEY", unset = NA)

# without a key the URLs are unchanged and the anonymous quota is used
Sys.unsetenv("OPENALEX_API_KEY")
expect_equal(codecheck:::openalex_api_key(), "")
expect_equal(codecheck:::openalex_url_with_key("https://api.openalex.org/works/W1"),
             "https://api.openalex.org/works/W1")

# OpenAlex authenticates with an api_key query parameter
Sys.setenv(OPENALEX_API_KEY = "k3y")
expect_equal(codecheck:::openalex_url_with_key("https://api.openalex.org/works/W1"),
             "https://api.openalex.org/works/W1?api_key=k3y")

# the works search already carries query parameters
expect_equal(codecheck:::openalex_url_with_key("https://api.openalex.org/works?filter=title.search:x"),
             "https://api.openalex.org/works?filter=title.search:x&api_key=k3y")

# keys are escaped rather than breaking the URL
Sys.setenv(OPENALEX_API_KEY = "a b&c")
expect_equal(codecheck:::openalex_url_with_key("https://api.openalex.org/works/W1"),
             "https://api.openalex.org/works/W1?api_key=a%20b%26c")

if (is.na(old_key)) Sys.unsetenv("OPENALEX_API_KEY") else Sys.setenv(OPENALEX_API_KEY = old_key)
