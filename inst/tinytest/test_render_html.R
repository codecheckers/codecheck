tinytest::using(ttdo)

test_path <- "register/short.csv"
test_register <- read.csv(test_path)

register_render(register = test_register, filter_by = c(), outputs = c("html"),
                config = c(system.file("extdata", "config.R", package = "codecheck"),
                           "config/render_html.R")
                )

# file generation ----
expect_true(file.exists(file.path("docs/index.html")))
expect_true(file.exists(file.path("docs/certs/2024-017/index.html")))
expect_false(file.exists(file.path("docs/certs/2024-017/cert.pdf")))
expect_false(file.exists(file.path("docs/certs/2024-017/cert_20.png")))

expect_true(file.exists(file.path("docs/certs/2021-010/index.html")))
expect_true(file.exists(file.path("docs/certs/2022-018/index.html")))

# TODO ----

# clean up
expect_equal(unlink("docs", recursive = TRUE), 0)
