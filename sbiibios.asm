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
XXXBUF  EQU     5F00H+OFFSET    ;128 BYTES FOR ?
YYYBUF  EQU     5F80H+OFFSET    ;128 BYTES FOR ?
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
CONSTK: dw      3545h           ;Save SP during console routines
DSKSTK: dw      4443h           ;Save SP during disk routines
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
INTSTK: DW      3134h   ;Save SP during interrupts
        db      0,0     ;e458 00 00           lxi sp, 0000h
        db      0       ;e45a 00                 nop
KBDCHR: db      0       ;replaces kbchar in os3bdos
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
;
        sta     B001
        sta     B003
        sta     B005
        lxi     h, XXXBUF       ; What buffer is this?
        shld    W003
        shld    W004
                                ; N.B D = 0 - so start of screen
        lxi     h, 0000h        ; Start of CPU-2 RAM block
        mvi     b, 50h          ; 80 characters - screen line length
        call    L003
        call    L004
        out     48h
        IM1
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
        lda     SYNC
        JRZ     L006
        out     MNSTAT
L006:   out     MNSTAT
        ret
;
INTRP:  SSPD    INTSTK
        lxi     sp, STACK1
        push    h
        push    d
        push    b
        push    psw
L008:   in      PPIB
        ani     04h
        JRZ     L009
        call    L004
        lxi     h, B008
        mvi     m, 00h
LX00:   in      INTRST
        pop     psw
        pop     b
        pop     d
        pop     h
        LSPD    INTSTK
        ei
        RETI
;
L009:   call    L025            ;e515
        lxi     h, B008
        inr     m
        JR      LX00
;;;INIT1
L004:   call    L012            ;e51e
        lxi     h, W002
        lxi     d, W001
        lxi     b, 0018h
        LDIR
        lxi     h, W001
        shld    W012
        call    L025
        call    L027
        lda     0e44dh
        dcr     a
        sta     0e44dh
        JRNZ    L010
        mvi     a, 0Ch
        out     PPICW
L010:   lda     0e45ch
        ora     a
        JRZ     L011
        dcr     a
        sta     0e45ch
        JRNZ    L011
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
        mov     a, c
        ani     01h             ; New keyboard character
        JRZ     L016
        call    L021
        mvi     a, 28h
L020:   sta     0e44eh
        lda     0ef0ah
        ora     a
        JRZ     L014
        mvi     a, 0dh
        out     PPICW
        mvi     a, 01h
        sta     0e44dh
L014:   in      KBCHAR
        mov     b, a
        cpi     0f1h
        JRZ     L019
        mov     a, c
        ani     10h
        JRNZ    L015
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
        mvi     a, 01h
        JR      L020
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
        sta     KBDCHR
        sta     B005
        lxi     h, XXXBUF
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
        inr     a
        sta     B005
        lhld    W003
        lxi     d, YYYBUF
        mov     a, l
        cmp     e
        JRNZ    L023
        mov     a, h
        cmp     d
        JRNZ    L023
        lxi     h, XXXBUF
L023:   mov     m, b            ;e61b
        inx     h
        shld    W003
        ret
;
L024:   jmp     L058           ;e621
;;; L001[INIT1]
L025:   lhld    W012           ;e624
        mov     a, m
        inx     h
        shld    W012
        ora     a
        JRZ     L026
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
        ani     0fh
        cpi     0fh
        JRNZ    L029
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
        dcx     h
        mvi     m, 3ah
        mvi     e, 02h
L030a:  inr     c                ;e66e
        DJNZ    L030
        mvi     m, 20h
        ret
;
CRTIN1: call    L038            ;e674
        mov     b, a
        BIT     7,A
        cnz     0e6dch
        cpi     00h
        JRZ     L031
        cpi     81h
        JRZ     L032
        cpi     82h
        JRZ     L033
        cpi     83h
        JRZ     L034
        cpi     85h
        JRZ     L035

        cpi     80h
        JRZ     L036
        JR      L037
;
L031:   lxi     h, 0e45eh        ;e697
        mov     a, m
        inr     a
        ani     01h
        mov     m, a
        JR      L037
L032:   mvi     b, 08h  ;e6a1
        JR      L037
L034:   mvi     b, 0bh  ;e6a5
        JR      L037
L033:   mvi     b, 06h  ;e6a9
        JR      L037
L035:   mvi     b, 0ah  ;e6ad
        JR      L037
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
        lxi     d, YYYBUF
        mov     a, l
        cmp     e
        JRNZ    L039
        mov     a, h
        cmp     d
        JRNZ    L039
        lxi     h, XXXBUF
L039:   mov     a, m
        inx     h
        shld    W004
        ret
;
        push    b
        lxi     h, 0e703h
        lxi     b, 0012h
        CCDR                    ;aka CPDR
        JRNZ    L040
        lxi     h, 0ef0eh
        dad     b               ;??? Is it b (lost its argument)
        mov     a, m
        pop     b
        mov     b, a
        JR      L041
L040:   pop     b       ;e6f0
L041:   ret
        db      081h, 082h, 083h, 085h
        db      08Dh, 0ACh, 0ADh, 0AEh
        db      0B0h, 0B1h, 0B2h, 0B3h
        db      0B4h, 0B5h, 0B6h, 0B7h
        db      0B8h, 0B9h
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
        dad     d
L050:   SLAR    E
        RALR    D               ;aka RL
        dcr     b
        JRNZ    L051
        LDED    W011
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
        cpi     02h
        JRZ     L057
        cpi     07h
        JRZ     L058
        cpi     09h
        JRZ     L059
        cpi     0dh
        JRZ     L060
        cpi     14h
        JRZ     L061
        cpi     0bh
        JRZ     L062
        cpi     06h
        JRZ     L063
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
        mvi     l, 00h
        mov     a, h
        cpi     17h
        JRNZ    L068
        push    h
        call    L046
        pop     h
        JR      L067
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
        mvi     l, 4fh
        dcr     h
        JR      L072
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
        cpi     02h
        JRZ     L077
        cpi     03h
        JRZ     L078
        xra     a
        sta     B001
        ret
;
L076:   mov     a, b    ;e941
        cpi     59h
        JRZ     L079
        cpi     3dh
        JRZ     L079
        cpi     7eh
        JRZ     L080
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
;       
L077:   lda     0e451h   ;e964
        ora     a
        JRNZ    L082
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
        cpi     72h
        JRZ     L085
        cpi     48h
        JRZ     L086
        cpi     68h
        JRZ     L087
        cpi     42h
        JRZ     L088
        cpi     62h
        JRZ     L089
        cpi     4eh
        JRZ     L092
        cpi     55h
        JRZ     L090
        cpi     75h
        JRZ     L091
        lxi     h, 0e44fh
        cpi     73h
        JRZ     L093
        cpi     53h
        JRZ     L094
        lxi     h, PRTA
        cpi     67h
        JRZ     L095
        cpi     47h
        JRZ     L096
        cpi     41h
        JRZ     L097
        cpi     61h
        JRZ     L098
        lxi     h, B003
        cpi     45h
        JRZ     L099
        cpi     44h
        JRZ     L100
        cpi     4bh
        JRZ     L101
        cpi     6bh
        JRZ     L102
        ret
L084:   SETB    0, M
        ret
L085:   RES     0, M
        ret
L086:   SETB    1, M
        ret
L087:   RES     1, M
        ret
L088:   SETB    2, M
        ret
L089:   RES     2, M
        ret
L090:   SETB    3, M
        ret
L091:   RES     3, M
        ret
L092:   xra     a                       ;ea1e
        sta     0e45ah
        ret
L093:   mvi     m, 00h                  ;ea23
        ret
L094:   mvi     m, 0ffh                  ;ea26
        ret
L095:   SETB    0, M
        mov     a, m
        out     PPIA
        ret
L096:   RES     0, M
        mov     a, m
        out     68h
        ret
L097:   RES     7, M
        mov     a, m
        out     68h
        ret
L098:   SETB    7, M
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
        ret
;
DISK1:  shld    0e458h           ;ea72
        SSPD    DSKSTK
        lxi     sp, STACK3
        mov     a, b
        cpi     00h
        JRZ     L104
        cpi     04h
        JRZ     L104
        cpi     05h
        JRZ     L105
        cpi     01h
        JRZ     L103
        push    d
        push    b
        call    L111
        pop     b
        pop     d
L104:   call    L110            ;ea94
        call    L108
        call    L113
L106:   LSPD    DSKSTK
        ret
L103:   push    h               ;eaa2
        call    L110
        call    L108
        pop     h
        call    L112
        call    L113
        JR      L106   
;
L105:   call    L110            ;eab2
        mvi     b, 80h
L107:   push    h               ;eab7
        pop     h
        dcr     b
        JRNZ    L107
        xra     a
        JR      L106
;
L108:   in      PPIB           ;eabf
        ani     20h
        JRZ     L108
;
L109:   in      PPIB           ;eac5
        ani     20h
        JRNZ    L109
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
        call    L116
        ret
;
L112:   call    L114            ;eaf8
        lxi     d, 0f600h
        lxi     h, 8808h
        lxi     b, 0200h
        LDIR
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
        call    L128
        ret
;;;
L125:   call    L127            ;eb83
        lxi     d, 0f600h
        lxi     h, 8808h
        lxi     b, 0200h
        LDIR
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
L129    in      PPIB
        ral
        jc      L129
        mvi     a, 08h
        out     PPICW
        ret
;;;
L128:   mvi     a, 09h          ;ebb0
        out     PPICW
        mvi     a, 0bh
        out     PPICW
        ret
;;;
        end
