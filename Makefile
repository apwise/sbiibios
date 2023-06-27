ASM  := ASM
RMAC := RMAC
LINK := LINK


all: system.dsk diffs.txt

flopboot.hex: flopboot.asm
	cpm $(ASM) $<

flopboot.com: flopboot.hex
	sed '/^:000000/q' flopboot.hex > flopboot.tmp
	objcopy -I ihex -O binary flopboot.tmp flopboot.com && truncate --size=128 flopboot.com 
	rm -f flopboot.tmp

os2ccp.rel: os2ccp.asm
	cpm $(RMAC) $<

os2ccp.com: os2ccp.rel
	cpm $(LINK) os2ccp.rel[L0000,Pc800]
	mv os2ccp.com os2ccp.tmp && tail -c +51201 os2ccp.tmp | head -c 2034 > os2ccp.com \
		&& truncate --size=2048 os2ccp.com
	rm -f os2ccp.tmp
#                                           0xc800+1                   0x7f2

os3bdos.rel: os3bdos.asm
	cpm $(RMAC) $<

os3bdos.com: os3bdos.rel
	cpm $(LINK) os3bdos.rel[L0000,Pc800]
	mv os3bdos.com os3bdos.tmp && tail -c +53249 os3bdos.tmp | head -c 3564 > os3bdos.com \
		&& truncate --size=3584 os3bdos.com
	rm -f os3bdos.tmp
#                                             0xd000+1                    0xded

qd31bios.hex: qd31bios.asm
	cpm $(ASM) $<

qd31bios.com config.com: qd31bios.hex
	sed '/^:000000/q' qd31bios.hex > qd31bios.tmp
	objcopy -I ihex -O binary qd31bios.tmp qd31bios.tm2
	head -c  1175 qd31bios.tm2 > qd31bios.com
	tail -c +4353 qd31bios.tm2 > config.com
	rm -f qd31bios.tmp qd31bios.tm2

# && truncate --size=1536 qd31bios.com
# && truncate --size=128 config.com

junk1: SBIIBOOT.dsk
	tail -c +6936 $< | head -c 361 > $@ 
#              0x1b17+1          0x1c80 - 0x1b17

sbiibios.rel: sbiibios.asm
	cpm $(RMAC) $<

sbiibios.com: sbiibios.rel
	cpm $(LINK) sbiibios.rel[L0000,Pe400]
	mv sbiibios.com sbiibios.tmp && tail -c +58369 sbiibios.tmp | head -c 1837 > sbiibios.com
	rm -f sbiibios.tmp

# && truncate --size=2816 sbiibios.com

junk2: SBIIBOOT.dsk
	tail -c +9134 $< | head -c 979 > $@
#              0x23ad+1          0x2780 - 0x23ad

# config.com (from qd31bios) comes here

junk3: SBIIBOOT.dsk
	tail -c +10145 $< | head -c 96 > $@ 
#              0x27a0+1           0x2800 - 0x27a0

# mv os2ccp.com os2ccp.tmp && tail -c +51200 os2ccp.tmp | head -c -2034 > os2ccp.com

system.dsk: flopboot.com os2ccp.com os3bdos.com qd31bios.com junk1 sbiibios.com junk2 config.com junk3
	cat $^ > $@

system.hex: system.dsk
	od -tx1z -A x system.dsk > system.hex

diffs.txt: system.hex
	sdiff -w 160 SBIIBOOT.hex system.hex > $@

clean:
	rm -f flopboot.hex flopboot.prn flopboot.sym flopboot.com flopboot.tmp
	rm -f os2ccp.rel   os2ccp.prn   os2ccp.sym   os2ccp.com   os2ccp.tmp
	rm -f os3bdos.rel  os3bdos.prn  os3bdos.sym  os3bdos.com  os3bdos.tmp
	rm -f qd31bios.hex qd31bios.prn qd31bios.sym qd31bios.com qd31bios.tmp qd31bios.tm2 config.com 
	rm -f sbiibios.rel sbiibios.prn sbiibios.sym sbiibios.com sbiibios.tmp
	rm -f system.dsk   system.hex   diffs.txt
	rm -f junk1 junk2 junk3
	rm -f 'xxprog.$$$$$$' 'xxabs.$$$$$$'
	rm -f *~

.PHONY:	clean
