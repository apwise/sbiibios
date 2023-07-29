ASM  := ASM
RMAC := RMAC
LINK := LINK


all: system.dsk diffs.txt

flopboot.hex: flopboot.asm
	cpm $(ASM) $<

flopboot.com: flopboot.hex
	sed '/^:000000/q' $< > flopboot.tmp \
		&& objcopy -I ihex -O binary flopboot.tmp flopboot.com && truncate --size=128 $@ \
		&& rm -f flopboot.tmp

os2ccp.rel: os2ccp.asm
	cpm $(RMAC) $<

os2ccp.com: os2ccp.rel
	cpm $(LINK) $<[L0000,Pc800] \
		&& mv $@ os2ccp.tmp && tail -c +51201 os2ccp.tmp | head -c 2034 > $@ \
		&& truncate --size=2048 $@ \
		&& rm -f os2ccp.tmp
#                                             0xc800+1                   0x7f2

os3bdos.rel: os3bdos.asm
	cpm $(RMAC) $<

os3bdos.com: os3bdos.rel
	cpm $(LINK) $<[L0000,Pc800] \
		&& mv $@ os3bdos.tmp && tail -c +53249 os3bdos.tmp | head -c 3564 > $@ \
		&& truncate --size=3584 $@ \
		&& rm -f os3bdos.tmp
#                                              0xd000+1                    0xded

SBIIBIOS.HEX: SBIIBIOS.ASM
	cpm $(ASM) $< \
		&& mv sbiibios.hex $@

SBIIBIOS.COM sbconfig.com: SBIIBIOS.HEX
	sed '/^:000000/q' $< > SBIIBIOS.TMP \
		&& objcopy -I ihex -O binary SBIIBIOS.TMP SBIIBIOS.TM2 \
		&& head -c  1175 SBIIBIOS.TM2 > SBIIBIOS.COM \
		&& tail -c +4353 SBIIBIOS.TM2 > sbconfig.com \
		&& rm -f SBIIBIOS.TMP SBIIBIOS.TM2

junk1: originals/SBIIBOOT.dsk
	tail -c +6936 $< | head -c 361 > $@ 
#              0x1b17+1          0x1c80 - 0x1b17

pviibios.rel: pviibios.asm
	cpm $(RMAC) $<

pviibios.com: pviibios.rel
	cpm $(LINK) $<[L0000,Pe400] \
		&& mv $@ pviibios.tmp && tail -c +58369 pviibios.tmp | head -c 1837 > $@ \
		&& rm -f pviibios.tmp

junk2: originals/SBIIBOOT.dsk
	tail -c +9134 $< | head -c 979 > $@
#              0x23ad+1          0x2780 - 0x23ad

# config.com (from SBIIBIOS) comes here

junk3: originals/SBIIBOOT.dsk
	tail -c +10145 $< | head -c 96 > $@ 
#              0x27a0+1           0x2800 - 0x27a0

# mv os2ccp.com os2ccp.tmp && tail -c +51200 os2ccp.tmp | head -c -2034 > os2ccp.com

system.dsk: flopboot.com os2ccp.com os3bdos.com SBIIBIOS.COM junk1 pviibios.com junk2 sbconfig.com junk3
	cat $^ > $@

system.hex: system.dsk
	od -tx1z -A x $< > $@

SBIIBOOT.hex: originals/SBIIBOOT.dsk
	od -tx1z -A x $< > $@

diffs.txt: system.hex SBIIBOOT.hex
	sdiff -w 160 SBIIBOOT.hex system.hex > $@

clean:
	rm -f flopboot.hex flopboot.prn flopboot.sym flopboot.com flopboot.tmp
	rm -f os2ccp.rel   os2ccp.prn   os2ccp.sym   os2ccp.com   os2ccp.tmp
	rm -f os3bdos.rel  os3bdos.prn  os3bdos.sym  os3bdos.com  os3bdos.tmp
	rm -f SBIIBIOS.HEX sbiibios.prn sbiibios.sym SBIIBIOS.COM SBIIBIOS.TMP SBIIBIOS.TM2 sbconfig.com 
	rm -f pviibios.rel pviibios.prn pviibios.sym pviibios.com pviibios.tmp
	rm -f system.dsk   system.hex   SBIIBOOT.hex diffs.txt
	rm -f junk1 junk2 junk3
	rm -f 'xxprog.$$$$$$' 'xxabs.$$$$$$'
	rm -f *~

.PHONY:	clean
