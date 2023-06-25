; file offset is c780
        MACLIB  Z80
OFFSET  EQU     9400H           ;OFFSET FOR 64K = 9400H
                                ;OFFSET FOR 32K = 1400H
HSTBUF  EQU     6200H+OFFSET    ;DMA DISK BUFFER
STACK   EQU     5FFFH+OFFSET    ;STACK WHEN LOADING
STACK1  EQU     5FDFH+OFFSET    ;STACK DURING INTERRUPT
STACK2  EQU     5FBFH+OFFSET    ;STACK DURING CONOUT; DISK ROUTINES
STACK3  EQU     5F9FH+OFFSET
DIRBUF  EQU     5E80H+OFFSET    ;128 BYTES FOR DISK DIRECTORY
 ;DISK    EQU     500FH+OFFSET
 ;INIT    EQU     5006H+OFFSET
 ;CRTIN   EQU     5009H+OFFSET
 ;CRTOUT  EQU     500CH+OFFSET
 ;CONSTK  EQU     5002H+OFFSET
KBBUFF  EQU     505BH+OFFSET    ;CCP'S KEYBOARD BUFFER
BUFCNT  EQU     505DH+OFFSET    ;TYPE-AHEAD BUFFER COUNT
PVBIOS: EQU     5000H+OFFSET    ;START OF PRIVATE BIOS MODULE
CONFIG  EQU     5B00H+OFFSET    ;Configuration table read from disk
PRTA    EQU     CONFIG+5        ;Port A current value (initial value on disk)
SYNC    EQU     CONFIG+9        ;Sync byte
TIME    EQU     0042H           ;TIME ( IN ASCII )
DATE    EQU     004BH           ;DATE ( BCD )
;
;TABLE OF EQUATES--I/O DEVICES
;
AUXDAT  EQU     40H             ;AUX PORT DATA
AUXST   EQU     41H             ;AUX PORT STATUS
INTRST  EQU     48H             ;RESET INTERRUPT LATCH
KBCHAR  EQU     50H             ;KEYBOARD CHARACTER
MNDAT   EQU     58H             ;MAIN PORT DATA
MNSTAT  EQU     59H             ;MAIN PORT STATUS
BDGEN   EQU     60H             ;BAUD RATE GENERATOR
PPIA    EQU     68H             ;8255 PORT A
PPIB    EQU     69H             ;8255 PORT B
PPIC    EQU     6AH             ;8255 PORT C
PPICW   EQU     6BH             ;8255 CONTROL PORT
TOPSEL  EQU     02H             ;CRTC TOP OF PAGE REGISTER
ROWSTR  EQU     01H             ;CRTC ROW START REGISTER
CURSOR  EQU     03H             ;CRTC CURSOR REGISTER
BELTIM  EQU     15              ;BELL TIME LOOP
KEYDLY  EQU     40              ;KEY DELAY BEFRE REPEAT
RPTTIM  EQU      1              ;KEY REPEAT TIME LOOP
BRKTIM  EQU      15             ;250 MILLISEC BREAK TIME FOR COMM PORT
LPF     EQU      24             ;NO. OF ROWS ON CRT
;
        ASEG
        ORG     PVBIOS
;;;
W007:   dw      3745h           ;e400
CONSTK: dw      3545h           ;e402
W008:   dw      4443h           ;e404
INIT:   jmp     INIT1           ;e406
CRTIN:  jmp     CRTIN1          ;e409
CRTOUT: jmp     CRTOU1          ;e40c
DISK:   jmp     DISK1           ;e40f
W009:   dw      0000h           ;e412
W010:   dw      0000h           ;e414
W011:   dw      0000h           ;e416
B009:   db      00h             ;e418
W012:   dw      0000h           ;e419
W001:   dw      3339h           ;e41b
        db      45h       ;e41d 45                 mov b, l
        db      30h       ;e41e 30                 nop
        db      41h       ;e41f 41                 mov b, c
        db      0dh       ;e420 0d                 dcr c
        db      0ah       ;e421 0a                 ldax b
        db      3ah, 31h, 38h ;e422 3a 31 38           lda 3831h
        db      45h       ;e425 45                 mov b, l
        db      37h       ;e426 37                 stc
        db      31h, 35h, 30h ;e427 31 35 30           lxi sp, 3035h
        db      30h       ;e42a 30                 nop
        db      30h       ;e42b 30                 nop
        db      44h       ;e42c 44                 mov b, h
        db      44h       ;e42d 44                 mov b, h
        db      33h       ;e42e 33                 inx sp
        db      36h, 42h    ;e42f 36 42              mvi m, 42h
        db      33h       ;e431 33                 inx sp
        db      45h       ;e432 45                 mov b, l
        db      30h       ;e433 30                 nop
W002:   dw      3346h           ;e434 46 ;e435 33
        db      32h, 34h, 44h ;e436 32 34 44           sta 4434h
        db      45h       ;e439 45                 mov b, l
        db      34h       ;e43a 34                 inr m
        db      43h       ;e43b 43                 mov b, e
        db      39h       ;e43c 39                 dad sp
        db      43h       ;e43d 43                 mov b, e
        db      44h       ;e43e 44                 mov b, h
        db      45h       ;e43f 45                 mov b, l
        db      45h       ;e440 45                 mov b, l
        db      45h       ;e441 45                 mov b, l
        db      36h, 37h    ;e442 36 37              mvi m, 37h
        db      44h       ;e444 44                 mov b, h
        db      45h       ;e445 45                 mov b, l
        db      36h, 30h    ;e446 36 30              mvi m, 30h
        db      37h       ;e448 37                 stc
        db      43h       ;e449 43                 mov b, e
        db      32h, 31h, 45h ;e44a 32 31 45           sta 4531h
        db      45h       ;e44d 45                 mov b, l
        db      37h       ;e44e 37                 stc
        db      00h       ;e44f 00                 nop
B001:   DB      0       ;e450 00
B002:   DB      32h     ;e451 32
B003:   DB      41h     ;e452 41
B004:   DB      31h     ;e453 31
B007:   DB      32h     ;e454 32
B008:   DB      43h     ;e455 43
W006:   DW      3134h   ;e456 3134h
        db      0,0     ;e458 00 00           lxi sp, 0000h
        db      0       ;e45a 00                 nop
        db      0       ;e45b 00                 nop
        db      43h     ;e45c 43                 mov b, e
B005:   DB      0       ;e45d 00
        db      0       ;e45e 00                 nop
W003:   DW      0       ;e45f 00 ;e460 00
W004:   DW      0       ;e461 00 ;e462 00
        db      0       ;e463 00                 nop
        db      0       ;e464 00                 nop
        db      0       ;e465 00                 nop
        db      0       ;e466 00                 nop
INIT1:  di
        lda     PRTA            ; Initialize 50Hz/60Hz
        out     PPIA
        mvi     a, 0c3h
        sta     0038h           ; Set up interrupt vector
        lxi     h, INTRP
        shld    0039h
        mvi     a, 0eh          ; PPIC7 = 0
        out     PPICW
        call    L001
        call    L073
        lxi     h, W001
        lxi     d, W002
        mvi     b, 18h          ; 24 bytes
        xra     a
L002:   mov     m, a            ; Clear byte in W001
        stax    d               ; Clear byte in W002
        inx     h               ; increment pointers
        inx     d
        dcr     b
        JRNZ    L002
        ;dw      0F920h          ; JR    NZ, L002
;
        sta     B001
        sta     B003
        sta     B005
        lxi     h, 0F300h       ; What buffer is this?
        shld    W003
        shld    W004
                                ; N.B D = 0 - so start of screen
        lxi     h, 0000h        ; Start of CPU-2 RAM block
        mvi     b, 50h          ; 80 characters - screen line length
        call    L003
        call    L004
        out     48h
        IM1
        ;dw      56EDh            ; IM 1
        ;IM      1
        ei
        ret
;;; INIT1
L001:   lxi     h, CONFIG
        mov     a, m
        out     BDGEN
        mvi     a, 42h          ; Force reset (and ~DTR low)
        out     AUXST           ; Might be considered a mode byte
        out     AUXST           ; Second one forces the reset
        out     MNSTAT
        out     MNSTAT
        BIT     1,A
        ;dw      4fcbh           ;BIT 1, A ; e4c5
        cz      L005
        inx     h
        mov     a, m
        out     MNSTAT          ; Mode Byte
        inx     h
        mov     a, m
        out     MNSTAT          ; Command byte
        inx     h
        mov     a, m
        out     AUXST
        inx     h
        mov     a, m
        out     AUXST
        in      AUXDAT
        in      AUXDAT
        in      MNDAT
        in      MNDAT
        ret
;
L005:   BIT     7,A
        ;dw      7FCBh   ;BIT 7,A ; Set up sync byte
        lda     SYNC
        JRZ     L006
        ;dw      0228h   ;JR Z, L006
        out     MNSTAT
L006:   out     MNSTAT
        ret
;
INTRP:  SSPD    W006
        ;dw      73EDh, W006     ; e4ef LD ($E456), SP
        lxi     sp, 0F3DFh
        push    h
        push    d
        push    b
        push    psw
L008:   in      PPIB
        ani     04h
        JRZ     L009
        ;dw      1528h           ;JR Z, L009
        call    L004
        lxi     h, B008
        mvi     m, 00h
LX00:   in      INTRST
        pop     psw
        pop     b
        pop     d
        pop     h
        LSPD    W006
        ;dw      7BEDh, W006     ;LD SP,($E456)
        ei
        RETI
        ;dw      04DEDh          ;RETI
;
L009:   call    L025            ;e515
        lxi     h, B008
        inr     m
        JR      LX00
        ;DW      0EA18h           ;JR LX00
;;;INIT1
L004:   call    L012            ;e51e
        lxi     h, W002
        lxi     d, W001
        lxi     b, 0018h
        LDIR
        ;dw      0B0EDh           ;LDIR
        lxi     h, W001
        shld    0e419h
        call    L025
        call    L027
        lda     0e44dh
        dcr     a
        sta     0e44dh
        JRNZ    L010
        ;dw      0420h           ;JR NZ, L010
        mvi     a, 0Ch
        out     PPICW
L010:   lda     0e45ch
        ora     a
        JRZ     L011
        ;dw      0D28h           ;JR Z, L011
        dcr     a
        sta     0e45ch
        JRNZ    L011
        ;dw      0720h           ;JR NZ, L011
        lda     0ef02h
        ani     0f7h
        out     MNSTAT
L011:   call    L013
        ret
;
L012:   lhld    0e465h           ;e55c
        shld    0e463h
        lhld    0e416h
        shld    0e414h
        xchg
        lhld    0e412h
        mov     a, h
        ani     0fh             ; Limit to 12-bit address
        mov     h, a
        mov     a, d
        ani     0fh
        mov     d, a
        mvi     a, 01h          ; PPIC0 = 1
        out     PPICW
        mvi     a, 03h          ; CRSOR
        mov     m, a
        mvi     a, 01h          ; TOPSEL
        xchg
        mov     m, a
        mvi     a, 02h          ; What's this? attributes? SB-II guess...
        mov     m, a
        mvi     a, 00h          ; PPIC0 = 0
        out     PPICW
        ret
;
L013:   in      PPIB           ;e587
        mov     c, a
        ani     02h             ; Any key down
        JRZ     L018
        ;dw      4A28h           ;JR Z, L018
        mov     a, c
        ani     01h             ; New keyboard character
        JRZ     L016
        ;dw      3628h           ;JR Z, L016
        call    L021
        mvi     a, 28h
L020:   sta     0e44eh
        lda     0ef0ah
        ora     a
        JRZ     L014
        ;dw      0928h           ;JR Z, L014
        mvi     a, 0dh
        out     PPICW
        mvi     a, 01h
        sta     0e44dh
L014:   in      KBCHAR
        mov     b, a
        cpi     0f1h
        JRZ     L019
        ;dw      2D28h           ;JR Z, L019
        mov     a, c
        ani     10h
        JRNZ    L015
        ;dw      0F20h           ;JR NZ, L015
        mov     a, b
        sui     61h
        jm      L015
        sui     1Ah
        jp      L015
        mov     a, b
        ani     5fh
        mov     b, a
L015:   call    L022            ;e5c5
        ret
;
L016:   lda     0e44eh           ;e5c9
        ora     a
        JRNZ    L017
        ;dw      0420h           ;JR NZ, L017
        mvi     a, 01h
        JR      L020
        ;dw      0c518h          ;JR L020
;       
L017:   dcr     a               ;e5d3
        sta     0e44eh
        ret
;
L018:   mvi     a, 0f0h          ;e5d8
        sta     0e44eh
        ret
;
L019:   call    L021            ;e5de
        mvi     a, 28h
        sta     0e44eh
        xra     a
        sta     0e45bh
        sta     B005
        lxi     h, 0f300h
        shld    W003
        shld    W004
        ret
;
L021:   mvi     a, 0eh          ;e5f7
        out     PPICW
        inr     a
        out     PPICW
        ret
;
L022:   lda     B005            ;e5ff
        cpi     80h
        JRZ     L024
        ;dw      1B28h           ;JR Z, L024
        inr     a
        sta     B005
        lhld    W003
        lxi     d, 0f380h
        mov     a, l
        cmp     e
        JRNZ    L023
        ;dw      0720h           ;JR NZ, L023
        mov     a, h
        cmp     d
        JRNZ    L023
        ;dw      0320h           ;JR NZ, L023
        lxi     h, 0f300h
L023:   mov     m, b            ;e61b
        inx     h
        shld    W003
        ret
;
L024:   jmp     0e858h           ;e621
;;; L001[INIT1]
L025:   lhld    0e419h           ;e624
        mov     a, m
        inx     h
        shld    0e419h
        ora     a
        JRZ     L026
        ;dw      0528h           ;JR Z, L026
        mvi     a, 02h
        out     PPICW
        ret
;
L026:   mvi     a, 03h          ;e634
        out     PPICW
        ret
;
L027:   lda     0ef08h           ;e639
        ora     a
        rz
        lhld    0e463h
        lxi     d, 0009h
        dad     d
        mvi     c, 32h          ; What port is this? RTC?
        mvi     e, 02h
        mvi     b, 06h
L030:   mov     a, h
        ori     0f8h
        mov     h, a
        mvi     d, 0ah
L028:   INP     A
        ;dw      78edh           ;IN A, (C)
        ani     0fh
        cpi     0fh
        JRNZ    L029
        ;dw      0920h           ;JR NZ, L029
        dcr     d
        jnz     L028
        xra     a
        sta     0ef08h
        ret
;
L029:   ori     30h     ;e662
        dcx     h
        mov     m, a
        dcr     e
        JRNZ    L030a
        ;dw      0520h           ;JR NZ, L030a
        dcx     h
        mvi     m, 3ah
        mvi     e, 02h
L030a:  inr     c                ;e66e
        DJNZ    L030
        ;dw      0dA10h          ;DJNZ L030
        mvi     m, 20h
        ret
;
CRTIN1: call    L038            ;e674
        mov     b, a
        BIT     7,A
        ;dw      7FCBh           ;BIT 7, A
        cnz     0e6dch
        cpi     00h
        JRZ     L031
        ;dw      1628h           ;JR Z, L031
        cpi     81h
        JRZ     L032
        ;dw      1c28h           ;JR Z, L032
        cpi     82h
        JRZ     L033
        ;dw      2028h           ;JR Z, L033
        cpi     83h
        JRZ     L034
        ;dw      1828h           ;JR Z, L034
        cpi     85h
        JRZ     L035
        ;dw      1c28h           ;JR Z, L035
        cpi     80h
        JRZ     L036
        ;dw      1c28h           ;JR Z, L036
        JR      L037
        ;dw      2618h           ;JR L037
;
L031:   lxi     h, 0e45eh        ;e697
        mov     a, m
        inr     a
        ani     01h
        mov     m, a
        JR      L037
        ;dw      1C18h           ;JR L037
L032:   mvi     b, 08h  ;e6a1
        JR      L037
        ;dw      1818h           ;JR L037
L034:   mvi     b, 0bh  ;e6a5
        JR      L037
        ;dw      1418H           ;JR L037
L033:   mvi     b, 06h  ;e6a9
        JR      L037
        ;dw      1018h           ;JR L037
L035:   mvi     b, 0ah  ;e6ad
        JR      L037
        ;dw      0c18h           ;JR L037
L036:   mvi     a, 0fh  ;e6b1
        sta     0e45ch
        lda     0ef02h
        ori     08h
        out     MNSTAT
L037:   mov     a, b    ;e6bd
        ret
;;; CRTIN1
L038:   lxi     h, B005 ;e6bf
        di
        dcr     m
        ei
        lhld    W004
        lxi     d, 0f380h
        mov     a, l
        cmp     e
        JRNZ    L039
        ;dw      0720h           ;JR NZ, L039
        mov     a, h
        cmp     d
        JRNZ    L039
        ;dw      0320h           ;JR NZ, L039
        lxi     h, 0f300h
L039:   mov     a, m
        inx     h
        shld    W004
        ret
;
        push    b
        lxi     h, 0e703h
        lxi     b, 0012h
        CCDR                    ;aka CPDR
        ;dw      0B9EDh          ;CPDR
        JRNZ    L040
        ;dw      0920h           ;JR NZ, L040
        lxi     h, 0ef0eh
        dad     b               ;??? Is it b (lost its argument)
        mov     a, m
        pop     b
        mov     b, a
        JR      L041
        ;dw      0118h           ;JR L041
L040:   pop     b       ;e6f0
L041:   ret
        db      081h, 082h, 083h, 085h
        db      08Dh, 0ACh, 0ADh, 0AEh
        db      0B0h, 0B1h, 0B2h, 0B3h
        db      0B4h, 0B5h, 0B6h, 0B7h
        db      0B8h, 0B9h
;e6f2 81                 add c
;e6f3 82                 add d
;e6f4 83                 add e
;e6f5 85                 add l
;e6f6 8d                 adc l
;e6f7 ac                 xra h
;e6f8 ad                 xra l
;e6f9 ae                 xra m
;e6fa b0                 ora b
;e6fb b1                 ora c
;e6fc b2                 ora d
;e6fd b3                 ora e
;e6fe b4                 ora h
;e6ff b5                 ora l
;e700 b6                 ora m
;e701 b7                 ora a
;e702 b8                 cmp b
;e703 b9                 cmp c
CRTOU1: mov     b, c            ;1f84+offset
        mov     a, c
        cpi     1bh
        jz      L074
        lda     B001
        ora     a
        jnz     L075
        lda     B003
        ora     a
        JRNZ    LX02
        ;dw      0620h           ;JR NZ, L042
        mov a, b
L042:   sui     20h             ;e719
        jm      L055
LX02:   mov     a, b
        call    L043
        ret
;
L043:   ani     7fh             ;e723
        sta     0e418h
        call    L045
        mov     a, m
        ora     a
        cz      L052
        lhld    0e412h
        mov     a, h
        ori     0f8h
        mov     h, a
        lda     0e44fh
        ora     a
        lda     0e418h
        JRZ     L044
        ;dw      0228h           ;JR Z, L044
        ori     80h
L044:   mov     m, a    ;e742
        di
        lda     PRTA
        ani     0dfh
        out     PPIA
        EXAF
        ;db      08h             ;EX       AF, AF'
        mov     a, h
        ani     4fh
        mov     h, a
        lda     0e45ah
        mov     m, a
        EXAF
        ;db      08h             ;EX       AF, AF'
        ori     20h
        out     PPIA
        ei
        call    L063
        ret
;;; CRTOU1
L045:   lxi     h, W002         ;e75e
        mvi     d, 00h
        lda     0e401h
        mov     e, a
        dad     d
        ret
;
L046:   lda     0e45eh               ;e769
        ora     a
        rnz
        lda     0ef08h
        ora     a
        JRZ     L048
        ;dw      0828h           ;JR Z, L048
L047:   lda     0e455h   ;e774
        sui     15h
        jp      0e774h
L048:   di              ;e77c
        lhld    0e416h
        lxi     d, 0050h
        dad     d
        shld    0e416h
        lhld    0e465h
        dad     d
        shld    0e465h
        lxi     h, 0e435h
        lxi     d, W002
        lxi     b, 0017h
        LDIR
        ;dw      0B0EDh          ;LDIR
        xra     a
        stax    d
        ei
        lxi     h, W002
        mov     a, m
        ora     a
        rnz
        mvi     b, 50h          ; Line length
        lhld    0e416h           ; e416 must store address in screen CPU2 RAM
        call    L003            ; clear it (and in CPU2 RAM)
        lxi     h, W002
        mvi     m, 0ffh
        ret
;
L049:   lda     0e401h           ;e7b0
        lxi     h, 0000h
        lxi     d, 0050h
        mvi     b, 08h          ; 8 characters at the start of screen RAM?
L051:   rrc                     ;e7bb
        JRNC    L050
        ;dw      0130h           ;JR NC, L050
        dad     d
L050:   SLAR    E
;L050:   dw      23CBh           ;SLA E  e7bf
        RALR    D               ;aka RL
        ;dw      12CBh           ;RL D
        dcr     b
        JRNZ    L051
        ;dw      0F520h          ;JR NZ, L051
        LDED    W011
        ;dw      05BEDh, 0E416h  ;LD DE, ($E416)
        dad     d
        ret
;
L052:   call    L049            ;e7cc
        mvi     b, 50h
        call    L003
        call    L045
        mvi     m, 0ffh
        ret
;;; INIT1
;;; Clear B bytes of video RAM to ASCII space
;;; D is MS byte of address in video RAM
;;; HL points at RAM in CPU2
L003:   mov     c, b            ;e7da Save B
        mvi     d, 0f8h
        push    h
L053:   mov     a, d
        ora     h               ; HL = 11111xxx_xxxxxxxx i.e. in video RAM
        mov     h, a
        mvi     m, 20h          ; Space
        inx     h
        DJNZ    L053
        ;dw      0F810h          ;DJNZ L053
        pop     h
        di
        lda     PRTA
        ani     0dfh             ; PRTA = xx0xxxxx - clear bit 6
        sta     PRTA            ; Map CPU-2 RAM to 4800h ?
        out     PPIA
        ei
        mov     b, c            ; Recover B
L054:   mov     a, h
        ani     4fh             ; H = 01001xxx_xxxxxxxx
        ori     48h
        mov     h, a
        mvi     m, 00h          ; Clear to zero
        inx     h
        DJNZ    L054
        ;dw      0F510h          ;DJNZ L054
        di
        lda     PRTA
        ori     20h             ; PRTA = xx1xxxxx - set bit 6
        sta     PRTA            ; Map CPU-2 RAM to 4800h DRAM back
        out     PPIA
        ei
        ret
;
L055:   mov     a, b    ;e80c
        cpi     01h
        JRZ     L056
        ;dw      3128h           ;JR Z, L056
        cpi     02h
        JRZ     L057
        ;dw      3a28h           ;JR Z, L057
        cpi     07h
        JRZ     L058
        ;dw      3f28h           ;JR Z, L058
        cpi     09h
        JRZ     L059
        ;dw      4528h           ;JR Z, L059
        cpi     0dh
        JRZ     L060
        ;dw      4a28h           ;JR Z, L060
        cpi     14h
        JRZ     L061
        ;dw      5228h           ;JR Z, L061
        cpi     0bh
        JRZ     L062
        ;dw      6028h           ;JR Z, L062
        cpi     06h
        JRZ     L063
        ;dw      7028h           ;JR Z, L063
        cpi     0ah
        jz      L064
        cpi     0ch
        jz      L065
        cpi     15h
        jz      L066
        cpi     08h
        jz      L066
        ret
;
L056:   lxi     h, 0000h
        shld    W007
        lhld    0e416h
        shld    0e412h
        ret
L057:   lxi     h, 0ef0ah
        mov     a, m
        inr     a
        ani     01h
        mov     m, a
        ret
L058:   mvi     a, 0dh
        out     PPICW
        mvi     a, 0fh
        sta     0e44dh
        ret
L059:   call    L063
        mov     a, l
        ani     07h
        JRNZ    L059
        ;dw      0F820h          ;JR NZ, L059
        ret
L060:   call    L049
        shld    0e412h
        mvi     a, 00h
        sta     W007
        ret
L061:   lxi     h, 0ef08h
        mov     a, m
        inr     a
        ani     01h
        mov     m, a
        rnz
        lhld    0e465h
        mvi     b, 0bh
        call    L003
        ret
L062:   lda     0e401h
        ora     a
        rz
        dcr     a
        sta     0e401h
        lhld    0e412h
        lxi     d, 0ffb0h
        dad     d
        shld    0e412h
        ret
;;; CRTOUT
L063:   lhld    0e412h           ;e89d
        inx     h
        shld    0e412h
        lhld    W007
        inr     l
        mov     a, l
        cpi     50h
        JRNZ    L067
        ;dw      0f20h           ;JR NZ, L067
        mvi     l, 00h
        mov     a, h
        cpi     17h
        JRNZ    L068
        ;dw      0720h           ;JR NZ, L068
        push    h
        call    L046
        pop     h
        JR      L067
        ;dw      0118h           ;JR L067
;
L068:   inr     h
L067:   shld    W007
        ret
L064:   lhld    0e412h   ;e8c0 2a
        lxi     d, 0050h
        dad     d
        shld    0e412h
        lda     0e401h
        cpi     17h
        JRNZ    L069
        ;dw      0420h           ;JR NZ, L069
        call    L046
        ret
L069:   inr     a
        sta     0e401h
        ret
L065:   lxi     h, W002 ;e8da
        mvi     b, 18h
        xra     a
L070:   mov     m, a
        inx     h
        DJNZ    L070
        ;dw      0FC10h          ;DJNZ L070
        call    L073
        lxi     h, 0000h
        mvi     b, 50h
        call    L003
        lxi     h, W002
        mvi     m, 0ffh
        ret
L066:   lhld    W007
        mov     a, l
        ora     h
        rz
        mov     a, l
        ora     a
        JRNZ    L071
        ;dw      0520h           ;JR NZ, L071
        mvi     l, 4fh
        dcr     h
        JR      L072
        ;dw      0118h           ;JR L072
;
L071:   dcr     l
L072:   shld    W007
        lhld    0e412h
        dcx     h
        shld    0e412h
        ret
;;; INIT1
L073:   lxi     h,0000h  ;e910
        shld    W007
        shld    0e414h
        shld    0e416h
        shld    0e412h
        lxi     d, 0045h
        dad     d
        shld    0e465h
        ret
;
L074:   mvi     a, 01h  ;e927
        sta     B001
        ret
;
L075:   lda     B001    ;e92d
        cpi     01h
        JRZ     L076
        ;dw      0d28h           ;JR Z, L076
        cpi     02h
        JRZ     L077
        ;dw      2c28h           ;JR Z, L077
        cpi     03h
        JRZ     L078
        ;dw      4428h           ;JR Z, L078
        xra     a
        sta     B001
        ret
;
L076:   mov     a, b    ;e941
        cpi     59h
        JRZ     L079
        ;dw      0d28h           ;JR Z, L079
        cpi     3dh
        JRZ     L079
        ;dw      0928h           ;JR Z, L079
        cpi     7eh
        JRZ     L080
        ;dw      0f28h           ;JR Z, L080
L083:   xra     a               ;e94eh
        sta     B001
        ret
;
L079:   xra     a       ;e953
        sta     0e451h
L081:   mvi     a, 02h
        sta     B001
        ret
L080:   mvi     a, 0ffh  ;e95d
        sta     0e451h
        JR      L081
        ;dw      0f318h          ;JR L081
;       
L077:   lda     0e451h   ;e964
        ora     a
        JRNZ    L082
        ;dw      3e20h           ;JR NZ, L082
        mov     a, b
        sui     20h
        mov     c, a
        jm      L083
        sui     18h
        jp      L083
        mov     a, c
        sta     0e454h
        mvi     a, 03h
        sta     B001
        ret
L078:   mov     a, b    ;e980
        sui     20h
        mov     c, a
        jm      L083
        sui     70h
        jp      L083
        mov     a, c
        sta     0e453h
        xra     a
        sta     B001
        lhld    0e453h
        shld    W007
        call    L049
        xchg
        lhld    W007
        mvi     h, 00h
        dad     d
        shld    0e412h
        ret
L082:   xra     a           ;e9a8
        sta     B001
        mov     a, b
        lxi     h, 0e45ah
        cpi     52h
        JRZ     L084
        ;dw      5228h           ;JR Z, L084
        cpi     72h
        JRZ     L085
        ;dw      5128h           ;JR Z, L085
        cpi     48h
        JRZ     L086
        ;dw      5028h           ;JR Z, L086
        cpi     68h
        JRZ     L087
        ;dw      4f28h           ;JR Z, L087
        cpi     42h
        JRZ     L088
        ;dw      4e28h           ;JR Z, L088
        cpi     62h
        JRZ     L089
        ;dw      4d28h           ;JR Z, L089
        cpi     4eh
        JRZ     L092
        ;dw      5228h           ;JR Z, L092
        cpi     55h
        JRZ     L090
        ;dw      4828h           ;JR Z, L090
        cpi     75h
        JRZ     L091
        ;dw      4728h           ;JR Z, L091
        lxi     h, 0e44fh
        cpi     73h
        JRZ     L093
        ;dw      4828h           ;JR Z, L093
        cpi     53h
        JRZ     L094
        ;dw      4728h           ;JR Z, L094
        lxi     h, PRTA
        cpi     67h
        JRZ     L095
        ;dw      4328h           ;JR Z, L095
        cpi     47h
        JRZ     L096
        ;dw      4528h           ;JR Z, L096
        cpi     41h
        JRZ     L097
        ;dw      4728h           ;JR Z, L097
        cpi     61h
        JRZ     L098
        ;dw      4928h           ;JR Z, L098
        lxi     h, B003
        cpi     45h
        JRZ     L099
        ;dw      4828h           ;JR Z, L099
        cpi     44h
        JRZ     L100
        ;dw      4728h           ;JR Z, L100
        cpi     4bh
        JRZ     L101
        ;dw      4628h           ;JR Z, L101
        cpi     6bh
        JRZ     L102
        ;dw      5528h           ;JR Z, L102
        ret
L084:   SETB    0, M
        ;dw      0C6CBh   ;SET 0, (HL)   ;ea06
        ret
L085:   RES     0, M
        ;dw      086CBh   ;RES 0, (HL)   ;ea09
        ret
L086:   SETB    1, M
        ;dw      0CECBh   ;SET 1, (HL)   ;ea0c
        ret
L087:   RES     1, M
        ;dw      08ECBh   ;RES 1, (HL)   ;ea0f
        ret
L088:   SETB    2, M
        ;dw      0D6CBh   ;SET 2, (HL)   ;ea12
        ret
L089:   RES     2, M
        ;dw      096CBh   ;RES 2, (HL)   ;ea15
        ret
L090:   SETB    3, M
        ;dw      0DECBh   ;SET 3, (HL)   ;ea18
        ret
L091:   RES     3, M
        ;dw      09ECBh   ;RES 3, (HL)   ;ea1b
        ret
L092:   xra     a                       ;ea1e
        sta     0e45ah
        ret
L093:   mvi     m, 00h                  ;ea23
        ret
L094:   mvi     m, 0ffh                  ;ea26
        ret
L095:   SETB    0, M
        ;dw      0C6CBh   ;SET 0, (HL)   ;ea29
        mov     a, m
        out     PPIA
        ret
L096:   RES     0, M
        ;dw      086CBh   ;RES 0, (HL)   ;ea2f
        mov     a, m
        out     68h
        ret
L097:   RES     7, M
        ;dw      0BECBh   ;RES 7, (HL)   ;ea35
        mov     a, m
        out     68h
        ret
L098:   SETB    7, M
        ;dw      0FECBh   ;SET 7, (HL)   ;ea3b
        mov     a, m
        out     68h
        ret
L099:   mvi     m, 0ffh          ;ea41
        ret
L100:   mvi     m, 00h          ;ea44
        ret
;;;
L101:   call    L049            ;ea47
        lda     W007
        lxi     b, 0000h
        mov     c, a
        dad     b
        mvi     a, 50h
        sub     c
        mov     b, a
        call    L003
        ret
;
L102:   call    L101            ;ea5a
        call    L045
        lda     0e401h
        cpi     17h
        rz
        mov     b, a
        mvi     a, 17h
        sub     b
        mov     c, a
        xra     a
LX01:   inx     h
        mov     m, a
        dcr     c
        JRNZ    LX01
        ;dw      0FB20h          ;JR Z, L103
        ret
;
DISK1:  shld    0e458h           ;ea72
        SSPD    W008
        ;dw      73EDh, 0E404h   ;LD ($E404), SP
        lxi     sp, 0f39fh      ;Is it lxi??
        mov     a, b
        cpi     00h
        JRZ     L104
        ;dw      1328h           ;JR Z, L104
        cpi     04h
        JRZ     L104
        ;dw      0F28h           ;JR Z, L104
        cpi     05h
        JRZ     L105
        ;dw      2928h           ;JR Z, L105
        cpi     01h
        JRZ     L103
        ;dw      1528h           ;JR Z, L103
        push    d
        push    b
        call    L111
        pop     b
        pop     d
L104:   call    L110            ;ea94
        call    L108
        call    L113
L106:   LSPD    W008
        ;dw      7BEDh, 0E404h   ;LD SP, ($E404) ;ea9d
        ret
L103:   push    h               ;eaa2
        call    L110
        call    L108
        pop     h
        call    L112
        call    L113
        JR      L106   
        ;dw      0EB18h          ;JR $231D
;
L105:   call    L110            ;eab2
        mvi     b, 80h
L107:   push    h               ;eab7
        pop     h
        dcr     b
        JRNZ    L107
        ;dw      0FB20h           ;JR NZ, L107
        xra     a
        JR      L106
        ;dw      0DE18h          ;JR L106
;
L108:   in      PPIB           ;eabf
        ani     20h
        JRZ     L108
        ;dw      0FA28h          ;JR Z, L108
;
L109:   in      PPIB           ;eac5
        ani     20h
        JRNZ    L109
        ;dw      0FA20h           ;JR NZ, L109
        ret
;
L110:   call    L114            ;eacc
        lxi     h, 8802h
        mov     m, b
        inx     h
        mov     m, c
        inx     h
        mov     a, e
        cma
        mov     m, a
        inx     h
        mov     a, d
        cma
        mov     m, a
        mvi     a, 0ffh
        sta     8807h
        call    L116
        ret
;
L111:   lxi     h, 0f600h        ;eae6
        call    L114
        lxi     d, 8808h
        lxi     b, 0200h
        LDIR
        ;dw      0B0EDh          ;LDIR
        call    L116
        ret
;
L112:   call    L114            ;eaf8
        lxi     d, 0f600h
        lxi     h, 8808h
        lxi     b, 0200h
        LDIR
        ;dw      0B0EDh          ;LDIR
        call    L116
        ret
;
L113:   call    L114            ;eb0a
        lda     8a0bh
        push    psw
        call    L116
        pop     psw
        ret
;
L114:   mvi     a, 0ah          ;eb16
        out     PPICW
L115:   in      PPIB
        ral
        JRC     L115
        ;dw      0FB38h          ;JR C, L115
        mvi     a, 08h
        out     PPICW
L120:   ret
;
L116:   mvi     a, 09h          ;eb24
        out     PPICW
        mvi     a, 0bh
        out     PPICW
        ret
;
L117:   mov l, e                ;eb2d
        ret
;
L118:   pop     h               ;eb2f
        call    L125
        call    L126
        jmp     L120
        call    L123            ;Can this be reached?
;;;
        mvi     b, 80h
L119:   push    h               ;eb3e
        pop     h
        dcr     b
        jnz     L119
        xra     a
        jmp     L120
;
L121:   in      PPIB           ;eb48
        ani     20h
        jz      L121
L122:   in      PPIB           ;eb4f
        ani     20h
        jnz     L122
        ret
;
L123:   call    L127            ;eb57
        lxi     h, 8802h
        mov     m, b
        inx     h
        mov     m, c
        inx     h
        mov     a, e
        cma
        mov     m, a
        inx     h
        mov     a, d
        cma
        mov     m, a
        mvi     a, 0ffh
        sta     8807h
        call    L128
        ret
;;;
L124:   lxi     h, 0f600h        ;eb71
        call    L127
        lxi     d, 8808h
        lxi     b, 0200h
        LDIR
        ;dw      0B0EDh          ;LDIR
        call    L128
        ret
;;;
L125:   call    L127            ;eb83
        lxi     d, 0f600h
        lxi     h, 8808h
        lxi     b, 0200h
        LDIR
        ;dw      0B0EDh          ;LDIR
        call    L128
        ret
;;;
L126:   call    L127            ;eb95
        lda     8a0bh
        push    psw
        call    L128
        pop     psw
        ret
;;;
L127:   mvi     a, 0ah          ;eba1
        out     PPICW
        in      PPIB
        ral
        jc      0eba5h
        mvi     a, 08h
        out     PPICW
        ret
;;;
L128:   mvi     a, 09h          ;ebb0
        out     PPICW
        mvi     a, 0bh
        out     PPICW
        ret
        IF      0
;;;  Is this called - doesn't make much sense...
L129:   adc     c               ;ebb9
        rst     1
;ebbb 11 d6 cf           lxi d, cfd6h ; Data in CCP?
;ebbe 1a                 ldax d
;ebbf fe 20              cpi 20h
;ebc1 c2 09 ca           jnz ca09h
;ebc4 d5                 push d
;ebc5 cd 54 cc           call cc54h
;ebc8 d1                 pop d
;ebc9 21 83 cf           lxi h, cf83h
;ebcc cd 40 cc           call cc40h
;ebcf cd d0 c8           call c8d0h
;ebd2 ca 6b cf           jz cf6bh
;ebd5 21 00 01           lxi h, 0100h
;ebd8 e5                 push h
;ebd9 eb                 xchg
;ebda cd d8 c9           call c9d8h
;ebdd 11 cd cf           lxi d, cfcdh
;ebe0 cd f9 c8           call c8f9h
;ebe3 c2 01 cf           jnz cf01h
;ebe6 e1                 pop h
;ebe7 11 80 00           lxi d, 0080h
;ebea 19                 dad d
;ebeb 11 00 c8           lxi d, c800h
;ebee 7d                 mov a, l
;ebef 93                 sub e
;ebf0 7c                 mov a, h
;ebf1 9a                 sbb d
;ebf2 d2 71 cf           jnc cf71h
;ebf5 c3 e1 ce           jmp cee1h
;ebf8 e1                 pop h
;ebf9 3d                 dcr a
;ebfa c2 71 cf           jnz cf71h
;ebfd cd 66 cc           call cc66h
;ec00 cd 5e ca           call ca5eh
;ec03 21 f0 cf           lxi h, cff0h
;ec06 e5                 push h
;ec07 7e                 mov a, m
;ec08 32 cd cf           sta cfcdh
;ec0b 3e 10              mvi a, 10h
;ec0d cd 60 ca           call ca60h
;ec10 e1                 pop h
;ec11 7e                 mov a, m
;ec12 32 dd cf           sta cfddh
;ec15 af                 xra a
;ec16 32 ed cf           sta cfedh
;ec19 11 5c 00           lxi d, 005ch
;ec1c 21 cd cf           lxi h, cfcdh
;ec1f 06 21              mvi b, 21h
;ec21 cd 42 cc           call cc42h
;ec24 21 08 c8           lxi h, c808h
;ec27 7e                 mov a, m
;ec28 b7                 ora a
;ec29 ca 3e cf           jz cf3eh
;ec2c fe 20              cpi 20h
;ec2e ca 3e cf           jz cf3eh
;ec31 23                 inx h
;ec32 c3 30 cf           jmp cf30h
;ec35 06 00              mvi b, 00h
;ec37 11 81 00           lxi d, 0081h
;ec3a 7e                 mov a, m
;ec3b 12                 stax d
;ec3c b7                 ora a
;ec3d ca 4f cf           jz cf4fh
;ec40 04                 inr b
;ec41 23                 inx h
;ec42 13                 inx d
;ec43 c3 43 cf           jmp cf43h
;ec46 78                 mov a, b
;ec47 32 80 00           sta 0080h
;ec4a cd 98 c8           call c898h
;ec4d cd d5 c9           call c9d5h
;ec50 cd 1a c9           call c91ah
;ec53 cd 00 01           call 0100h
;ec56 31 ab cf           lxi sp, cfabh
;ec59 cd 29 c9           call c929h
;ec5c cd bd c8           call c8bdh
;ec5f c3 82 cb           jmp cb82h
;ec62 cd 66 cc           call cc66h
;ec65 c3 09 ca           jmp ca09h
;ec68 01 7a cf           lxi b, cf7ah
;ec6b cd a7 c8           call c8a7h
;ec6e c3 86 cf           jmp cf86h
;ec71 42                 mov b, d
;ec72 41                 mov b, c
;ec73 44                 mov b, h
;ec74 20                 nop
;ec75 4c                 mov c, h
;ec76 4f                 mov c, a
;ec77 41                 mov b, c
;ec78 44                 mov b, h
;ec79 00                 nop
;ec7a 43                 mov b, e
;ec7b 4f                 mov c, a
;ec7c 4d                 mov c, l
;ec7d cd 66 cc           call cc66h
;ec80 cd 5e ca           call ca5eh
;ec83 3a ce cf           lda cfceh
;ec86 d6 20              sui 20h
;ec88 21 f0 cf           lxi h, cff0h
;ec8b b6                 ora m
;ec8c c2 09 ca           jnz ca09h
;ec8f c3 82 cb           jmp cb82h
;ec92 00                 nop
;ec93 00                 nop
;ec94 00                 nop
;ec95 00                 nop
;ec96 00                 nop
;ec97 00                 nop
;ec98 00                 nop
;ec99 00                 nop
;ec9a 00                 nop
;ec9b 00                 nop
;ec9c 00                 nop
;ec9d 00                 nop
;ec9e 00                 nop
;ec9f 00                 nop
;eca0 00                 nop
;eca1 00                 nop
;eca2 00                 nop
;eca3 00                 nop
;eca4 24                 inr h
;eca5 24                 inr h
;eca6 24                 inr h
;eca7 20                 nop
;eca8 20                 nop
;eca9 20                 nop
;ecaa 20                 nop
;ecab 20                 nop
;ecac 53                 mov d, e
;ecad 55                 mov d, l
;ecae 42                 mov b, d
;ecaf 00                 nop
;ecb0 00                 nop
;ecb1 00                 nop
;ecb2 00                 nop
;ecb3 00                 nop
;ecb4 00                 nop
;ecb5 00                 nop
;ecb6 00                 nop
;ecb7 00                 nop
;ecb8 00                 nop
;ecb9 00                 nop
;ecba 00                 nop
;ecbb 00                 nop
;ecbc 00                 nop
;ecbd 00                 nop
;ecbe 00                 nop
;ecbf 00                 nop
;ecc0 00                 nop
;ecc1 00                 nop
;ecc2 00                 nop
;ecc3 00                 nop
;ecc4 00                 nop
;ecc5 00                 nop
;ecc6 00                 nop
;ecc7 00                 nop
;ecc8 00                 nop
;ecc9 00                 nop
;ecca 00                 nop
;eccb 00                 nop
;eccc 00                 nop
;eccd 00                 nop
;ecce 00                 nop
;eccf 00                 nop
;ecd0 00                 nop
;ecd1 00                 nop
;ecd2 00                 nop
;ecd3 00                 nop
;ecd4 00                 nop
;ecd5 00                 nop
;ecd6 00                 nop
;ecd7 00                 nop
;ecd8 00                 nop
;ecd9 00                 nop
;ecda 00                 nop
;ecdb 00                 nop
;ecdc 00                 nop
;ecdd 00                 nop
;ecde 00                 nop
;ecdf 00                 nop
;ece0 00                 nop
;ece1 00                 nop
;ece2 00                 nop
;ece3 00                 nop
;ece4 00                 nop
;ece5 00                 nop
;ece6 00                 nop
;ece7 00                 nop
;ece8 00                 nop
;ece9 00                 nop
;ecea 00                 nop
;eceb 00                 nop
;ecec 00                 nop
;eced 00                 nop
;ecee 00                 nop
;ecef 00                 nop
;ecf0 00                 nop
;ecf1 00                 nop
;ecf2 00                 nop
;ecf3 00                 nop
;ecf4 00                 nop
;ecf5 00                 nop
;ecf6 00                 nop
;ecf7 00                 nop
;ecf8 16 00              mvi d, 00h
;ecfa 00                 nop
;ecfb 08                 nop
;ecfc f5                 push psw
;ecfd c3 11 d0           jmp d011h
;ed00 99                 sbb c
;ed01 d0                 rnc
;ed02 a5                 ana l
;ed03 d0                 rnc
;ed04 ab                 xra e
;ed05 d0                 rnc
;ed06 b1                 ora c
;ed07 d0                 rnc
;ed08 eb                 xchg
;ed09 22 43 d3           shld  d343h
;ed0c eb                 xchg
;ed0d 7b                 mov a, e
;ed0e 32 d6 dd           sta ddd6h
;ed11 21 00 00           lxi h, 0000h
;ed14 22 45 d3           shld  d345h
;ed17 39                 dad sp
;ed18 22 0f d3           shld  d30fh
;ed1b 31 41 d3           lxi sp, d341h
;ed1e af                 xra a
;ed1f 32 e0 dd           sta dde0h
;ed22 32 de dd           sta dddeh
;ed25 21 74 dd           lxi h, dd74h
;ed28 e5                 push h
;ed29 79                 mov a, c
;ed2a fe 29              cpi 29h
;ed2c d0                 rnc
;ed2d 4b                 mov c, e
;ed2e 21 47 d0           lxi h, d047h
;ed31 5f                 mov e, a
;ed32 16 00              mvi d, 00h
;ed34 19                 dad d
;ed35 19                 dad d
;ed36 5e                 mov e, m
;ed37 23                 inx h
;ed38 56                 mov d, m
;ed39 2a 43 d3           lhld d343h
;ed3c eb                 xchg
;ed3d e9                 pchl
;ed3e 03                 inx b
;ed3f de c8              sbi c8h
;ed41 d2 90 d1           jnc d190h
;ed44 ce d2              aci d2h
;ed46 12                 stax d
;ed47 de 0f              sbi 0fh
;ed49 de d4              sbi d4h
;ed4b d2 ed d2           jnc d2edh
;ed4e f3                 di
;ed4f d2 f8 d2           jnc d2f8h
;ed52 e1                 pop h
;ed53 d1                 pop d
;ed54 fe d2              cpi d2h
;ed56 7e                 mov a, m
;ed57 dc 83 dc           cc dc83h
;ed5a 45                 mov b, l
;ed5b dc 9c dc           cc dc9ch
;ed5e a5                 ana l
;ed5f dc ab dc           cc dcabh
;ed62 c8                 rz
;ed63 dc d7 dc           cc dcd7h
;ed66 e0                 rpo
;ed67 dc e6 dc           cc dce6h
;ed6a ec dc f5           cpe f5dch
;ed6d dc fe dc           cc dcfeh
;ed70 04                 inr b
;ed71 dd 0a dd           call dd0ah
;ed74 11 dd 2c           lxi d, 2cddh
;ed77 d5                 push d
;ed78 17                 ral
;ed79 dd 1d dd           call dd1dh
;ed7c 26 dd              mvi h, ddh
;ed7e 2d                 dcr l
;ed7f dd 41 dd           call dd41h
;ed82 47                 mov b, a
;ed83 dd 4d dd           call dd4dh
;ed86 0e dc              mvi c, dch
;ed88 53                 mov d, e
;ed89 dd 04 d3           call d304h
;ed8c 04                 inr b
;ed8d d3 9b              out 9bh
;ed8f dd 21 ca           call ca21h
;ed92 d0                 rnc
;ed93 cd e5 d0           call d0e5h
;ed96 fe 03              cpi 03h
;ed98 ca 00 00           jz 0000h
;ed9b c9                 ret
;ed9c 21 d5 d0           lxi h, d0d5h
;ed9f c3 b4 d0           jmp d0b4h
;eda2 21 e1 d0           lxi h, d0e1h
;eda5 c3 b4 d0           jmp d0b4h
;eda8 21 dc d0           lxi h, d0dch
;edab cd e5 d0           call d0e5h
;edae c3 00 00           jmp 0000h
;edb1 42                 mov b, d
;edb2 64                 mov h, h
;edb3 6f                 mov l, a
;edb4 73                 mov m, e
;edb5 20                 nop
;edb6 45                 mov b, l
;edb7 72                 mov m, d
;edb8 72                 mov m, d
;edb9 20                 nop
;edba 4f                 mov c, a
;edbb 6e                 mov l, m
;edbc 20                 nop
;edbd 20                 nop
;edbe 3a 20 24           lda 2420h
;edc1 42                 mov b, d
;edc2 61                 mov h, c
;edc3 64                 mov h, h
;edc4 20                 nop
;edc5 53                 mov d, e
;edc6 65                 mov h, l
;edc7 63                 mov h, e
;edc8 74                 mov m, h
;edc9 6f                 mov l, a
;edca 72                 mov m, d
;edcb 24                 inr h
;edcc 53                 mov d, e
;edcd 65                 mov h, l
;edce 6c                 mov l, h
;edcf 65                 mov h, l
;edd0 63                 mov h, e
;edd1 74                 mov m, h
;edd2 24                 inr h
;edd3 46                 mov b, m
;edd4 69                 mov l, c
;edd5 6c                 mov l, h
;edd6 65                 mov h, l
;edd7 20                 nop
;edd8 52                 mov d, d
;edd9 2f                 cma
;edda 4f                 mov c, a
;eddb 24                 inr h
;eddc e5                 push h
;eddd cd c9 d1           call d1c9h
;ede0 3a 42 d3           lda d342h
;ede3 c6 41              adi 41h
;ede5 32 c6 d0           sta d0c6h
;ede8 01 ba d0           lxi b, d0bah
;edeb cd d3 d1           call d1d3h
;edee c1                 pop b
;edef cd d3 d1           call d1d3h
;edf2 21 0e d3           lxi h, d30eh
;edf5 7e                 mov a, m
;edf6 36 00              mvi m, 00h
;edf8 b7                 ora a
;edf9 c0                 rnz
;edfa c3 09 de           jmp de09h
;edfd cd fb d0           call d0fbh
;ee00 cd 14 d1           call d114h
;ee03 d8                 rc
;ee04 f5                 push psw
;ee05 4f                 mov c, a
;ee06 cd 90 d1           call d190h
;ee09 f1                 pop psw
;ee0a c9                 ret
;ee0b fe 0d              cpi 0dh
;ee0d c8                 rz
;ee0e fe 0a              cpi 0ah
;ee10 c8                 rz
;ee11 fe 09              cpi 09h
;ee13 c8                 rz
;ee14 fe 08              cpi 08h
;ee16 c8                 rz
;ee17 fe 20              cpi 20h
;ee19 c9                 ret
;ee1a 3a 0e d3           lda d30eh
;ee1d b7                 ora a
;ee1e c2 45 d1           jnz d145h
;ee21 cd 06 de           call de06h
;ee24 e6 01              ani 01h
;ee26 c8                 rz
;ee27 cd 09 de           call de09h
;ee2a fe 13              cpi 13h
;ee2c c2 42 d1           jnz d142h
;ee2f cd 09 de           call de09h
;ee32 fe 03              cpi 03h
;ee34 ca 00 00           jz 0000h
;ee37 af                 xra a
;ee38 c9                 ret
;ee39 32 0e d3           sta d30eh
;ee3c 3e 01              mvi a, 01h
;ee3e c9                 ret
;ee3f 3a 0a d3           lda d30ah
;ee42 b7                 ora a
;ee43 c2 62 d1           jnz d162h
;ee46 c5                 push b
;ee47 cd 23 d1           call d123h
;ee4a c1                 pop b
;ee4b c5                 push b
;ee4c cd 0c de           call de0ch
;ee4f c1                 pop b
;ee50 c5                 push b
;ee51 3a 0d d3           lda d30dh
;ee54 b7                 ora a
;ee55 c4 0f de           cnz de0fh
;ee58 c1                 pop b
;ee59 79                 mov a, c
;ee5a 21 0c d3           lxi h, d30ch
;ee5d fe 7f              cpi 7fh
;ee5f c8                 rz
;ee60 34                 inr m
;ee61 fe 20              cpi 20h
;ee63 d0                 rnc
;ee64 35                 dcr m
;ee65 7e                 mov a, m
;ee66 b7                 ora a
;ee67 c8                 rz
;ee68 79                 mov a, c
;ee69 fe 08              cpi 08h
;ee6b c2 79 d1           jnz d179h
;ee6e 35                 dcr m
;ee6f c9                 ret
;ee70 fe 0a              cpi 0ah
;ee72 c0                 rnz
;ee73 36 00              mvi m, 00h
;ee75 c9                 ret
;ee76 79                 mov a, c
;ee77 cd 14 d1           call d114h
;ee7a d2 90 d1           jnc d190h
;ee7d f5                 push psw
;ee7e 0e 5e              mvi c, 5eh
;ee80 01 00 00           lxi b, 0000h
;ee83 cd 33 de           call de33h
;ee86 21 80 c9           lxi h, c980h
;ee89 11 02 00           lxi d, 0002h
;ee8c 06 01              mvi b, 01h
;ee8e 0e 00              mvi c, 00h
;ee90 cd cd ee           call eecdh
;ee93 1c                 inr e
;ee94 1c                 inr e
;ee95 7b                 mov a, e
;ee96 fe 0c              cpi 0ch
;ee98 c2 90 ee           jnz ee90h
;ee9b 22 ee ee           shld  eeeeh
;ee9e 21 80 c7           lxi h, c780h
;eea1 1e 01              mvi e, 01h
;eea3 cd cd ee           call eecdh
;eea6 1c                 inr e
;eea7 1c                 inr e
;eea8 7b                 mov a, e
;eea9 fe 0b              cpi 0bh
;eeab c2 a3 ee           jnz eea3h
;eeae 14                 inr d
;eeaf 1e 01              mvi e, 01h
;eeb1 cd cd ee           call eecdh
;eeb4 1c                 inr e
;eeb5 1c                 inr e
;eeb6 7b                 mov a, e
;eeb7 fe 03              cpi 03h
;eeb9 c2 b1 ee           jnz eeb1h
;eebc 1e 02              mvi e, 02h
;eebe 2a ee ee           lhld eeeeh
;eec1 cd cd ee           call eecdh
;eec4 1c                 inr e
;eec5 1c                 inr e
;eec6 7b                 mov a, e
;eec7 fe 04              cpi 04h
;eec9 c2 c1 ee           jnz eec1h
;eecc c9                 ret
;eecd d5                 push d
;eece c5                 push b
;eecf e5                 push h
;eed0 22 f0 ee           shld  eef0h
;eed3 cd 33 de           call de33h
;eed6 cd e1 ee           call eee1h
;eed9 e1                 pop h
;eeda 11 00 04           lxi d, 0400h
;eedd 19                 dad d
;eede c1                 pop b
;eedf d1                 pop d
;eee0 c9                 ret
;eee1 2a f0 ee           lhld eef0h
;eee4 11 00 f6           lxi d, f600h
;eee7 eb                 xchg
;eee8 01 00 02           lxi b, 0200h
;eeeb ed b0 c9           call c9b0h
;eeee 00                 nop
;eeef 00                 nop
;eef0 00                 nop
;eef1 00                 nop
;eef2 c1                 pop b
;eef3 d2 fe 0a           jnc 0afeh
;eef6 ca c1 d2           jz d2c1h
;eef9 fe 08              cpi 08h
;eefb c2 16 d2           jnz d216h
;eefe 78                 mov a, b
;eeff b7                 ora a
;;; This is the config table defined in qdbios...
;;; but it's a bit garbled (and PRTA in the middle of it?...)
W005:   dw      h4eeeh    ;ef00 ee 4e              xri 4eh
;ef02 17                 ral
;ef03 4e                 mov c, m
;ef04 17                 ral
PRTA:   DB      20h     ;ef05
;ef06 00                 nop
;ef07 00                 nop
;ef08 00                 nop
B006: dw        0d3h      ;ef09
;ef0a 01
;ef0b 70                 mov m, b
;ef0c d2 fe 13           jnc 13feh
;ef0f 04                 inr b
;ef10 05                 dcr b
;ef11 18                 nop
;ef12 11 01 06           lxi d, 0601h
;ef15 03                 inx b
;ef16 02                 stax b
;ef17 10                 nop
;ef18 0b                 dcx b
;ef19 12                 stax d
;ef1a 16 0e              mvi d, 0eh
;ef1c 1a                 ldax d
;ef1d 19                 dad d
;ef1e 14                 inr d
;ef1f 17                 ral
;ef20 37                 stc
;ef21 d2 c5 e5           jnc e5c5h
;ef24 cd c9 d1           call d1c9h
;ef27 af                 xra a
;ef28 32 0b d3           sta d30bh
;ef2b c3 f1 d1           jmp d1f1h
;ef2e fe 10              cpi 10h
;ef30 c2 48 d2           jnz d248h
;ef33 e5                 push h
;ef34 21 0d d3           lxi h, d30dh
;ef37 3e 01              mvi a, 01h
;ef39 96                 sub m
;ef3a 77                 mov m, a
;ef3b e1                 pop h
;ef3c c3 ef d1           jmp d1efh
;ef3f fe 18              cpi 18h
;ef41 c2 5f d2           jnz d25fh
;ef44 e1                 pop h
;ef45 3a 0b d3           lda d30bh
;ef48 21 0c d3           lxi h, d30ch
;ef4b be                 cmp m
;ef4c d2 e1 d1           jnc d1e1h
;ef4f 35                 dcr m
;ef50 cd a4 d1           call d1a4h
;ef53 c3 4e d2           jmp d24eh
;ef56 fe 15              cpi 15h
;ef58 c2 6b d2           jnz d26bh
;ef5b cd b1 d1           call d1b1h
;ef5e e1                 pop h
;ef5f c3 e1 d1           jmp d1e1h
;ef62 fe 12              cpi 12h
;ef64 c2 a6 d2           jnz d2a6h
;ef67 c5                 push b
;ef68 cd b1 d1           call d1b1h
;ef6b c1                 pop b
;ef6c e1                 pop h
;ef6d e5                 push h
;ef6e c5                 push b
;ef6f 78                 mov a, b
;ef70 b7                 ora a
;ef71 ca 8a d2           jz d28ah
;ef74 23                 inx h
;ef75 4e                 mov c, m
;ef76 05                 dcr b
;ef77 c5                 push b
;ef78 e5                 push h
;ef79 cd 7f d1           call d17fh
;ef7c e1                 pop h
;ef7d c1                 pop b
        ENDIF
        end
