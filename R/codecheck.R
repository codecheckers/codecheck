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
  cat("Created codecheck report files at ", target, ":", toString(list.files("codecheck")), "\n")
}

##' Return the metadata for the codecheck project in root folder of project
##'
##' @title Return the metadata for the codecheck project in root folder of project
##' @param root Path to the root folder of the project, defaults to current working directory
##' @return A list containing the metadata found in the codecheck.yml file
##' @author Stephen Eglen
##' @importFrom yaml read_yaml
##' @export
codecheck_metadata <- function(root = getwd()) {
  read_yaml(file.path(root, "codecheck.yml") )
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
  summary_entries = list(
    "Title of checked publication" =            metadata$paper$title,
    "Author(s)" =       .names(metadata$paper$authors),
    "Reference" =       as_latex_url(metadata$paper$reference),
    "Codechecker(s)" =  .names(metadata$codechecker),
    "Date of check" =   metadata$check_time,
    "Summary" =         metadata$summary,
    "Repository" =      as_latex_url(metadata$repository))
  summary_df = data.frame(Item=names(summary_entries),
                          Value=unlist(summary_entries, use.names=FALSE))

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
##' @param metadata - the codecheck metadata list.
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
  urls = sub(root, sprintf('%s/blob/master', metadata$repository), manifest_df$dest)
  m1 = sprintf('\\href{%s}{\\path{%s}}',
               urls,
               m[,1])
  m[,1] = m1
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

# Zenodo records interaction ----

#' Create a new Zenodo record and return its pre-assigned DOI
#'
#' Run this only once per new codecheck.
#' @title Create a new Zenodo record and return its pre-assigned DOI
#' @param zen Object from zen4R to interact with Zenodo
#' @param metadata codecheck.yml file
#' @param warn Ask for user input before creating a new record
#' @return Number of Zenodo record created
#' @author Stephen Eglen
#' @importFrom zen4R ZenodoRecord
#' @importFrom utils askYesNo
#' 
#' @export
get_or_create_zenodo_record <- function(zen, metadata, warn=TRUE) {
  id <- get_zenodo_record(metadata$report)
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
#' Retrieve the Zenodo record, if one exists.
#' If no record number is currently  listed in the metadata (i.e. the "FIXME" tag is still there)
#' then the code returns NULL and an empty record should be created.
#' @title Get the full zenodo record using the record number stored in the metadata.
#' @param zenodo An object from zen4R to connect with Zenodo
#' @param metadata A codecheck configuration (likely read from a codecheck.yml)
#' @return The Zenodo record, or NULL.
#' @author Stephen Eglen
#' @export
get_zenodo_record <- function(zenodo, metadata) {
  id <- get_zenodo_id(metadata$report)
  if (is.na(id)) {
    NULL
  } else {
    zenodo$getDepositionById(id)
  }
}

#' Upload codecheck metadata to Zenodo.
#'
#' The contents of codecheck.yml are uploaded to Zenodo using this funciton.
#' 
#' @title Upload metadata to Zenodod
#' @param zenodo object from zen4R to connect with Zenodo
#' @param myrec a Zenodo record object
#' @param metadata codecheck metadata, likely loaded from a codecheck.yml file
#' @return rec -- the updated record.
#' @author Stephen Eglen
#' @export
upload_zenodo_metadata <- function(zenodo, myrec, metadata) {
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
