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

  # Warn about missing files but continue processing
  if (any(missing)) {
    warning("Manifest files missing:\n",
            paste(src_files[missing], collapse='\n'),
            "\nThese files will be marked as missing in the certificate.")
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
                           comment=sapply(manifest, function(x) x$comment),
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
