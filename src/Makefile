ASM  := ASM
RMAC := RMAC
LINK := LINK


all: jriicpm.com

sysgen.rel: sysgen.asm
	cpm $(RMAC) $<

sysgen.com: sysgen.rel
	cpm $(LINK) sysgen.rel[L0000] \
		&& mv $@ sysgen.tmp \
		&& tail -c +257 sysgen.tmp > $@ \
		&& truncate --size=2048 $@ \
		&& rm -f sysgen.tmp

flopboot.hex: flopboot.asm
	cpm $(ASM) $<

flopboot.com: flopboot.hex
	sed '/^:000000/q' $< > flopboot.tmp \
		&& objcopy -I ihex -O binary flopboot.tmp $@ && truncate --size=128 $@ \
		&& rm -f flopboot.tmp

os2ccp.rel: os2ccp.asm
	cpm $(RMAC) $<

os2ccp.com: os2ccp.rel
	cpm $(LINK) $<[L0000,Pc800] \
		&& mv $@ os2ccp.tmp && tail -c +51201 os2ccp.tmp | head -c 2034 > $@ \
		&& truncate --size=2048 $@ \
		&& rm -f os2ccp.tmp
#                                              0xc800+1                   0x7f2

os3bdos.rel: os3bdos.asm
	cpm $(RMAC) $<

os3bdos.com: os3bdos.rel
	cpm $(LINK) $<[L0000,Pc800] \
		&& mv $@ os3bdos.tmp && tail -c +53249 os3bdos.tmp | head -c 3564 > $@ \
		&& truncate --size=3584 $@ \
		&& rm -f os3bdos.tmp
#                                              0xd000+1                    0xded

jriibios.hex: jriibios.asm
	cpm $(ASM) $<

jriibios.com config.com: jriibios.hex
	sed '/^:000000/q' $< > jriibios.tmp \
		&& objcopy -I ihex -O binary jriibios.tmp jriibios.tm2 \
		&& head -c 1536 jriibios.tm2 > jriibios.com \
		&& tail -c +4353 jriibios.tm2 > config.com \
		&& truncate --size=128 config.com \
		&& rm -f jriibios.tmp jriibios.tm2

sbiibios.rel: sbiibios.asm
	cpm $(RMAC) $<

sbiibios.com: sbiibios.rel
	cpm $(LINK) $<[L0000,Pe400] \
		&& mv $@ sbiibios.tmp && tail -c +58369 sbiibios.tmp | head -c 1837 > $@ \
		&& truncate --size=2816 $@ \
		&& rm -f sbiibios.tmp

jriicpm.com: sysgen.com flopboot.com os2ccp.com os3bdos.com jriibios.com sbiibios.com config.com
	cat $^ > $@

clean:
	rm -f sysgen.rel sysgen.prn sysgen.sym sysgen.com sysgen.tmp
	rm -f flopboot.hex flopboot.prn flopboot.sym flopboot.com flopboot.tmp
	rm -f os2ccp.rel   os2ccp.prn   os2ccp.sym   os2ccp.com   os2ccp.tmp
	rm -f os3bdos.rel  os3bdos.prn  os3bdos.sym  os3bdos.com  os3bdos.tmp
	rm -f jriibios.hex jriibios.prn jriibios.sym jriibios.com jriibios.tmp jriibios.tm2 config.com 
	rm -f sbiibios.rel sbiibios.prn sbiibios.sym sbiibios.com sbiibios.tmp
	rm -f jriicpm.com
	rm -f 'xxprog.$$$$$$' 'xxabs.$$$$$$'
	rm -f *~

.PHONY:	clean
