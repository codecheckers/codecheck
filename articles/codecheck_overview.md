# codecheck: Introduction to the codecheck package

## Installing the package

The latest version of the package can be installed using:

``` r
remotes::install_github("codecheckers/codecheck")
```

## Pre-requisites for being a CODECHECKER using the codecheck R package

1.  Member of the GitHub codecheckers community.
2.  Have a Zenodo account.
3.  Experience with R Markdown and R is helpful, but not essential.

## Clarify used workflow

Check with your editor which of the [CODECHECK
workflows](https://codecheck.org.uk/workflows/) applies to your check.
The workflow determines some of the steps below and guides you through
the process. The remainder of this document should be seen as a
minimalistic guide to get you started.

## Visit corresponding issue or get a certificate number

Go the the corresponding issue on the [CODECHECK
register](https://github.com/codecheckers/register/issues/) to find all
relevant information about the paper to reproduce. If there is none,
continue:

Visit the **CODECHECK Launch Pad** at
<https://codecheck.org.uk/launch-pad/> to easily open a new issue for
your check.

Alternatively, do it the manual way: Go to
<https://github.com/codecheckers/register> and add an issue for the new
paper to reproduce. Check the other issues for the highest used
certificate number, and claim the next one by adding it to an issue
comment and adding the tag [“id
assigned”](https://github.com/codecheckers/register/issues?q=is%3Aissue+is%3Aopen+label%3A%22id+assigned%22).
Certificate numbers are simply YYYY-NNN where YYYY is the current year
and NNN is a 3 digit number that starts at 001 and increases by 1 with
each certificate.

## Clone the workflow project

Clone the project that you wish to check into [`codecheckers`
organisation](https://github.com/codecheckers/) on GitHub or
[`cdchck`](https://gitlab.com/cdchck) on GitLab.

## Write a codecheck certificate

In the top-level of the repo to replicate (“the root”), start R and run
the following to generate several template files. These will then need
to be committed into the repo.

``` r
require(codecheck)
create_codecheck_files()
```

These create several files that need to be edited for the codecheck
process:

1.  `codecheck.yml` contains the metadata for the reproduction. If the
    author or someone else has already created it, double-check if all
    required information is provided - see the
    [specification](https://codecheck.org.uk/spec/config/latest/).
2.  `codecheck/codecheck.Rmd` is a suggested R Markdown script to edit,
    along with `Makefile` and `codecheck-preamble.sty` to help compile
    the PDF.
3.  `codecheck/zenodo-codecheck.R` for help in loading the certificate
    to Zenodo along with the corresponding metadata.
4.  `CODECHECK_report_template.odt` and `.docx` are templates for usage
    with common word processors - please delete if you use the `.Rmd`
    file.

There is also a Makefile so that `make` within the `codecheck/` folder
will rebuild `codecheck.pdf`.

## Completing the metadata file `codecheck.yml`

The `codecheck.yml` eventually contains all the relevant metadata for
the certificate. The R Markdown template includes diverse validations
and checks for this metadata file. If you can compile the certificate
document without warnings then you can be sure that the metadata file is
fine. Simply edit it to your needs, bearing in mind the specification
comments at <https://codecheck.org.uk/spec/config/latest>.

## Publish certificate

### Submitting the certificate to the CODECHECK community on Zenodo

There is no requirement to use the following code to generate the record
on Zenodo – if you prefer to do it manually, that is fine. However, we
encourage codecheckers to use this API as it will save time and ensure
that certificates have similar structure.

You will first need a zenodo account and to generate a token to use the
API. This token can be generated from
<https://zenodo.org/account/settings/applications/tokens/new/>. The
token should not be stored in your R script, but should be typed in or
read from a local file and stored in the variable `my_token` in the file
`codecheck/codecheck-zenodo.R`.

The metadata contained in `codecheck.yml` is uploaded using some helper
functions from the codecheck package. To start with, you can create a
new empty record on Zenodo using
[`get_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/get_zenodo_record.md)
and then store the resulting URL in `codecheck.yml`. The rest of the
metadata can remain as before.

Once you are ready, upload the certificate itself using the function
[`upload_zenodo_certificate()`](http://codecheck.org.uk/codecheck/reference/upload_zenodo_certificate.md)
(previously
[`set_zenodo_certificate()`](http://codecheck.org.uk/codecheck/reference/upload_zenodo_certificate.md)).
The certificate is always uploaded first to ensure it becomes the
preview file. You can also upload additional files (e.g., data, code)
using the `additional_files` parameter. Whilst the Zenodo record is in
draft form, you can delete files from the website, and then re-add them
using the API.

Once you have uploaded the certificate and checked the metadata, you can
then submit the record to the CODECHECK community on Zenodo to retrieve
feedback from a CODECHECK editor before publishing the certiciate.

### Publish on OSF or ResearchEquals

CODECHECK supports multiple repositories to publish certificates. If you
are unfamiliar with Zenodo or prefer to user another platform, you can
also publish your certificate on [OSF](https://osf.io/) or
[ResearchEquals](https://researchequals.com/). Simply put the respective
DOI in the `report` field of the `codecheck.yml` file and use another
way of communication to get feedback from the CODECHECK editor before
publishing.

## Final steps

After the publication, the CODECHECK editor will handle the update of
the register and the closing of the check’s issue on the register
repository. Final steps may include setting the code repository as
“Archived” (read-only) or publishing further data and code on Zenodo or
other repositories, updating the certificate based on author feedback,
and more.
