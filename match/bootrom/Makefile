ASM  := ASM
RMAC := RMAC
LINK := LINK


all: diffs.txt


sbboot41.rel: sbboot41.asm
	cpm $(RMAC) $<

sbboot41.com: sbboot41.rel
	cpm $(LINK) $<[L0000]

rom1.com: sbboot41.com
	cp $< $@ && truncate --size 1024 $@

rom2.com: sbboot41.com
	tail -c +49153 $< > $@ && \
		truncate --size 772 $@ && \
		truncate --size 1024 $@

sbboot41.bin: rom1.com rom2.com
	cat $^ > $@

SuperBrain_V4.1.hex: originals/SuperBrain_V4.1.bin
	od -tx1z -Ax $< > $@

sbboot41.hex: sbboot41.bin
	od -tx1z -Ax $< > $@

diffs.txt: SuperBrain_V4.1.hex sbboot41.hex
	sdiff -w 160 $^ > $@

clean:
	rm -f sbboot41.rel  sbboot41.prn  sbboot41.sym sbboot41.com
	rm -f rom1.com rom2.com sbboot41.bin
	rm -f SuperBrain_V4.1.hex sbboot41.hex diffs.txt
	rm -f 'xxprog.$$$$$$' 'xxabs.$$$$$$'
	rm -f *~
