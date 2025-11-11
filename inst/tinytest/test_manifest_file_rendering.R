# Comprehensive tests for manifest file rendering in certificates
# Tests that each supported file format renders correctly to PDF without errors
# and that expected content appears in the output

library(tinytest)

# Helper function to setup test environment with certificate template
setup_cert_env <- function(formats_to_test = "all") {
  test_root <- tempfile("cert_test_")
  dir.create(test_root, recursive = TRUE)

  # Copy template files
  template_dir <- system.file("extdata", "templates", "codecheck", package = "codecheck")
  if (template_dir == "") {
    # Package not installed, use source location
    template_dir <- file.path(getwd(), "inst", "extdata", "templates", "codecheck")
  }
  file.copy(file.path(template_dir, "codecheck.Rmd"),
            file.path(test_root, "codecheck.Rmd"))
  file.copy(file.path(template_dir, "codecheck-preamble.sty"),
            file.path(test_root, "codecheck-preamble.sty"))

  # Disable strict validation in the template for testing
  template_content <- readLines(file.path(test_root, "codecheck.Rmd"))
  template_content <- gsub("strict = TRUE", "strict = FALSE", template_content, fixed = TRUE)
  writeLines(template_content, file.path(test_root, "codecheck.Rmd"))

  # Copy test fixtures
  fixtures_dir <- system.file("tinytest", "fixtures", "manifest_formats", package = "codecheck")
  if (fixtures_dir == "" || !dir.exists(fixtures_dir)) {
    # Package not installed, try multiple possible locations
    possible_dirs <- c(
      file.path(getwd(), "inst", "tinytest", "fixtures", "manifest_formats"),
      file.path(dirname(getwd()), "inst", "tinytest", "fixtures", "manifest_formats"),
      file.path(getwd(), "fixtures", "manifest_formats")
    )
    for (d in possible_dirs) {
      if (dir.exists(d)) {
        fixtures_dir <- d
        break
      }
    }
  }

  if (!dir.exists(fixtures_dir)) {
    stop("Cannot find test fixtures directory. Tried: ", fixtures_dir)
  }

  # Determine which test files to copy based on formats_to_test
  if (length(formats_to_test) == 0) {
    test_files <- character(0)
  } else if (length(formats_to_test) == 1 && formats_to_test == "all") {
    test_files <- list.files(fixtures_dir, full.names = FALSE)
  } else {
    test_files <- formats_to_test
  }

  # Copy test files to test root
  for (f in test_files) {
    src_file <- file.path(fixtures_dir, f)
    dest_file <- file.path(test_root, f)
    if (file.exists(src_file)) {
      copied <- file.copy(src_file, dest_file, overwrite = TRUE)
      if (!copied) {
        stop("Failed to copy test fixture: ", src_file, " to ", dest_file)
      }
    } else {
      stop("Test fixture not found: ", src_file, "\nFixtures dir: ", fixtures_dir,
           "\nAvailable files: ", paste(list.files(fixtures_dir), collapse = ", "))
    }
  }

  # Create codecheck directory
  codecheck_dir <- file.path(test_root, "codecheck", "outputs")
  dir.create(codecheck_dir, recursive = TRUE)

  return(list(
    root = test_root,
    codecheck_dir = codecheck_dir,
    test_files = test_files
  ))
}

# Helper function to create codecheck.yml with specified manifest entries
create_test_yml <- function(root, manifest_entries) {
  # Use a real DOI from an actual CODECHECK to avoid validation failures
  yml_content <- sprintf('---
version: https://codecheck.org.uk/spec/config/1.0
paper:
  title: Test Manuscript for Manifest Rendering
  authors:
    - name: Test Author
      ORCID: 0000-0002-1825-0097
  reference: https://doi.org/10.1093/gigascience/giaa026
%s
codechecker:
  - name: Test Codechecker
    ORCID: 0000-0001-8607-8025
summary: Testing manifest file rendering for various file formats
repository: https://github.com/codecheckers/Piccolo-2020
check_time: "2024-11-06 12:00:00"
certificate: 2024-999
report: https://doi.org/10.5281/zenodo.9999999
', manifest_entries)

  writeLines(yml_content, file.path(root, "codecheck.yml"))
}

# Helper function to render certificate and capture output
render_certificate <- function(root) {
  output_file <- file.path(root, "codecheck", "codecheck.pdf")

  tryCatch({
    # Suppress messages but capture warnings and errors
    suppressMessages({
      rmarkdown::render(
        file.path(root, "codecheck.Rmd"),
        output_file = output_file,
        quiet = TRUE,
        envir = new.env()
      )
    })

    if (file.exists(output_file)) {
      return(list(success = TRUE, output_file = output_file, error = NULL))
    } else {
      return(list(success = FALSE, output_file = NULL, error = "PDF not created"))
    }
  }, error = function(e) {
    return(list(success = FALSE, output_file = NULL, error = as.character(e)))
  })
}

# Helper function to extract text from PDF
extract_pdf_text <- function(pdf_file) {
  if (!file.exists(pdf_file)) {
    return(NULL)
  }

  # Use pdftools package to extract text
  tryCatch({
    text <- pdftools::pdf_text(pdf_file)
    return(paste(text, collapse = "\n"))
  }, error = function(e) {
    message("Could not extract PDF text: ", e$message)
    return(NULL)
  })
}

# Test 1: PNG image renders without errors ----
env <- setup_cert_env(formats_to_test = "test_figure.png")
create_test_yml(env$root, 'manifest:
  - file: test_figure.png
    comment: Test figure in PNG format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("PNG rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF output file should exist")
}

# Check PDF contains figure reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_figure\\.png", pdf_text, ignore.case = TRUE),
              info = "PDF should reference PNG filename")
  expect_true(grepl("Comment: Test figure in PNG format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference PNG description")
}

unlink(env$root, recursive = TRUE)

# Test 2: JPG image renders without errors ----
env <- setup_cert_env(formats_to_test = "test_figure.jpg")
create_test_yml(env$root, 'manifest:
  - file: test_figure.jpg
    comment: Test figure in JPG format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("JPG rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF output file should exist")
}

# Check PDF contains figure reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_figure\\.jpg", pdf_text, ignore.case = TRUE),
              info = "PDF should reference JPG filename")
  expect_true(grepl("Comment: Test figure in JPG format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference JPG description")
}

unlink(env$root, recursive = TRUE)

# Test 3: JPEG image renders without errors ----
env <- setup_cert_env(formats_to_test = "test_figure.jpeg")
create_test_yml(env$root, 'manifest:
  - file: test_figure.jpeg
    comment: Test figure in JPEG format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("JPEG rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF output file should exist")
}

# Check PDF contains figure reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_figure\\.jpeg", pdf_text, ignore.case = TRUE),
              info = "PDF should reference JPEG filename")
  expect_true(grepl("Comment: Test figure in JPEG format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference JPEG description")
}

unlink(env$root, recursive = TRUE)

# Test 4: PDF figure renders without errors ----
env <- setup_cert_env(formats_to_test = "test_figure.pdf")
create_test_yml(env$root, 'manifest:
  - file: test_figure.pdf
    comment: Test figure in PDF format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("PDF figure rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF output file should exist")
}

# Check PDF contains figure reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_figure\\.pdf", pdf_text, ignore.case = TRUE),
              info = "PDF should reference PDF filename")
  expect_true(grepl("Comment: Test figure in PDF format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference PDF description")
}

unlink(env$root, recursive = TRUE)

# Test 4a: TIF image renders without errors ----
env <- setup_cert_env(formats_to_test = "test_figure.tif")
create_test_yml(env$root, 'manifest:
  - file: test_figure.tif
    comment: Test figure in TIF format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("TIF rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF output file should exist")
}

# Check PDF contains figure reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_figure\\.tif", pdf_text, ignore.case = TRUE),
              info = "PDF should reference TIF filename")
  expect_true(grepl("Comment: Test figure in TIF format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference TIF description")
}

unlink(env$root, recursive = TRUE)

# Test 4b: TIFF image renders without errors ----
env <- setup_cert_env(formats_to_test = "test_figure.tiff")
create_test_yml(env$root, 'manifest:
  - file: test_figure.tiff
    comment: Test figure in TIFF format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("TIFF rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF output file should exist")
}

# Check PDF contains figure reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_figure\\.tiff", pdf_text, ignore.case = TRUE),
              info = "PDF should reference TIFF filename")
  expect_true(grepl("Comment: Test figure in TIFF format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference TIFF description")
}

unlink(env$root, recursive = TRUE)

# Test 4c: EPS image renders without errors ----
env <- setup_cert_env(formats_to_test = "test_figure.eps")
create_test_yml(env$root, 'manifest:
  - file: test_figure.eps
    comment: Test figure in EPS format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("EPS rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF output file should exist")
}

# Check PDF contains figure reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_figure\\.eps", pdf_text, ignore.case = TRUE),
              info = "PDF should reference EPS filename")
  expect_true(grepl("Comment: Test figure in EPS format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference EPS description")
}

unlink(env$root, recursive = TRUE)

# Test 4d: SVG image renders without errors ----
env <- setup_cert_env(formats_to_test = "test_figure.svg")
create_test_yml(env$root, 'manifest:
  - file: test_figure.svg
    comment: Test figure in SVG format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("SVG rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF output file should exist")
}

# Check PDF contains figure reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_figure\\.svg", pdf_text, ignore.case = TRUE),
              info = "PDF should reference SVG filename")
  expect_true(grepl("Comment: Test figure in SVG format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference SVG description")
}

unlink(env$root, recursive = TRUE)

# Test 4e: Multi-page PDF renders with all pages ----
env <- setup_cert_env(formats_to_test = "multipage_figure.pdf")
create_test_yml(env$root, 'manifest:
  - file: multipage_figure.pdf
    comment: Multi-page figure PDF')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("Multi-page PDF rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF output file should exist")
}

# Check PDF contains figure reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("multipage_figure\\.pdf", pdf_text, ignore.case = TRUE),
              info = "PDF should reference multi-page PDF filename")
  expect_true(grepl("Comment: Multi-page figure PDF", pdf_text, ignore.case = TRUE),
              info = "PDF should reference multi-page PDF description")
}

unlink(env$root, recursive = TRUE)

# Test 5: TXT file renders with content visible ----
env <- setup_cert_env(formats_to_test = "test_output.txt")
create_test_yml(env$root, 'manifest:
  - file: test_output.txt
    comment: Test text output file')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("TXT rendering failed:", result$error))

# Verify expected content appears in PDF
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_output\\.txt", pdf_text, ignore.case = TRUE),
              info = "PDF should reference TXT filename")
  expect_true(grepl("Comment: Test text output file", pdf_text, ignore.case = TRUE),
              info = "PDF should reference TXT description")
  expect_true(grepl("CODECHECK Test Output", pdf_text),
              info = "TXT content should appear in PDF")
  expect_true(grepl("All tests passed successfully", pdf_text),
              info = "TXT file content should be readable")
  expect_true(grepl("Mean: 43\\.32", pdf_text),
              info = "Statistics from TXT should appear")
}

unlink(env$root, recursive = TRUE)

# Test 6: Rout file renders with R output visible ----
env <- setup_cert_env(formats_to_test = "analysis.Rout")
create_test_yml(env$root, 'manifest:
  - file: analysis.Rout
    comment: R analysis output')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("Rout rendering failed:", result$error))

# Verify R output appears in PDF
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("analysis\\.Rout", pdf_text, ignore.case = TRUE),
              info = "PDF should reference Rout filename")
  expect_true(grepl("Comment: R analysis output", pdf_text, ignore.case = TRUE),
              info = "PDF should reference Rout description")
  expect_true(grepl("R version", pdf_text),
              info = "R version info should appear")
  expect_true(grepl("summary\\(data", pdf_text) || grepl("Min\\.", pdf_text),
              info = "R output should be visible")
}

unlink(env$root, recursive = TRUE)

# Test 7: CSV file renders with skimr statistics ----
env <- setup_cert_env(formats_to_test = "test_data.csv")
create_test_yml(env$root, 'manifest:
  - file: test_data.csv
    comment: Test data in CSV format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("CSV rendering failed:", result$error))

# Check PDF contains file reference and data values
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_data\\.csv", pdf_text, ignore.case = TRUE),
              info = "PDF should reference CSV filename")
  expect_true(grepl("Comment: Test data in CSV format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference CSV description")
  # Verify actual data values appear (from skimr statistics or data)
  expect_true(grepl("name|value|category", pdf_text, ignore.case = TRUE),
              info = "CSV column names should appear")
  expect_true(grepl("Sample A|Sample B|Sample C", pdf_text, ignore.case = TRUE),
              info = "CSV sample names should appear")
  expect_true(grepl("42\\.5|38\\.2|51\\.0", pdf_text),
              info = "CSV numeric values should appear")
}

unlink(env$root, recursive = TRUE)

# Test 7a: TSV file renders with skimr statistics ----
env <- setup_cert_env(formats_to_test = "test_data.tsv")
create_test_yml(env$root, 'manifest:
  - file: test_data.tsv
    comment: Test data in TSV format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("TSV rendering failed:", result$error))

# Check PDF contains file reference and data values
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_data\\.tsv", pdf_text, ignore.case = TRUE),
              info = "PDF should reference TSV filename")
  expect_true(grepl("Comment: Test data in TSV format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference TSV description")
  # Verify actual data values appear (from skimr statistics or data)
  expect_true(grepl("name|value|category", pdf_text, ignore.case = TRUE),
              info = "TSV column names should appear")
  expect_true(grepl("Sample A|Sample B|Sample C", pdf_text, ignore.case = TRUE),
              info = "TSV sample names should appear")
  expect_true(grepl("42\\.5|38\\.2|51\\.0", pdf_text),
              info = "TSV numeric values should appear")
}

unlink(env$root, recursive = TRUE)

# Test 7b: JSON file renders with pretty-printed content ----
env <- setup_cert_env(formats_to_test = "test_register.json")
create_test_yml(env$root, 'manifest:
  - file: test_register.json
    comment: Test JSON data')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("JSON rendering failed:", result$error))

# Check PDF contains file reference and JSON data values
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_register\\.json", pdf_text, ignore.case = TRUE),
              info = "PDF should reference JSON filename")
  expect_true(grepl("Comment: Test JSON data", pdf_text, ignore.case = TRUE),
              info = "PDF should reference JSON description")
  # Verify actual JSON data values appear
  expect_true(grepl("2020-001|2020-002|2020-003", pdf_text),
              info = "JSON certificate IDs should appear")
  expect_true(grepl("GigaScience|community", pdf_text),
              info = "JSON venue values should appear")
  expect_true(grepl("ShinyLearner|principal components", pdf_text, ignore.case = TRUE),
              info = "JSON title values should appear")
}

unlink(env$root, recursive = TRUE)

# Test 8: XLSX file renders with content ----
env <- setup_cert_env(formats_to_test = "test_spreadsheet.xlsx")
create_test_yml(env$root, 'manifest:
  - file: test_spreadsheet.xlsx
    comment: Test spreadsheet in Excel format')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("XLSX rendering failed:", result$error))

# Verify Excel content appears in PDF
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_spreadsheet\\.xlsx", pdf_text, ignore.case = TRUE),
              info = "PDF should reference XLSX filename")
  expect_true(grepl("Comment: Test spreadsheet in Excel format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference XLSX description")
  expect_true(grepl("Partial content|tabular data", pdf_text, ignore.case = TRUE),
              info = "Should show Excel content label")
  expect_true(grepl("Sample A|Sample B", pdf_text) ||
              grepl("42\\.5|38\\.2", pdf_text),
              info = "Excel data should be visible")
}

unlink(env$root, recursive = TRUE)

# Test 9: HTML file renders (requires wkhtmltopdf) ----
if (Sys.which("wkhtmltopdf") != "") {
  env <- setup_cert_env(formats_to_test = "report.html")
  create_test_yml(env$root, 'manifest:
  - file: report.html
    comment: HTML report file')

  result <- render_certificate(env$root)
  expect_true(result$success, info = paste("HTML rendering failed:", result$error))

  # Verify HTML was processed
  if (!is.null(result$output_file)) {
    pdf_text <- extract_pdf_text(result$output_file)
    expect_true(grepl("report\\.html", pdf_text, ignore.case = TRUE),
                info = "PDF should reference HTML filename")
    expect_true(grepl("Comment: HTML report file", pdf_text, ignore.case = TRUE),
                info = "PDF should reference HTML description")
    expect_true(grepl("Content of HTML|CODECHECK Test Report", pdf_text, ignore.case = TRUE),
                info = "HTML content should be included")
  }

  unlink(env$root, recursive = TRUE)
}

# Test 10: Multiple file formats in single certificate ----
env <- setup_cert_env(formats_to_test = "all")
create_test_yml(env$root, 'manifest:
  - file: test_figure.png
    comment: Figure 1 - PNG format
  - file: test_figure.jpg
    comment: Figure 2 - JPG format
  - file: test_figure.tif
    comment: Figure 3 - TIF format
  - file: test_figure.eps
    comment: Figure 4 - EPS format
  - file: multipage_figure.pdf
    comment: Figure 5 - Multi-page PDF
  - file: test_output.txt
    comment: Analysis output
  - file: test_data.csv
    comment: Summary data (CSV)
  - file: test_data.tsv
    comment: Summary data (TSV)
  - file: test_register.json
    comment: JSON data file
  - file: test_spreadsheet.xlsx
    comment: Detailed results')

result <- render_certificate(env$root)
expect_true(result$success, info = paste("Multiple formats rendering failed:", result$error))
if (!is.null(result$output_file)) {
  expect_true(file.exists(result$output_file), info = "PDF with multiple formats should be created")
}

# Copy the test PDF to a permanent location for manual inspection
if (!is.null(result$output_file) && file.exists(result$output_file)) {
  inspection_dir <- system.file("tinytest", package = "codecheck")
  if (inspection_dir == "") {
    # Package not installed, use source location
    inspection_dir <- file.path(getwd(), "inst", "tinytest")
  }
  inspection_pdf <- file.path(inspection_dir, "test_manifest_rendering_output.pdf")
  file.copy(result$output_file, inspection_pdf, overwrite = TRUE)

  cat("\n")
  cat("================================================================================\n")
  cat("MANIFEST RENDERING TEST - MANUAL INSPECTION\n")
  cat("================================================================================\n")
  cat("Inspect the test output at:\n")
  cat("  ", inspection_pdf, "\n")
  cat("\nThis PDF contains examples of all supported manifest file formats:\n")
  cat("  - PNG, JPG, JPEG, TIF, TIFF, EPS, SVG (images)\n")
  cat("  - PDF (single and multi-page)\n")
  cat("  - TXT, Rout (text files)\n")
  cat("  - CSV, TSV (tabular data with skimr statistics)\n")
  cat("  - JSON (pretty-printed with configurable line limit)\n")
  cat("  - XLSX (Excel spreadsheet)\n")
  cat("  - HTML (converted to PDF via wkhtmltopdf)\n")
  cat("================================================================================\n")
  cat("\n")

  # Verify all formats are referenced and data values appear
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("test_figure\\.png", pdf_text, ignore.case = TRUE),
              info = "Should reference PNG file")
  expect_true(grepl("Comment: Figure 1 - PNG format", pdf_text, ignore.case = TRUE),
              info = "Should reference PNG description")
  expect_true(grepl("test_output\\.txt", pdf_text, ignore.case = TRUE),
              info = "Should reference TXT file")
  expect_true(grepl("Comment: Analysis output", pdf_text, ignore.case = TRUE),
              info = "Should reference TXT description")
  expect_true(grepl("CODECHECK Test Output|All tests passed", pdf_text),
              info = "TXT file content should appear")
  expect_true(grepl("test_data\\.csv", pdf_text, ignore.case = TRUE),
              info = "Should reference CSV file")
  expect_true(grepl("Comment: Summary data \\(CSV\\)", pdf_text, ignore.case = TRUE),
              info = "Should reference CSV description")
  expect_true(grepl("Sample A|Sample B|42\\.5|38\\.2", pdf_text),
              info = "CSV data values should appear")
  expect_true(grepl("test_register\\.json", pdf_text, ignore.case = TRUE),
              info = "Should reference JSON file")
  expect_true(grepl("2020-001|GigaScience", pdf_text),
              info = "JSON data values should appear")
}

unlink(env$root, recursive = TRUE)

# Test 11: manifest_files chunk is named correctly ----
# Check source template first (for development), then installed (for released package)
source_template <- file.path(getwd(), "inst", "extdata", "templates", "codecheck", "codecheck.Rmd")
if (file.exists(source_template)) {
  template_file <- source_template
} else {
  template_file <- system.file("extdata", "templates", "codecheck", "codecheck.Rmd",
                               package = "codecheck")
}

if (file.exists(template_file)) {
  template_content <- paste(readLines(template_file, warn = FALSE), collapse = "\n")
  expect_true(grepl("`{r manifest_files", template_content, fixed = TRUE),
              info = "Template should have named chunk 'manifest_files'")
} else {
  # Skip test if template not found
  cat("Skipping template chunk test - template file not found\n")
}

# Test 12: Unsupported file format handling ----
env <- setup_cert_env(formats_to_test = character(0))

# Create a fake unsupported file
writeLines("Binary data", file.path(env$root, "data.bin"))

create_test_yml(env$root, 'manifest:
  - file: data.bin
    comment: Unsupported binary file')

result <- render_certificate(env$root)
# Should still render but with "Cannot include" message
expect_true(result$success, info = "Should render even with unsupported format")

# Check PDF contains file reference
if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("data\\.bin", pdf_text, ignore.case = TRUE),
              info = "PDF should reference unsupported filename")
  expect_true(grepl("Comment: Unsupported binary file", pdf_text, ignore.case = TRUE),
              info = "PDF should reference unsupported file description")
}

unlink(env$root, recursive = TRUE)

# ==============================================================================
# ERROR HANDLING TESTS
# ==============================================================================
# These tests verify that the rendering is stable when dealing with erroneous
# files and that error messages are properly included in the PDF output to help
# codecheckers diagnose and fix issues.

# Test 13: Missing file reference - should render with error message ----
env <- setup_cert_env(formats_to_test = character(0))
create_test_yml(env$root, 'manifest:
  - file: nonexistent_file.txt
    comment: This file does not exist')

result <- render_certificate(env$root)
expect_true(result$success, info = "Should render even when manifest file is missing")

if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("nonexistent_file\\.txt", pdf_text, ignore.case = TRUE),
              info = "PDF should reference missing filename")
  expect_true(grepl("Comment: This file does not exist", pdf_text, ignore.case = TRUE),
              info = "PDF should reference missing file description")
  # Verify error message is included in PDF
  expect_true(grepl("Cannot include|Error:", pdf_text, ignore.case = TRUE),
              info = "Error message should be included in PDF output")
}

unlink(env$root, recursive = TRUE)

# Test 14: Broken CSV file - should handle gracefully with error message ----
env <- setup_cert_env(formats_to_test = "broken_data.csv")
create_test_yml(env$root, 'manifest:
  - file: broken_data.csv
    comment: CSV with malformed rows and inconsistent columns')

result <- render_certificate(env$root)
expect_true(result$success, info = "Should render even with broken CSV")

if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("broken_data\\.csv", pdf_text, ignore.case = TRUE),
              info = "PDF should reference CSV filename")
  expect_true(grepl("Comment: CSV with malformed rows", pdf_text, ignore.case = TRUE),
              info = "PDF should reference CSV description")
  # Verify error message is included to help codecheckers
  expect_true(grepl("Cannot include|Error:", pdf_text, ignore.case = TRUE),
              info = "Error message should be included in PDF output for broken CSV")
}

unlink(env$root, recursive = TRUE)

# Test 15: Invalid JSON file - should handle gracefully with error message ----
env <- setup_cert_env(formats_to_test = "invalid.json")
create_test_yml(env$root, 'manifest:
  - file: invalid.json
    comment: JSON with syntax errors')

result <- render_certificate(env$root)
expect_true(result$success, info = "Should render even with invalid JSON")

if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("invalid\\.json", pdf_text, ignore.case = TRUE),
              info = "PDF should reference JSON filename")
  expect_true(grepl("Comment: JSON with syntax errors", pdf_text, ignore.case = TRUE),
              info = "PDF should reference JSON description")
  # Verify error message is included to help codecheckers
  expect_true(grepl("Cannot include|Error:", pdf_text, ignore.case = TRUE),
              info = "Error message should be included in PDF output for invalid JSON")
}

unlink(env$root, recursive = TRUE)

# Test 16: Corrupted image file - should handle gracefully with error message ----
env <- setup_cert_env(formats_to_test = "corrupted_image.png")
create_test_yml(env$root, 'manifest:
  - file: corrupted_image.png
    comment: PNG file with corrupted data')

result <- render_certificate(env$root)
expect_true(result$success, info = "Should render even with corrupted image")

if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("corrupted_image\\.png", pdf_text, ignore.case = TRUE),
              info = "PDF should reference corrupted image filename")
  expect_true(grepl("Comment: PNG file with corrupted data", pdf_text, ignore.case = TRUE),
              info = "PDF should reference corrupted image description")
  # Images typically fail during LaTeX compilation, not in R code,
  # so we just verify the filename and comment are present
}

unlink(env$root, recursive = TRUE)

# Test 17: Malformed Excel file - should handle gracefully with error message ----
env <- setup_cert_env(formats_to_test = "malformed.xlsx")
create_test_yml(env$root, 'manifest:
  - file: malformed.xlsx
    comment: Excel file with invalid format')

result <- render_certificate(env$root)
expect_true(result$success, info = "Should render even with malformed Excel file")

if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)
  expect_true(grepl("malformed\\.xlsx", pdf_text, ignore.case = TRUE),
              info = "PDF should reference Excel filename")
  expect_true(grepl("Comment: Excel file with invalid format", pdf_text, ignore.case = TRUE),
              info = "PDF should reference Excel description")
  # Verify error message is included to help codecheckers
  expect_true(grepl("Cannot include|Error:", pdf_text, ignore.case = TRUE),
              info = "Error message should be included in PDF output for malformed Excel")
}

unlink(env$root, recursive = TRUE)

# Test 18: Multiple erroneous files together - comprehensive stability test ----
env <- setup_cert_env(formats_to_test = "all")
create_test_yml(env$root, 'manifest:
  - file: test_figure.png
    comment: Valid PNG for contrast
  - file: nonexistent_file.csv
    comment: Missing file
  - file: broken_data.csv
    comment: Broken CSV data
  - file: invalid.json
    comment: Invalid JSON
  - file: corrupted_image.png
    comment: Corrupted image
  - file: malformed.xlsx
    comment: Malformed Excel')

result <- render_certificate(env$root)
expect_true(result$success, info = "Should render with mix of valid and erroneous files")

if (!is.null(result$output_file)) {
  pdf_text <- extract_pdf_text(result$output_file)

  # Verify all files are referenced (even erroneous ones)
  expect_true(grepl("test_figure\\.png", pdf_text, ignore.case = TRUE),
              info = "Should reference valid PNG")
  expect_true(grepl("nonexistent_file\\.csv", pdf_text, ignore.case = TRUE),
              info = "Should reference missing file")
  expect_true(grepl("broken_data\\.csv", pdf_text, ignore.case = TRUE),
              info = "Should reference broken CSV")
  expect_true(grepl("invalid\\.json", pdf_text, ignore.case = TRUE),
              info = "Should reference invalid JSON")
  expect_true(grepl("corrupted_image\\.png", pdf_text, ignore.case = TRUE),
              info = "Should reference corrupted image")
  expect_true(grepl("malformed\\.xlsx", pdf_text, ignore.case = TRUE),
              info = "Should reference malformed Excel")

  # Comprehensive check: error messages should be present to help codecheckers
  # Count how many error messages are present (expect at least 3 from the broken files)
  error_count <- length(gregexpr("Cannot include|Error:", pdf_text, ignore.case = TRUE)[[1]])
  expect_true(error_count >= 3,
              info = paste("Should have multiple error messages to help codecheckers (found:", error_count, ")"))
}

unlink(env$root, recursive = TRUE)
