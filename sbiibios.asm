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
KBDBUF  EQU     5F00H+OFFSET    ;128 BYTE KEYBOARD BUFFER
KBDBFE  EQU     5F80H+OFFSET    ;END OF KEYBOARD BUFFER (BOTTOM OF STACK3)
CONFIG  EQU     5B00H+OFFSET    ;Configuration table read from disk
MNCMD   EQU     CONFIG+2        ;MAIN PORT COMMAND BYTE
FREQ    EQU     CONFIG+5        ;4BH=60HZ, 0BH=50H
prta    EQU     FREQ            ; also maintains current PPIA value
TIMENB  EQU     CONFIG+8        ;00 = TIME FUNCTION DISABLED; FF = TIME ENABLED
SYNC    EQU     CONFIG+9        ;Sync byte
KEYCLK  EQU     CONFIG+10       ;Handshake byte
KEYPAD  EQU     CONFIG+14       ;
PVBIOS: EQU     5000H+OFFSET    ;START OF PRIVATE BIOS MODULE
TIME    EQU     0042H           ;TIME ( IN ASCII )
DATE    EQU     004BH           ;DATE ( BCD )
;
FPYPRM  EQU     8802h           ; 4-byte parameter block
FPYCMD  EQU     8807h           ; Command byte (FF = "go")
FPYBUF  EQU     8808h           ; 512-byte sector buffer
FPYSTS  EQU     8a0bh           ; Returned status byte
PHYSEC  EQU     0200h           ; Physical sector size (512 bytes)
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
KEYDLY  EQU     40              ;KEY DELAY BEFORE REPEAT
RPTTIM  EQU      1              ;KEY REPEAT TIME LOOP
BRKTIM  EQU      15             ;250 MILLISEC BREAK TIME FOR COMM PORT
LPF     EQU      24             ;NO. OF ROWS ON CRT
RTCSEC  EQU     32H
;
        ASEG
        ORG     PVBIOS
;;;
W007:   dw      3745h           ;e400
W007H   EQU     W007+1
CONSTK: dw      3545h           ;Save SP during console routines
DSKSTK: dw      4443h           ;Save SP during disk routines
INIT:   jmp     INIT1           ;e406
CRTIN:  jmp     CRTIN1          ;e409
CRTOUT: jmp     CRTOU1          ;e40c
DISK:   jmp     DISK1           ;e40f
vcursr: dw      0000h           ;e412
vtopsc: dw      0000h           ; Copy of vtopsl for this frame
vtopsl: dw      0000h           ; Video top select
B009:   db      00h             ;e418
vblnkp: dw      0000h           ;e419
;;; Copy of vblnk used (in interrupt routine) during video frame
vblnkc: db      39h, 33h, 45h, 30h, 41h, 0dh, 0ah, 3ah
        db      31h, 38h, 45h, 37h, 31h, 35h, 30h, 30h
        db      30h, 44h, 44h, 33h, 36h, 42h, 33h, 45h
        db      30h
;;; Video blanking - 1 byte per row of video
vblnk:  db      46h, 33h, 32h, 34h, 44h, 45h, 34h, 43h
        db      39h, 43h, 44h, 45h, 45h, 45h, 36h, 37h
        db      44h, 45h, 36h, 30h, 37h, 43h, 32h, 31h
        db      45h
belctr: db      45h             ;e44d 45
B011:   db      37h             ;e44e 37
B012:   db      00h             ;e44f 00
B001:   DB      0               ;e450 00
B002:   DB      32h             ;e451 32
B003:   DB      41h             ;e452 41
B004:   DB      31h             ;e453 31
B007:   DB      32h             ;e454 32
vlinum: DB      43h             ;e455 43
INTSTK: DW      3134h           ;Save SP during interrupts
dskptr: dw      0               ;e458 00 00
B013:   db      0               ;e45a 00
KBBUFF: db      0               ;replaces kbchar in os3bdos
brkctr: db      43h             ; Main port break time counter
BUFCNT: db      0               ;e45d 00
B015:   db      0               ;e45e 00
kbwptr: dw      0               ;e45f 00 00
W004:   dw      0               ;e461 00 00
timpsc: dw      0               ; Copy of timpos for current frame
timpos: dw      0               ; Position tor time display on top line
;;;
;;; Initialization
INIT1:  di
        lda     prta            ; Initialize 50Hz/60Hz
        out     PPIA
;;; Set up interrupt vector
        mvi     a, 0c3h
        sta     0038h           ; JMP opcode
        lxi     h, INTRP
        shld    0039h           ; Address of interrupt routine
;;;
        mvi     a, 0eh          ; PPIC[7] = 0
        out     PPICW           ; New keyboard char ack.
;;;
        call    L001
        call    vinipt
;;;
;;; Clear video blanking buffers
        lxi     h, vblnkc
        lxi     d, vblnk
        mvi     b, 18h          ; 24 bytes - 1 per row
        xra     a
L002:   mov     m, a            ; Clear byte in vblnkc
        stax    d               ; Clear byte in vblnk
        inx     h               ; increment pointers
        inx     d
        dcr     b
        JRNZ    L002
;;;
        sta     B001
        sta     B003
        sta     BUFCNT
        lxi     h, KBDBUF
        shld    kbwptr
        shld    W004
                                ; N.B D = 0 - so start of screen
        lxi     h, 0000h        ; Start of CPU-2 RAM block
        mvi     b, 50h          ; 80 characters - screen line length
        call    L003
        call    ivsync
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
        in      PPIB
        ani     04h             ; Vertical sync?
        JRZ     ihsync
;;; Vertical sync
        call    ivsync
        lxi     h, vlinum
        mvi     m, 00h          ; Clear line number
intrpx: in      INTRST
        pop     psw
        pop     b
        pop     d
        pop     h
        LSPD    INTSTK
        ei
        RETI
;
ihsync: call    vsetbl          ; Set blanking for the next row
        lxi     h, vlinum
        inr     m               ; Step line number
        JR      intrpx
;;;
ivsync: call    vidpts          ; Send video pointers to controller
;;;
        lxi     h, vblnk        ; Copy array from vblnk to vblnkc
        lxi     d, vblnkc
        lxi     b, 0018h        ; 24 bytes (but there are 25 allocated?)
        LDIR
;;;
        lxi     h, vblnkc       ; Start of (copy of) blanking array
        shld    vblnkp          ; Initialize pointer for the frame
        call    vsetbl          ; Set blanking for the first row
        call    rtcdpy          ; Display time on screen
;;;
        lda     belctr
        dcr     a
        sta     belctr
        JRNZ    ivsyn1
        mvi     a, 0ch          ; PPIC[6] = 0 (Bell off)
        out     PPICW
ivsyn1: lda     brkctr
        ora     a
        JRZ     ivsyn2
        dcr     a
        sta     brkctr
        JRNZ    ivsyn2
        lda     MNCMD
        ani     0f7h            ; Clear the break bit
        out     MNSTAT
ivsyn2: call    L013
        ret
;
vidpts: lhld    timpos          ; Take copy of time display position
        shld    timpsc
        lhld    vtopsl          ; Take copy of video top select
        shld    vtopsc
        xchg
        lhld    vcursr          ; Cursor position
;;;
        mov     a, h
        ani     0fh             ; Limit to 12-bit address (but why not 11-bit since it's 2K?)
        mov     h, a
        mov     a, d
        ani     0fh
        mov     d, a
;;;
        mvi     a, 01h          ; PPIC[0] = 1 swap addr and data buses
        out     PPICW
        mvi     a, CURSOR
        mov     m, a            ; Set cursor address
        mvi     a, ROWSTR
        xchg
        mov     m, a            ; Set row start (for first row)
        mvi     a, TOPSEL
        mov     m, a            ; which is also the top of scrren
        mvi     a, 00h          ; PPIC[0] = 0 - addr/data bus back to normal
        out     PPICW
        ret
;
L013:   in      PPIB            ; Get port B
        mov     c, a            ; Save
        ani     02h             ; Any key down?
        JRZ     L018
        mov     a, c            ; Recover saved Port B
        ani     01h             ; New keyboard character
        JRZ     L016
        call    L021
        mvi     a, 28h
L020:   sta     B011
        lda     KEYCLK          ; Configured for key-click
        ora     a
        JRZ     knoclk          ; No...
        mvi     a, 0dh          ; PPIC[6] = 1 (Bell on)
        out     PPICW
        mvi     a, 01h          ; Bell duration
        sta     belctr
knoclk: in      KBCHAR          ; Read character
        mov     b, a            ; Save character
        cpi     0f1h            ; ??
        JRZ     L019
        mov     a, c            ; Recover saved Port B
        ani     10h             ; Bit[4] - caps lock
        JRNZ    kstore
        mov     a, b            ; Recover character
        sui     61h             ; 'a'
        jm      kstore          ; < 'a' - leave unchanged
        sui     1Ah             ; 26
        jp      kstore          ; >= 26 - leave unchanged
        mov     a, b            ; Recover character ('a' to 'z')
        ani     5fh             ; Map to capital letter
        mov     b, a            ; Replace character
kstore: call    kbstbf          ; Store in buffer
        ret
;
L016:   lda     B011           ;e5c9
        ora     a
        JRNZ    L017
        mvi     a, 01h
        JR      L020
;
L017:   dcr     a               ;e5d3
        sta     B011
        ret
;
L018:   mvi     a, 0f0h          ;e5d8
        sta     B011
        ret
;
L019:   call    L021            ;e5de
        mvi     a, 28h
        sta     B011
        xra     a
        sta     KBBUFF
        sta     BUFCNT
        lxi     h, KBDBUF
        shld    kbwptr
        shld    W004
        ret
;
L021:   mvi     a, 0eh          ; PPIC[7] = 0  ??? what's this do ???
        out     PPICW
        inr     a               ; PPIC[7] = 1
        out     PPICW
        ret
;
kbstbf: lda     BUFCNT          ; Characters in the buffer
        cpi     80h             ; Is it full?
        JRZ     kbfull          ; Yes, ring bell
        inr     a               ; Step counter
        sta     BUFCNT
        lhld    kbwptr          ; Get buffer write pointer
        lxi     d, KBDBFE       ; One beyond the end of the buffer
        mov     a, l            ; Compare to write pointer
        cmp     e
        JRNZ    kbstb1          ; Pointer don't match
        mov     a, h
        cmp     d
        JRNZ    kbstb1          ; Pointer don't match
        lxi     h, KBDBUF       ; Beyond end of buffer, go to start
kbstb1: mov     m, b            ; Store character in buffer
        inx     h               ; Increment write pointer
        shld    kbwptr          ; and save
        ret
;
kbfull: jmp     rngbel          ; Ring bell - keyboard buffer full
;;;
vsetbl: lhld    vblnkp          ; Point into vblnkc array
        mov     a, m            ; Pick up flag for current line
        inx     h               ; Step pointer
        shld    vblnkp          ; Save for next line
        ora     a               ; Test flag
        JRZ     vblnkr
        mvi     a, 02h          ; PPIC[1] = 0 Display video row
        out     PPICW
        ret
;
vblnkr: mvi     a, 03h          ; PPIC[1] = 1 Blank video row
        out     PPICW
        ret
;
rtcdpy: lda     TIMENB          ; Is time display enabled?
        ora     a
        rz                      ; No - return
        lhld    timpsc          ; First row address?
        lxi     d, 0009h        ; 9 characters in time display
        dad     d
        mvi     c, RTCSEC
        mvi     e, 02h          ; Digits between ':' chars
        mvi     b, 06h          ; Total digits
rtclp:  mov     a, h            ; Force address into video RAM area
        ori     0f8h
        mov     h, a
        mvi     d, 10           ; Read attempt counter
rtcrdl: INP     A               ; Read RTC register
        ani     0fh             ; Drop upper 4 bits
        cpi     0fh             ; Is it ready?
        JRNZ    rtcasc          ; yes
        dcr     d               ; No - decrement try counter
        jnz     rtcrdl
;;; Timeout
        xra     a
        sta     TIMENB          ; Clear time display enable
        ret
;
rtcasc: ori     30h             ; Convert to ASCII digit
        dcx     h               ; Decrement address
        mov     m, a            ; Save character
        dcr     e               ; Decrement characters to ':' counter
        JRNZ    rtcnxt
        dcx     h               ; Decremnt address
        mvi     m, 3ah          ; ASCII ':' character
        mvi     e, 02h          ; Reset counter
rtcnxt: inr     c               ; Increment port address
        DJNZ    rtclp
        mvi     m, 20h          ; Insert space before time
        ret
;
CRTIN1: call    L038            ;e674
        mov     b, a
        BIT     7,A
        cnz     mapkpd
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
        JRZ     break
        JR      L037
;
L031:   lxi     h, B015        ;e697
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
;;;
break:  mvi     a, 0fh          ; Set time to 15 video frames
        sta     brkctr          ; (~0.25 seconds)
        lda     MNCMD
        ori     08h             ; Set break bit
        out     MNSTAT
L037:   mov     a, b    ;e6bd
        ret
;;; CRTIN1
L038:   lxi     h, BUFCNT ;e6bf
        di
        dcr     m
        ei
        lhld    W004
        lxi     d, KBDBFE
        mov     a, l
        cmp     e
        JRNZ    L039
        mov     a, h
        cmp     d
        JRNZ    L039
        lxi     h, KBDBUF
L039:   mov     a, m
        inx     h
        shld    W004
        ret
;
mapkpd: push    b               ; Save character
        lxi     h, kpdcds       ; Table of key codes
        lxi     b, 18           ; 18 keys on the keypad
        CCDR                    ; aka CPDR
        JRNZ    notkpd          ; None match
        lxi     h, KEYPAD       ; Point at table in CONFIG
        dad     b               ; Offset into table
        mov     a, m            ; Pick up mapped character
        pop     b               ; Adjust stack
        mov     b, a            ; Return mapped character
        JR      mapkpx
notkpd: pop     b               ; Recover unchanged code
mapkpx: ret
;;; Table of keypad key-codes
        db      081h, 082h, 083h, 085h
        db      08Dh, 0ACh, 0ADh, 0AEh
        db      0B0h, 0B1h, 0B2h, 0B3h
        db      0B4h, 0B5h, 0B6h, 0B7h
        db      0B8h
kpdcds: db      0B9h
;;;
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
        sta     B009
        call    L045
        mov     a, m
        ora     a
        cz      L052
        lhld    vcursr
        mov     a, h
        ori     0f8h
        mov     h, a
        lda     B012
        ora     a
        lda     B009
        JRZ     L044
        ori     80h
L044:   mov     m, a    ;e742
        di
        lda     prta
        ani     0dfh
        out     PPIA
        EXAF
        mov     a, h
        ani     4fh
        mov     h, a
        lda     B013
        mov     m, a
        EXAF
        ori     20h
        out     PPIA
        ei
        call    L063
        ret
;;; CRTOU1
L045:   lxi     h, vblnk         ;e75e
        mvi     d, 00h
        lda     W007H
        mov     e, a
        dad     d
        ret
;
L046:   lda     B015               ;e769
        ora     a
        rnz
        lda     TIMENB
        ora     a
        JRZ     L048
L047:   lda     vlinum   ;e774
        sui     15h
        jp      L047
L048:   di              ;e77c
        lhld    vtopsl
        lxi     d, 0050h        ; 80 - line length
        dad     d
        shld    vtopsl
        lhld    timpos
        dad     d
        shld    timpos
        lxi     h, vblnk+1
        lxi     d, vblnk
        lxi     b, 0017h
        LDIR
        xra     a
        stax    d
        ei
        lxi     h, vblnk
        mov     a, m
        ora     a
        rnz
        mvi     b, 50h          ; Line length
        lhld    vtopsl           ; e416 must store address in screen CPU2 RAM
        call    L003            ; clear it (and in CPU2 RAM)
        lxi     h, vblnk
        mvi     m, 0ffh
        ret
;
L049:   lda     W007H           ;e7b0
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
        LDED    vtopsl
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
        lda     prta
        ani     0dfh             ; prta = xx0xxxxx - clear bit 6
        sta     prta            ; Map CPU-2 RAM to 4800h ?
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
        lda     prta
        ori     20h             ; prta = xx1xxxxx - set bit 6
        sta     prta            ; Map CPU-2 RAM to 4800h DRAM back
        out     PPIA
        ei
        ret
;
L055:   mov     a, b    ;e80c
        cpi     01h             ; SOH - Home cursor
        JRZ     L056
        cpi     02h             ; STX - Toggle Key-clock
        JRZ     tglclk
        cpi     07h             ; BEL - Ring Bell
        JRZ     rngbel
        cpi     09h             ; HT  - Tab
        JRZ     L059
        cpi     0dh             ; CR
        JRZ     L060
        cpi     14h             ; DC4
        JRZ     L061
        cpi     0bh             ; VT  - Cursor up
        JRZ     L062
        cpi     06h             ; ACK - Cursor forwards
        JRZ     L063
        cpi     0ah             ; LF  - Cursor down
        jz      L064
        cpi     0ch             ; FF  - Clear screen
        jz      L065
        cpi     15h             ; NAK -
        jz      L066
        cpi     08h             ; BS
        jz      L066
        ret
;
L056:   lxi     h, 0000h
        shld    W007
        lhld    vtopsl
        shld    vcursr
        ret
;;;
tglclk: lxi     h, KEYCLK       ; Toggle key click
        mov     a, m
        inr     a
        ani     01h
        mov     m, a
        ret
;;;
rngbel: mvi     a, 0dh          ; PPIC[6] = 1 (Bell on)
        out     PPICW
        mvi     a, 0fh          ; Bell duration
        sta     belctr
        ret
;;;
L059:   call    L063
        mov     a, l
        ani     07h
        JRNZ    L059
        ret
L060:   call    L049
        shld    vcursr
        mvi     a, 00h
        sta     W007
        ret
L061:   lxi     h, TIMENB
        mov     a, m
        inr     a
        ani     01h
        mov     m, a
        rnz
        lhld    timpos
        mvi     b, 0bh
        call    L003
        ret
L062:   lda     W007H
        ora     a
        rz
        dcr     a
        sta     W007H
        lhld    vcursr
        lxi     d, 0ffb0h
        dad     d
        shld    vcursr
        ret
;;; CRTOUT
L063:   lhld    vcursr           ;e89d
        inx     h
        shld    vcursr
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
L064:   lhld    vcursr   ;e8c0 2a
        lxi     d, 0050h
        dad     d
        shld    vcursr
        lda     w007H
        cpi     17h
        JRNZ    L069
        call    L046
        ret
L069:   inr     a
        sta     W007H
        ret
L065:   lxi     h, vblnk ;e8da
        mvi     b, 18h
        xra     a
L070:   mov     m, a
        inx     h
        DJNZ    L070
        call    vinipt
        lxi     h, 0000h
        mvi     b, 50h
        call    L003
        lxi     h, vblnk
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
        lhld    vcursr
        dcx     h
        shld    vcursr
        ret
;;;
;;; Initialize video pointer
vinipt: lxi     h,0000h
        shld    W007
        shld    vtopsc
        shld    vtopsl
        shld    vcursr
        lxi     d, 0045h        ; 69 + 9 = 78 (_00:00:00__)
        dad     d
        shld    timpos
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
        sta     B002
L081:   mvi     a, 02h
        sta     B001
        ret
L080:   mvi     a, 0ffh  ;e95d
        sta     B002
        JR      L081
;
L077:   lda     B002   ;e964
        ora     a
        JRNZ    L082
        mov     a, b
        sui     20h
        mov     c, a
        jm      L083
        sui     18h
        jp      L083
        mov     a, c
        sta     B007
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
        sta     B004
        xra     a
        sta     B001
        lhld    B004
        shld    W007
        call    L049
        xchg
        lhld    W007
        mvi     h, 00h
        dad     d
        shld    vcursr
        ret
L082:   xra     a           ;e9a8
        sta     B001
        mov     a, b
        lxi     h, B013
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
        lxi     h, B012
        cpi     73h
        JRZ     L093
        cpi     53h
        JRZ     L094
        lxi     h, prta
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
        sta     B013
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
        lda     W007H
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
;;;
;;; Enter with something in HL - pointer to data?
;;; Something in b - seems to be
;;;  0,4 - Restore
;;;  1 - Read
;;;  2 - Write with    RAW verification
;;;  5 - format
;;;  6 - Write without RAW verification
;;;
;;; c = disk   number
;;; d = track  number
;;; e = sector number
;;;
DISK1:  shld    dskptr          ; Save data pointer (but this never used)
        SSPD    DSKSTK
        lxi     sp, STACK3
        mov     a, b
        cpi     00h             ; Restore
        JRZ     drestr
        cpi     04h             ; Restore
        JRZ     drestr
        cpi     05h             ; Format
        JRZ     dfrmt
        cpi     01h             ; Read
        JRZ     dread
;;; Here for write
        push    d
        push    b
        call    hst2fp          ; Copy data to CPU2
        pop     b
        pop     d
drestr: call    fparam          ; Send parameters
        call    fpwres          ; Wait for result
        call    fpstat          ; Get status to return
dexit:  LSPD    DSKSTK
        ret
;;;
dread:  push    h               ; Save data pointer (why is dskptr not used?)
        call    fparam          ; Send parameters
        call    fpwres          ; Wait for result
        pop     h               ; Recover data pointer
        call    fp2hst          ; Copy data from CPU2
        call    fpstat          ; Get status to return
        JR      dexit
;
dfrmt:  call    fparam          ; Send parameters
        mvi     b, 80h
dfrmt1: push    h               ; Waste time for command to start
        pop     h
        dcr     b
        JRNZ    dfrmt1
        xra     a               ; Clear return status
        JR      dexit
;
fpwres: in      PPIB            ; Wait for FPY command to complete
        ani     20h
        JRZ     fpwres          ; Wait for PPIB[5] to go high
fpwr2:  in      PPIB
        ani     20h
        JRNZ    fpwr2           ; Wait for PPIB[5] to go low
        ret
;
fparam: call    busopn          ; Send params
        lxi     h, FPYPRM
        mov     m, b            ; Command byte
        inx     h
        mov     m, c            ; Disk number
        inx     h
        mov     a, e
        cma
        mov     m, a            ; ~sector number
        inx     h
        mov     a, d
        cma
        mov     m, a            ; ~track number
        mvi     a, 0ffh
        sta     FPYCMD
        call    buscls
        ret
;
hst2fp: lxi     h, HSTBUF        ;eae6
        call    busopn
        lxi     d, FPYBUF
        lxi     b, PHYSEC
        LDIR
        call    buscls
        ret
;
fp2hst: call    busopn            ;eaf8
        lxi     d, HSTBUF
        lxi     h, FPYBUF
        lxi     b, PHYSEC
        LDIR
        call    buscls
        ret
;
fpstat: call    busopn            ;eb0a
        lda     FPYSTS
        push    psw
        call    buscls
        pop     psw
        ret
;
busopn: mvi     a, 0ah          ;PPIC[5] Low
        out     PPICW
busbsy: in      PPIB            ; Wait for CPU2
        ral                     ; not busy
        JRC     busbsy
        mvi     a, 08h          ;PPIC[4] Low
        out     PPICW
        ret
;
buscls: mvi     a, 09h          ;PPIC[4] High
        out     PPICW
        mvi     a, 0bh
        out     PPICW           ;PPIC[5] High
        ret
;
        end
