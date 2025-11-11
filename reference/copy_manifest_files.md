# Copy files from manifest into the codecheck folder and summarise.

Copy manifest files into the root/codecheck/outputs folder; return
manifest.

## Usage

``` r
copy_manifest_files(
  root,
  metadata,
  dest_dir,
  keep_full_path = FALSE,
  overwrite = FALSE
)
```

## Arguments

- root:

  \- Path to the root folder of the project.

- metadata:

  \- the codecheck metadata list.

- dest_dir:

  \- folder where outputs are to be copied to (codecheck/outputs)

- keep_full_path:

  \- TRUE to keep relative pathname of figures.

- overwrite:

  \- TRUE to overwrite the output files even if they already exist

## Value

A dataframe containing one row per manifest file.

## Details

The metadata should specify the manifest – the files to copy into the
codecheck/oututs folder. Each of the files in the manifest is copied
into the destination directory and then the manifest is returned as a
dataframe. If KEEP_FULL_PATH is TRUE, we keep the full path for the
output files. This is useful when there are two output files with the
same name in different folders, e.g. expt1/out.pdf and expt2/out.pdf

## Author

Stephen Eglen
