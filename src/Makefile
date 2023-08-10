ASM  := ASM
RMAC := RMAC
LINK := LINK

BUILD_DIR := ../build

all: $(BUILD_DIR)/SBIICPM.COM $(BUILD_DIR)/QDIICPM.COM $(BUILD_DIR)/SDIICPM.COM

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

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

SBIIBIOS.HEX: SBIIBIOS.ASM
	cpm $(ASM) $< \
		&& mv sbiibios.hex $@

SBIIBIOS.COM sbconfig.com: SBIIBIOS.HEX
	sed '/^:000000/q' $< > SBIIBIOS.TMP \
		&& objcopy -I ihex -O binary SBIIBIOS.TMP SBIIBIOS.TM2 \
		&& head -c 1536 SBIIBIOS.TM2 > SBIIBIOS.COM \
		&& tail -c +4353 SBIIBIOS.TM2 > sbconfig.com \
		&& truncate --size=128 sbconfig.com \
		&& rm -f SBIIBIOS.TMP SBIIBIOS.TM2

QDIIBIOS.HEX: QDIIBIOS.ASM
	cpm $(ASM) $< \
		&& mv qdiibios.hex $@

QDIIBIOS.COM qdconfig.com: QDIIBIOS.HEX
	sed '/^:000000/q' $< > QDIIBIOS.TMP \
		&& objcopy -I ihex -O binary QDIIBIOS.TMP QDIIBIOS.TM2 \
		&& head -c 1536 QDIIBIOS.TM2 > QDIIBIOS.COM \
		&& tail -c +4353 QDIIBIOS.TM2 > qdconfig.com \
		&& truncate --size=128 qdconfig.com \
		&& rm -f QDIIBIOS.TMP QDIIBIOS.TM2

SDIIBIOS.HEX: SDIIBIOS.ASM
	cpm $(ASM) $< \
		&& mv sdiibios.hex $@

SDIIBIOS.COM sdconfig.com: SDIIBIOS.HEX
	sed '/^:000000/q' $< > SDIIBIOS.TMP \
		&& objcopy -I ihex -O binary SDIIBIOS.TMP SDIIBIOS.TM2 \
		&& head -c 1536 SDIIBIOS.TM2 > SDIIBIOS.COM \
		&& tail -c +4353 SDIIBIOS.TM2 > sdconfig.com \
		&& truncate --size=128 sdconfig.com \
		&& rm -f SDIIBIOS.TMP SDIIBIOS.TM2

pviibios.rel: pviibios.asm
	cpm $(RMAC) $<

pviibios.com: pviibios.rel
	cpm $(LINK) $<[L0000,Pe400] \
		&& mv $@ pviibios.tmp && tail -c +58369 pviibios.tmp | head -c 1837 > $@ \
		&& truncate --size=2688 $@ \
		&& rm -f pviibios.tmp

wmstrt.rel: wmstrt.asm
	cpm $(RMAC) $<

wmstrt.com: wmstrt.rel
	cpm $(LINK) $<[L0000] \
		&& mv $@ wmstrt.tmp && tail -c +61057 wmstrt.tmp | head -c 114 > $@ \
		&& truncate --size=128 $@ \
		&& rm -f wmstrt.tmp

$(BUILD_DIR)/SBIICPM.COM: sysgen.com flopboot.com os2ccp.com os3bdos.com SBIIBIOS.COM pviibios.com wmstrt.com sbconfig.com | $(BUILD_DIR)
	cat $^ > $@

$(BUILD_DIR)/QDIICPM.COM: sysgen.com flopboot.com os2ccp.com os3bdos.com QDIIBIOS.COM pviibios.com wmstrt.com qdconfig.com | $(BUILD_DIR)
	cat $^ > $@

$(BUILD_DIR)/SDIICPM.COM: sysgen.com flopboot.com os2ccp.com os3bdos.com SDIIBIOS.COM pviibios.com wmstrt.com sdconfig.com | $(BUILD_DIR)
	cat $^ > $@

clean:
	rm -f sysgen.rel sysgen.prn sysgen.sym sysgen.com sysgen.tmp
	rm -f flopboot.hex flopboot.prn flopboot.sym flopboot.com flopboot.tmp
	rm -f os2ccp.rel   os2ccp.prn   os2ccp.sym   os2ccp.com   os2ccp.tmp
	rm -f os3bdos.rel  os3bdos.prn  os3bdos.sym  os3bdos.com  os3bdos.tmp
	rm -f SBIIBIOS.HEX sbiibios.prn sbiibios.sym SBIIBIOS.COM SBIIBIOS.TMP SBIIBIOS.TM2 sbconfig.com
	rm -f QDIIBIOS.HEX qdiibios.prn qdiibios.sym QDIIBIOS.COM QDIIBIOS.TMP QDIIBIOS.TM2 qdconfig.com
	rm -f SDIIBIOS.HEX sdiibios.prn sdiibios.sym SDIIBIOS.COM SDIIBIOS.TMP SDIIBIOS.TM2 sdconfig.com
	rm -f pviibios.rel pviibios.prn pviibios.sym pviibios.com pviibios.tmp
	rm -f wmstrt.rel   wmstrt.prn   wmstrt.sym   wmstrt.com   wmstrt.tmp
	rm -f $(BUILD_DIR)/SBIICPM.COM $(BUILD_DIR)/QDIICPM.COM $(BUILD_DIR)/QDIICPM.COM
	rm -f 'xxprog.$$$$$$' 'xxabs.$$$$$$'
	rm -f *~

.PHONY:	all clean
