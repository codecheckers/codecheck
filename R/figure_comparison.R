##' Extract figures from the PDF of a published article
##'
##' Extracts the raster images embedded in a PDF, e.g., the article being
##' checked, so that they can be compared with the reproduced figures using
##' \code{\link{compare_figures}}. With \code{method = "pdfimages"}, the images
##' are extracted at their original resolution with the \code{pdfimages} tool
##' from poppler-utils, JPEG images as JPEG and all others as PNG, and images
##' smaller than \code{min_size} pixels in width or height (e.g., logos, icons)
##' are skipped. With \code{method = "pages"}, whole pages are rendered with
##' \code{pdftools::pdf_convert()} instead, e.g., for vector figures that are not
##' embedded as images; crop them with \code{magick::image_crop()} if needed.
##'
##' The order of embedded images in a PDF does not always follow the page
##' layout, so check the extracted images against the figure captions.
##'
##' @param pdf Path to the PDF file.
##' @param dest_dir Directory to write the images to; created if missing.
##' @param pages Page numbers to extract from; \code{NULL} for all pages.
##' @param min_size Minimum width and height in pixels of an embedded image
##'   to be extracted (only for \code{method = "pdfimages"}).
##' @param method \code{"auto"} (default) uses \code{"pdfimages"} if the
##'   \code{pdfimages} tool is available and \code{"pages"} otherwise.
##' @param dpi Resolution for rendering pages (only for \code{method = "pages"}).
##' @param prefix File name prefix of the extracted images.
##' @return A data frame with one row per extracted image and the columns
##'   \code{page}, \code{width}, \code{height}, and \code{file}, invisibly.
##' @importFrom pdftools pdf_info pdf_convert
##' @export
##' @examples
##' \dontrun{
##' figures <- extract_pdf_figures("article.pdf", "published", pages = 6:12)
##' }
extract_pdf_figures <- function(pdf, dest_dir = "published", pages = NULL,
                                min_size = 300,
                                method = c("auto", "pdfimages", "pages"),
                                dpi = 150, prefix = "figure") {
  method <- match.arg(method)
  if (!file.exists(pdf)) stop("PDF file not found: ", pdf)
  pdfimages <- Sys.which("pdfimages")
  if (method == "auto") {
    method <- if (nzchar(pdfimages)) "pdfimages" else "pages"
    if (method == "pages") message("pdfimages (poppler-utils) not found, rendering whole pages instead")
  }
  if (method == "pdfimages" && !nzchar(pdfimages)) {
    stop("pdfimages (poppler-utils) not found; install it or use method = \"pages\"")
  }
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  if (is.null(pages)) pages <- seq_len(pdftools::pdf_info(pdf)$pages)

  if (method == "pages") return(invisible(render_pdf_pages(pdf, dest_dir, pages, dpi, prefix)))

  # `pdfimages -list` prints a table with the page, image number, type, and size of
  # every image; soft masks ("smask") are the transparency of another image. Image
  # numbers count from the first page of the range, so use the same range for both calls
  page_range <- c("-f", min(pages), "-l", max(pages))
  listing <- system2(pdfimages, c("-list", page_range, shQuote(pdf)), stdout = TRUE)[-(1:2)]
  empty <- data.frame(page = integer(0), width = numeric(0), height = numeric(0), file = character(0))
  if (length(listing) == 0) return(invisible(empty))
  # only the first five columns are used; later columns differ, e.g., for inline images
  fields <- do.call(rbind, lapply(strsplit(trimws(listing), "\\s+"), `[`, 1:5))
  images <- data.frame(page = as.integer(fields[, 1]), num = as.integer(fields[, 2]),
                       type = fields[, 3], width = as.numeric(fields[, 4]),
                       height = as.numeric(fields[, 5]))
  images <- images[images$type == "image" & images$page %in% pages &
                     images$width >= min_size & images$height >= min_size, ]
  if (nrow(images) == 0) return(invisible(empty))

  tmp <- tempfile("pdfimages")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  # -p puts the page number into the file name (<prefix>-<page>-<num>.<ext>); -j keeps
  # JPEG images as they are, -png writes all other images as PNG
  status <- system2(pdfimages, c("-png", "-j", "-p", page_range, shQuote(pdf),
                                 shQuote(file.path(tmp, prefix))))
  if (status != 0) warning("pdfimages exited with status ", status, " for ", pdf)
  extracted <- list.files(tmp, full.names = TRUE)
  parts <- regmatches(basename(extracted), regexec("-(\\d+)-(\\d+)\\.[^.]+$", basename(extracted)))
  keys <- vapply(parts, function(p) paste(as.integer(p[2]), as.integer(p[3]), sep = "-"), "")
  source_files <- extracted[match(paste(images$page, images$num, sep = "-"), keys)]
  if (anyNA(source_files)) {
    warning(sum(is.na(source_files)), " image(s) listed by pdfimages were not extracted from ", pdf)
    images <- images[!is.na(source_files), ]
    source_files <- source_files[!is.na(source_files)]
  }
  images$file <- file.path(dest_dir, basename(source_files))
  file.copy(source_files, images$file, overwrite = TRUE)
  rownames(images) <- NULL
  invisible(images[, c("page", "width", "height", "file")])
}

# Render whole PDF pages as PNG; poppler's diagnostics are captured and only messages
# meaning the PDF could not be parsed are reported (see classify_poppler_log())
render_pdf_pages <- function(pdf, dest_dir, pages, dpi, prefix) {
  files <- file.path(dest_dir, sprintf("%s-%03d.png", prefix, pages))
  outcome <- capture_poppler_log(
    pdftools::pdf_convert(pdf, format = "png", pages = pages, filenames = files,
                          dpi = dpi, verbose = FALSE))
  if (!is.null(outcome$error)) stop("Could not render ", pdf, ": ", outcome$error)
  if (length(outcome$fatal) > 0) {
    warning("Problems reading ", pdf, ": ", paste(outcome$fatal, collapse = "; "))
  }
  # read one page at a time, so that only one decoded page is in memory
  sizes <- vapply(files, function(f) {
    info <- magick::image_info(magick::image_read(f))
    c(info$width, info$height)
  }, numeric(2))
  data.frame(page = pages, width = sizes[1, ], height = sizes[2, ], file = files,
             row.names = NULL)
}

##' Create side-by-side comparisons of published and reproduced figures
##'
##' Combines each published figure with the corresponding reproduced figure into
##' one image, with a label below each, so that differences can be seen at a
##' glance in the certificate. Both images are scaled to the same width; only the
##' first page or frame of an image file is used. PDF and SVG figures are rendered
##' at a resolution that fits \code{width}. The font size of long labels is reduced
##' so that they fit. Include the comparisons in the
##' certificate with \code{\link{render_figure_comparisons}}.
##'
##' Make sure the license of the published figures allows their reuse, e.g., CC
##' BY, and attribute them in \code{labels}.
##'
##' @param published Paths to the published figures, e.g., from
##'   \code{\link{extract_pdf_figures}}.
##' @param reproduced Paths to the reproduced figures, in the same order.
##' @param output_dir Directory to write the comparison images to; created if missing.
##' @param names File names of the comparison images, ending in \code{.jpg},
##'   \code{.jpeg}, or \code{.png}; default \code{comparison-1.jpg},
##'   \code{comparison-2.jpg}, etc.
##' @param labels Labels for the published and the reproduced figure.
##' @param layout \code{"vertical"} (default) puts the published figure above the
##'   reproduced one, \code{"horizontal"} puts them side by side.
##' @param width Width in pixels to which each figure is scaled.
##' @param quality JPEG quality of the comparison images.
##' @return A data frame with the columns \code{published}, \code{reproduced},
##'   and \code{file}, invisibly.
##' @importFrom magick image_read image_scale image_blank image_annotate
##' @importFrom magick image_append image_write image_info image_background image_trim
##' @importFrom magick image_read_pdf image_read_svg
##' @importFrom pdftools pdf_pagesize
##' @export
##' @examples
##' \dontrun{
##' comparisons <- compare_figures(
##'   published = figures$file[1:2],
##'   reproduced = c("outputs/Figure 1.png", "outputs/Figure 2.png"),
##'   labels = c("Published (Author et al., 2026, CC BY 4.0)", "Reproduced (CODECHECK)"))
##' }
compare_figures <- function(published, reproduced, output_dir = "comparison",
                            names = sprintf("comparison-%d.jpg", seq_along(published)),
                            labels = c("Published", "Reproduced"),
                            layout = c("vertical", "horizontal"),
                            width = 1600, quality = 85) {
  layout <- match.arg(layout)
  if (length(published) != length(reproduced)) {
    stop("published and reproduced must have the same length")
  }
  if (length(names) != length(published)) {
    stop("names must have the same length as published")
  }
  missing <- c(published, reproduced)[!file.exists(c(published, reproduced))]
  if (length(missing) > 0) stop("Figure file(s) not found: ", paste(missing, collapse = ", "))
  if (length(labels) != 2) stop("labels must have two elements")
  formats <- c(jpg = "jpeg", jpeg = "jpeg", png = "png")[tolower(tools::file_ext(names))]
  if (anyNA(formats)) stop("names must end in .jpg, .jpeg, or .png")
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  # the labels are the same for all comparisons
  captions <- lapply(labels, label_image, width = width)

  files <- file.path(output_dir, names)
  for (i in seq_along(published)) {
    write_figure_comparison(published[i], reproduced[i], files[i], captions, width,
                            stack = layout == "vertical", format = formats[[i]],
                            quality = quality)
  }
  invisible(data.frame(published = published, reproduced = reproduced, file = files))
}

# Compose and write one comparison; a separate function so that the (large) images
# are released when it returns
write_figure_comparison <- function(published, reproduced, file, captions, width, stack,
                                    format, quality) {
  read_scaled <- function(path) magick::image_scale(read_figure(path, width), as.character(width))
  gap_size <- round(width / 40)
  if (stack) {
    gap <- magick::image_blank(width, gap_size, color = "white")
    combined <- magick::image_append(c(read_scaled(published), captions[[1]], gap,
                                       read_scaled(reproduced), captions[[2]]), stack = TRUE)
  } else {
    pair <- c(magick::image_append(c(read_scaled(published), captions[[1]]), stack = TRUE),
              magick::image_append(c(read_scaled(reproduced), captions[[2]]), stack = TRUE))
    gap <- magick::image_blank(gap_size, max(magick::image_info(pair)$height), color = "white")
    combined <- magick::image_append(c(pair[1], gap, pair[2]))
  }
  magick::image_write(magick::image_background(combined, "white"), file,
                      format = format, quality = quality)
}

# Read the first page or frame of a figure; PDF and SVG figures are rendered at a
# resolution that fits the comparison width, without needing Ghostscript
read_figure <- function(path, width) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "pdf") {
    page_width <- pdftools::pdf_pagesize(path)$width[1] # in points (1/72 inch)
    return(magick::image_read_pdf(path, pages = 1, density = ceiling(72 * width / page_width)))
  }
  if (ext == "svg") return(magick::image_read_svg(path, width = width))
  # "[0]" reads only the first page or frame
  magick::image_read(paste0(path, "[0]"))
}

# A label of the given width; the font size shrinks so that long labels fit
label_image <- function(label, width) {
  size <- max(14, round(width / 50))
  text_width <- function(size) {
    magick::image_info(magick::image_trim(magick::image_annotate(
      magick::image_blank(width * 4, size * 3, color = "white"), label, size = size,
      color = "black")))$width
  }
  while (size > 8 && text_width(size) > 0.95 * width) size <- size - 1
  magick::image_annotate(magick::image_blank(width, round(size * 2.2), color = "white"),
                         label, size = size, gravity = "center", color = "black")
}

##' Include figure comparisons in the certificate
##'
##' Writes Markdown to include the images created by
##' \code{\link{compare_figures}} in the certificate, one per figure with a
##' caption. Use it in a chunk with \code{results = "asis"}.
##'
##' @param files Paths to the comparison images, relative to the certificate
##'   source file.
##' @param captions Captions of the figures; default is the file name.
##' @param width Width of the figures in the certificate.
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @export
##' @examples
##' \dontrun{
##' render_figure_comparisons(comparisons$file,
##'   captions = paste("Figure", 1:2, "of the article: published (top) and reproduced (bottom)."))
##' }
render_figure_comparisons <- function(files, captions = basename(files), width = "85%") {
  if (length(captions) != length(files)) stop("captions must have the same length as files")
  for (i in seq_along(files)) {
    include_validated_image(files[i], captions[i], attributes = sprintf("{width=%s}", width))
    cat("\n")
  }
  invisible(NULL)
}
