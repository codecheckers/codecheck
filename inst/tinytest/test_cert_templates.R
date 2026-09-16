# Test the certificate page templates are well-formed

tinytest::using(ttdo)

cert_templates <- c("template_base.md", "template_no_cert.md")

for (template in cert_templates) {
  template_path <- system.file("extdata", "templates", "cert", template, package = "codecheck")
  lines <- readLines(template_path, warn = FALSE)

  # An unclosed <div> is closed implicitly by pandoc at the end of the file,
  # with a "Div at temp.md line 8 column 1 unclosed" warning for every
  # rendered certificate
  opened <- sum(lengths(regmatches(lines, gregexpr("<div[ >]", lines))))
  closed <- sum(lengths(regmatches(lines, gregexpr("</div>", lines))))
  expect_equal(opened, closed,
               info = paste(template, "opens as many <div>s as it closes"))

  # The JSON link sits in a full-width row of its own below the card columns,
  # so it aligns with the cards
  link_line <- grep("cert-footer-link", lines)
  expect_equal(length(link_line), 1, info = paste(template, "has one footer link"))
  expect_true(any(grepl('<div class="col-12">', lines[link_line - 1])),
              info = paste(template, "wraps the footer link in a full-width column"))
}
