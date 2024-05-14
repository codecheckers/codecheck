load_template_file <- function(template_path){
  if (!file.exists(template_path)){
    stop("No register table template found")
  }

  template_content <- readLines(template_path)
  return(template_content)
}

adjust_markdown_title <- function(markdown_table, register_table_name){
  title_addition <- ""
  
  if (grepl("venue", register_table_name)){
    venue_name <- sub("^venue", "", register_table_name)
    title_addition <- paste("for", venue_name, "")
  }

  markdown_table <- gsub("\\$title_addition\\$", title_addition, markdown_table)
  return(markdown_table)
}

#' Function for rendering the register markdown file.
#' 
#' @param register_table The register table
#' @param md_columns_widths The column widths for the markdown file
#' @return None

render_register_md <- function(list_register_tables, md_columns_widths) {
  template_path <- system.file("extdata", "template_register.md", package = "codecheck")
  template_content <- load_template_file(template_path)

  # Looping over the list of register tables and creating a md file for each
  for (register_table_name in names(list_register_tables)) {
    register_table <- list_register_tables[[register_table_name]]
    
    markdown_table <- adjust_markdown_title(template_content, register_table_name)
    
    # Fill in the content
    markdown_content <- capture.output(kable(register_table, format = "markdown"))
    markdown_table <- gsub("\\$content\\$", paste(markdown_content, collapse = "\n"), markdown_table)

    # Adding column width
    markdown_table <- unlist(strsplit(markdown_table, "\n", fixed = TRUE))
    markdown_table[7] <- md_columns_widths

    # Writing the output
    output_file_path <- determine_output_directory(register_table_name)
    # Creating the directory if it does not exist
    if (!dir.exists(output_file_path)) {
      dir.create(output_file_path, recursive = TRUE, showWarnings = TRUE)
    }
    output_file_path <- paste(output_file_path, "/register.md", sep = "")

    writeLines(markdown_table, output_file_path)
  }
}

#' Function for rendering the register html file. 
#' The html file is rendered from the markdown file.
#' 
#' @param register_table The register table
#' @param md_columns_widths The column widths for the markdown file
#' @return None


render_register_html <- function(list_register_tables, md_columns_widths) {
  template_path <- system.file("extdata", "template_register.md", package = "codecheck")
  template_content <- load_template_file(template_path)

  # Loop over each register table
  for (register_table_name in names(list_register_tables)) {
    register_table <- list_register_tables[[register_table_name]]

    # Adjust the title in the markdown template
    markdown_table <- adjust_markdown_title(template_content, register_table_name)

    # Add icons to the Repository column for HTML output, use a copy of the register.md
    register_table$Repository <- sapply(
      X = register_table$Repository,
      FUN = function(repository) {
        spec <- parse_repository_spec(repository)
        if (!any(is.na(spec))) {
          urrl <- "#"
          if (spec[["type"]] == "github") {
            urrl <- paste0("https://github.com/", spec[["repo"]])
            return(paste0("<i class='fa fa-github'></i>&nbsp;[", spec[["repo"]], "](", urrl, ")"))
          } else if (spec[["type"]] == "osf") {
            urrl <- paste0("https://osf.io/", spec[["repo"]])
            return(paste0("<i class='ai ai-osf'></i>&nbsp;[", spec[["repo"]], "](", urrl, ")"))
          } else if (spec[["type"]] == "gitlab") {
            urrl <- paste0("https://gitlab.com/", spec[["repo"]])
            return(paste0("<i class='fa fa-gitlab'></i>&nbsp;[", spec[["repo"]], "](", urrl, ")"))
          } else {
            return(repository)
          }
        } else {
          return(repository)
        }
      }
    )

    # Capture the HTML output in a markdown table first
    markdown_content <- capture.output(knitr::kable(register_table, format = "markdown"))
    markdown_table <- gsub("\\$content\\$", paste(markdown_content, collapse = "\n"), markdown_table)

    # Adjust column width
    markdown_table <- unlist(strsplit(markdown_table, "\n", fixed = TRUE))
    markdown_table[7] <- md_columns_widths

    # Determine the output path
    output_file_path <- determine_output_directory(register_table_name, "html")
    output_file_path <- paste(output_file_path, "/index.html", sep = "")

    # Create the directory if it does not exist
    if (!dir.exists(dirname(output_file_path))) {
      dir.create(dirname(output_file_path), recursive = TRUE, showWarnings = TRUE)
    }

    # Save the modified markdown to a temporary file
    temp_md_file <- tempfile(fileext = ".md")
    writeLines(markdown_table, temp_md_file)

    # Render HTML from markdown
    rmarkdown::render(
      input = temp_md_file,
      output_file = output_file_path,
      output_yaml = paste0("html_document.yml")
    )

    # Optionally remove the temporary markdown file
    file.remove(temp_md_file)
  }
}

# Helper function to determine output paths based on the table name
determine_output_directory <- function(register_table_name) {
  if (grepl("venue", register_table_name)){
    folder_venue_name <- sub("^venue", "", register_table_name)
    folder_venue_name <- trimws(folder_venue_name) # Removing trailing space
    folder_venue_name <- gsub(" ", "_", gsub("[()]", "", folder_venue_name))
    return(paste0("docs/venues/", folder_venue_name))
  } else {
    return(paste0("docs"))
  }
}

#' Function for rendering the register json file. 
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return None

render_register_json <- function(register_table, register) {
  # Get paper titles and references
  titles <- c()
  references <- c()

  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml(register[i, ]$Repo)

    title <- NA
    reference <- NA
    if (!is.null(config_yml)) {
      title <- config_yml$paper$title
      reference <- config_yml$paper$reference
    }

    titles <- c(titles, title)
    references <- c(references, reference)
  }

  register_table$Title <- stringr::str_trim(titles)
  register_table$`Paper reference` <- stringr::str_trim(references)
  register_table$`Repository Link` <- sapply(
    X = register$Repository,
    FUN = function(repository) {
      spec <- parse_repository_spec(repository)
      if (spec[["type"]] == "github") {
        paste0("https://github.com/", spec[["repo"]])
      } else if (spec[["type"]] == "osf") {
        paste0("https://osf.io/", spec[["repo"]])
      } else if (spec[["type"]] == "gitlab") {
        paste0("https://gitlab.com/", spec[["repo"]])
      } else {
        repository
      }
    }
  )

  jsonlite::write_json(
    register_table[, c(
      "Certificate",
      "Repository Link",
      "Type",
      "Report",
      "Title",
      "Paper reference",
      "Check date"
    )],
    path = "docs/register.json",
    pretty = TRUE
  )

  jsonlite::write_json(
    utils::tail(register_table, 10)[, c(
      "Certificate",
      "Repository Link",
      "Type",
      "Report",
      "Title",
      "Paper reference",
      "Check date"
    )],
    path = "docs/featured.json",
    pretty = TRUE
  )

  jsonlite::write_json(
    list(
      source = "https://codecheck.org.uk/register/register.json",
      cert_count = nrow(register_table)
      # TODO count conferences, preprints,
      # journals, etc.
    ),
    auto_unbox = TRUE,
    path = "docs/stats.json",
    pretty = TRUE
  )
}
