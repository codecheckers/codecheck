## Zenodo deposit; see vignette("codecheck_overview.Rmd")

require(codecheck)
metadata = read_yaml( "../codecheck.yml") 

## To interact with the Zenodo API, you need to create a token.  This should
## not be shared, or stored in this script.  Here I am using the Unix password
## tool pass to retrieve the token.
my_token = system("pass show codechecker-token", intern=TRUE)

## make a connection to Zenodo API
zenodo <- ZenodoManager$new(token = my_token)


## To create a new Zenodo record, run the following line ONCE
## and update the report: line of  ../codecheck.yml
## This will generate a new record every time that you run it.
## After creating the record, reload the metadata above.
##
## record = create_zenodo_record(zenodo)


record = get_zenodo_record(metadata$report)
set_zenodo_metadata(zenodo, record, metadata)

## If you have already uploaded the certificate once, you will need to
## delete it via the web page before uploading it again.
## set_zenodo_certificate(zenodo, record, "codecheck.pdf") 

## Now go to zenodo and check the record (the URL is printed
## by set_zenodo_metadata() ) and then publish.
