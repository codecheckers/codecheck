all: codecheck.pdf

codecheck.pdf:
ifneq ($(and $(wildcard codecheck.Rmd),$(wildcard codecheck.qmd)),)
	$(error Both codecheck.Rmd and codecheck.qmd exist - remove one so the certificate source is unambiguous)
else ifneq ($(wildcard codecheck.qmd),)
	quarto render codecheck.qmd --to pdf
else
	Rscript -e 'rmarkdown::render("codecheck.Rmd", "pdf_document")'
endif

.PHONY: run clean

clean:
	rm -fr codecheck.pdf outputs


