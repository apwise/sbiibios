all: sbiibios.pdf

sbiibios.pdf: sbiibios.adoc
	asciidoctor-pdf $<

clean:
	rm -f sbiibios.pdf
	rm -f *~

.PHONY: all clean
