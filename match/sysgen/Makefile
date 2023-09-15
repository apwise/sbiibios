#ASM  := ASM
RMAC := RMAC
LINK := LINK

CLEAN_FILES := clean_sysgen.asm

all:	diffs.txt $(CLEAN_FILES)

sysgen.rel: sysgen.asm
	cpm $(RMAC) $<

sysgen.com: sysgen.rel
	cpm $(LINK) sysgen.rel[L0000]

sysgen.odx: sysgen.com
	tail -c +257 $< | head -c 996 | od -tx1z -Ax > $@

clean_%: %
	sed -f ../clean_src.sed $< > $@

cs30cpm.odx: originals/cs30cpm.com
	cp $< cs30cpm.tmp
	truncate --size=996 cs30cpm.tmp
	od -tx1z -Ax cs30cpm.tmp > $@
	rm -f cs30cpm.tmp

diffs.txt: sysgen.odx cs30cpm.odx
	sdiff -w 160 cs30cpm.odx sysgen.odx > $@

clean:
	rm -f sysgen.hex sysgen.prn sysgen.rel sysgen.sym sysgen.com
	rm -f sysgen.odx cs30cpm.odx diffs.txt
	rm -f $(CLEAN_FILES)
	rm -f *~

.PHONY: clean
