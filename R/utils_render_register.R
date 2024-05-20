load_markdown_table_template <- function(template_path){
  if (!file.exists(template_path)){
    stop("No register table template found")
  }

  markdown_table_template <- readLines(template_path)
  return(markdown_table_template)
}

adjust_markdown_title <- function(markdown_table, register_table_name){
  title_addition <- ""
  
  if (grepl("venue", register_table_name)){
    venue_name <- sub("^venue", "", register_table_name)
    title_addition <- paste0("for", venue_name)
  }

  markdown_table <- gsub("\\$title_addition\\$", title_addition, markdown_table)
  return(markdown_table)
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

#' Function for adding repository links to each report in the register table.
#' 
#' @param register_table The register table
#' @return register_table

add_repository_links_md <- function(register_table) {
  register_table$Repository <- sapply(
    X = register_table$Repository,
    FUN = function(repository) {
      spec <- parse_repository_spec(repository)
      if (!any(is.na(spec))) {
        urrl <- "#"

        switch(spec["type"],
          "github" = {
            urrl <- paste0("https://github.com/", spec[["repo"]])
            paste0("[", spec[["repo"]], "](", urrl, ")")
          },
          "osf" = {
            urrl <- paste0("https://osf.io/", spec[["repo"]])
            paste0("[", spec[["repo"]], "](", urrl, ")")
          },
          "gitlab" = {
            urrl <- paste0("https://gitlab.com/", spec[["repo"]])
            paste0("[", spec[["repo"]], "](", urrl, ")")
          },

          # Type is none of the above
          {
            repository
          }
        )
      } else {
        repository
      }
    }
  )
  return(register_table)
}

#' Function for adding repository links to each report in the register table.
#' 
#' @param register_table The register table
#' @return register_table

add_repository_links_html <- function(register_table) {
  register_table$Repository <- sapply(
    X = register_table$Repository,
    FUN = function(repository) {
      spec <- parse_repository_spec(repository)
      if (!any(is.na(spec))) {
        urrl <- "#"
        if (spec[["type"]] == "github") {
          urrl <- paste0("https://github.com/", spec[["repo"]])
          paste0("<i class='fa fa-github'></i>&nbsp;[", spec[["repo"]], "](", urrl, ")")
        } else if (spec[["type"]] == "osf") {
          urrl <- paste0("https://osf.io/", spec[["repo"]])
          paste0("<i class='ai ai-osf'></i>&nbsp;[", spec[["repo"]], "](", urrl, ")")
        } else if (spec[["type"]] == "gitlab") {
          urrl <- paste0("https://gitlab.com/", spec[["repo"]])
          paste0("<i class='fa fa-gitlab'></i>&nbsp;[", spec[["repo"]], "](", urrl, ")")
        } else {
          repository
        }
      } else {
        repository
      }
    }
  )
  return(register_table)
}

#' Function for adding repository links to each report in the register table.
#' 
#' @param register_table The register table
#' @return register_table

add_repository_links_json <- function(register_table) {
  register_table$`Repository Link` <- sapply(
    X = register_table$Repository,
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
  return(register_table)
}

render_register_md <- function(list_register_tables, md_columns_widths) {
  template_path <- system.file("extdata", "templates/template_register.md", package = "codecheck")

  # Looping over the list of register tables and creating a md file for each
  for (register_table_name in names(list_register_tables)) {
    markdown_table <- load_markdown_table_template(template_path)
    register_table <- list_register_tables[[register_table_name]]

    register_table <- add_repository_links_md(register_table)
    
    # Fill in the content
    markdown_content <- capture.output(kable(register_table, format = "markdown"))
    
    markdown_table <- adjust_markdown_title(markdown_table, register_table_name)
    markdown_table <- gsub("\\$content\\$", paste(markdown_content, collapse = "\n"), markdown_table)

    # Adjusting the column widths
    markdown_table <- unlist(strsplit(markdown_table, "\n", fixed = TRUE))

    alignment_line_index <- grep("^\\|:---", markdown_table)
    markdown_table[alignment_line_index] <- md_columns_widths

    # Determining the directory and saving the file
    output_dir <- determine_output_directory(register_table_name)
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = TRUE)
    }
    output_file_path <- paste0(output_dir, "/register.md")

    writeLines(markdown_table, output_file_path)
  }
}

#' Generates a html_document.yml with the full paths to the index header, prefix 
#' and postfix.html files. This is necessary to retrieve the correct .html files
#' when generating the htmls from the sorted register markdown files which exist
#' inside subdirectories

generate_html_document_yml <- function() {
  working_dir <- getwd()

  yaml_content <- sprintf(
    "html_document:
      includes:
        in_header: '%s/docs/index_header.html'
        before_body: '%s/docs/index_prefix.html'
        after_body: '%s/docs/index_postfix.html'
      mathjax: null
      highlight: null
      self_contained: false
      lib_dir: libs",
    working_dir, working_dir, working_dir
  )
  writeLines(yaml_content, "docs/html_document.yml")
}

#' Function for rendering the register html file. 
#' The html file is rendered from the markdown file.
#' 
#' @param register_table The register table
#' @param md_columns_widths The column widths for the markdown file
#' @return None


render_register_html <- function(list_register_tables, md_columns_widths) {
  template_path <- system.file("extdata", "templates/template_register.md", package = "codecheck")
  generate_html_document_yml()

  # Loop over each register table
  for (register_table_name in names(list_register_tables)) {
    markdown_table <- load_markdown_table_template(template_path)
    register_table <- list_register_tables[[register_table_name]]
    
    # Add icons to the Repository column for HTML output, use a copy of the register.md
    register_table <- add_repository_links_html(register_table)

    # Capture the HTML output in a markdown table first
    markdown_content <- capture.output(knitr::kable(register_table, format = "markdown"))
    
    markdown_table <- adjust_markdown_title(markdown_table, register_table_name)
    markdown_table <- gsub("\\$content\\$", paste(markdown_content, collapse = "\n"), markdown_table)

    # Adjust column width
    markdown_table <- unlist(strsplit(markdown_table, "\n", fixed = TRUE))
    alignment_line_index <- grep("^\\|:---", markdown_table)
    markdown_table[alignment_line_index] <- md_columns_widths

    # Determine the output path
    output_dir <- determine_output_directory(register_table_name)

    # Create the directory if it does not exist
    if (!dir.exists(dirname(output_dir))) {
      dir.create(dirname(output_dir), recursive = TRUE, showWarnings = TRUE)
    }
 
    # Save the modified markdown to a temporary file
    temp_file_path <- paste0(output_dir, "/temp-file.md")
    writeLines(markdown_table, temp_file_path)

    yaml_path <- normalizePath(file.path(getwd(), "docs/html_document.yml"))

    # Render HTML from markdown
    rmarkdown::render(
      input = temp_file_path,
      output_file = "index.html",
      output_dir = output_dir,
      output_yaml = yaml_path
    )
    file.remove(temp_file_path)
  }
}

#' Function for rendering the register json file. 
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return None

render_register_json <- function(list_register_tables, register) {
  for (register_table_name in names(list_register_tables)) {
    register_table <- list_register_tables[[register_table_name]]
    register_table <- add_repository_links_json(register_table)

    # Get paper titles and references
    titles <- c()
    references <- c()
    for (i in seq_len(nrow(register_table))) {
      config_yml <- get_codecheck_yml(register_table[i, ]$Repository)

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

    output_dir <- determine_output_directory(register_table_name)
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = TRUE)
    }

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
      path = paste0(output_dir, "/register.json"),
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
      path = paste0(output_dir, "/featured.json"),
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
      path = paste0(output_dir, "/stats.json"),
      pretty = TRUE
    )
  }
}
