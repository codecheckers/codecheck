##' Copy manifest files into the root/codecheck/outputs folder; return manifest.
##'
##' The metadata should specify the manifest -- the files to copy into the
##' codecheck/oututs folder.  Each of the files in the manifest is copied into
##' the destination directory and then the manifest is returned as a dataframe.
##' If KEEP_FULL_PATH is TRUE, we keep the full path for the output files.
##' This is useful when there are two output files with the same name in
##' different folders, e.g. expt1/out.pdf and expt2/out.pdf
##'
##' Whitespace in the names of the copies is replaced by underscores, e.g.
##' \code{Figure 1.png} is copied to \code{Figure_1.png}, because LaTeX cannot
##' reliably include files with spaces in their names. The \code{output} column
##' keeps the name from the manifest, \code{dest} holds the path of the copy.
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
  entries = .manifest_entries(metadata$manifest)
  outputs = entries$file
  src_files = file.path(root, outputs)
  missing = !file.exists(src_files)

  # Warn about missing files but continue processing: a certificate is drafted
  # while outputs are still being reproduced, and a missing file is marked as
  # such in it. validate_codecheck_yml_rules() reports the same thing as a
  # failure of CC-BUN-001 manifest-files-exist, at the rule's severity.
  if (any(missing)) {
    warning("Manifest files missing:\n",
            paste(src_files[missing], collapse='\n'),
            "\nThese files will be marked as missing in the certificate.")
  }

  dest_files = .manifest_dest_files(if (keep_full_path) outputs else basename(outputs),
                                   dest_dir)
  clash = dest_files %in% dest_files[duplicated(dest_files)]
  if (any(clash)) {
    warning("Manifest files are copied to the same file in ", dest_dir, ":\n",
            paste(outputs[clash], "->", dest_files[clash], collapse = "\n"))
  }

  ## See if we need to make extra directories in the codecheck/outputs
  if (keep_full_path) {
    for (d in dest_files) {
      dir = dirname(d)
      if ( !dir.exists(dir) )
        dir.create(dir, recursive=TRUE)
    }
  }

  # Only copy files that exist
  existing_files = !missing
  if (any(existing_files)) {
    if (overwrite && any(file.exists(dest_files[existing_files]))) {
      message("Overwriting output files: ", toString(dest_files[existing_files]))
    }
    file.copy(src_files[existing_files], dest_files[existing_files], overwrite = overwrite)
  }

  # Get file sizes, using NA for missing files
  file_sizes = rep(NA_real_, length(dest_files))
  file_sizes[existing_files] = file.size(dest_files[existing_files])

  manifest_df = data.frame(output=outputs,
                           comment=entries$comment,
                           dest=dest_files,
                           size=file_sizes,
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
##' @author Daniel Nuest
##' @export
list_manifest_files <- function(root, metadata, check_dir) {
  entries = .manifest_entries(metadata$manifest)
  outputs = entries$file
  dest_files = .manifest_dest_files(basename(outputs), check_dir)
  manifest_df = data.frame(output=outputs,
                           comment=entries$comment,
                           dest=dest_files,
                           size=file.size(dest_files),
                           stringsAsFactors = FALSE)
  manifest_df
}

##' The files and comments of the manifest, as character vectors
##'
##' An empty manifest gives empty vectors and a warning, so that a certificate
##' can be drafted before the manifest is filled in.
##' @keywords internal
##' @noRd
.manifest_entries <- function(manifest) {
  if (!is.null(.manifest_no_files_comment(manifest))) {
    return(list(file = character(0), comment = character(0)))
  }
  manifest <- as_items(manifest)
  if (length(manifest) == 0) {
    warning("codecheck.yml lists no manifest files: add the outputs you reproduced ",
            "under 'manifest:', see https://codecheck.org.uk/spec/config/latest/",
            call. = FALSE)
  }
  files <- lapply(manifest, function(x) if (is.list(x)) x$file)
  no_file <- !vapply(files, function(f) is.character(f) && length(f) == 1 && has_value(f),
                     logical(1))
  if (any(no_file)) {
    stop("manifest item(s) ", toString(which(no_file)), " in codecheck.yml ",
         "must have exactly one 'file'", call. = FALSE)
  }
  list(file = as.character(unlist(files, use.names = FALSE)),
       comment = vapply(manifest, function(x) paste(x$comment, collapse = " "), character(1)))
}

##' The comment of a manifest that declares a check without output files
##'
##' A check of a workflow that writes no files declares so with a manifest of
##' a single item with a comment and no \code{file} node, e.g.
##' \code{manifest: [comment: "The analysis prints its results."]}.
##' @return The comment, or \code{NULL} for any other manifest.
##' @keywords internal
##' @noRd
.manifest_no_files_comment <- function(manifest) {
  manifest <- as_items(manifest)
  # An empty file: is an entry not filled in yet, not a declaration
  if (length(manifest) == 1 && is.list(manifest[[1]]) &&
      !"file" %in% names(manifest[[1]]) && has_value(manifest[[1]]$comment)) {
    paste(manifest[[1]]$comment, collapse = " ")
  }
}

##' Paths of the copies of manifest files in the outputs folder
##'
##' Whitespace becomes an underscore, so that the copies can be included in
##' the LaTeX certificate (codecheck#98).
##' @keywords internal
##' @noRd
.manifest_dest_files <- function(outputs, dest_dir) {
  file.path(dest_dir, gsub("[[:space:]]+", "_", outputs))
}
