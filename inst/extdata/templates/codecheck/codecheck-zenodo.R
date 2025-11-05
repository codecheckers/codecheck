## Zenodo deposit; see vignette("codecheck_overview.Rmd")

library("codecheck")

## This assumes your working directory is the codecheck directory
metadata = read_yaml( "../codecheck.yml")

## To interact with the Zenodo API, you need to create a token.  This should
## not be shared, or stored in this script.  Here I am using the Unix password
## tool pass to retrieve the token.
my_token = system("pass show codechecker-token", intern=TRUE)

## make a connection to Zenodo API
zenodo <- ZenodoManager$new(token = my_token)


## If you wish to create a new record on zenodo, run the following line once
## and then store the URL of the record in  ../codecheck.yml
## This will generate a new record every time that you run it and 
## save the new record ID in the codecheck configuration file:
## record = create_zenodo_record(zenodo); metadata = read_yaml( "../codecheck.yml")

record = get_zenodo_record(metadata$report)
codecheck:::set_zenodo_metadata(zenodo, record, metadata)

## Upload the certificate PDF (will be set as the preview file)
## If you have additional files, you can upload them as well:
## codecheck:::upload_zenodo_certificate(zenodo, record, "codecheck.pdf")
## codecheck:::upload_zenodo_certificate(zenodo, record, "codecheck.pdf",
##                                        additional_files = c("data.csv", "code.zip"))

## Now go to zenodo and check the record (the URL is printed
## by set_zenodo_metadata() ) and then publish.
