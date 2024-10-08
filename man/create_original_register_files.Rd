% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_render_register_general.r
\name{create_original_register_files}
\alias{create_original_register_files}
\title{Generates original register files in various output formats.}
\usage{
create_original_register_files(register_table, outputs)
}
\arguments{
\item{register_table}{The register table.}

\item{outputs}{List of the output types (e.g., "csv", "json").

The function iterates through the provided output types, generates an output directory,
filters and adjusts the register table, and renders the original register files based on the specified formats.}
}
\description{
Generates original register files in various output formats.
}
