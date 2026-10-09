# Tests for comparing published and reproduced figures:
# extract_pdf_figures(), compare_figures(), render_figure_comparisons()

library(tinytest)

tmp <- tempfile("figure_comparison_")
dir.create(tmp)

# test images of different sizes
img_file <- function(name, width, height, color) {
  path <- file.path(tmp, name)
  magick::image_write(magick::image_blank(width, height, color = color), path, format = "png")
  path
}
pub <- c(img_file("pub1.png", 800, 600, "red"), img_file("pub2.png", 400, 400, "blue"))
rep <- c(img_file("rep1.png", 1200, 900, "red"), img_file("rep2.png", 200, 300, "green"))

# compare_figures(): vertical layout --------------------------------------------
out <- file.path(tmp, "comparison")
cmp <- compare_figures(pub, rep, output_dir = out, width = 500)
expect_equal(nrow(cmp), 2)
expect_equal(cmp$file, file.path(out, c("comparison-1.jpg", "comparison-2.jpg")))
expect_true(all(file.exists(cmp$file)))
info <- magick::image_info(magick::image_read(cmp$file[1]))
expect_equal(info$format, "JPEG")
expect_equal(info$width, 500)
# both figures (scaled to 500 x 375) plus labels and gap are stacked
expect_true(info$height > 2 * 375)

info2 <- magick::image_info(magick::image_read(cmp$file[2]))
expect_equal(info2$width, 500)
# 500 x 500 and 500 x 750 plus labels and gap
expect_true(info2$height > 500 + 750)

# compare_figures(): horizontal layout and custom names --------------------------
cmp_h <- compare_figures(pub[1], rep[1], output_dir = out, names = "side.jpg",
                         layout = "horizontal", width = 300)
info_h <- magick::image_info(magick::image_read(cmp_h$file))
expect_equal(basename(cmp_h$file), "side.jpg")
expect_true(info_h$width > 2 * 300)
expect_true(info_h$height < 2 * 225 + 100)

# compare_figures(): PNG output, PDF and SVG figures, long labels ----------------
pdf_fig <- file.path(tmp, "fig.pdf")
grDevices::pdf(pdf_fig, width = 4, height = 3)
plot(1:10)
invisible(grDevices::dev.off())
svg_fig <- file.path(tmp, "fig.svg")
writeLines('<svg xmlns="http://www.w3.org/2000/svg" width="40" height="30"><rect width="40" height="30" fill="red"/></svg>', svg_fig)
long_label <- "Published (Author, Author, and Author, 2026, Some Journal, CC BY 4.0)"
cmp_mixed <- compare_figures(c(pdf_fig, svg_fig), c(rep[1], pdf_fig), output_dir = out,
                             names = c("mixed-1.png", "mixed-2.png"), width = 300,
                             labels = c(long_label, "Reproduced"))
expect_equal(magick::image_info(magick::image_read(cmp_mixed$file[1]))$format, "PNG")
# the PDF figure is rendered at the comparison width, not upscaled from 72 dpi
pdf_panel <- codecheck:::read_figure(pdf_fig, 1200)
expect_true(magick::image_info(pdf_panel)$width >= 1200)
expect_equal(magick::image_info(codecheck:::read_figure(svg_fig, 300))$width, 300)
# the long label is shrunk to fit the panel width
label <- codecheck:::label_image(long_label, 300)
expect_equal(magick::image_info(label)$width, 300)
text <- magick::image_trim(label)
expect_true(magick::image_info(text)$width < 300)

expect_error(compare_figures(pub[1], rep[1], output_dir = out, names = "x.gif"), "must end in")

# compare_figures(): input checks ----------------------------------------------
expect_error(compare_figures(pub, rep[1], output_dir = out), "same length")
expect_error(compare_figures(pub[1], file.path(tmp, "missing.png"), output_dir = out),
             "not found")
expect_error(compare_figures(pub[1], rep[1], output_dir = out, labels = "one"),
             "two elements")
expect_error(compare_figures(pub, rep, output_dir = out, names = "one.jpg"),
             "same length")

# render_figure_comparisons() ---------------------------------------------------
md <- capture.output(render_figure_comparisons(cmp$file, captions = c("Figure 1", "Figure 2")))
expect_true(any(grepl(sprintf("![Figure 1](<%s>){width=85%%}", cmp$file[1]), md, fixed = TRUE)))
expect_true(any(grepl("![Figure 2]", md, fixed = TRUE)))

md_default <- capture.output(render_figure_comparisons(cmp$file[1], width = "50%"))
expect_true(any(grepl("![comparison-1.jpg]", md_default, fixed = TRUE)))
expect_true(any(grepl("{width=50%}", md_default, fixed = TRUE)))

# paths with spaces are put in angle brackets
spaced <- compare_figures(pub[1], rep[1], output_dir = file.path(tmp, "with space"), width = 200)
md_spaced <- capture.output(render_figure_comparisons(spaced$file))
expect_true(any(grepl(sprintf("](<%s>)", spaced$file), md_spaced, fixed = TRUE)))

md_missing <- capture.output(render_figure_comparisons(file.path(tmp, "missing.jpg")))
expect_true(any(grepl("ERROR", md_missing)))
expect_true(any(grepl("missing.jpg", md_missing)))

# a corrupt image shows an error box instead of breaking the LaTeX compilation
corrupt <- file.path(tmp, "corrupt.jpg")
writeLines("not an image", corrupt)
md_corrupt <- capture.output(render_figure_comparisons(corrupt))
expect_true(any(grepl("ERROR", md_corrupt)))
expect_false(any(grepl("![corrupt.jpg]", md_corrupt, fixed = TRUE)))

expect_error(render_figure_comparisons(cmp$file, captions = "only one"), "same length")

# extract_pdf_figures() ---------------------------------------------------------
# a PDF with a large image on page 1, a small one ("logo") on page 2, and none on page 3
pdf_file <- file.path(tmp, "article.pdf")
grDevices::pdf(pdf_file, width = 5, height = 5)
plot.new(); rasterImage(matrix(seq(0, 1, length.out = 400 * 400), 400, 400), 0, 0, 1, 1, interpolate = FALSE)
plot.new(); rasterImage(matrix(0.5, 50, 50), 0, 0, 0.2, 0.2, interpolate = FALSE)
plot.new(); text(0.5, 0.5, "no image")
invisible(grDevices::dev.off())

expect_error(extract_pdf_figures(file.path(tmp, "missing.pdf")), "not found")

pages <- extract_pdf_figures(pdf_file, dest_dir = file.path(tmp, "pages"),
                             pages = 2:3, method = "pages", dpi = 50)
expect_equal(pages$page, 2:3)
expect_true(all(file.exists(pages$file)))
expect_equal(pages$width, c(250, 250))

if (nzchar(Sys.which("pdfimages"))) {
  figs <- extract_pdf_figures(pdf_file, dest_dir = file.path(tmp, "published"))
  # the small image on page 2 is skipped
  expect_equal(nrow(figs), 1)
  expect_equal(figs$page, 1L)
  expect_equal(figs$width, 400)
  expect_equal(figs$height, 400)
  expect_true(file.exists(figs$file))
  expect_equal(magick::image_info(magick::image_read(figs$file))$width, 400)

  small <- extract_pdf_figures(pdf_file, dest_dir = file.path(tmp, "small"), min_size = 10)
  expect_equal(sort(small$page), 1:2)

  # image numbers restart at the first page of the range
  page2 <- extract_pdf_figures(pdf_file, dest_dir = file.path(tmp, "page2"), pages = 2,
                               min_size = 10)
  expect_equal(nrow(page2), 1)
  expect_true(file.exists(page2$file))
  expect_equal(page2$width, 50)

  none <- extract_pdf_figures(pdf_file, dest_dir = file.path(tmp, "none"), pages = 3)
  expect_equal(nrow(none), 0)
} else {
  expect_error(extract_pdf_figures(pdf_file, method = "pdfimages"), "pdfimages")
}

unlink(tmp, recursive = TRUE)
