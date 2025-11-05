##' Create template files for the codecheck process.
##'
##' This function simply creates some template files to help start the
##' codecheck process.  If either ./codecheck.yml or codecheck/ exists then
##' it assumes you have already started codechecking, and so will not copy any
##' files across.
##' @title Create template files for the codecheck process.
##' @return Nothing
##' @author Stephen J. Eglen
##' @export
create_codecheck_files <- function() {
  if (file.exists("codecheck.yml"))
    warning("codecheck.yml already exists, so not overwriting it.",
            "See the template file at ",
            system.file("extdata", "templates/codecheck.yml", package="codecheck"),
            " for required metadata and examples.")
  else
    copy_codecheck_yaml_template()
  
  if (dir.exists("codecheck"))
    stop("codecheck folder exists, so stopping.")
  else
    copy_codecheck_report_template()
}

copy_codecheck_yaml_template <- function(target = ".") {
  templates <- system.file("extdata", "templates", package="codecheck")
  file.copy(file.path(templates, "codecheck.yml"), target)
  cat("Created codecheck.yml file at ", target, "\n")
}

copy_codecheck_report_template <- function(target = ".") {
  templates <- system.file("extdata", "templates", package="codecheck")
  file.copy(file.path(templates, "codecheck"), target, recursive = TRUE)
  cat("Created CODECHECK certificate files at ", target, ":", toString(list.files("codecheck")), "\n")
}

##' Return the metadata for the codecheck project in root folder of project
##'
##' Loads and parses the codecheck.yml file from the specified directory.
##' If the file doesn't exist, stops with a clear error message.
##'
##' @title Return the metadata for the codecheck project in root folder of project
##' @param root Path to the root folder of the project, defaults to current working directory
##' @return A list containing the metadata found in the codecheck.yml file
##' @author Stephen Eglen
##' @importFrom yaml read_yaml
##' @export
codecheck_metadata <- function(root = getwd()) {
  yml_path <- file.path(root, "codecheck.yml")

  if (!file.exists(yml_path)) {
    stop("No codecheck.yml file found in directory: ", root, "\n",
         "Please create a codecheck.yml file first using create_codecheck_files() ",
         "or run this function from a directory containing a codecheck.yml file.")
  }

  read_yaml(yml_path)
}

##' Copy manifest files into the root/codecheck/outputs folder; return manifest.
##'
##' The metadata should specify the manifest -- the files to copy into the
##' codecheck/oututs folder.  Each of the files in the manifest is copied into
##' the destination directory and then the manifest is returned as a dataframe.
##' If KEEP_FULL_PATH is TRUE, we keep the full path for the output files.
##' This is useful when there are two output files with the same name in
##' different folders, e.g. expt1/out.pdf and expt2/out.pdf
##' 
##' @title Copy files from manifest into the codecheck folder and summarise.
##' @param root - Path to the root folder of the project.
##' @param metadata - the codecheck metadata list.
##' @param dest_dir - folder where outputs are to be copied to (codecheck/outputs)
##' @param keep_full_path - TRUE to keep relative pathname of figures.
##' @param overwrite - TRUE to overwrite the output files even if they already exist
##' @return A dataframe containing one row per manifest file.
##' @author Stephen Eglen
##' @export
copy_manifest_files <- function(root, metadata, dest_dir,
                                keep_full_path = FALSE,
                                overwrite = FALSE) {
  manifest = metadata$manifest
  outputs = sapply(manifest, function(x) x$file)
  src_files = file.path(root, outputs)
  missing = !file.exists(src_files)
  if (any(missing)) {
    err = paste("Manifest files missing:\n",
                paste(src_files[missing], sep='\n'))
    stop(err)
  }

  dest_files = file.path(dest_dir,
                         if ( keep_full_path) outputs else basename(outputs))

  ## See if we need to make extra directories in the codecheck/outputs
  if (keep_full_path) {
    for (d in dest_files) {
      dir = dirname(d)
      if ( !dir.exists(dir) )
        dir.create(dir, recursive=TRUE)
    }
  }
  
  if (overwrite) message("Overwriting output files: ", toString(dest_files))
  file.copy(src_files, dest_files, overwrite = overwrite)
  
  manifest_df = data.frame(output=outputs,
                           comment=sapply(manifest, function(x) x$comment),
                           dest=dest_files,
                           size=file.size(dest_files),
                           stringsAsFactors = FALSE)
  manifest_df
}

##' List manifest.
##'
##' @title Summarise manifest files.
##' @param root - Path to the root folder of the project.
##' @param metadata - the codecheck metadata list.
##' @param check_dir - folder where outputs have been copied to (codecheck/outputs)
##' @return A dataframe containing one row per manifest file.
##' @author Daniel Nüst
##' @export
list_manifest_files <- function(root, metadata, check_dir) {
  manifest = metadata$manifest
  outputs = sapply(manifest, function(x) x$file)
  dest_files = file.path(check_dir, basename(outputs))
  manifest_df = data.frame(output=outputs,
                           comment=sapply(manifest, function(x) x$comment),
                           dest=dest_files,
                           size=file.size(dest_files),
                           stringsAsFactors = FALSE)
  manifest_df
}

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
## “ -> \u201c  
## ” -> \u201d
## ‘ -> \u2018
## ’ -> \u2019

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
  cat("\\vspace*{2cm}")
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

#' Create a new Zenodo record and return its pre-assigned DOI
#'
#' Run this only once per new codecheck. By default, loads metadata from
#' codecheck.yml in the current working directory.
#' @title Create a new Zenodo record and return its pre-assigned DOI
#' @param zen Object from zen4R to interact with Zenodo
#' @param metadata codecheck.yml metadata (list). Defaults to loading from
#'   codecheck.yml in the current working directory using \code{codecheck_metadata(getwd())}.
#' @param warn Ask for user input before creating a new record
#' @return Number of Zenodo record created
#' @author Stephen Eglen
#' @importFrom zen4R ZenodoRecord
#' @importFrom utils askYesNo
#'
#' @export
get_or_create_zenodo_record <- function(zen, metadata = codecheck_metadata(getwd()), warn=TRUE) {
  id <- get_zenodo_id(metadata$report)
  if (!is.na(id)) {
    my_rec <- zen$getDepositionById(id)
  } else {
    ## no record, create a new one.
    if(warn) {
      proceed <- askYesNo("You do not have a Zenodo record yet; I can fix this for you but please make sure your codecheck.yaml is saved, as I will need to update it. Proceed?")
      stopifnot(proceed==TRUE)
    }
    my_rec <- zen$createEmptyRecord()
  }
  my_rec
}
  
    
##   myrec <- zen$createEmptyRecord()
##   this_doi = myrec$metadata$prereserve_doi$doi
##   cat("The following URL is your Zenodo DOI.\n")
##   cat("Please add this to codecheck.yml in report: field\n")
##   print(paste0(CONFIG$HYPERLINKS[["doi"]], this_doi))
##   cat("Remember to reload the yaml file after editing it.\n")
##   get_zenodo_record(this_doi)
## }




##' Extract the Zenodo record number from the report URL
##'
##' The report paramater should contain a URL like:
##' http://doi.org/10.5281/zenodo.3750741 where the final part of the
##' URL is zenodo.X where X is a number containing at least 7 digits.
##' X is returned.  If we cannot extract the number X, we return an
##' error, in which case the function create_zenodo_record() can be
##' run to create a new record.  Alternatively, the report URL is
##' pre-assigned a DOI when manually creating the record.
##' 
##' @title Extract the Zenodo record number from the report URL
##' @param report - string containing the report URL on Zenodo.
##' @return the Zenodo record number (a number with at least 7 digits).
##' @author Stephen Eglen
##' @importFrom stringr str_match
##' @export
get_zenodo_id <- function(report) {
  result = str_match(report, "10\\.5281/zenodo\\.([0-9]{7,})")[2]
  as.integer(result)
}

#' Get the full Zenodo record from the metadata
#'
#' Retrieve the Zenodo record, if one exists. By default, loads metadata from
#' codecheck.yml in the current working directory.
#' If no record number is currently listed in the metadata (i.e. the "FIXME" tag is still there)
#' then the code returns NULL and an empty record should be created.
#' @title Get the full zenodo record using the record number stored in the metadata.
#' @param zenodo An object from zen4R to connect with Zenodo
#' @param metadata A codecheck configuration (list). Defaults to loading from
#'   codecheck.yml in the current working directory using \code{codecheck_metadata(getwd())}.
#' @return The Zenodo record, or NULL.
#' @author Stephen Eglen
#' @export
get_zenodo_record <- function(zenodo, metadata = codecheck_metadata(getwd())) {
  id <- get_zenodo_id(metadata$report)
  if (is.na(id)) {
    NULL
  } else {
    zenodo$getDepositionById(id)
  }
}

#' Upload codecheck metadata to Zenodo.
#'
#' The contents of codecheck.yml are uploaded to Zenodo using this function.
#' By default, loads metadata from codecheck.yml in the current working directory.
#'
#' @title Upload metadata to Zenodo
#' @param zenodo object from zen4R to connect with Zenodo
#' @param myrec a Zenodo record object
#' @param metadata codecheck metadata (list). Defaults to loading from
#'   codecheck.yml in the current working directory using \code{codecheck_metadata(getwd())}.
#' @return rec -- the updated record.
#' @author Stephen Eglen
#' @export
upload_zenodo_metadata <- function(zenodo, myrec, metadata = codecheck_metadata(getwd())) {

  ##draft$setPublicationType("report")
  ##draft$setCommunities(communities = c("codecheck"))
  myrec$metadata <- NULL
  myrec$setTitle(paste("CODECHECK certificate", metadata$certificate))
  myrec$addLanguage(language = "eng")
  myrec$setLicense("cc-by-4.0")

  myrec$metadata$creators <- NULL
  num_creators <- length(metadata$codechecker)
  for (i in 1:num_creators) {
    myrec$addCreator(
            name  = metadata$codechecker[[i]]$name,
            orcid = metadata$codechecker[[i]]$ORCID)
  }

  myrec$setPublicationDate(substring(metadata$check_time, 1, 10))
  myrec$setPublisher("CODECHECK")
  myrec$setResourceType("publication-preprint")

  description_text <- paste("CODECHECK certificate for paper:",
                           metadata$paper$title)
  repo_url <- gsub("[<>]", "", metadata$repository)
  description_text <- paste(description_text,
                           sprintf('<p><p>Repository: <a href="%s">%s</a>',
                                   repo_url, repo_url))
  myrec$setDescription(description_text)
  myrec$setSubjects(subjects= c("CODECHECK"))
  myrec$setNotes(notes = c("See file LICENSE for license of the contained code. The report document codecheck.pdf is published under CC-BY 4.0 International."))
  ##myrec$setAccessRight(accessRight = "open")
  ##myrec$addRelatedIdentifier(relation = "isSupplementTo", identifier = metadata$repository)
  ##myrec$addRelatedIdentifier(relation = "isSupplementTo", identifier = metadata$paper$reference)
  cat(paste0("Check your record online at ",  myrec$links$self_html, "\n"))
  myrec <- zenodo$depositRecord(myrec)

}


#' Upload the CODECHECK certificate to Zenodo.
#'
#' Upload the CODECHECK certificate to Zenodo as a draft.  Warning: if
#' the file has already been uploaded once, you will need to delete it via
#' the web interface before being able to upload a new versin.
#' @title Upload the CODECHECK certificate to Zenodo.
#' @param zen - Object from zen4R to interact with Zenodo
#' @param record - string containing the report URL on Zenodo.
#' @param certificate name of the PDF file.
#' @return NULL
#' @author Stephen Eglen
#' @export
set_zenodo_certificate <- function(zen, record, certificate) {
  draft <- zen$getDepositionById(record)
  stopifnot(file.exists(certificate))
  invisible(zen$uploadFile(certificate, draft$id))
}

## We deliberately do not provide a function to publish the certificate.
## You should go check it yourself.


## Helper functions
add_id_to_yml <- function(id, yml_file) {
  ## Add id to the yaml file.
  data1 <- readLines(yml_file)
  data2 <- gsub(pattern = "zenodo.FIXME$",
                replacement = paste0("zenodo.",id),
                x = data1)
  writeLines(data2, yml_file)
}


##' Retrieve metadata from Lifecycle Journal via CrossRef API
##'
##' Fetches article metadata from the Lifecycle Journal using either a
##' submission ID or a DOI. The metadata includes title, authors with ORCIDs,
##' abstract, and publication date.
##'
##' @title Retrieve metadata from Lifecycle Journal
##' @param identifier Either a Lifecycle Journal submission ID (e.g., "10", "7")
##'   or a full DOI (e.g., "10.71240/lcyc.355146"). If the identifier doesn't
##'   contain a dot, it's treated as a submission ID and converted to a DOI.
##' @return A list containing parsed metadata with elements:
##'   \describe{
##'     \item{title}{Article title}
##'     \item{authors}{List of authors, each with \code{name} and optionally \code{ORCID}}
##'     \item{abstract}{Article abstract (if available)}
##'     \item{reference}{The DOI URL}
##'     \item{date}{Publication date}
##'   }
##' @author Daniel Nüst
##' @importFrom httr GET content status_code
##' @importFrom jsonlite fromJSON
##' @export
##' @examples
##' \dontrun{
##'   # Using submission ID
##'   meta <- get_lifecycle_metadata("10")
##'
##'   # Using full DOI
##'   meta <- get_lifecycle_metadata("10.71240/lcyc.355146")
##' }
get_lifecycle_metadata <- function(identifier) {
  # Convert submission ID to DOI if needed
  if (!grepl("\\.", identifier)) {
    doi <- paste0("10.71240/lcyc.", identifier)
    message("Converting submission ID to DOI: ", doi)
  } else if (grepl("^10\\.71240/lcyc\\.", identifier)) {
    doi <- identifier
  } else {
    stop("Identifier must be either a Lifecycle Journal submission ID or a DOI starting with 10.71240/lcyc.")
  }

  # Fetch metadata from CrossRef API
  api_url <- paste0("https://api.crossref.org/works/", doi)
  message("Fetching metadata from CrossRef: ", api_url)

  response <- httr::GET(api_url)

  if (httr::status_code(response) != 200) {
    stop("Failed to retrieve metadata from CrossRef. Status code: ",
         httr::status_code(response),
         "\nPlease check that the identifier is correct.")
  }

  data <- httr::content(response, "parsed")$message

  # Parse authors with ORCIDs
  authors <- lapply(data$author, function(author) {
    author_data <- list(name = paste(author$given, author$family))

    # Extract ORCID if available
    if (!is.null(author$ORCID)) {
      # Remove the URL prefix if present, keep only the ID
      orcid <- sub("^https?://orcid\\.org/", "", author$ORCID)
      author_data$ORCID <- orcid
    }

    author_data
  })

  # Extract abstract if available
  abstract <- if (!is.null(data$abstract)) {
    # Remove XML tags that might be present
    gsub("<[^>]+>", "", data$abstract)
  } else {
    NULL
  }

  # Build the metadata list
  metadata <- list(
    title = data$title[[1]],
    authors = authors,
    reference = paste0("https://doi.org/", doi),
    date = data$created$`date-parts`[[1]]
  )

  if (!is.null(abstract)) {
    metadata$abstract <- abstract
  }

  metadata
}


##' Update codecheck.yml with Lifecycle Journal metadata
##'
##' Updates the local codecheck.yml file with metadata retrieved from the
##' Lifecycle Journal. By default, shows a diff of what would be changed
##' without actually modifying the file. Use \code{apply_updates = TRUE} to
##' apply the changes.
##'
##' @title Update codecheck.yml with Lifecycle Journal metadata
##' @param identifier Either a Lifecycle Journal submission ID or DOI
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param apply_updates Logical. If \code{TRUE}, actually update the file.
##'   If \code{FALSE} (default), only show what would be changed.
##' @param overwrite_existing Logical. If \code{TRUE}, overwrite existing
##'   non-empty fields. If \code{FALSE} (default), only populate empty or
##'   placeholder fields.
##' @return Invisibly returns the updated metadata list
##' @author Daniel Nüst
##' @importFrom yaml read_yaml write_yaml
##' @export
##' @examples
##' \dontrun{
##'   # Preview changes without applying them
##'   update_codecheck_yml_from_lifecycle("10")
##'
##'   # Apply changes to the file
##'   update_codecheck_yml_from_lifecycle("10", apply_updates = TRUE)
##'
##'   # Overwrite existing fields
##'   update_codecheck_yml_from_lifecycle("10", apply_updates = TRUE,
##'                                        overwrite_existing = TRUE)
##' }
update_codecheck_yml_from_lifecycle <- function(identifier,
                                                 yml_file = "codecheck.yml",
                                                 apply_updates = FALSE,
                                                 overwrite_existing = FALSE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file,
         "\nPlease create it first using create_codecheck_files().")
  }

  # Read existing metadata
  existing <- yaml::read_yaml(yml_file)

  # Fetch Lifecycle metadata
  lifecycle_meta <- get_lifecycle_metadata(identifier)

  # Create a copy for updates
  updated <- existing

  # Track changes
  changes <- list()

  # Helper function to check if a field should be updated
  should_update <- function(current_value) {
    if (overwrite_existing) {
      return(TRUE)
    }
    # Update if empty, NULL, or contains placeholder text
    is.null(current_value) ||
      identical(current_value, "") ||
      grepl("FIXME|TODO|template|example", current_value, ignore.case = TRUE)
  }

  # Update title
  if (should_update(existing$paper$title)) {
    changes$title <- list(
      old = existing$paper$title,
      new = lifecycle_meta$title
    )
    updated$paper$title <- lifecycle_meta$title
  }

  # Update authors
  if (should_update(existing$paper$authors) || length(existing$paper$authors) == 0) {
    changes$authors <- list(
      old = existing$paper$authors,
      new = lifecycle_meta$authors
    )
    updated$paper$authors <- lifecycle_meta$authors
  }

  # Update reference
  if (should_update(existing$paper$reference)) {
    changes$reference <- list(
      old = existing$paper$reference,
      new = lifecycle_meta$reference
    )
    updated$paper$reference <- lifecycle_meta$reference
  }

  # Print diff
  if (length(changes) > 0) {
    cat("\n")
    cat("=" , rep("=", 78), "\n", sep = "")
    cat("CHANGES TO BE APPLIED TO ", yml_file, "\n", sep = "")
    cat("=" , rep("=", 78), "\n", sep = "")
    cat("\n")

    for (field_name in names(changes)) {
      cat("Field: ", field_name, "\n", sep = "")
      cat(rep("-", 80), "\n", sep = "")
      cat("OLD:\n")
      if (field_name == "authors") {
        for (i in seq_along(changes[[field_name]]$old)) {
          author <- changes[[field_name]]$old[[i]]
          cat("  - name: ", author$name, "\n", sep = "")
          if (!is.null(author$ORCID)) {
            cat("    ORCID: ", author$ORCID, "\n", sep = "")
          }
        }
      } else {
        cat("  ", changes[[field_name]]$old, "\n", sep = "")
      }

      cat("\nNEW:\n")
      if (field_name == "authors") {
        for (i in seq_along(changes[[field_name]]$new)) {
          author <- changes[[field_name]]$new[[i]]
          cat("  - name: ", author$name, "\n", sep = "")
          if (!is.null(author$ORCID)) {
            cat("    ORCID: ", author$ORCID, "\n", sep = "")
          }
        }
      } else {
        cat("  ", changes[[field_name]]$new, "\n", sep = "")
      }
      cat("\n")
    }

    cat("=" , rep("=", 78), "\n", sep = "")

    if (apply_updates) {
      yaml::write_yaml(updated, yml_file)
      cat("\n✓ Changes applied to ", yml_file, "\n\n", sep = "")
    } else {
      cat("\n⚠ No changes applied. Use apply_updates = TRUE to save changes.\n\n")
    }
  } else {
    cat("\nNo changes needed. All fields are already populated.\n")
    cat("Use overwrite_existing = TRUE to force updates.\n\n")
  }

  invisible(updated)
}


##' Analyze and complete codecheck.yml with missing fields
##'
##' Analyzes a codecheck.yml file to identify missing mandatory and optional
##' fields according to the CODECHECK specification (https://codecheck.org.uk/spec/config/1.0/).
##' Can add placeholders for missing fields. By default, shows what would be
##' changed without actually modifying the file.
##'
##' The function identifies three categories of fields:
##' \itemize{
##'   \item \strong{Mandatory fields}: manifest, codechecker, report
##'   \item \strong{Recommended fields}: version, paper (title, authors, reference)
##'   \item \strong{Optional fields}: source, summary, repository, check_time, certificate
##' }
##'
##' @title Analyze and complete codecheck.yml with missing fields
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param add_mandatory Logical. If \code{TRUE}, add placeholders for all
##'   missing mandatory fields. Default is \code{FALSE}.
##' @param add_optional Logical. If \code{TRUE}, add placeholders for all
##'   missing optional and recommended fields. Default is \code{FALSE}.
##' @param apply_updates Logical. If \code{TRUE}, actually update the file.
##'   If \code{FALSE} (default), only show what would be changed.
##' @return Invisibly returns a list with two elements:
##'   \describe{
##'     \item{missing}{List of missing fields by category (mandatory, recommended, optional)}
##'     \item{updated}{The updated metadata list (if changes were made)}
##'   }
##' @author Daniel Nüst
##' @importFrom yaml read_yaml write_yaml
##' @export
##' @examples
##' \dontrun{
##'   # Analyze current codecheck.yml
##'   result <- complete_codecheck_yml()
##'
##'   # Add mandatory fields only
##'   complete_codecheck_yml(add_mandatory = TRUE, apply_updates = TRUE)
##'
##'   # Add all missing fields
##'   complete_codecheck_yml(add_mandatory = TRUE, add_optional = TRUE,
##'                          apply_updates = TRUE)
##' }
complete_codecheck_yml <- function(yml_file = "codecheck.yml",
                                   add_mandatory = FALSE,
                                   add_optional = FALSE,
                                   apply_updates = FALSE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file,
         "\nPlease create it first using create_codecheck_files().")
  }

  # Read existing metadata
  existing <- yaml::read_yaml(yml_file)

  # Define field specifications
  mandatory_fields <- list(
    manifest = list(
      type = "list",
      placeholder = list(list(file = "FIXME.pdf", comment = "FIXME: describe this output file"))
    ),
    codechecker = list(
      type = "list",
      placeholder = list(list(name = "FIXME", ORCID = "0000-0000-0000-0000"))
    ),
    report = list(
      type = "string",
      placeholder = "https://doi.org/10.5281/zenodo.FIXME"
    )
  )

  recommended_fields <- list(
    version = list(
      type = "string",
      placeholder = "https://codecheck.org.uk/spec/config/1.0/"
    ),
    paper = list(
      type = "list",
      placeholder = list(
        title = "FIXME: Paper title",
        authors = list(list(name = "FIXME", ORCID = "0000-0000-0000-0000")),
        reference = "https://FIXME"
      )
    )
  )

  optional_fields <- list(
    source = list(
      type = "string",
      placeholder = "FIXME: Description of material provenance"
    ),
    summary = list(
      type = "string",
      placeholder = "FIXME: Short summary of the CODECHECK certificate"
    ),
    repository = list(
      type = "string",
      placeholder = "https://FIXME"
    ),
    check_time = list(
      type = "string",
      placeholder = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    ),
    certificate = list(
      type = "string",
      placeholder = "YYYY-NNN"
    )
  )

  # Helper function to check if a field is missing or empty
  is_missing_or_placeholder <- function(value) {
    is.null(value) ||
      identical(value, "") ||
      (is.list(value) && length(value) == 0) ||
      (is.character(value) && grepl("FIXME|TODO|template|example", value, ignore.case = TRUE))
  }

  # Analyze missing fields
  missing <- list(
    mandatory = character(0),
    recommended = character(0),
    optional = character(0)
  )

  for (field in names(mandatory_fields)) {
    if (is_missing_or_placeholder(existing[[field]])) {
      missing$mandatory <- c(missing$mandatory, field)
    }
  }

  for (field in names(recommended_fields)) {
    if (is_missing_or_placeholder(existing[[field]])) {
      missing$recommended <- c(missing$recommended, field)
    }
  }

  for (field in names(optional_fields)) {
    if (is_missing_or_placeholder(existing[[field]])) {
      missing$optional <- c(missing$optional, field)
    }
  }

  # Print analysis
  cat("\n")
  cat("=", rep("=", 78), "\n", sep = "")
  cat("CODECHECK.YML ANALYSIS FOR ", yml_file, "\n", sep = "")
  cat("=", rep("=", 78), "\n", sep = "")
  cat("\n")

  cat("Missing MANDATORY fields:\n")
  if (length(missing$mandatory) > 0) {
    for (field in missing$mandatory) {
      cat("  - ", field, "\n", sep = "")
    }
  } else {
    cat("  (none - all mandatory fields present)\n")
  }
  cat("\n")

  cat("Missing RECOMMENDED fields:\n")
  if (length(missing$recommended) > 0) {
    for (field in missing$recommended) {
      cat("  - ", field, "\n", sep = "")
    }
  } else {
    cat("  (none - all recommended fields present)\n")
  }
  cat("\n")

  cat("Missing OPTIONAL fields:\n")
  if (length(missing$optional) > 0) {
    for (field in missing$optional) {
      cat("  - ", field, "\n", sep = "")
    }
  } else {
    cat("  (none - all optional fields present)\n")
  }
  cat("\n")

  # Build updated configuration if requested
  updated <- existing
  changes <- list()

  if (add_mandatory) {
    for (field in missing$mandatory) {
      changes[[field]] <- list(
        old = existing[[field]],
        new = mandatory_fields[[field]]$placeholder,
        category = "mandatory"
      )
      updated[[field]] <- mandatory_fields[[field]]$placeholder
    }
  }

  if (add_optional) {
    for (field in missing$recommended) {
      changes[[field]] <- list(
        old = existing[[field]],
        new = recommended_fields[[field]]$placeholder,
        category = "recommended"
      )
      updated[[field]] <- recommended_fields[[field]]$placeholder
    }

    for (field in missing$optional) {
      changes[[field]] <- list(
        old = existing[[field]],
        new = optional_fields[[field]]$placeholder,
        category = "optional"
      )
      updated[[field]] <- optional_fields[[field]]$placeholder
    }
  }

  # Print changes if any
  if (length(changes) > 0) {
    cat("=", rep("=", 78), "\n", sep = "")
    cat("CHANGES TO BE APPLIED\n")
    cat("=", rep("=", 78), "\n", sep = "")
    cat("\n")

    for (field_name in names(changes)) {
      change <- changes[[field_name]]
      cat("Field: ", field_name, " (", toupper(change$category), ")\n", sep = "")
      cat(rep("-", 80), "\n", sep = "")

      cat("OLD:\n")
      if (is.null(change$old)) {
        cat("  (field does not exist)\n")
      } else if (is.list(change$old)) {
        cat("  ", yaml::as.yaml(change$old), sep = "")
      } else {
        cat("  ", change$old, "\n", sep = "")
      }

      cat("\nNEW:\n")
      if (is.list(change$new)) {
        cat("  ", yaml::as.yaml(change$new), sep = "")
      } else {
        cat("  ", change$new, "\n", sep = "")
      }
      cat("\n")
    }

    cat("=", rep("=", 78), "\n", sep = "")

    if (apply_updates) {
      yaml::write_yaml(updated, yml_file)
      cat("\n✓ Changes applied to ", yml_file, "\n\n", sep = "")
    } else {
      cat("\n⚠ No changes applied. Use apply_updates = TRUE to save changes.\n\n")
    }
  } else {
    if (add_mandatory || add_optional) {
      cat("No fields to add.\n\n")
    } else {
      cat("Use add_mandatory = TRUE and/or add_optional = TRUE to add placeholders.\n\n")
    }
  }

  invisible(list(missing = missing, updated = if(length(changes) > 0) updated else NULL))
}


##' Validate codecheck.yml metadata against CrossRef
##'
##' Retrieves metadata from CrossRef for the paper's DOI and compares it with
##' the local codecheck.yml metadata. Validates title and author information
##' (names and ORCIDs against CrossRef data).
##'
##' This function is useful for ensuring consistency between the published paper
##' metadata and the CODECHECK certificate, helping to catch typos, outdated
##' information, or missing data.
##'
##' Note: For comprehensive validation including ORCID name verification and
##' codechecker validation, use \code{validate_contents_references()} instead.
##'
##' @title Validate codecheck.yml metadata against CrossRef
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param strict Logical. If \code{TRUE}, throw an error on any mismatch.
##'   If \code{FALSE} (default), only issue warnings.
##' @param check_orcids Logical. If \code{TRUE} (default), validate ORCID
##'   identifiers. If \code{FALSE}, skip ORCID validation.
##' @return Invisibly returns a list with validation results:
##'   \describe{
##'     \item{valid}{Logical indicating if all checks passed}
##'     \item{issues}{Character vector of any issues found}
##'     \item{crossref_metadata}{The metadata retrieved from CrossRef (if available)}
##'   }
##' @author Daniel Nüst
##' @importFrom httr GET content status_code
##' @export
##' @examples
##' \dontrun{
##'   # Validate with warnings only
##'   result <- validate_codecheck_yml_crossref()
##'
##'   # Validate with strict error checking
##'   validate_codecheck_yml_crossref(strict = TRUE)
##'
##'   # Skip ORCID validation
##'   validate_codecheck_yml_crossref(check_orcids = FALSE)
##' }
validate_codecheck_yml_crossref <- function(yml_file = "codecheck.yml",
                                            strict = FALSE,
                                            check_orcids = TRUE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file)
  }

  # Read local metadata
  local_meta <- yaml::read_yaml(yml_file)

  issues <- character(0)
  crossref_meta <- NULL

  # Check if paper metadata exists
  if (is.null(local_meta$paper)) {
    issues <- c(issues, "No paper metadata found in codecheck.yml")
    if (strict) {
      stop("Validation failed: No paper metadata found in codecheck.yml")
    }
    return(invisible(list(valid = FALSE, issues = issues, crossref_metadata = NULL)))
  }

  # Check if paper reference (DOI) exists
  if (is.null(local_meta$paper$reference)) {
    issues <- c(issues, "No paper reference (DOI) found in codecheck.yml")
    if (strict) {
      stop("Validation failed: No paper reference found")
    }
    return(invisible(list(valid = FALSE, issues = issues, crossref_metadata = NULL)))
  }

  # Extract DOI from reference
  paper_ref <- local_meta$paper$reference

  # Skip validation if reference contains placeholder
  if (grepl("FIXME|TODO|template|example", paper_ref, ignore.case = TRUE)) {
    message("Skipping CrossRef validation: paper reference contains placeholder")
    return(invisible(list(valid = TRUE, issues = character(0), crossref_metadata = NULL)))
  }

  # Try to extract DOI
  doi <- sub("^https?://(dx\\.)?doi\\.org/", "", paper_ref)
  doi <- sub("^doi:", "", doi)

  # Fetch metadata from CrossRef
  api_url <- paste0("https://api.crossref.org/works/", doi)
  message("Fetching metadata from CrossRef: ", api_url)

  response <- tryCatch(
    httr::GET(api_url),
    error = function(e) {
      issues <<- c(issues, paste("Failed to connect to CrossRef API:", e$message))
      return(NULL)
    }
  )

  if (is.null(response)) {
    if (strict) {
      stop("Validation failed: Could not connect to CrossRef API")
    }
    return(invisible(list(valid = FALSE, issues = issues, crossref_metadata = NULL)))
  }

  if (httr::status_code(response) != 200) {
    msg <- paste0("CrossRef API returned status code ", httr::status_code(response),
                  " for DOI: ", doi)
    issues <- c(issues, msg)
    if (strict) {
      stop("Validation failed: ", msg)
    }
    return(invisible(list(valid = FALSE, issues = issues, crossref_metadata = NULL)))
  }

  crossref_meta <- httr::content(response, "parsed")$message

  # Validate title
  if (!is.null(local_meta$paper$title) && !is.null(crossref_meta$title)) {
    local_title <- tolower(trimws(local_meta$paper$title))
    # CrossRef returns title as a list, take first element
    crossref_title <- tolower(trimws(crossref_meta$title[[1]]))

    # Remove common differences (punctuation, extra spaces)
    local_title_clean <- gsub("[[:punct:]]", "", gsub("\\s+", " ", local_title))
    crossref_title_clean <- gsub("[[:punct:]]", "", gsub("\\s+", " ", crossref_title))

    if (local_title_clean != crossref_title_clean) {
      issue <- paste0("Title mismatch:\n",
                     "  Local:    ", local_meta$paper$title, "\n",
                     "  CrossRef: ", crossref_meta$title[[1]])
      issues <- c(issues, issue)
      warning(issue)
    } else {
      message("✓ Title matches CrossRef metadata")
    }
  }

  # Validate authors
  if (!is.null(local_meta$paper$authors) && !is.null(crossref_meta$author)) {
    local_authors <- local_meta$paper$authors
    crossref_authors <- crossref_meta$author

    # Check author count
    if (length(local_authors) != length(crossref_authors)) {
      issue <- paste0("Author count mismatch: local has ", length(local_authors),
                     " authors, CrossRef has ", length(crossref_authors), " authors")
      issues <- c(issues, issue)
      warning(issue)
    }

    # Compare each author
    for (i in seq_along(local_authors)) {
      if (i > length(crossref_authors)) break

      local_author <- local_authors[[i]]
      crossref_author <- crossref_authors[[i]]

      # Build full name from CrossRef
      crossref_name <- paste(
        if (!is.null(crossref_author$given)) crossref_author$given else "",
        if (!is.null(crossref_author$family)) crossref_author$family else ""
      )
      crossref_name <- trimws(crossref_name)

      # Compare names (case-insensitive)
      if (!is.null(local_author$name)) {
        local_name_clean <- tolower(trimws(local_author$name))
        crossref_name_clean <- tolower(trimws(crossref_name))

        # Allow for different name formats (e.g., "John Smith" vs "Smith, John")
        # Just check if key parts are present
        local_parts <- strsplit(local_name_clean, "\\s+")[[1]]
        crossref_parts <- strsplit(crossref_name_clean, "\\s+")[[1]]

        # Check if all significant parts match (at least 2 characters)
        local_parts_sig <- local_parts[nchar(local_parts) >= 2]
        crossref_parts_sig <- crossref_parts[nchar(crossref_parts) >= 2]

        if (!all(local_parts_sig %in% crossref_parts_sig) &&
            !all(crossref_parts_sig %in% local_parts_sig)) {
          issue <- paste0("Author ", i, " name mismatch:\n",
                         "  Local:    ", local_author$name, "\n",
                         "  CrossRef: ", crossref_name)
          issues <- c(issues, issue)
          warning(issue)
        } else {
          message("✓ Author ", i, " name matches: ", local_author$name)
        }
      }

      # Compare ORCIDs if checking is enabled
      if (check_orcids && !is.null(local_author$ORCID)) {
        if (!is.null(crossref_author$ORCID)) {
          # Normalize ORCIDs (remove URL prefix if present)
          local_orcid <- sub("^https?://orcid\\.org/", "", local_author$ORCID)
          crossref_orcid <- sub("^https?://orcid\\.org/", "", crossref_author$ORCID)

          if (local_orcid != crossref_orcid) {
            issue <- paste0("Author ", i, " ORCID mismatch:\n",
                           "  Local:    ", local_orcid, "\n",
                           "  CrossRef: ", crossref_orcid)
            issues <- c(issues, issue)
            warning(issue)
          } else {
            message("✓ Author ", i, " ORCID matches: ", local_orcid)
          }
        } else {
          msg <- paste0("Author ", i, " has ORCID in local file but not in CrossRef")
          message("ℹ ", msg)
        }
      }
    }
  }

  # Final validation result
  valid <- length(issues) == 0

  if (!valid) {
    message("\n⚠ Validation completed with ", length(issues), " issue(s)")
    if (strict) {
      stop("Validation failed with ", length(issues), " issue(s):\n",
           paste(issues, collapse = "\n"))
    }
  } else {
    message("\n✓ All validations passed!")
  }

  invisible(list(
    valid = valid,
    issues = issues,
    crossref_metadata = crossref_meta
  ))
}


##' Validate codecheck.yml metadata against ORCID
##'
##' Validates author and codechecker information against the ORCID API.
##' For each person with an ORCID, retrieves their ORCID record and compares
##' the name in the ORCID record with the name in the local codecheck.yml file.
##'
##' @title Validate codecheck.yml metadata against ORCID
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param strict Logical. If \code{TRUE}, throw an error on any mismatch.
##'   If \code{FALSE} (default), only issue warnings.
##' @param validate_authors Logical. If \code{TRUE} (default), validate author ORCIDs.
##' @param validate_codecheckers Logical. If \code{TRUE} (default), validate codechecker ORCIDs.
##' @return Invisibly returns a list with validation results:
##'   \describe{
##'     \item{valid}{Logical indicating if all checks passed}
##'     \item{issues}{Character vector of any issues found}
##'   }
##' @author Daniel Nüst
##' @importFrom rorcid orcid_person
##' @export
##' @examples
##' \dontrun{
##'   # Validate with warnings only
##'   result <- validate_codecheck_yml_orcid()
##'
##'   # Validate with strict error checking
##'   validate_codecheck_yml_orcid(strict = TRUE)
##'
##'   # Validate only codecheckers
##'   validate_codecheck_yml_orcid(validate_authors = FALSE)
##' }
validate_codecheck_yml_orcid <- function(yml_file = "codecheck.yml",
                                         strict = FALSE,
                                         validate_authors = TRUE,
                                         validate_codecheckers = TRUE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file)
  }

  # Read local metadata
  local_meta <- yaml::read_yaml(yml_file)

  issues <- character(0)

  # Helper function to normalize names for comparison
  normalize_name <- function(name) {
    tolower(trimws(gsub("\\s+", " ", name)))
  }

  # Helper function to extract name from ORCID record
  get_orcid_name <- function(orcid_id) {
    tryCatch({
      # Query ORCID API
      person_data <- rorcid::orcid_person(orcid_id)

      if (is.null(person_data) || length(person_data) == 0) {
        return(NULL)
      }

      # Extract name from nested structure
      name_data <- person_data[[1]]$name

      if (is.null(name_data)) {
        return(NULL)
      }

      # Try to get given and family names
      given_names <- name_data$`given-names`$value
      family_name <- name_data$`family-name`$value

      if (!is.null(given_names) && !is.null(family_name)) {
        return(paste(given_names, family_name))
      } else if (!is.null(family_name)) {
        return(family_name)
      } else if (!is.null(given_names)) {
        return(given_names)
      }

      return(NULL)
    }, error = function(e) {
      warning("Failed to retrieve ORCID record for ", orcid_id, ": ", e$message)
      return(NULL)
    })
  }

  # Validate authors
  if (validate_authors && !is.null(local_meta$paper$authors)) {
    message("Validating author ORCIDs...")

    for (i in seq_along(local_meta$paper$authors)) {
      author <- local_meta$paper$authors[[i]]

      if (!is.null(author$ORCID)) {
        # Validate ORCID format
        orcid_regex <- "^(\\d{4}\\-\\d{4}\\-\\d{4}\\-\\d{3}(\\d|X))$"
        if (!grepl(orcid_regex, author$ORCID, perl = TRUE)) {
          issue <- paste0("Author ", i, " has invalid ORCID format: ", author$ORCID,
                         " (should be NNNN-NNNN-NNNN-NNNX)")
          issues <- c(issues, issue)
          warning(issue)
          next
        }

        # Query ORCID for name
        orcid_name <- get_orcid_name(author$ORCID)

        if (!is.null(orcid_name)) {
          local_name_norm <- normalize_name(author$name)
          orcid_name_norm <- normalize_name(orcid_name)

          # Compare names - check if key parts match
          local_parts <- strsplit(local_name_norm, "\\s+")[[1]]
          orcid_parts <- strsplit(orcid_name_norm, "\\s+")[[1]]

          # Filter to significant parts (at least 2 characters)
          local_parts_sig <- local_parts[nchar(local_parts) >= 2]
          orcid_parts_sig <- orcid_parts[nchar(orcid_parts) >= 2]

          if (!all(local_parts_sig %in% orcid_parts_sig) &&
              !all(orcid_parts_sig %in% local_parts_sig)) {
            issue <- paste0("Author ", i, " name mismatch with ORCID record:\n",
                           "  Local:  ", author$name, "\n",
                           "  ORCID:  ", orcid_name, "\n",
                           "  (ORCID: ", author$ORCID, ")")
            issues <- c(issues, issue)
            warning(issue)
          } else {
            message("✓ Author ", i, " name matches ORCID: ", author$name, " (", author$ORCID, ")")
          }
        } else {
          message("ℹ Could not retrieve ORCID record for author ", i, ": ", author$ORCID)
        }
      }
    }
  }

  # Validate codecheckers
  if (validate_codecheckers) {
    if (is.null(local_meta$codechecker) || length(local_meta$codechecker) == 0) {
      issue <- "No codechecker information found in codecheck.yml"
      issues <- c(issues, issue)
      warning(issue)
    } else {
      message("Validating codechecker information...")

      for (i in seq_along(local_meta$codechecker)) {
        checker <- local_meta$codechecker[[i]]

        # Check if name exists
        if (is.null(checker$name) || trimws(checker$name) == "") {
          issue <- paste0("Codechecker ", i, " is missing a name")
          issues <- c(issues, issue)
          warning(issue)
          next
        }

        message("✓ Codechecker ", i, ": ", checker$name)

        # Validate ORCID if present
        if (!is.null(checker$ORCID)) {
          # Validate ORCID format
          orcid_regex <- "^(\\d{4}\\-\\d{4}\\-\\d{4}\\-\\d{3}(\\d|X))$"
          if (!grepl(orcid_regex, checker$ORCID, perl = TRUE)) {
            issue <- paste0("Codechecker ", i, " has invalid ORCID format: ", checker$ORCID,
                           " (should be NNNN-NNNN-NNNN-NNNX)")
            issues <- c(issues, issue)
            warning(issue)
            next
          }

          # Query ORCID for name
          orcid_name <- get_orcid_name(checker$ORCID)

          if (!is.null(orcid_name)) {
            local_name_norm <- normalize_name(checker$name)
            orcid_name_norm <- normalize_name(orcid_name)

            # Compare names
            local_parts <- strsplit(local_name_norm, "\\s+")[[1]]
            orcid_parts <- strsplit(orcid_name_norm, "\\s+")[[1]]

            local_parts_sig <- local_parts[nchar(local_parts) >= 2]
            orcid_parts_sig <- orcid_parts[nchar(orcid_parts) >= 2]

            if (!all(local_parts_sig %in% orcid_parts_sig) &&
                !all(orcid_parts_sig %in% local_parts_sig)) {
              issue <- paste0("Codechecker ", i, " name mismatch with ORCID record:\n",
                             "  Local:  ", checker$name, "\n",
                             "  ORCID:  ", orcid_name, "\n",
                             "  (ORCID: ", checker$ORCID, ")")
              issues <- c(issues, issue)
              warning(issue)
            } else {
              message("✓ Codechecker ", i, " ORCID matches: ", checker$name, " (", checker$ORCID, ")")
            }
          } else {
            message("ℹ Could not retrieve ORCID record for codechecker ", i, ": ", checker$ORCID)
          }
        }
      }
    }
  }

  # Final validation result
  valid <- length(issues) == 0

  if (!valid) {
    message("\n⚠ ORCID validation completed with ", length(issues), " issue(s)")
    if (strict) {
      stop("ORCID validation failed with ", length(issues), " issue(s):\n",
           paste(issues, collapse = "\n"))
    }
  } else {
    message("\n✓ All ORCID validations passed!")
  }

  invisible(list(
    valid = valid,
    issues = issues
  ))
}


##' Validate codecheck.yml metadata against external references
##'
##' Wrapper function that validates codecheck.yml metadata against both
##' CrossRef (for paper metadata) and ORCID (for author and codechecker information).
##' This provides comprehensive validation of all external references.
##'
##' @title Validate codecheck.yml metadata against external references
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param strict Logical. If \code{TRUE}, throw an error on any mismatch.
##'   If \code{FALSE} (default), only issue warnings.
##' @param validate_crossref Logical. If \code{TRUE} (default), validate against CrossRef.
##' @param validate_orcid Logical. If \code{TRUE} (default), validate against ORCID.
##' @param check_orcids Logical. If \code{TRUE} (default), validate ORCID identifiers in CrossRef check.
##' @return Invisibly returns a list with validation results:
##'   \describe{
##'     \item{valid}{Logical indicating if all checks passed}
##'     \item{crossref_result}{Results from CrossRef validation (if performed)}
##'     \item{orcid_result}{Results from ORCID validation (if performed)}
##'   }
##' @author Daniel Nüst
##' @export
##' @examples
##' \dontrun{
##'   # Validate everything with warnings only
##'   result <- validate_contents_references()
##'
##'   # Validate with strict error checking
##'   validate_contents_references(strict = TRUE)
##'
##'   # Validate only CrossRef
##'   validate_contents_references(validate_orcid = FALSE)
##'
##'   # Validate only ORCID
##'   validate_contents_references(validate_crossref = FALSE)
##' }
validate_contents_references <- function(yml_file = "codecheck.yml",
                                         strict = FALSE,
                                         validate_crossref = TRUE,
                                         validate_orcid = TRUE,
                                         check_orcids = TRUE) {

  crossref_result <- NULL
  orcid_result <- NULL
  all_valid <- TRUE

  # Run CrossRef validation
  if (validate_crossref) {
    message("\n", rep("=", 80))
    message("CROSSREF VALIDATION")
    message(rep("=", 80), "\n")

    crossref_result <- validate_codecheck_yml_crossref(
      yml_file = yml_file,
      strict = FALSE,  # Don't stop on CrossRef errors if we still need to run ORCID
      check_orcids = check_orcids
    )

    if (!crossref_result$valid) {
      all_valid <- FALSE
    }
  }

  # Run ORCID validation
  if (validate_orcid) {
    message("\n", rep("=", 80))
    message("ORCID VALIDATION")
    message(rep("=", 80), "\n")

    orcid_result <- validate_codecheck_yml_orcid(
      yml_file = yml_file,
      strict = FALSE  # Don't stop yet
    )

    if (!orcid_result$valid) {
      all_valid <- FALSE
    }
  }

  # Final result
  if (!all_valid) {
    total_issues <- 0
    if (!is.null(crossref_result)) total_issues <- total_issues + length(crossref_result$issues)
    if (!is.null(orcid_result)) total_issues <- total_issues + length(orcid_result$issues)

    message("\n", rep("=", 80))
    message("⚠ VALIDATION SUMMARY: ", total_issues, " issue(s) found")
    message(rep("=", 80))

    if (strict) {
      all_issues <- c()
      if (!is.null(crossref_result)) all_issues <- c(all_issues, crossref_result$issues)
      if (!is.null(orcid_result)) all_issues <- c(all_issues, orcid_result$issues)

      stop("Validation failed with ", total_issues, " issue(s):\n",
           paste(all_issues, collapse = "\n"))
    }
  } else {
    message("\n", rep("=", 80))
    message("✓ ALL VALIDATIONS PASSED!")
    message(rep("=", 80))
  }

  invisible(list(
    valid = all_valid,
    crossref_result = crossref_result,
    orcid_result = orcid_result
  ))
}


##' Check if certificate identifier is a placeholder
##'
##' Determines whether a certificate identifier in codecheck.yml is a placeholder
##' that needs to be replaced with an actual certificate ID. Checks for common
##' placeholder patterns like "YYYY-NNN", "0000-000", or placeholder year prefixes.
##'
##' @title Check if certificate identifier is a placeholder
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param metadata Optional metadata list. If NULL (default), loads from yml_file.
##' @return Logical value: TRUE if certificate is a placeholder, FALSE otherwise
##' @author Daniel Nüst
##' @export
##' @examples
##' \dontrun{
##'   # Check if certificate is a placeholder
##'   if (is_placeholder_certificate()) {
##'     message("Certificate ID needs to be set")
##'   }
##'
##'   # Check specific file
##'   is_placeholder_certificate("path/to/codecheck.yml")
##' }
is_placeholder_certificate <- function(yml_file = "codecheck.yml", metadata = NULL) {
  # Load metadata if not provided
  if (is.null(metadata)) {
    if (!file.exists(yml_file)) {
      stop("codecheck.yml file not found at: ", yml_file)
    }
    metadata <- yaml::read_yaml(yml_file)
  }

  cert_id <- metadata$certificate

  # Check if certificate is missing or empty
  if (is.null(cert_id) || cert_id == "") {
    return(TRUE)
  }

  # Placeholder patterns
  placeholder_patterns <- c("YYYY-NNN", "0000-000", "9999-999")

  # Check exact matches with placeholder patterns
  if (cert_id %in% placeholder_patterns) {
    return(TRUE)
  }

  # Check for placeholder year prefixes (YYYY, 0000, 9999)
  if (grepl("^(YYYY|0000|9999)-\\d{3}$", cert_id)) {
    return(TRUE)
  }

  # Check for template-like patterns
  if (grepl("(FIXME|TODO|template|example)", cert_id, ignore.case = TRUE)) {
    return(TRUE)
  }

  return(FALSE)
}


##' Update certificate ID from GitHub issue
##'
##' Automatically retrieves and updates the certificate identifier from a GitHub issue.
##' This function checks if the current certificate is a placeholder, searches for
##' matching GitHub issues, and if a unique match is found, updates the codecheck.yml
##' file with the certificate ID.
##'
##' The function provides detailed logging of all steps and will only update the file
##' if exactly one matching issue is found (to avoid ambiguity).
##'
##' @title Update certificate ID from GitHub issue
##' @param yml_file Path to the codecheck.yml file (defaults to "./codecheck.yml")
##' @param issue_state State of issues to search: "open" (default), "closed", or "all"
##' @param force Logical. If TRUE, update even if certificate is not a placeholder.
##'   Default is FALSE.
##' @param apply_update Logical. If TRUE, actually update the file. If FALSE (default),
##'   only show what would be changed.
##' @return Invisibly returns a list with:
##'   \describe{
##'     \item{updated}{Logical indicating if file was updated}
##'     \item{certificate}{The certificate ID (if found)}
##'     \item{issue_number}{The GitHub issue number (if found)}
##'     \item{was_placeholder}{Logical indicating if original was a placeholder}
##'   }
##' @author Daniel Nüst
##' @export
##' @examples
##' \dontrun{
##'   # Preview what would be updated
##'   result <- update_certificate_from_github()
##'
##'   # Actually update the file
##'   update_certificate_from_github(apply_update = TRUE)
##'
##'   # Force update even if not a placeholder
##'   update_certificate_from_github(force = TRUE, apply_update = TRUE)
##' }
update_certificate_from_github <- function(yml_file = "codecheck.yml",
                                           issue_state = "open",
                                           force = FALSE,
                                           apply_update = FALSE) {

  if (!file.exists(yml_file)) {
    stop("codecheck.yml file not found at: ", yml_file)
  }

  # Load current metadata
  metadata <- yaml::read_yaml(yml_file)

  # Check if certificate is a placeholder
  is_placeholder <- is_placeholder_certificate(yml_file, metadata)

  message("\n", rep("=", 80))
  message("CERTIFICATE ID UPDATE FROM GITHUB")
  message(rep("=", 80))

  message("\nCurrent certificate ID: ", metadata$certificate)
  message("Is placeholder: ", is_placeholder)

  # Check if we should proceed
  if (!is_placeholder && !force) {
    message("\n⚠ Certificate ID is already set and is not a placeholder.")
    message("Use force = TRUE to update anyway.")
    message(rep("=", 80), "\n")

    return(invisible(list(
      updated = FALSE,
      certificate = metadata$certificate,
      issue_number = NULL,
      was_placeholder = is_placeholder
    )))
  }

  # Try to retrieve certificate from GitHub
  message("\nSearching for certificate in GitHub issues...")
  message("Issue state: ", issue_state)

  result <- tryCatch({
    get_certificate_from_github_issue(yml_file, issue_state = issue_state)
  }, error = function(e) {
    message("✖ Error retrieving from GitHub: ", e$message)
    return(NULL)
  })

  # Check if we found a result
  if (is.null(result)) {
    message("\n✖ No certificate found in GitHub issues")
    message(rep("=", 80), "\n")

    return(invisible(list(
      updated = FALSE,
      certificate = NULL,
      issue_number = NULL,
      was_placeholder = is_placeholder
    )))
  }

  # Check if we have a certificate
  if (is.null(result$certificate)) {
    message("\n✖ No certificate ID found in matching issues")
    if (!is.null(result$message)) {
      message("Reason: ", result$message)
    }
    message(rep("=", 80), "\n")

    return(invisible(list(
      updated = FALSE,
      certificate = NULL,
      issue_number = result$issue_number,
      was_placeholder = is_placeholder
    )))
  }

  # We have a certificate!
  message("\n✓ Found certificate: ", result$certificate)
  message("  Issue #", result$issue_number, ": ", result$title)
  if (!is.null(result$matched_author)) {
    message("  Matched author: ", result$matched_author)
  }

  # Show the change
  message("\n", rep("-", 80))
  message("PROPOSED CHANGE")
  message(rep("-", 80))
  message("OLD certificate: ", metadata$certificate)
  message("NEW certificate: ", result$certificate)
  message(rep("-", 80))

  # Apply update if requested
  if (apply_update) {
    message("\nUpdating codecheck.yml...")

    # Update the certificate in metadata
    metadata$certificate <- result$certificate

    # Write back to file
    tryCatch({
      yaml::write_yaml(metadata, yml_file)
      message("✓ Successfully updated ", yml_file)
      message("  Certificate ID: ", result$certificate)
      message("  From GitHub issue #", result$issue_number)

      updated <- TRUE
    }, error = function(e) {
      message("✖ Failed to write file: ", e$message)
      updated <- FALSE
    })
  } else {
    message("\n⚠ No changes applied. Use apply_update = TRUE to save changes.")
    updated <- FALSE
  }

  message(rep("=", 80), "\n")

  invisible(list(
    updated = updated,
    certificate = result$certificate,
    issue_number = result$issue_number,
    was_placeholder = is_placeholder
  ))
}
