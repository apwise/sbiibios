VERS    EQU     41
        ORG     0000h
        lda     8800h   ;0000 3a 00 88         lda 8800h
        cpi     55h     ;0003 fe 55            cpi 55h
        jnz     btcpu1  ;0005 c2 13 00         jnz 0013h
        lda     8801h   ;0008 3a 01 88         lda 8801h
        cpi     aah     ;000b fe aa            cpi aah
        jnz     btcpu1  ;000d c2 13 00         jnz 0013h
        jmp     btcpu2  ;0010 c3 21 00         jmp 0021h
;;;
btcpu1: lxi     h, 0400h        ;0013 21 00 04         lxi h, 0400h
        lxi     d, c000h        ;0016 11 00 c0         lxi d, c000h
        lxi     b, 0400h        ;0019 01 00 04         lxi b, 0400h
        LDIR
        jmp     c006h   ;001e c3 06 c0
;;;
btcpu2: lxi     sp, 8bffh       ;0021 31 ff 8b         lxi sp, 8bffh
        mvi     a, 00h  ;0024 3e 00            mvi a, 00h
        sta     8800h   ;0026 32 00 88         sta 8800h
        sta     8801h   ;0029 32 01 88         sta 8801h
        sta     8807h   ;002c 32 07 88         sta 8807h
        sta     8806h   ;002f 32 06 88         sta 8806h
        out     10h     ;0032 d3 10            out 10h
        lda     002fh   ;0034 3a 2f 00         lda 002fh
        out     08h     ;0037 d3 08            out 08h
        mvi     a, 00h  ;0039 3e 00            mvi a, 00h
        sta     8a0ch   ;003b 32 0c 8a         sta 8a0ch
        lxi     sp, 8bffh ;003e 31 ff 8b         lxi sp, 8bffh
;;;
        lda     8807h   ;0041 3a 07 88         lda 8807h
        ora     a        ;0044 b7               ora a
        jz      0041h   ;0045 ca 41 00         jz 0041h
;;;
        mvi     a, 2fh  ;0048 3e 2f            mvi a, 2fh
        out     08h     ;004a d3 08            out 08h
        xra     a       ;004c af               xra a
        sta     8807h   ;004d 32 07 88         sta 8807h
        sta     FPYSTS  ;0050 32 0b 8a         sta 8a0bh
        lda     8803h   ;0053 3a 03 88         lda 8803h
        ani     03h     ;0056 e6 03            ani 03h
        mov     b, a    ;0058 47               mov b, a
        inr     b       ;0059 04               inr b
        mvi     a, 02h  ;005a 3e 02            mvi a, 02h
        dcr     b       ;005c 05               dcr b
        jz      0064h   ;005d ca 64 00         jz 0064h
        rlc             ;0060 07               rlc
        jmp     005ch   ;0061 c3 5c 00         jmp 005ch
        ani     1eh     ;0064 e6 1e            ani 1eh
        sta     8803h   ;0066 32 03 88         sta 8803h
        lda     8805h   ;0069 3a 05 88         lda 8805h
        cma             ;006c 2f               cma
        sbi     23h     ;006d de 23            sbi 23h
        jm      007eh   ;006f fa 7e 00         jm 007eh
        cma             ;0072 2f               cma
        sta     8805h   ;0073 32 05 88         sta 8805h
        lda     8803h   ;0076 3a 03 88         lda 8803h
        ori     20h     ;0079 f6 20            ori 20h
        sta     8803h   ;007b 32 03 88         sta 8803h
        lda     8803h   ;007e 3a 03 88         lda 8803h
        ori     01h     ;0081 f6 01            ori 01h
        out     10h     ;0083 d3 10            out 10h
        lda     8802h   ;0085 3a 02 88         lda 8802h
        cpi     05h     ;0088 fe 05            cpi 05h
        jz      02a2h   ;008a ca a2 02         jz 02a2h
 ;008d fe 04            cpi 04h
 ;008f ca bc 02         jz 02bch
 ;0092 fe 01            cpi 01h
 ;0094 ca eb 00         jz 00ebh
 ;0097 f2 f2 00         jp 00f2h
 ;009a 21 05 00         lxi h, 0005h
 ;009d 22 0d 8a         shld  8a0dh
 ;00a0 3a 03 88         lda 8803h
 ;00a3 e6 1e            ani 1eh
 ;00a5 32 06 88         sta 8806h
 ;00a8 cd c8 00         call 00c8h
 ;00ab b7               ora a
 ;00ac e6 1c            ani 1ch
 ;00ae ee 04            xri 04h
 ;00b0 32 0b 8a         sta 8a0bh
 ;00b3 ca 2a 02         jz 022ah
 ;00b6 21 0d 8a         lxi h, 8a0dh
 ;00b9 7e               mov a, m
 ;00ba b7               ora a
 ;00bb ca 22 02         jz 0222h
 ;00be 35               dcr m
 ;00bf cd aa 03         call 03aah
 ;00c2 cd aa 03         call 03aah
 ;00c5 c3 a0 00         jmp 00a0h
 ;00c8 3a 02 88         lda 8802h
 ;00cb b7               ora a
 ;00cc f2 d4 00         jp 00d4h
 ;00cf 3e f3            mvi a, f3h
 ;00d1 c3 d6 00         jmp 00d6h
 ;00d4 3e f7            mvi a, f7h
 ;00d6 d3 08            out 08h
 ;00d8 cd b0 02         call 02b0h
 ;00db cd b0 02         call 02b0h
 ;00de cd b0 02         call 02b0h
 ;00e1 cd b0 02         call 02b0h
 ;00e4 00               nop
 ;00e5 00               nop
 ;00e6 00               nop
 ;00e7 cd 7c 02         call 027ch
 ;00ea c9               ret
 ;00eb 97               sub a
 ;00ec 21 19 00         lxi h, 0019h
 ;00ef c3 f7 00         jmp 00f7h
 ;00f2 3e 01            mvi a, 01h
 ;00f4 21 00 05         lxi h, 0500h
 ;00f7 22 08 8a         shld  8a08h
 ;00fa 32 0a 8a         sta 8a0ah
 ;00fd 3a 06 88         lda 8806h
 ;0100 57               mov d, a
 ;0101 3a 03 88         lda 8803h
 ;0104 e6 1e            ani 1eh
 ;0106 ba               cmp d
 ;0107 ca 34 01         jz 0134h
 ;010a 3a 03 88         lda 8803h
 ;010d e6 1e            ani 1eh
 ;010f 32 06 88         sta 8806h
 ;0112 cd 3b 02         call 023bh
 ;0115 ca 2d 01         jz 012dh
 ;0118 cd b9 03         call 03b9h
 ;011b cd 3b 02         call 023bh
 ;011e ca 2d 01         jz 012dh
 ;0121 cd c8 00         call 00c8h
 ;0124 cd 3b 02         call 023bh
 ;0127 ca 2d 01         jz 012dh
 ;012a c3 22 02         jmp 0222h
 ;012d db 0a            in 0ah
 ;012f d3 09            out 09h
 ;0131 cd c8 03         call 03c8h
 ;0134 2a 04 88         lhld 8804h
 ;0137 4d               mov c, l
 ;0138 db 09            in 09h
 ;013a bc               cmp h
 ;013b ca 60 01         jz 0160h
 ;013e 7c               mov a, h
 ;013f d3 0b            out 0bh
 ;0141 cd c8 03         call 03c8h
 ;0144 3e e7            mvi a, e7h
 ;0146 d3 08            out 08h
 ;0148 cd b0 02         call 02b0h
 ;014b cd b0 02         call 02b0h
 ;014e cd b0 02         call 02b0h
 ;0151 cd b0 02         call 02b0h
 ;0154 00               nop
 ;0155 00               nop
 ;0156 00               nop
 ;0157 00               nop
 ;0158 00               nop
 ;0159 00               nop
 ;015a cd 7c 02         call 027ch
 ;015d c3 12 01         jmp 0112h
 ;0160 79               mov a, c
 ;0161 d3 0a            out 0ah
 ;0163 cd c8 03         call 03c8h
 ;0166 21 08 88         lxi h, 8808h
 ;0169 3a 0a 8a         lda 8a0ah
 ;016c b7               ora a
 ;016d c2 a5 01         jnz 01a5h
 ;0170 3e 77            mvi a, 77h
 ;0172 d3 08            out 08h
 ;0174 cd c8 03         call 03c8h
 ;0177 3a 02 88         lda 8802h
 ;017a d6 02            sui 02h
 ;017c fa 87 01         jm 0187h
 ;017f cd 91 01         call 0191h
 ;0182 db 0b            in 0bh
 ;0184 c3 7f 01         jmp 017fh
 ;0187 cd 91 01         call 0191h
 ;018a db 0b            in 0bh
 ;018c 77               mov m, a
 ;018d 23               inx h
 ;018e c3 87 01         jmp 0187h
 ;0191 db 08            in 08h
 ;0193 1f               rar
 ;0194 1f               rar
 ;0195 d0               rnc
 ;0196 17               ral
 ;0197 d2 91 01         jnc 0191h
 ;019a 3a 0c 8a         lda 8a0ch
 ;019d b7               ora a
 ;019e c2 a8 03         jnz 03a8h
 ;01a1 e1               pop h
 ;01a2 c3 bd 01         jmp 01bdh
 ;01a5 fe 03            cpi 03h
 ;01a7 3e 57            mvi a, 57h
 ;01a9 c2 ae 01         jnz 01aeh
 ;01ac 3e 50            mvi a, 50h
 ;01ae d3 08            out 08h
 ;01b0 cd c8 03         call 03c8h
 ;01b3 cd 91 01         call 0191h
 ;01b6 7e               mov a, m
 ;01b7 d3 0b            out 0bh
 ;01b9 23               inx h
 ;01ba c3 b3 01         jmp 01b3h
 ;01bd 0e 7c            mvi c, 7ch
 ;01bf 3a 0a 8a         lda 8a0ah
 ;01c2 b7               ora a
 ;01c3 c2 c8 01         jnz 01c8h
 ;01c6 0e 1c            mvi c, 1ch
 ;01c8 cd 7c 02         call 027ch
 ;01cb a1               ana c
 ;01cc 32 0b 8a         sta 8a0bh
 ;01cf ca 00 02         jz 0200h
 ;01d2 21 08 8a         lxi h, 8a08h
 ;01d5 3a 0a 8a         lda 8a0ah
 ;01d8 b7               ora a
 ;01d9 ca e4 01         jz 01e4h
 ;01dc 23               inx h
 ;01dd 35               dcr m
 ;01de ca 22 02         jz 0222h
 ;01e1 c3 fd 00         jmp 00fdh
 ;01e4 35               dcr m
 ;01e5 c2 fd 00         jnz 00fdh
 ;01e8 3a 02 88         lda 8802h
 ;01eb fe 01            cpi 01h
 ;01ed c2 f3 01         jnz 01f3h
 ;01f0 c3 22 02         jmp 0222h
 ;01f3 23               inx h
 ;01f4 35               dcr m
 ;01f5 ca 22 02         jz 0222h
 ;01f8 3e 01            mvi a, 01h
 ;01fa 32 0a 8a         sta 8a0ah
 ;01fd c3 fd 00         jmp 00fdh
 ;0200 3a 02 88         lda 8802h
 ;0203 fe 06            cpi 06h
 ;0205 ca 2a 02         jz 022ah
 ;0208 b7               ora a
 ;0209 de 02            sbi 02h
 ;020b fa 2a 02         jm 022ah
 ;020e 21 0a 8a         lxi h, 8a0ah
 ;0211 97               sub a
 ;0212 be               cmp m
 ;0213 ca 2a 02         jz 022ah
 ;0216 77               mov m, a
 ;0217 3e 0a            mvi a, 0ah
 ;0219 32 08 8a         sta 8a08h
 ;021c 3a 04 88         lda 8804h
 ;021f c3 61 01         jmp 0161h
 ;0222 3a 0b 8a         lda 8a0bh
 ;0225 f6 01            ori 01h
 ;0227 32 0b 8a         sta 8a0bh
 ;022a 3e 2f            mvi a, 2fh
 ;022c d3 08            out 08h
 ;022e cd c8 03         call 03c8h
 ;0231 3a 03 88         lda 8803h
 ;0234 e6 3e            ani 3eh
 ;0236 d3 10            out 10h
 ;0238 c3 39 00         jmp 0039h
 ;023b 21 0a 00         lxi h, 000ah
 ;023e 22 0d 8a         shld  8a0dh
 ;0241 11 00 a0         lxi d, a000h
 ;0244 21 0f 8a         lxi h, 8a0fh
 ;0247 3e 3b            mvi a, 3bh
 ;0249 d3 08            out 08h
 ;024b 1b               dcx d
 ;024c 7b               mov a, e
 ;024d b2               ora d
 ;024e ca 8b 02         jz 028bh
 ;0251 db 08            in 08h
 ;0253 1f               rar
 ;0254 1f               rar
 ;0255 da 4b 02         jc 024bh
 ;0258 db 0b            in 0bh
 ;025a 77               mov m, a
 ;025b 23               inx h
 ;025c db 08            in 08h
 ;025e 1f               rar
 ;025f 1f               rar
 ;0260 d2 58 02         jnc 0258h
 ;0263 17               ral
 ;0264 d2 5c 02         jnc 025ch
 ;0267 cd 7c 02         call 027ch
 ;026a e6 0c            ani 0ch
 ;026c 32 0b 8a         sta 8a0bh
 ;026f c8               rz
 ;0270 21 0d 8a         lxi h, 8a0dh
 ;0273 35               dcr m
 ;0274 c2 41 02         jnz 0241h
 ;0277 3a 0b 8a         lda 8a0bh
 ;027a b7               ora a
 ;027b c9               ret
 ;027c 2e 05            mvi l, 05h
 ;027e 2d               dcr l
 ;027f c2 7e 02         jnz 027eh
 ;0282 21 00 00         lxi h, 0000h
 ;0285 2b               dcx h
 ;0286 7c               mov a, h
 ;0287 b5               ora l
 ;0288 c2 93 02         jnz 0293h
 ;028b 3c               inr a
 ;028c 0f               rrc
 ;028d 32 0b 8a         sta 8a0bh
 ;0290 c3 22 02         jmp 0222h
 ;0293 db 08            in 08h
 ;0295 2f               cma
 ;0296 1f               rar
 ;0297 da 85 02         jc 0285h
 ;029a 17               ral
 ;029b f5               push psw
 ;029c 3e 2f            mvi a, 2fh
 ;029e d3 08            out 08h
 ;02a0 f1               pop psw
 ;02a1 c9               ret
 ;02a2 3a 03 88         lda 8803h
 ;02a5 e6 3e            ani 3eh
 ;02a7 d3 10            out 10h
 ;02a9 af               xra a
 ;02aa 32 0b 8a         sta 8a0bh
 ;02ad c3 39 00         jmp 0039h
 ;02b0 21 00 18         lxi h, 1800h
 ;02b3 e5               push h
 ;02b4 e1               pop h
 ;02b5 2b               dcx h
 ;02b6 7c               mov a, h
 ;02b7 b5               ora l
 ;02b8 c2 b3 02         jnz 02b3h
 ;02bb c9               ret
 ;02bc 3e ff            mvi a, ffh
 ;02be 32 0c 8a         sta 8a0ch
 ;02c1 3a 03 88         lda 8803h
 ;02c4 e6 1e            ani 1eh
 ;02c6 32 06 88         sta 8806h
 ;02c9 01 01 ff         lxi b, ff01h
 ;02cc ed 43 19         call 1943h
 ;02cf 8a               adc d
 ;02d0 3a 03 88         lda 8803h
 ;02d3 e6 20            ani 20h
 ;02d5 ca df 02         jz 02dfh
 ;02d8 01 01 fe         lxi b, fe01h
 ;02db ed 43 19         call 1943h
 ;02de 8a               adc d
 ;02df 3a 05 88         lda 8805h
 ;02e2 57               mov d, a
 ;02e3 db 09            in 09h
 ;02e5 ba               cmp d
 ;02e6 ca f6 02         jz 02f6h
 ;02e9 7a               mov a, d
 ;02ea d3 0b            out 0bh
 ;02ec 3e e7            mvi a, e7h
 ;02ee d3 08            out 08h
 ;02f0 cd 7c 02         call 027ch
 ;02f3 cd b0 02         call 02b0h
 ;02f6 1e fe            mvi e, feh
 ;02f8 26 0a            mvi h, 0ah
 ;02fa 3e 0b            mvi a, 0bh
 ;02fc d3 08            out 08h
 ;02fe 01 28 b1         lxi b, b128h
 ;0301 cd 8e 03         call 038eh
 ;0304 01 10 b1         lxi b, b110h
 ;0307 cd 8e 03         call 038eh
 ;030a 01 0a ff         lxi b, ff0ah
 ;030d cd 8e 03         call 038eh
 ;0310 01 03 0a         lxi b, 0a03h
 ;0313 cd 8e 03         call 038eh
 ;0316 01 01 01         lxi b, 0101h
 ;0319 cd 8e 03         call 038eh
 ;031c 42               mov b, d
 ;031d 0e 01            mvi c, 01h
 ;031f cd 8e 03         call 038eh
 ;0322 ed 4b 19         call 194bh
 ;0325 8a               adc d
 ;0326 cd 8e 03         call 038eh
 ;0329 43               mov b, e
 ;032a 0e 01            mvi c, 01h
 ;032c cd 8e 03         call 038eh
 ;032f 01 01 fd         lxi b, fd01h
 ;0332 cd 8e 03         call 038eh
 ;0335 01 01 08         lxi b, 0801h
 ;0338 cd 8e 03         call 038eh
 ;033b 01 16 b1         lxi b, b116h
 ;033e cd 8e 03         call 038eh
 ;0341 01 0c ff         lxi b, ff0ch
 ;0344 cd 8e 03         call 038eh
 ;0347 01 03 0a         lxi b, 0a03h
 ;034a cd 8e 03         call 038eh
 ;034d 01 01 05         lxi b, 0501h
 ;0350 cd 8e 03         call 038eh
 ;0353 01 ff e5         lxi b, e5ffh
 ;0356 cd 8e 03         call 038eh
 ;0359 0e ff            mvi c, ffh
 ;035b cd 8e 03         call 038eh
 ;035e 0e 02            mvi c, 02h
 ;0360 cd 8e 03         call 038eh
 ;0363 01 01 08         lxi b, 0801h
 ;0366 cd 8e 03         call 038eh
 ;0369 1d               dcr e
 ;036a 25               dcr h
 ;036b c2 04 03         jnz 0304h
 ;036e 01 ff b1         lxi b, b1ffh
 ;0371 cd 9d 03         call 039dh
 ;0374 0e ff            mvi c, ffh
 ;0376 cd 9d 03         call 039dh
 ;0379 db 08            in 08h
 ;037b 2f               cma
 ;037c e6 22            ani 22h
 ;037e 32 0b 8a         sta 8a0bh
 ;0381 c2 22 02         jnz 0222h
 ;0384 3e 2f            mvi a, 2fh
 ;0386 d3 08            out 08h
 ;0388 cd c8 03         call 03c8h
 ;038b c3 2a 02         jmp 022ah
 ;038e db 08            in 08h
 ;0390 1f               rar
 ;0391 1f               rar
 ;0392 da 8e 03         jc 038eh
 ;0395 78               mov a, b
 ;0396 d3 0b            out 0bh
 ;0398 0d               dcr c
 ;0399 c2 8e 03         jnz 038eh
 ;039c c9               ret
 ;039d cd 91 01         call 0191h
 ;03a0 78               mov a, b
 ;03a1 d3 0b            out 0bh
 ;03a3 0d               dcr c
 ;03a4 c2 9d 03         jnz 039dh
 ;03a7 c9               ret
 ;03a8 c1               pop b
 ;03a9 c9               ret
 ;03aa d9               ret
 ;03ab 3e a7            mvi a, a7h
 ;03ad d3 08            out 08h
 ;03af cd 7c 02         call 027ch
 ;03b2 e6 00            ani 00h
 ;03b4 d9               ret
 ;03b5 c2 22 02         jnz 0222h
 ;03b8 c9               ret
 ;03b9 d9               ret
 ;03ba 3e 87            mvi a, 87h
 ;03bc d3 08            out 08h
 ;03be cd 7c 02         call 027ch
 ;03c1 e6 00            ani 00h
 ;03c3 d9               ret
 ;03c4 c2 22 02         jnz 0222h
 ;03c7 c9               ret
 ;03c8 3e 05            mvi a, 05h
 ;03ca 3d               dcr a
 ;03cb c2 ca 03         jnz 03cah
 ;03ce c9               ret
;;;
STACK   EQU     0f3ffh
;;;
INTRST  EQU     48h             ; Reset interrupt latch
PPIA    EQU     68h             ; 8255 port a
PPIB    EQU     69h             ; 8255 port b
PPIC    EQU     6ah             ; 8255 port c
PPICW   EQU     6bh             ; 8255 control port
;
; Locations in CPU-2 RAM concerned with floppy disks
;
FPYPRM  EQU     8802h           ; 4-byte parameter block
FPYCMD  EQU     8807h           ; Command byte (FF = "go")
FPYBUF  EQU     8808h           ; 512-byte sector buffer
FPYSTS  EQU     8a0bh           ; Returned status byte
PHYSEC  EQU     0200h           ; Physical sector size (512 bytes)
;;;
BTSTRP  EQU     0c780h          ; Bootstrap loader address
;;;
        ORG     0c000h
        jmp     c006h   ;0400 c3 06 c0         jmp c006h
        jmp     dread   ;0403 c3 87 c2         jmp c287h
        di              ;0406 f3               di
        lxi     sp, STACK       ;0407 31 ff f3         lxi sp, f3ffh
        mvi     a, 82h  ;040a 3e 82            mvi a, 82h
        out     PPICW   ;040c d3 6b            out 6bh
        mvi     a, 2ah  ;040e 3e 2a            mvi a, 2ah
        out     PPIC    ;0410 d3 6a            out 6ah
        mvi     a, 60h  ;0412 3e 60            mvi a, 60h
        sta     c349h   ;0414 32 49 c3         sta c349h
        out     PPIA    ;0417 d3 68            out 68h
        mvi     a, 08h  ;0419 3e 08            mvi a, 08h
        out     PPICW   ;041b d3 6b            out 6bh
        mvi     a, 55h  ;041d 3e 55            mvi a, 55h
        sta     8800h   ;041f 32 00 88         sta 8800h
        mvi     a, aah  ;0422 3e aa            mvi a, aah
        sta     8801h   ;0424 32 01 88         sta 8801h
        mvi     a, b2h  ;0427 3e b2            mvi a, b2h
        out     PPIC    ;0429 d3 6a            out 6ah
        mvi     a, 40h  ;042b 3e 40            mvi a, 40h
        out     PPIA    ;042d d3 68            out 68h
;;;
        lxi     h, 4800h        ;042f 21 00 48         lxi h, 4800h
        lxi     d, 0800h        ;0432 11 00 08         lxi d, 0800h
lp1:    xra     a               ;0435 af               xra a
        mov     m, a    ;0436 77               mov m, a
        inx     h       ;0437 23               inx h
        dcx     d       ;0438 1b               dcx d
        mov     a, d    ;0439 7a               mov a, d
        ora     e       ;043a b3               ora e
        jnz     lp1     ;043b c2 35 c0         jnz c035h
;;;
        mvi     a, 60h  ;043e 3e 60            mvi a, 60h
        out     PPIA    ;0440 d3 68            out 68h
;;;
        lxi     h, f800h        ;0442 21 00 f8         lxi h, f800h
        lxi     d, 0800h        ;0445 11 00 08         lxi d, 0800h
lp2:    mvi     a, 20h  ;0448 3e 20            mvi a, 20h
        mov     m, a    ;044a 77               mov m, a
        inx     h       ;044b 23               inx h
        dcx     d       ;044c 1b               dcx d
        mov     a, d    ;044d 7a               mov a, d
        ora     e       ;044e b3               ora e
        jnz     lp2     ;044f c2 48 c0         jnz c048h
;;; Set up an interrupt vector
        mvi     a, c3h  ;0452 3e c3            mvi a, c3h
        sta     0038h   ;0454 32 38 00         sta 0038h
        lxi     h, intrp        ;0457 21 01 c1         lxi h, c101h
        shld    0039h   ;045a 22 39 00         shld  0039h
;;;
        lxi     h, 0000h        ;045d 21 00 00         lxi h, 0000h
        shld    c305h           ;0460 22 05 c3         shld  c305h
        shld    c307h           ;0463 22 07 c3         shld  c307h
        shld    c309h           ;0466 22 09 c3         shld  c309h
        shld    c30bh           ;0469 22 0b c3         shld  c30bh
;;;
        lxi     h, c310h        ;046c 21 10 c3         lxi h, c310h
        mvi     b, 19h  ;046f 06 19            mvi b, 19h
        mvi     a, 00h  ;0471 3e 00            mvi a, 00h
lp3:    mov     m, a    ;0473 77               mov m, a
        inx     h       ;0474 23               inx h
        dcr     b       ;0475 05               dcr b
        jnz     lp3     ;0476 c2 73 c0         jnz c073h
;;;
        lxi     h, c329h        ;0479 21 29 c3         lxi h, c329h
        mvi     b, 19h          ;047c 06 19            mvi b, 19h
        mvi     a, 00h          ;047e 3e 00            mvi a, 00h
lp4:    mov     m, a            ;0480 77               mov m, a
        inx     h               ;0481 23               inx h
        dcr     b               ;0482 05               dcr b
        jnz     lp4             ;0483 c2 80 c0         jnz c080h
;;;
        sta     c345h   ;0486 32 45 c3         sta c345h
        sta     c346h   ;0489 32 46 c3         sta c346h
        call    c14ch   ;048c cd 4c c1         call c14ch
        out     INRST   ;048f d3 48            out 48h
        call    fb56h   ;0491 ed 56 fb         call fb56h
        jmp     c0cdh   ;0494 c3 cd c0         jmp c0cdh
;;;
prnmsg: lxi     h, signon        ;0497 21 ab c0         lxi h, c0abh
        call    c09eh           ;049a cd 9e c0         call c09eh
        ret                     ;049d c9               ret
;;;
print:  mov     a, m            ; Get character
        push    h               ; Save pointer
        call    c11eh           ; Print character
        pop     h               ; Restore pointer
        mov     a, m            ; Recover character
        ora     a               ; Set flags
        rm                      ; Top bit set, return
        inx     h               ; Step pointer
        jmp     print           ; Loop over message
;;;
signon: db      VERS/10+'0','.',VERS MOD 10+'0'
        db      '   '
        db      'INSERT DISKETTE INTO DRIVE '
        db      'A'+0x80
;;;
        lxi     b, ff00h        ; ?? command, Disk 0
        call    fparam          ; Send parameters
        call    fpwres          ; Wait for result
        call    fpstat          ; Get status
        ani     80h             ; Failed?
        jz      L001            ; No, go read bootstrap
        call    prnmsg          ; Yes, print "Insert disk" message
;;;
lp6:    lxi     b, 0000h        ; Restore command, Disk 0
        call    fparam          ; Send parameters
        call    fpwres          ; Wait for result
        call    fpstat          ; Get status
        ani     80h             ; Failed...
        jnz     lp6             ; Wait until floppy in drive
;;;
L001:   lxi     h, BTSTRP       ; Bootstrap loader address
        lxi     d, 0001h        ; Track 0, Sector 1
        lxi     b, 0100h        ; Read command, Disk 0
        call    dread           ; Read the sector
        jmp     BTSTRP          ; Jump to the bootstrap loader
;;;
intrp:  push    h       ;0501 e5               push h
        push    d       ;0502 d5               push d
        push    b       ;0503 c5               push b
        push    psw     ;0504 f5               push psw
        in      PPIB    ;0505 db 69            in 69h
        ani     04h     ;0507 e6 04            ani 04h
        jz      L002    ;0509 ca 18 c1         jz c118h
        call    c14ch   ;050c cd 4c c1         call c14ch
        in      INTRST  ;050f db 48            in 48h
        pop     psw     ;0511 f1               pop psw
        pop     b       ;0512 c1               pop b
        pop     d       ;0513 d1               pop d
        pop     h       ;0514 e1               pop h
        ei              ;0515 fb               ei
        RETI            ;0516 ed 4d
;;;
L002:   call    c136h   ;0518 cd 36 c1
        jmp     c10fh   ;051b c3 0f c1         jmp c10fh
        ani     7fh     ;051e e6 7f            ani 7fh
        mov     b, a    ;0520 47               mov b, a
        sui     20h     ;0521 d6 20            sui 20h
        jm      c12bh   ;0523 fa 2b c1         jm c12bh
        mov     a, b    ;0526 78               mov a, b
        call    c177h   ;0527 cd 77 c1         call c177h
        ret             ;052a c9               ret
;;;
        cpi     0ah     ;052b fe 0a            cpi 0ah
        jz      c25dh   ;052d ca 5d c2         jz c25dh
        cpi     0dh     ;0530 fe 0d            cpi 0dh
        jz      c27bh   ;0532 ca 7b c2         jz c27bh
        ret             ;0535 c9               ret
;;;
        lhld    c30eh   ;0536 2a 0e c3         lhld c30eh
        mov     a, m    ;0539 7e               mov a, m
        inx     h       ;053a 23               inx h
        shld    c30eh   ;053b 22 0e c3         shld  c30eh
        ora     a       ;053e b7               ora a
        jz      c147h   ;053f ca 47 c1         jz c147h
        mvi     a, 02h  ;0542 3e 02            mvi a, 02h
        out     PPICW   ;0544 d3 6b            out 6bh
        ret             ;0546 c9               ret
;;;
        mvi     a, 03h  ;0547 3e 03            mvi a, 03h
        out     PPICW   ;0549 d3 6b            out 6bh
        ret             ;054b c9               ret
;;;
        call    c212h   ;054c cd 12 c2         call c212h
        lxi     h, c329h        ;054f 21 29 c3         lxi h, c329h
        lxi     d, c310h        ;0552 11 10 c3         lxi d, c310h
        lxi     b, 0019h        ;0555 01 19 00         lxi b, 0019h
        LDIR                    ;0558 ed b0
        lxi     h, c310         ;055a 21 10 c3
        shld    c30e            ;055d 22 0e c3
        call    c136            ;0560 cd 36 c1
        lda     c343h   ;0563 3a 43 c3         lda c343h
        dcr     a       ;0566 3d               dcr a
        sta     c343h   ;0567 32 43 c3         sta c343h
        lda     c342h   ;056a 3a 42 c3         lda c342h
        dcr     a       ;056d 3d               dcr a
        sta     c342h   ;056e 32 42 c3         sta c342h
        rnz             ;0571 c0               rnz
        mvi     a, 0ch  ;0572 3e 0c            mvi a, 0ch
        out     PPICW   ;0574 d3 6b            out 6bh
        ret             ;0576 c9               ret
;;;
        sta     c30dh   ;0577 32 0d c3         sta c30dh
        call    c191h   ;057a cd 91 c1         call c191h
        mov     a, m    ;057d 7e               mov a, m
        ora     a       ;057e b7               ora a
        cz      c1fch   ;057f cc fc c1         cz c1fch
        lhld    c307h   ;0582 2a 07 c3         lhld c307h
        mov     a, h    ;0585 7c               mov a, h
        ori     f8h     ;0586 f6 f8            ori f8h
        mov      h, a   ;0588 67               mov h, a
        lda     c30dh   ;0589 3a 0d c3         lda c30dh
        mov     m, a    ;058c 77               mov m, a
        call    c237h   ;058d cd 37 c2         call c237h
        ret             ;0590 c9               ret
;;;
        lxi     h, c329h        ;0591 21 29 c3         lxi h, c329h
        mvi     d, 00h  ;0594 16 00            mvi d, 00h
        lda     c306h   ;0596 3a 06 c3         lda c306h
        mov     e, a    ;0599 5f               mov e, a
        dad     d       ;059a 19               dad d
        ret             ;059b c9               ret
;;;
        di              ;059c f3               di
        lhld    c30bh   ;059d 2a 0b c3         lhld c30bh
        lxi     d, 0050h        ;05a0 11 50 00         lxi d, 0050h
        dad     d       ;05a3 19               dad d
        shld    c30bh   ;05a4 22 0b c3         shld  c30bh
        lxi     h, c32ah        ;05a7 21 2a c3         lxi h, c32ah
        lxi     d, c329h        ;05aa 11 29 c3         lxi d, c329h
        lxi     b, 0018h        ;05ad 01 18 00         lxi b, 0018h
        LDIR                    ;05b0 ed b0
        mvi     a, 0    ;05b2 3e 00
        stax    d       ;05b4 12               stax d
        ei              ;05b5 fb               ei
        ret             ;05b6 c9               ret
;;;
        lxi     h, c1cah        ;05b7 21 ca c1         lxi h, c1cah
        lda     c306h   ;05ba 3a 06 c3         lda c306h
        rlc             ;05bd 07               rlc
        mov     e, a    ;05be 5f               mov e, a
        mvi     d, 00h  ;05bf 16 00            mvi d, 00h
        dad     d       ;05c1 19               dad d
        mov     e, m    ;05c2 5e               mov e, m
        inx     h       ;05c3 23               inx h
        mov     d, m    ;05c4 56               mov d, m
        lhld    c30bh   ;05c5 2a 0b c3         lhld c30bh
        dad     d       ;05c8 19               dad d
        ret             ;05c9 c9               ret
;;;
 ;05ca 00               nop (c1ca)
 ;05cb 00               nop
 ;05cc 50               mov d, b
 ;05cd 00               nop
 ;05ce a0               ana b
 ;05cf 00               nop
 ;05d0 f0               rp
 ;05d1 00               nop
 ;05d2 40               mov b, b
 ;05d3 01 90 01         lxi b, 0190h
 ;05d6 e0               rpo
 ;05d7 01 30 02         lxi b, 0230h
 ;05da 80               add b
 ;05db 02               stax b
 ;05dc d0               rnc
 ;05dd 02               stax b
 ;05de 20               nop
 ;05df 03               inx b
 ;05e0 70               mov m, b
 ;05e1 03               inx b
 ;05e2 c0               rnz
 ;05e3 03               inx b
 ;05e4 10               nop
 ;05e5 04               inr b
 ;05e6 60               mov h, b
 ;05e7 04               inr b
 ;05e8 b0               ora b
 ;05e9 04               inr b
 ;05ea 00               nop
 ;05eb 05               dcr b
 ;05ec 50               mov d, b
 ;05ed 05               dcr b
 ;05ee a0               ana b
 ;05ef 05               dcr b
 ;05f0 f0               rp
 ;05f1 05               dcr b
 ;05f2 40               mov b, b
 ;05f3 06 90            mvi b, 90h
 ;05f5 06 e0            mvi b, e0h
 ;05f7 06 30            mvi b, 30h
 ;05f9 07               rlc
 ;05fa 80               add b
 ;05fb 07               rlc
;;;
        call    c1b7h   ;05fc cd b7 c1         call c1b7h
        mvi     d, 50h  ;05ff 16 50            mvi d, 50h
        mvi     a, f8h  ;0601 3e f8            mvi a, f8h
        ora     h       ;0603 b4               ora h
        mov     h, a    ;0604 67               mov h, a
        mvi     m, 20h  ;0605 36 20            mvi m, 20h
        inx     h       ;0607 23               inx h
        dcr     d       ;0608 15               dcr d
        jnz     c201h   ;0609 c2 01 c2         jnz c201h
        call    c191h   ;060c cd 91 c1         call c191h
        mvi     m, ffh  ;060f 36 ff            mvi m, ffh
        ret             ;0611 c9               ret
;;;
        lhld    c30bh   ;0612 2a 0b c3         lhld c30bh
        shld    c309h   ;0615 22 09 c3         shld  c309h
        xchg            ;0618 eb               xchg
        lhld    c307h   ;0619 2a 07 c3         lhld c307h
        mov     a, h    ;061c 7c               mov a, h
        ani     0fh     ;061d e6 0f            ani 0fh
        mov     h, a    ;061f 67               mov h, a
        mov     a, d    ;0620 7a               mov a, d
        ani     0fh     ;0621 e6 0f            ani 0fh
        mov     d, a    ;0623 57               mov d, a
        mvi     a, 01h  ;0624 3e 01            mvi a, 01h
        out     PPICW   ;0626 d3 6b            out 6bh
        mvi     a, 03h ;0628 3e 03            mvi a, 03h
        mov     m, a    ;062a 77               mov m, a
        mvi     a, 01h  ;062b 3e 01            mvi a, 01h
        xchg            ;062d eb               xchg
        mov     m, a    ;062e 77               mov m, a
        mvi     a, 02h  ;062f 3e 02            mvi a, 02h
        mov     m, a    ;0631 77               mov m, a
        mvi     a, 00h  ;0632 3e 00            mvi a, 00h
        out     PPICW   ;0634 d3 6b            out 6bh
        ret             ;0636 c9               ret
;;;
        lhld    c307h    ;0637 2a 07 c3         lhld c307h
        inx     h       ;063a 23               inx h
        shld    c307h   ;063b 22 07 c3         shld  c307h
        lhld    c305h   ;063e 2a 05 c3         lhld c305h
        inr     l       ;0641 2c               inr l
        mov     a, l    ;0642 7d               mov a, l
        cpi     50h     ;0643 fe 50            cpi 50h
        jnz     c259h   ;0645 c2 59 c2         jnz c259h
        mvi     l, 00h  ;0648 2e 00            mvi l, 00h
        mov     a, h    ;064a 7c               mov a, h
        cpi     18h     ;064b fe 18            cpi 18h
        jnz     c258h   ;064d c2 58 c2         jnz c258h
        push    h       ;0650 e5               push h
        call    c19ch   ;0651 cd 9c c1         call c19ch
        pop     h       ;0654 e1               pop h
        jmp     c259h   ;0655 c3 59 c2         jmp c259h
        inr     h       ;0658 24               inr h
        shld    c305h   ;0659 22 05 c3         shld  c305h
        ret             ;065c c9               ret
;;;
        lhld    c307h   ;065d 2a 07 c3         lhld c307h
        lxi     d, 0050h        ;0660 11 50 00         lxi d, 0050h
        dad d           ;0663 19               dad d
        shld    c307h   ;0664 22 07 c3         shld  c307h
        lda     c306h   ;0667 3a 06 c3         lda c306h
        cpi     18h     ;066a fe 18            cpi 18h
        jnz     c276h   ;066c c2 76 c2         jnz c276h
        sta     c306h   ;066f 32 06 c3         sta c306h
        call    c19ch   ;0672 cd 9c c1         call c19ch
        ret             ;0675 c9               ret
;;;
        inr     a       ;0676 3c               inr a
        sta     c306h   ;0677 32 06 c3         sta c306h
        ret             ;067a c9               ret
;;;
        call    c1b7h   ;067b cd b7 c1         call c1b7h
        shld    c307h   ;067e 22 07 c3         shld  c307h
        mvi     a, 00h  ;0681 3e 00            mvi a, 00h
        sta     c305h   ;0683 32 05 c3         sta c305h
        ret             ;0686 c9               ret
;;;
dread:  push    h       ;0687 e5               push h
        call    fparam   ;0688 cd 98 c2         call c298h
        call    fpwres   ;068b cd dd c2         call c2ddh
        pop     h       ;068e e1               pop h
        call    fp2hst   ;068f cd c1 c2         call c2c1h
        call    fpstat  ;0692 cd d1 c2         call c2d1h
        ani     01h     ;0695 e6 01            ani 01h
        ret             ;0697 c9               ret
;;;
fparam: call    busopn  ;0698 cd ec c2         call c2ech
        lxi     h, FPYPRM        ;069b 21 02 88         lxi h, 8802h
        mov     m, b    ;069e 70               mov m, b
        inx     h       ;069f 23               inx h
        mov     m, c    ;06a0 71               mov m, c
        inx     h       ;06a1 23               inx h
        mov     a, e    ;06a2 7b               mov a, e
        cma             ;06a3 2f               cma
        mov     m, a    ;06a4 77               mov m, a
        inx     h       ;06a5 23               inx h
        mov     a, d    ;06a6 7a               mov a, d
        cma             ;06a7 2f               cma
        mov     m, a    ;06a8 77               mov m, a
        mvi     a, ffh  ;06a9 3e ff            mvi a, ffh
        sta     FPYCMD   ;06ab 32 07 88         sta 8807h
        call    buscls  ;06ae cd fb c2         call c2fbh
        ret             ;06b1 c9               ret
;;;
hst2fp: call    busopn  ;06b2 cd ec c2         call c2ech   (unused)
        lxi     d, FPYBUF        ;06b5 11 08 88         lxi d, 8808h
        lxi     b, PHYSEC        ;06b8 01 00 02         lxi b, 0200h
        LDIR            ;06bb ed b0
        call    buscls  ;06bb cd fb c2
        ret             ;06c0 c9
;;;
fp2hst: call    busopn  ;06c1 cd ec c2
        xchg            ;06c4 eb
        lxi     h, FPYBUF        ;06c5 21 08 88         lxi h, 8808h
        lxi     b, PHYSEC       ;06c8 01 00 02         lxi b, 0200h
        LDIR            ;06cb ed b0
        call    buscls  ;06cd cd fb c2
        ret             ;06do c9
;;;
fpstat: call    busopn  ;06d1 cd ec c2
        lda     FPYSTS  ;06d4 3a 0b 8a
        push    psw     ;06d7 f5               push psw
        call    buscls  ;06d8 cd fb c2         call c2fbh
        pop     psw     ;06db f1               pop psw
        ret             ;06dc c9               ret
;;;
fpwres: in      PPIB    ;06dd db 69            in 69h
        ani     20h     ;06df e6 20            ani 20h
        jz      fpwres  ;06e1 ca dd c2         jz c2ddh
fpwr2:  in      PPIB    ;06e4 db 69            in 69h
        ani     20h     ;06e6 e6 20            ani 20h
        jnz     fpwr2   ;06e8 c2 e4 c2         jnz c2e4h
        ret             ;06eb c9               ret
;;;
busopn: mvi     a, 0ah  ;06ec 3e 0a            mvi a, 0ah
        out     PPICW   ;06ee d3 6b            out 6bh
busbsy: in      PPIB    ;06f0 db 69            in 69h
        ral             ;06f2 17               ral
        jc      busbsy  ;06f3 da f0 c2         jc c2f0h
        mvi     a, 08h  ;06f6 3e 08            mvi a, 08h
        out     PPICW   ;06f8 d3 6b            out 6bh
        ret             ;06fa c9               ret
;;;
buslcs: mvi     a, 09h  ; PPIC[4] High
        out     PPICW
        mvi     a, 0bh  ; PPIC[5] High
        out     PPICW
        ret
