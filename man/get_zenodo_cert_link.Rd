% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_download_certs.R
\name{get_zenodo_cert_link}
\alias{get_zenodo_cert_link}
\title{Accesses a codecheck's Zenodo record via its report link, retrieves the record ID, 
and searches for a certificate PDF or ZIP file within the record's files using the Zenodo API.}
\usage{
get_zenodo_cert_link(report_link, cert_id, api_key = "")
}
\arguments{
\item{report_link}{URL of the Zenodo report to access.}

\item{cert_id}{ID of the certificate, used for logging and warnings.}

\item{api_key}{(Optional) API key for Zenodo authentication if required.}
}
\value{
The download link for the certificate file as a string if found; otherwise, NULL.
}
\description{
Accesses a codecheck's Zenodo record via its report link, retrieves the record ID, 
and searches for a certificate PDF or ZIP file within the record's files using the Zenodo API.
}
