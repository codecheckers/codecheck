## latex summary of metadata
##
## https://daringfireball.net/2010/07/improved_regex_for_matching_urls
## To use the URL in R, I had to escape the \ characters and " -- this version
## does not work:
## .url_regexp = "(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?...]))"

## Have also converted the unicode into \uxxxx escapes to keep
## devtools::check() happy
## « -> \u00ab
## » -> \u00bb
## " -> \u201c
## " -> \u201d
## ' -> \u2018
## ' -> \u2019

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

  summary_entries = list(
    "Title of checked publication" = safe_value(metadata$paper$title),
    "Author(s)" =       safe_value(.names(metadata$paper$authors)),
    "Reference" =       safe_value(as_latex_url(metadata$paper$reference)),
    "Codechecker(s)" =  safe_value(.names(metadata$codechecker)),
    "Date of check" =   safe_value(metadata$check_time),
    "Summary" =         safe_value(metadata$summary),
    "Repository" =      safe_value(as_latex_url(metadata$repository)))

  # Create data frame - all entries now guaranteed to have a value
  summary_df = data.frame(Item=names(summary_entries),
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
##' @return The latex table, suitable for including in the Rmd
##' @author Stephen Eglen
##' @importFrom xtable xtable
##' @export
latex_summary_of_manifest <- function(metadata, manifest_df,
                                      root,
                                      align=c('l', 'p{6cm}', 'p{6cm}', 'p{2cm}')
                                      ) {
  m = manifest_df[, c("output", "comment", "size")]

  # Safely get repository URL
  # Handle NULL, empty, or list (multiple repositories)
  repo_url <- NULL
  if (!is.null(metadata$repository) && length(metadata$repository) > 0) {
    if (is.list(metadata$repository)) {
      # If multiple repositories, use the first one
      repo_url <- metadata$repository[[1]]
    } else if (is.character(metadata$repository) && nchar(metadata$repository) > 0) {
      repo_url <- metadata$repository
    }
  }

  # Generate URLs only if we have a valid repository
  if (!is.null(repo_url) && nchar(repo_url) > 0) {
    urls = sub(root, sprintf('%s/blob/master', repo_url), manifest_df$dest)
    m1 = sprintf('\\href{%s}{\\path{%s}}',
                 urls,
                 m[,1])
    m[,1] = m1
  } else {
    # No repository URL available - just use file paths without hyperlinks
    m[,1] = sprintf('\\path{%s}', m[,1])
  }

  names(m) = c("Output", "Comment", "Size (b)")
  xt = xtable(m,
              digits=0,
              caption="Summary of output files generated",
              align=align)
  print(xt, include.rownames=FALSE,
        sanitize.text.function = function(x){x},
        comment=FALSE)
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
                     names, year, metadata$certificate, metadata$report)
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
  cat("\\begin{center}\n")
  cat("\\fcolorbox{red}{yellow!20}{\\parbox{0.9\\textwidth}{\n")
  cat("\\textbf{\\textcolor{red}{\\Large \\ding{56}} Cannot include file: \\texttt{",
      filename, "}}\\\\\n", sep = "")
  cat("\\vspace{0.2cm}\n")
  cat("\\textbf{Error:} ", gsub("_", "\\\\_", error_msg, fixed = TRUE), "\n", sep = "")
  cat("}}\n")
  cat("\\end{center}\n\n")
}

##' Render single-page image for certificate output
##'
##' Internal helper function to render PNG, JPG, JPEG, TIF, TIFF, GIF images.
##' TIF/TIFF and GIF files are automatically converted to PNG since LaTeX doesn't natively support them.
##'
##' @param path - Path to the image file
##' @param comment - Comment/caption for the image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom magick image_read image_write
##' @keywords internal
render_manifest_image <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
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
      cat(paste0("![", comment, "](", png_path, ")\n"))
    }, error = function(e) {
      format_name <- toupper(ext)
      render_error_box(basename(path),
                      paste("Failed to convert", format_name, "image:", e$message))
    })
  } else {
    # PNG, JPG, JPEG - include directly
    tryCatch({
      cat(paste0("![", comment, "](", path, ")\n"))
    }, error = function(e) {
      render_error_box(basename(path),
                      paste("Failed to include image:", e$message))
    })
  }
}

##' Render EPS image for certificate output
##'
##' Internal helper function to render EPS files (LaTeX handles conversion).
##'
##' @param path - Path to the EPS file
##' @param comment - Comment/caption for the image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_eps <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    cat(paste0("![", comment, "](", path, ")\n"))
  }, error = function(e) {
    render_error_box(basename(path),
                    paste("Failed to include EPS image:", e$message))
  })
}

##' Render SVG image for certificate output
##'
##' Internal helper function to render SVG files (converts to PDF first).
##'
##' @param path - Path to the SVG file
##' @param comment - Comment/caption for the image
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom rsvg rsvg_pdf
##' @keywords internal
render_manifest_svg <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
    return(invisible(NULL))
  }

  # Convert SVG to PDF using rsvg package
  pdf_path <- sub("\\.svg$", "_converted.pdf", path)

  tryCatch({
    rsvg::rsvg_pdf(path, pdf_path)
    cat("\\textit{Note: SVG image automatically converted to PDF for display.}\n\n")
    cat(paste0("![", comment, "](", pdf_path, ")\n"))
  }, error = function(e) {
    render_error_box(basename(path),
                    paste("Failed to convert SVG image:", e$message))
  })
}

##' Render PDF file for certificate output
##'
##' Internal helper function to render PDF files (handles multi-page PDFs).
##'
##' @param path - Path to the PDF file
##' @param comment - Comment/caption for the PDF
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom pdftools pdf_info
##' @keywords internal
render_manifest_pdf <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
    return(invisible(NULL))
  }

  # Check if PDF has multiple pages using pdftools
  tryCatch({
    pdf_info <- pdftools::pdf_info(path)
    num_pages <- pdf_info$pages

    if (!is.na(num_pages) && num_pages > 1) {
      # Multi-page PDF - include all pages
      cat(paste0("\\includepdf[pages={-}]{", path, "}\n\n"))
      cat("End of ", basename(path), " (", num_pages, " pages).\n\n")
    } else {
      # Single-page PDF - include as image
      cat(paste0("![", comment, "](", path, ")\n"))
    }
  }, error = function(e) {
    render_error_box(basename(path),
                    paste("Failed to process PDF file:", e$message))
  })
}

##' Render text file for certificate output
##'
##' Internal helper function to render TXT and Rout files.
##'
##' @param path - Path to the text file
##' @param comment - Comment describing the file
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_text <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    cat("\\scriptsize \n\n", "```txt\n")
    cat(readLines(path, warn = FALSE), sep = "\n")
    cat("\n\n``` \n\n", "\\normalsize \n\n")
  }, error = function(e) {
    render_error_box(basename(path),
                    paste("Failed to read text file:", e$message))
  })
}

##' Render CSV file for certificate output
##'
##' Internal helper function to render CSV files with skimr statistics.
##'
##' @param path - Path to the CSV file
##' @param comment - Comment describing the file
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_csv <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    data <- read.csv(path)
    cat("Summary statistics of tabular data:", "\n\n")
    cat("\\scriptsize \n\n", "```txt\n")
    print(skimr::skim(data))
    cat("\n\n``` \n\n", "\\normalsize \n\n")
  }, error = function(e) {
    render_error_box(basename(path),
                    paste("Failed to read CSV file:", e$message))
  })
}

##' Render TSV file for certificate output
##'
##' Internal helper function to render TSV files with skimr statistics.
##'
##' @param path - Path to the TSV file
##' @param comment - Comment describing the file
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom utils read.delim
##' @keywords internal
render_manifest_tsv <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    data <- read.delim(path)
    cat("Summary statistics of tabular data:", "\n\n")
    cat("\\scriptsize \n\n", "```txt\n")
    print(skimr::skim(data))
    cat("\n\n``` \n\n", "\\normalsize \n\n")
  }, error = function(e) {
    render_error_box(basename(path),
                    paste("Failed to read TSV file:", e$message))
  })
}

##' Render Excel file for certificate output
##'
##' Internal helper function to render XLS/XLSX files.
##'
##' @param path - Path to the Excel file
##' @param comment - Comment describing the file
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom readxl read_excel
##' @keywords internal
render_manifest_excel <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
    return(invisible(NULL))
  }

  tryCatch({
    data <- readxl::read_excel(path)
    cat("Partial content of tabular data:", "\n\n")
    cat("\\scriptsize \n\n", "```txt\n")
    print(data)
    cat("\n\n``` \n\n", "\\normalsize \n\n")
  }, error = function(e) {
    render_error_box(basename(path),
                    paste("Failed to read Excel file:", e$message))
  })
}

##' Render JSON file for certificate output
##'
##' Internal helper function to render JSON files with pretty-printing.
##'
##' @param path - Path to the JSON file
##' @param comment - Comment describing the file
##' @param max_lines - Maximum number of lines to display (default: 50)
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @importFrom jsonlite prettify fromJSON
##' @importFrom utils head
##' @keywords internal
render_manifest_json <- function(path, comment, max_lines = 50) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
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
    render_error_box(basename(path),
                    paste("Failed to read JSON file:", e$message))
  })
}

##' Render HTML file for certificate output
##'
##' Internal helper function to render HTML files (converts to PDF via wkhtmltopdf).
##'
##' @param path - Path to the HTML file
##' @param comment - Comment describing the file
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_html <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
    return(invisible(NULL))
  }

  if (Sys.which("wkhtmltopdf") == "") {
    render_error_box(basename(path),
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
      cat("\n\n End of ", basename(path), " on previous page.", "\n\n")
    } else {
      render_error_box(basename(path), "HTML to PDF conversion failed")
    }
  }, error = function(e) {
    render_error_box(basename(path),
                    paste("Failed to convert HTML file:", e$message))
  })
}

##' Render unsupported file type for certificate output
##'
##' Internal helper function to handle unsupported file types.
##'
##' @param path - Path to the file
##' @param comment - Comment describing the file
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @keywords internal
render_manifest_unsupported <- function(path, comment) {
  cat("## ", basename(path), "\n\n")
  cat("**Comment:** ", comment, "\n\n")

  # Check if file exists
  if (!file.exists(path)) {
    render_error_box(basename(path), "File not found")
    return(invisible(NULL))
  }

  # Show file exists but format is not supported
  ext <- tools::file_ext(path)
  render_error_box(basename(path),
                  paste0("Unsupported file format", if(nchar(ext) > 0) paste0(" (.", ext, ")") else ""))
}

##' Render manifest files for certificate output
##'
##' Renders each file in the manifest appropriately based on its file type.
##' Supported formats include images (PNG, JPG, JPEG, GIF, PDF, TIF, TIFF, EPS, SVG),
##' text files (TXT, Rout), tabular data (CSV, TSV) with skimr statistics, Excel files
##' (XLS, XLSX), JSON files (pretty-printed), and HTML files (converted to PDF via wkhtmltopdf).
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
##' @return NULL (outputs directly via cat() for knitr/rmarkdown)
##' @author Daniel Nuest
##' @importFrom stringr str_ends
##' @export
render_manifest_files <- function(manifest_df, json_max_lines = 50) {
  for (i in seq_len(nrow(manifest_df))) {
    path <- manifest_df[i, "dest"]
    comment <- manifest_df[i, "comment"]

    if (stringr::str_ends(path, "(png|jpg|jpeg|gif|tif|tiff)")) {
      render_manifest_image(path, comment)
    } else if (stringr::str_ends(path, "svg")) {
      render_manifest_svg(path, comment)
    } else if (stringr::str_ends(path, "eps")) {
      render_manifest_eps(path, comment)
    } else if (stringr::str_ends(path, "pdf")) {
      render_manifest_pdf(path, comment)
    } else if (stringr::str_ends(path, "(Rout|txt)")) {
      render_manifest_text(path, comment)
    } else if (stringr::str_ends(path, "csv")) {
      render_manifest_csv(path, comment)
    } else if (stringr::str_ends(path, "tsv")) {
      render_manifest_tsv(path, comment)
    } else if (stringr::str_ends(path, "json")) {
      render_manifest_json(path, comment, json_max_lines)
    } else if (stringr::str_ends(path, "(xls|xlsx)")) {
      render_manifest_excel(path, comment)
    } else if (stringr::str_ends(path, "(htm|html)")) {
      render_manifest_html(path, comment)
    } else {
      render_manifest_unsupported(path, comment)
    }

    cat("\\clearpage \n\n")
  }
}
