
all:	readrom.com


readrom.rel: readrom.asm
	cpm RMAC $<

readrom.com: readrom.rel
	cpm LINK $<

clean:
	rm -f readrom.rel readrom.sym readrom.prn readrom.com
	rm -f 'xxprog.$$$$$$' 'xxabs.$$$$$$'
	rm -f *~

.PHONY: all clean
