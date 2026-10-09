## latex summary of metadata
##
## https://daringfireball.net/2010/07/improved_regex_for_matching_urls
## To use the URL in R, I had to escape the \ characters and " -- this version
## does not work:
## .url_regexp = "(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?...]))"

## Have also converted the unicode into \uxxxx escapes to keep
## devtools::check() happy
## \u00ab (left-pointing double angle quotation mark) -> \u00ab
## \u00bb (right-pointing double angle quotation mark) -> \u00bb
## \u201c (left double quotation mark) -> \u201c
## \u201d (right double quotation mark) -> \u201d
## \u2018 (left single quotation mark) -> \u2018
## \u2019 (right single quotation mark) -> \u2019

.url_regexp = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?\u00ab\u00bb\u201c\u201d\u2018\u2019]))"

##' Wrap URL for LaTeX
##'
##' @param x - A string that may contain URLs that should be hyperlinked.
##' @return A string with the passed URL as a latex `\url{http://the.url}`
##' @author Stephen Eglen
##' @importFrom stringr str_replace_all
as_latex_url  <- function(x) {
  wrapit <- function(url) { paste0("\\url{", url, "}") }
  str_replace_all(x, .url_regexp, wrapit)
}

## Text that deliberate LaTeX in free text owns and that is never escaped:
## math ($x_1$, $$x_1$$, \(x_1\), \[x_1\]) and the first argument of a command,
## e.g. the key in \cite{smith_2020} or the URL in \href{} and \url{}.
.latex_protected = paste0(
  "(?<!\\\\)\\$\\$.*?(?<!\\\\)\\$\\$|(?<!\\\\)\\$[^$]*(?<!\\\\)\\$|",
  "\\\\\\(.*?\\\\\\)|\\\\\\[.*?\\\\\\]|\\\\[A-Za-z]+\\*?\\{[^{}]*\\}")

## Escape the characters that break a LaTeX table cell: & starts a new cell,
## % comments out the rest of the row, # is a macro parameter, _ outside math
## is an error (e.g. a file name such as run_all.R). Other specials are left
## alone, and so is protected LaTeX. Already escaped characters (\&) are not
## escaped twice.
.escape_latex_table_text <- function(x) {
  gsub(paste0("(?:", .latex_protected, ")(*SKIP)(*FAIL)|(?<!\\\\)([&%#_])"),
       "\\\\\\1", x, perl = TRUE)
}

## Free text for a LaTeX table cell, with its bare http(s) URLs in \url{} so
## that they can break across lines. The \url{} is protected, so the URL is
## not escaped: \url{} would print \# literally.
.latex_table_text_with_urls <- function(x) {
  x <- gsub(paste0("(?:", .latex_protected, ")(*SKIP)(*FAIL)|",
                   "(https?://[^\\s<>{}]*[^\\s<>{}.,;:!?)'\"])"),
            "\\\\url{\\1}", paste(x, collapse = " "), perl = TRUE)
  .escape_latex_table_text(x)
}

.name_with_orcid <- function(person, add.orcid=TRUE) {
  name <- person$name
  orcid <- person$ORCID
  if (is.null(orcid) || !(add.orcid)) {
    name
  } else {
    paste(name, sprintf('\\orcidicon{%s} ', orcid))
  }
}

.names <- function(people, add.orcid=TRUE) {
  ## PEOPLE here is typically either metadata$paper$authors or
  ## metadata$codechecker
  num_people = length(people)
  text = ""
  sep = ""
  for (i in 1:num_people) {
    person = people[[i]]
    p = .name_with_orcid(person, add.orcid)
    text=paste(text, p, sep=sep)
    sep=", "
  }
  text
}

##' Print a latex table to summarise CODECHECK metadata
##'
##' Format a latex table that summarises the main CODECHECK metadata,
##' excluding the MANIFEST.
##' @title Print a latex table to summarise CODECHECK metadata
##' @param metadata - the codecheck metadata list.
##' @return The latex table, suitable for including in the Rmd
##' @author Stephen Eglen
##' @importFrom xtable xtable
##' @export
latex_summary_of_metadata <- function(metadata) {
  # Helper function to safely get value or empty string
  safe_value <- function(x) {
    if (is.null(x) || length(x) == 0) {
      return("")
    }
    return(x)
  }

  # Singular or plural row label, depending on the number of people
  people_label <- function(singular, people) {
    if (length(people) > 1) paste0(singular, "s") else singular
  }

  repositories = .repository_urls(metadata$repository)
  summary_entries = list(
    "Title of checked publication" = safe_value(.escape_latex_table_text(metadata$paper$title)),
    "Author" =          safe_value(.names(metadata$paper$authors)),
    "Reference" =       safe_value(as_latex_url(metadata$paper$reference)),
    "Codechecker" =     safe_value(.names(metadata$codechecker)),
    "Date of check" =   safe_value(metadata$check_time),
    "Summary" =         safe_value(.latex_table_text_with_urls(metadata$summary)),
    "Repository" =      paste(as_latex_url(repositories), collapse = " \\newline "))
  items = names(summary_entries)
  items[items == "Author"] = people_label("Author", metadata$paper$authors)
  items[items == "Codechecker"] = people_label("Codechecker", metadata$codechecker)
  if (length(repositories) > 1) items[items == "Repository"] = "Repositories"

  # Create data frame - all entries now guaranteed to have a value
  summary_df = data.frame(Item=items,
                          Value=unlist(summary_entries, use.names=FALSE),
                          stringsAsFactors=FALSE)

  print(xtable(summary_df, align=c('l', 'l', 'p{10cm}'),
             caption='CODECHECK summary'),
      include.rownames=FALSE,
      include.colnames=TRUE,
      sanitize.text.function = function(x){x},
      comment=FALSE)
}

##' Print a latex table to summarise CODECHECK manfiest
##'
##' Format a latex table that summarises the main CODECHECK manifest
##' @title Print a latex table to summarise CODECHECK metadata
##' @param metadata - the CODECHECK metadata list.
##' @param manifest_df - The manifest data frame
##' @param root - root directory of the project
##' @param align - alignment flags for the table.
##' @param repository_url - the repository to link the output files to. By
##'   default, the first GitHub or GitLab repository in the metadata, linked on
##'   its default branch; other repositories and DOIs are not linked. A string
##'   links to that repository, `FALSE` turns the links off.
##' @return The latex table, suitable for including in the Rmd
##' @author Stephen Eglen
##' @importFrom xtable xtable
##' @export
latex_summary_of_manifest <- function(metadata, manifest_df,
                                      root,
                                      align=c('l', 'p{6cm}', 'p{6cm}', 'p{2cm}'),
                                      repository_url = NULL
                                      ) {
  m = manifest_df[, c("output", "comment", "size")]
  m$comment = .escape_latex_table_text(m$comment)
  m$size = ifelse(is.na(m$size), "missing",
                  formatC(m$size, format = "f", digits = 0))

  # Link the outputs only to a repository with a known file URL scheme,
  # several repositories may be given (codecheck#97)
  paths = ifelse(startsWith(manifest_df$dest, root),
                 substring(manifest_df$dest, nchar(root) + 1),
                 manifest_df$dest)
  urls = rep(NA_character_, nrow(m))
  if (is.null(repository_url)) {
    for (repo in .repository_urls(metadata$repository)) {
      urls = .repository_file_url(repo, paths)
      if (!all(is.na(urls))) break
    }
  } else if (!isFALSE(repository_url)) {
    urls = .repository_file_url(repository_url, paths)
  }

  m[,1] = ifelse(is.na(urls),
                 sprintf('\\path{%s}', m[,1]),
                 sprintf('\\href{%s}{\\path{%s}}', urls, m[,1]))

  names(m) = c("Output", "Comment", "Size (b)")
  xt = xtable(m,
              digits=0,
              caption="Summary of output files generated",
              align=align)
  # A longtable continues on the next page instead of being cut off, and
  # repeats the header row there (codecheck#93). Declared to knitr as well,
  # for workspaces whose codecheck-preamble.sty does not load it.
  knitr::knit_meta_add(list(rmarkdown::latex_dependency("longtable")))
  print(xt, include.rownames=FALSE,
        sanitize.text.function = function(x){x},
        comment=FALSE,
        tabular.environment = "longtable", floating = FALSE,
        hline.after = -1,
        add.to.row = list(pos = list(0), command = "\\hline\n\\endhead\n"))
}

##' Print the latex code to include the CODECHECK logo
##'
##'
##' @title Print the latex code to include the CODECHECK logo
##' @return NULL
##' @author Stephen Eglen
##' @export
latex_codecheck_logo <- function() {
  logo_file = system.file("extdata", "codecheck_logo.pdf", package="codecheck")
  cat(sprintf("\\centerline{\\includegraphics[width=4cm]{%s}}",
              logo_file))
  cat("\\vspace*{1cm}")
}

##' Print a citation for the codecheck certificate.
##'
##' Turn the metadata into a readable citation for this document.
##' @title Print a citation for the codecheck certificate.
##' @param metadata - the codecheck metadata list.
##' @return NULL
##' @author Stephen Eglen
##' @export
cite_certificate <- function(metadata) {
  year = substring(metadata$check_time,1,4)
  names = .names(metadata$codechecker, add.orcid=FALSE)
  citation = sprintf("%s (%s). CODECHECK Certificate %s.  Zenodo. %s",
                     names, year, metadata$certificate, as_latex_url(metadata$report))
  cat(citation)
}

##' Display error box in certificate output
##'
##' Internal helper function to display a formatted error message box in LaTeX output.
##'
##' @param filename - Name of the file that caused the error
##' @param error_msg - The error message to display
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_error_box <- function(filename, error_msg) {
  # Use simple markdown formatting that will be reliably converted by pandoc
  # Avoid complex LaTeX to prevent compilation errors
  cat("**ERROR: Cannot include file:** `", filename, "`\n\n", sep = "")
  cat("**Reason:** ", error_msg, "\n\n", sep = "")
  cat("---\n\n")
}

##' Render single-page image for certificate output
##'
##' Internal helper function to render PNG, JPG, JPEG, TIF, TIFF, GIF images.
##' TIF/TIFF and GIF files are automatically converted to PNG since LaTeX doesn't natively support them.
##'
##' @param path - Path to the image file
##' @param comment - Comment/caption for the image
##' @param name - File name shown in the heading and messages (default: the base name of \code{path})
##' @param base_dir - Directory the image is linked relative to, or \code{NULL} to
##'   link it by \code{path}; files are read by \code{path} either way
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom magick image_read image_write
##' @keywords internal
render_manifest_image <- function(path, comment, name = basename(path), base_dir = NULL) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  # Check file extension
  ext <- tolower(tools::file_ext(path))

  # Handle TIF/TIFF/GIF conversion (pdflatex doesn't support these formats)
  if (ext %in% c("tif", "tiff", "gif")) {
    tryCatch({
      # Read and convert to PNG using magick package
      img <- magick::image_read(path)
      png_path <- sub(paste0("\\.", ext, "$"), "_converted.png", path, ignore.case = TRUE)
      magick::image_write(img, png_path, format = "png")

      format_display <- if (ext == "gif") "GIF" else "TIF/TIFF"
      cat("\\textit{Note: ", format_display, " image automatically converted to PNG for display.}\n\n", sep = "")
      cat(paste0("![", comment, "](", relative_to(png_path, base_dir), ")\n"))
    }, error = function(e) {
      format_name <- toupper(ext)
      render_error_box(name,
                      paste("Failed to convert", format_name, "image:", e$message))
    })
  } else {
    # PNG, JPG, JPEG - validate image before including
    include_validated_image(path, comment, name, base_dir = base_dir)
  }
}

##' Include an image in the certificate after validating it
##'
##' Internal helper: checks that the image file exists and can be read with
##' magick before writing the Markdown to include it, so that a missing or
##' corrupted image file shows an error box instead of breaking the LaTeX
##' compilation. The path is put in angle brackets, so that it may contain
##' spaces.
##'
##' @param path - Path to the image file
##' @param caption - Caption of the image
##' @param name - File name shown in the error box
##' @param attributes - Pandoc attributes of the image, e.g. \code{"{width=85\%}"}
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
include_validated_image <- function(path, caption, name = basename(path), attributes = "",
                                    base_dir = NULL) {
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }
  tryCatch({
    magick::image_read(path)
    cat(paste0("![", caption, "](<", relative_to(path, base_dir), ">)", attributes, "\n"))
  }, error = function(e) {
    render_error_box(name,
                     paste("Failed to read image file (possibly corrupted):", e$message))
  })
}

##' Render EPS image for certificate output
##'
##' Internal helper function to render EPS files (LaTeX handles conversion).
##'
##' @param path - Path to the EPS file
##' @param comment - Comment/caption for the image
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_eps <- function(path, comment, name = basename(path), base_dir = NULL) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    cat(paste0("![", comment, "](", relative_to(path, base_dir), ")\n"))
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to include EPS image:", e$message))
  })
}

##' Render SVG image for certificate output
##'
##' Internal helper function to render SVG files (converts to PDF first).
##'
##' @param path - Path to the SVG file
##' @param comment - Comment/caption for the image
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom rsvg rsvg_pdf
##' @keywords internal
render_manifest_svg <- function(path, comment, name = basename(path), base_dir = NULL) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  # Convert SVG to PDF using rsvg package
  pdf_path <- sub("\\.svg$", "_converted.pdf", path)

  tryCatch({
    rsvg::rsvg_pdf(path, pdf_path)
    cat("\\textit{Note: SVG image automatically converted to PDF for display.}\n\n")
    cat(paste0("![", comment, "](", relative_to(pdf_path, base_dir), ")\n"))
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to convert SVG image:", e$message))
  })
}

##' Render PDF file for certificate output
##'
##' Internal helper function to render PDF files (handles multi-page PDFs).
##'
##' @param path - Path to the PDF file
##' @param comment - Comment/caption for the PDF
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom pdftools pdf_info
##' @keywords internal
render_manifest_pdf <- function(path, comment, name = basename(path), base_dir = NULL) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  # Check if PDF has multiple pages using pdftools
  tryCatch({
    pdf_info <- pdftools::pdf_info(path)
    num_pages <- pdf_info$pages

    if (!is.na(num_pages) && num_pages > 1) {
      # Multi-page PDF - include all pages
      cat(paste0("\\includepdf[pages={-}]{", path, "}\n\n"))
      cat("End of ", name, " (", num_pages, " pages).\n\n")
    } else {
      # Single-page PDF - include as image
      cat(paste0("![", comment, "](", relative_to(path, base_dir), ")\n"))
    }
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to process PDF file:", e$message))
  })
}

##' Render text file for certificate output
##'
##' Internal helper function to render TXT and Rout files.
##'
##' @param path - Path to the text file
##' @param comment - Comment describing the file
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_text <- function(path, comment, name = basename(path)) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    cat("\\scriptsize \n\n", "```txt\n")
    cat(readLines(path, warn = FALSE), sep = "\n")
    cat("\n\n``` \n\n", "\\normalsize \n\n")
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to read text file:", e$message))
  })
}

##' Render CSV file for certificate output
##'
##' Internal helper function to render CSV files with skimr statistics.
##'
##' @param path - Path to the CSV file
##' @param comment - Comment describing the file
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_csv <- function(path, comment, name = basename(path)) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    data <- read.csv(path)
    cat("Summary statistics of tabular data:", "\n\n")
    cat("\\scriptsize \n\n", "```txt\n")
    print(skimr::skim(data))
    cat("\n\n``` \n\n", "\\normalsize \n\n")
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to read CSV file:", e$message))
  })
}

##' Render TSV file for certificate output
##'
##' Internal helper function to render TSV files with skimr statistics.
##'
##' @param path - Path to the TSV file
##' @param comment - Comment describing the file
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom utils read.delim
##' @keywords internal
render_manifest_tsv <- function(path, comment, name = basename(path)) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    data <- read.delim(path)
    cat("Summary statistics of tabular data:", "\n\n")
    cat("\\scriptsize \n\n", "```txt\n")
    print(skimr::skim(data))
    cat("\n\n``` \n\n", "\\normalsize \n\n")
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to read TSV file:", e$message))
  })
}

##' Render Excel file for certificate output
##'
##' Internal helper function to render XLS/XLSX files.
##'
##' @param path - Path to the Excel file
##' @param comment - Comment describing the file
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom readxl read_excel
##' @keywords internal
render_manifest_excel <- function(path, comment, name = basename(path)) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    data <- readxl::read_excel(path)
    cat("Partial content of tabular data:", "\n\n")
    cat("\\scriptsize \n\n", "```txt\n")
    print(data)
    cat("\n\n``` \n\n", "\\normalsize \n\n")
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to read Excel file:", e$message))
  })
}

##' Find pandoc for converting manifest files
##'
##' Internal helper returning the command and leading arguments to run pandoc:
##' the pandoc rmarkdown finds (which includes the one Quarto bundles), else
##' `quarto pandoc`.
##'
##' @return A list with `cmd` and `args`, or NULL if no pandoc is available
##' @keywords internal
manifest_pandoc <- function() {
  if (rmarkdown::pandoc_available()) {
    return(list(cmd = rmarkdown::pandoc_exec(), args = character(0)))
  }
  quarto <- Sys.which("quarto")
  if (nzchar(quarto)) {
    return(list(cmd = unname(quarto), args = "pandoc"))
  }
  NULL
}

##' Render Word or RTF file for certificate output
##'
##' Internal helper function to render DOCX and RTF files, converted to Markdown
##' with pandoc. The format is detected by content, not by extension, because
##' some packages (e.g. apaTables) write RTF to `.doc` files. Binary Word 97
##' `.doc` files are not supported by pandoc and get a note instead. Images in
##' Word files are extracted next to the file; images LaTeX cannot include (e.g.
##' EMF, WMF) are replaced by a note.
##'
##' @param path - Path to the Word or RTF file
##' @param comment - Comment describing the file
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_office <- function(path, comment, name = basename(path), base_dir = NULL) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  magic <- readBin(path, "raw", n = 8)
  if (length(magic) >= 5 && identical(rawToChar(magic[1:5]), "{\\rtf")) {
    from <- "rtf"
  } else if (length(magic) >= 4 && identical(magic[1:4], as.raw(c(0x50, 0x4b, 0x03, 0x04)))) {
    from <- "docx"
  } else if (identical(magic, as.raw(c(0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1)))) {
    cat("*Note: legacy binary Word (.doc) files cannot be converted;",
        "export it as .docx, RTF or PDF to include it.*\n\n")
    return(invisible(NULL))
  } else {
    render_error_box(name, "Unrecognised Word/RTF file content")
    return(invisible(NULL))
  }

  pandoc <- manifest_pandoc()
  if (is.null(pandoc)) {
    render_error_box(name, "Word/RTF conversion requires pandoc (not found)")
    return(invisible(NULL))
  }

  media_dir <- paste0(path, "_media")
  tryCatch({
    md <- suppressWarnings(system2(pandoc$cmd,
      c(pandoc$args, shQuote(path), "-f", from, "-t", "markdown-raw_html",
        "-L", shQuote(system.file("extdata", "unquote.lua", package = "codecheck")),
        "--columns=200", "--shift-heading-level-by=2",
        "--extract-media", shQuote(media_dir)),
      stdout = TRUE, stderr = FALSE))
    status <- attr(md, "status")
    if (!is.null(status) && status != 0) {
      render_error_box(name, paste("pandoc conversion failed with status", status))
    } else {
      if (from == "rtf") {
        message(name, ": pandoc's RTF reader can drop characters (e.g. the opening ",
                "'[' of confidence intervals), compare the certificate with the original file")
      }
      cat("Content of", if (from == "rtf") "RTF" else "Word", "document (converted with pandoc):", "\n\n")
      # images pdflatex cannot include would fail the whole certificate
      md <- stringr::str_replace_all(paste(md, collapse = "\n"),
        "!\\[[^\\]]*\\]\\(<?([^)>\\s]+)>?[^)]*\\)(\\{[^}]*\\})?",
        function(img) {
          src <- stringr::str_match(img, "\\(<?([^)>\\s]+)")[, 2]
          ext <- tolower(tools::file_ext(src))
          ifelse(ext %in% c("png", "jpg", "jpeg", "pdf"), img,
                 paste0("*(image omitted: .", ext, " is not supported in the certificate)*"))
        })
      # pandoc links the extracted images by the media directory as given
      md <- gsub(media_dir, relative_to(media_dir, base_dir), md, fixed = TRUE)
      cat(md, "\n\n")
    }
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to convert Word/RTF file:", e$message))
  })
}

##' Render JSON file for certificate output
##'
##' Internal helper function to render JSON files with pretty-printing.
##'
##' @param path - Path to the JSON file
##' @param comment - Comment describing the file
##' @param max_lines - Maximum number of lines to display (default: 50)
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom jsonlite prettify fromJSON
##' @importFrom utils head
##' @keywords internal
render_manifest_json <- function(path, comment, max_lines = 50, name = basename(path)) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    # Read and prettify JSON
    json_content <- readLines(path, warn = FALSE)
    json_text <- paste(json_content, collapse = "\n")
    pretty_json <- jsonlite::prettify(json_text)

    cat("JSON content (pretty-printed):", "\n\n")
    cat("\\scriptsize \n\n", "```json\n")

    # Split into lines and limit if needed
    json_lines <- strsplit(pretty_json, "\n")[[1]]

    if (length(json_lines) > max_lines) {
      cat(head(json_lines, max_lines), sep = "\n")
      cat("\n... (", length(json_lines) - max_lines, " more lines omitted)\n", sep = "")
    } else {
      cat(json_lines, sep = "\n")
    }

    cat("\n\n``` \n\n", "\\normalsize \n\n")
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to read JSON file:", e$message))
  })
}

##' Render HTML file for certificate output
##'
##' Internal helper function to render HTML files (converts to PDF via wkhtmltopdf).
##'
##' @param path - Path to the HTML file
##' @param comment - Comment describing the file
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_html <- function(path, comment, name = basename(path)) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  if (Sys.which("wkhtmltopdf") == "") {
    render_error_box(name,
                    "HTML conversion requires wkhtmltopdf (not installed)")
    return(invisible(NULL))
  }

  tryCatch({
    cat("Content of HTML file (starts on next page):", "\n\n")
    out_file <- paste0(path, ".pdf")
    result <- system2("wkhtmltopdf", c(shQuote(path), shQuote(out_file)),
                     stdout = FALSE, stderr = FALSE)
    if (result == 0 && file.exists(out_file)) {
      cat(paste0("\\includepdf[pages={-}]{", out_file, "}"))
      cat("\n\n End of ", name, " on previous page.", "\n\n")
    } else {
      render_error_box(name, "HTML to PDF conversion failed")
    }
  }, error = function(e) {
    render_error_box(name,
                    paste("Failed to convert HTML file:", e$message))
  })
}

##' Render unsupported file type for certificate output
##'
##' Internal helper function to handle unsupported file types.
##'
##' @param path - Path to the file
##' @param comment - Comment describing the file
##' @inheritParams render_manifest_image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_unsupported <- function(path, comment, name = basename(path)) {
  cat("## ", name, "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(name, "File not found")
    return(invisible(NULL))
  }

  # Show file exists but format is not supported
  ext <- tools::file_ext(path)
  render_error_box(name,
                  paste0("Unsupported file format", if(nchar(ext) > 0) paste0(" (.", ext, ")") else ""))
}

##' Render manifest files for certificate output
##'
##' Renders each file in the manifest appropriately based on its file type.
##' Supported formats include images (PNG, JPG, JPEG, GIF, PDF, TIF, TIFF, EPS, SVG),
##' text files (TXT, Rout), tabular data (CSV, TSV) with skimr statistics, Excel files
##' (XLS, XLSX), Word and RTF documents (DOCX, RTF, and RTF saved as DOC; converted to
##' Markdown with pandoc), JSON files (pretty-printed), and HTML files (converted to PDF
##' via wkhtmltopdf). Binary Word 97 DOC files are not supported and get a note.
##'
##' For PDF files that contain multiple pages, all pages are included using
##' \\includepdf[pages=\{-\}]. Page count is determined using the pdftools package.
##' SVG files are converted to PDF using the rsvg package. TIF/TIFF and GIF files are converted
##' to PNG using the magick package (must be installed). EPS files are included
##' directly (LaTeX handles the conversion with epstopdf package). JSON files are
##' pretty-printed with a configurable line limit.
##'
##' Error handling: If a file is missing, corrupted, or cannot be processed, an error box
##' is displayed in the certificate output instead of failing the entire rendering. This
##' allows codecheckers to identify and fix issues with individual files without blocking
##' the certificate generation.
##'
##' @title Render manifest files for certificate output
##' @param manifest_df - data frame with manifest file information (from copy_manifest_files)
##' @param json_max_lines - Maximum number of lines to display for JSON files (default: 50)
##' @param base_dir - Directory to link the images relative to, or `NULL` to
##'   link them by their paths in `manifest_df`. Defaults to the document's
##'   directory when Quarto renders it, and `NULL` otherwise. Files are read by
##'   their paths in `manifest_df` either way.
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @author Daniel Nuest
##' @importFrom stringr str_ends
##' @export
render_manifest_files <- function(manifest_df, json_max_lines = 50,
                                  base_dir = quarto_document_dir()) {
  for (i in seq_len(nrow(manifest_df))) {
    path <- manifest_df[i, "dest"]
    comment <- manifest_df[i, "comment"]
    # The copy in outputs/ may have been renamed, show the manifest's name
    name <- basename(if ("output" %in% names(manifest_df)) manifest_df[i, "output"] else path)

    if (stringr::str_ends(path, "(png|jpg|jpeg|gif|tif|tiff)")) {
      render_manifest_image(path, comment, name = name, base_dir = base_dir)
    } else if (stringr::str_ends(path, "svg")) {
      render_manifest_svg(path, comment, name = name, base_dir = base_dir)
    } else if (stringr::str_ends(path, "eps")) {
      render_manifest_eps(path, comment, name = name, base_dir = base_dir)
    } else if (stringr::str_ends(path, "pdf")) {
      render_manifest_pdf(path, comment, name = name, base_dir = base_dir)
    } else if (stringr::str_ends(path, "(Rout|txt)")) {
      render_manifest_text(path, comment, name = name)
    } else if (stringr::str_ends(path, "csv")) {
      render_manifest_csv(path, comment, name = name)
    } else if (stringr::str_ends(path, "tsv")) {
      render_manifest_tsv(path, comment, name = name)
    } else if (stringr::str_ends(path, "json")) {
      render_manifest_json(path, comment, json_max_lines, name = name)
    } else if (stringr::str_ends(path, "(xls|xlsx)")) {
      render_manifest_excel(path, comment, name = name)
    } else if (stringr::str_ends(path, "(docx|doc|rtf)")) {
      render_manifest_office(path, comment, name = name, base_dir = base_dir)
    } else if (stringr::str_ends(path, "(htm|html)")) {
      render_manifest_html(path, comment, name = name)
    } else {
      render_manifest_unsupported(path, comment, name = name)
    }

    cat("\\clearpage \n\n")
  }
}

##' The directory of the document Quarto is rendering, or `NULL` otherwise
##'
##' Quarto rewrites an absolute path such as `/home/...` into `./home/...`,
##' which LaTeX cannot find (codecheckers/codecheck#93). rmarkdown keeps
##' absolute paths: it runs LaTeX in the output directory, which may not be the
##' document's. Quarto runs LaTeX in the document's directory, wherever R runs.
##'
##' @keywords internal
##' @noRd
quarto_document_dir <- function() {
  if (is.null(knitr::opts_knit$get("quarto.version")) &&
      !nzchar(Sys.getenv("QUARTO_DOCUMENT_PATH"))) {
    return(NULL)
  }
  input <- knitr::current_input(dir = TRUE)
  if (is.null(input)) NULL else dirname(input)
}

##' A path relative to a directory it lies under, otherwise unchanged
##'
##' Both are compared as absolute paths, so a symbolic link or `..` in either
##' does not matter.
##'
##' @param path A file path
##' @param base A directory, or `NULL` to keep `path` as it is
##' @keywords internal
##' @noRd
relative_to <- function(path, base) {
  if (is.null(base)) {
    return(path)
  }
  # The directory only, so that a symbolic link to the file itself stays as it
  # is, and a file not there (yet) resolves like its directory
  absolute <- file.path(normalizePath(dirname(path), winslash = "/", mustWork = FALSE),
                        basename(path))
  prefix <- paste0(sub("/+$", "", normalizePath(base, winslash = "/", mustWork = FALSE)), "/")
  if (startsWith(absolute, prefix)) substring(absolute, nchar(prefix) + 1) else path
}
