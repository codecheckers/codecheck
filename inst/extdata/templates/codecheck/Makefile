## steps:
## make run
## make 


all: codecheck.pdf


codecheck.pdf: hancock1992-codecheck.Rmd preamble.sty ../codecheck.yml
	Rscript -e 'rmarkdown::render("$<", "pdf_document")'
	cp hancock1992-codecheck.pdf codecheck.pdf

hancock1992-codecheck.html: hancock1992-codecheck.Rmd ../codecheck.yml
	Rscript -e 'rmarkdown::render("$<")'

.PHONY: run clean

clean:
	rm -fr codecheck.pdf outputs

## to regenerate the figures takes about 5-10 mins per figure

run:
	cd ..; make

