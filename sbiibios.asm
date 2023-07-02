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
BRKTIM  EQU     15              ;250 MILLISEC BREAK TIME FOR COMM PORT
LPF     EQU     24              ;NO. OF ROWS ON CRT
RTCSEC  EQU     32H             ; Seconds register in RTC
;
        ASEG
        ORG     PVBIOS
;;;
rowcol: dw      3745h           ;e400
vidrow  EQU     rowcol+1
CONSTK: dw      3545h           ;Save SP during console routines
DSKSTK: dw      4443h           ;Save SP during disk routines
INIT:   jmp     init1           ;e406
CRTIN:  jmp     crtin1          ;e409
CRTOUT: jmp     crtou1          ;e40c
DISK:   jmp     disk1           ;e40f
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
belctr: db      45h             ; Bell counter
krptct: db      37h             ; Keyboard repeat counter
B012:   db      00h             ;e44f 00
escst1: db      0               ;e450 00
escst2: db      32h             ;e451 32
B003:   DB      41h             ;e452 41
scncol: db      31h             ; Screen column
scnrow: db      32h             ; Screen row
vlinum: db      43h             ;e455 43
INTSTK: dw      3134h           ;Save SP during interrupts
dskptr: dw      0               ;e458 00 00
B013:   db      0               ;e45a 00
KBBUFF: db      0               ;replaces kbchar in os3bdos
brkctr: db      43h             ; Main port break time counter
BUFCNT: db      0               ;e45d 00
scrlck: db      0               ; Scroll lock XXXX keep as DB - not initialized
kbwptr: dw      0               ; type-ahead buffer write pointer
kbrptr: dw      0               ; type-ahead buffer read pointer
timpsc: dw      0               ; Copy of timpos for current frame
timpos: dw      0               ; Position tor time display on top line
;;;
;;; Initialization
init1:  di
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
        mvi     b, LPF          ; LPF bytes - 1 per line
        xra     a
L002:   mov     m, a            ; Clear byte in vblnkc
        stax    d               ; Clear byte in vblnk
        inx     h               ; increment pointers
        inx     d
        dcr     b
        JRNZ    L002
;;;
        sta     escst1
        sta     B003
        sta     BUFCNT
        lxi     h, KBDBUF
        shld    kbwptr
        shld    kbrptr
                                ; N.B D = 0 - so start of screen
        lxi     h, 0000h        ; Start of CPU-2 RAM block
        mvi     b, 50h          ; 80 characters - screen line length
        call    L003
        call    ivsync
        out     48h
        IM1
        ei
        ret
;;; init1
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
        lxi     b, LPF          ; 24 bytes (but there are 25 allocated?)
        LDIR
;;;
        lxi     h, vblnkc       ; Start of (copy of) blanking array
        shld    vblnkp          ; Initialize pointer for the frame
        call    vsetbl          ; Set blanking for the first row
        call    rtcdpy          ; Display time on screen
;;;
        lda     belctr          ; Decrement bell counter
        dcr     a
        sta     belctr
        JRNZ    ivsyn1          ; Leave bell on for now
        mvi     a, 0ch          ; PPIC[6] = 0 (Bell off)
        out     PPICW
ivsyn1: lda     brkctr          ; Get main-port break counter
        ora     a
        JRZ     ivsyn2          ; Not sending break
        dcr     a               ; Decrement it
        sta     brkctr
        JRNZ    ivsyn2          ; Still a bit longer
        lda     MNCMD
        ani     0f7h            ; Clear the break bit
        out     MNSTAT
ivsyn2: call    keysrv
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
;;;
;;; Service the keyboard (called from vertical sync interrupt)
keysrv: in      PPIB            ; Get port B
        mov     c, a            ; Save
        ani     02h             ; Any key (still) down?
        JRZ     knodwn
        mov     a, c            ; Recover saved Port B
        ani     01h             ; New keyboard character
        JRZ     knonew
        call    keyack
        mvi     a, KEYDLY       ; Set for initial wait to repeat
keysr1: sta     krptct
        lda     KEYCLK          ; Configured for key-click?
        ora     a
        JRZ     knoclk          ; No...
        mvi     a, 0dh          ; PPIC[6] = 1 (Bell on)
        out     PPICW
        mvi     a, 01h          ; Bell duration
        sta     belctr
knoclk: in      KBCHAR          ; Read character
        mov     b, a            ; Save character
        cpi     0f1h            ; CTRL-1 ?
        JRZ     keyclr
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
knonew: lda     krptct          ; Get keyboard repeat counter
        ora     a
        JRNZ    krptnz
        mvi     a, RPTTIM       ; Set counter for next repeated key
        JR      keysr1
;
krptnz: dcr     a               ; Decrement counter
        sta     krptct
        ret
;
knodwn: mvi     a, 0f0h         ; Set repeat to a large number
        sta     krptct          ; to deal with key bounce?
        ret
;
keyclr: call    keyack          ; Discard any pending character
        mvi     a, KEYDLY       ; Set for initial wait to repeat
        sta     krptct
        xra     a               ; Clear buffer character
        sta     KBBUFF
        sta     BUFCNT
        lxi     h, KBDBUF       ; Reset type-ahead buffer pointer
        shld    kbwptr
        shld    kbrptr
        ret
;
keyack: mvi     a, 0eh          ; PPIC[7] = 0  Acknowledge new key
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
crtin1: call    kgetch          ; Get character from type-ahead buffer
        mov     b, a            ; Save it
        BIT     7,A             ; Top bit set? Then it could be keypad
        cnz     mapkpd          ; Map keypad characters
        cpi     00h             ; ^@ - Page on/off
        JRZ     tglslk          ; Toggle scroll lock
        cpi     81h
        JRZ     kmap81
        cpi     82h
        JRZ     kmap82
        cpi     83h
        JRZ     kmap83
        cpi     85h
        JRZ     kmap85
        cpi     80h
        JRZ     break
        JR      crtinx
;;;
tglslk: lxi     h, scrlck       ; Address scroll lock
        mov     a, m            ; Read it
        inr     a               ; Step
        ani     01h             ; Limit to 0/1 
        mov     m, a            ; Update it
        JR      crtinx
;;; 
kmap81: mvi     b, 08h          ; BS - backspace      - left ?
        JR      crtinx
kmap83: mvi     b, 0bh          ; VT - vertical tab   - down ?
        JR      crtinx
kmap82: mvi     b, 06h          ; ^F - cursor fowards - right ?
        JR      crtinx
kmap85: mvi     b, 0ah          ; LF - line feed      - down?
        JR      crtinx
;;;
break:  mvi     a, BRKTIM       ; Time for break (in video frames)
        sta     brkctr
        lda     MNCMD
        ori     08h             ; Set break bit
        out     MNSTAT
;;; Fall through to exit
crtinx: mov     a, b            ; Recover saved character
        ret
;;;
;;; Get character from type-ahead buffer
kgetch: lxi     h, BUFCNT       ; Number of chracters in buffer
        di
        dcr     m               ; Decrement it
        ei
        lhld    kbrptr          ; Type-ahead read pointer
        lxi     d, KBDBFE       ; End of buffer (+1)
        mov     a, l
        cmp     e               ; Compare low
        JRNZ    kgetc1          ; Not past buffer end
        mov     a, h
        cmp     d               ; Compare high
        JRNZ    kgetc1          ; Not past buffer end
        lxi     h, KBDBUF       ; Loop to start of buffer
kgetc1: mov     a, m            ; Get character
        inx     h               ; Step pointer
        shld    kbrptr          ; and save for next time
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
crtou1: mov     b, c
        mov     a, c
        cpi     1bh             ; ESC ?
        jz      crtesc
        lda     escst1
        ora     a
        jnz     escprc          ; Process escape code
        lda     B003
        ora     a
        JRNZ    LX02
        mov     a, b
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
;;;
L045:   lxi     h, vblnk         ;e75e
        mvi     d, 00h
        lda     vidrow
        mov     e, a
        dad     d
        ret
;
L046:   lda     scrlck               ;e769
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
;;;
;;; Address video RAM by multiplying row number
;;; by 80 (number of characters in row)
vraddr: lda     vidrow           ; Pick up row number
        lxi     h, 0000h
        lxi     d, 80           ; Length of row 
        mvi     b, 08h          ; 8 bits in row number
vradrl: rrc                     ; LSB set?
        JRNC    vradr0
        dad     d               ; Yes - add in (80 * 2^n)
vradr0: SLAR    E               ; Shift DE right one place
        RALR    D               ; (aka Z80 RLA instruction)
        dcr     b               ; Decrement bit counter
        JRNZ    vradrl          ; Loop over bits
        LDED    vtopsl          ; Start of top row
        dad     d               ; Add in (row * 80)
        ret
;
L052:   call    vraddr            ;e7cc
        mvi     b, 50h
        call    L003
        call    L045
        mvi     m, 0ffh
        ret
;;; init1
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
        shld    rowcol
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
        mvi     a, BELTIM       ; Bell duration
        sta     belctr
        ret
;;;
L059:   call    L063
        mov     a, l
        ani     07h
        JRNZ    L059
        ret
L060:   call    vraddr
        shld    vcursr
        mvi     a, 00h
        sta     rowcol
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
L062:   lda     vidrow
        ora     a
        rz
        dcr     a
        sta     vidrow
        lhld    vcursr
        lxi     d, 0ffb0h
        dad     d
        shld    vcursr
        ret
;;; CRTOUT
L063:   lhld    vcursr           ;e89d
        inx     h
        shld    vcursr
        lhld    rowcol
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
L067:   shld    rowcol
        ret
L064:   lhld    vcursr   ;e8c0 2a
        lxi     d, 0050h
        dad     d
        shld    vcursr
        lda     vidrow
        cpi     17h
        JRNZ    L069
        call    L046
        ret
L069:   inr     a
        sta     vidrow
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
L066:   lhld    rowcol
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
L072:   shld    rowcol
        lhld    vcursr
        dcx     h
        shld    vcursr
        ret
;;;
;;; Initialize video pointers
vinipt: lxi     h,0000h
        shld    rowcol
        shld    vtopsc
        shld    vtopsl
        shld    vcursr
        lxi     d, 0045h        ; 69 + 9 = 78 (_00:00:00..)
        dad     d
        shld    timpos
        ret
;
crtesc: mvi     a, 01h
        sta     escst1
        ret
;
escprc: lda     escst1          ; Escape state-machine state
        cpi     01h
        JRZ     escone          ; Process escape
        cpi     02h
        JRZ     esctwo
        cpi     03h
        JRZ     escrow
        xra     a
        sta     escst1
        ret
;;;
;;; First character after ESC
escone: mov     a, b            ; Recover character
        cpi     'Y'
        JRZ     escsy           ; Record ESC Y
        cpi     '='
        JRZ     escsy           ; Record ESC Y
        cpi     '~'
        JRZ     escstl          ; Record ESC ~
escbad: xra     a               ; Clear escst1
        sta     escst1
        ret
;;;
;;; ESC Y or ESC = received
escsy: xra     a
        sta     escst2          ; Clear escst2
esc1x:  mvi     a, 02h
        sta     escst1
        ret
escstl: mvi     a, 0ffh         ; Set escst2
        sta     escst2
        JR      esc1x
;;;
esctwo: lda     escst2   ;e964
        ora     a
        JRNZ    esctld
;;; Here for ESC Y ? or ESC = ?
        mov     a, b            ; Recover character
        sui     20h             ; Subtract ' '
        mov     c, a
        jm      escbad
        sui     18h             ; Off-by-one bug?
        jp      escbad          ; Not expecting beyond bottom of screen
        mov     a, c
        sta     scnrow          ; Save screen row
        mvi     a, 03h          ; Set to expect column byte
        sta     escst1
        ret
;;;
escrow: mov     a, b            ; Recover character
        sui     20h             ; Subtract ' '
        mov     c, a
        jm      escbad          ; Not expecting control characters
        sui     70h             ; This looks like a bug - should be 79
        jp      escbad          ; Not expecting beyond right of screen
        mov     a, c
        sta     scncol
        xra     a               ; Clear escape state
        sta     escst1          ; the sequence is complete
        lhld    scncol          ; Pick up ESC row-col pair
        shld    rowcol          ; Save in row-col
        call    vraddr          ; Address in video RAM
        xchg                    ; to DE reg
        lhld    rowcol          ; Get row-col
        mvi     h, 00h          ; but only the column
        dad     d               ; Add in RAM address
        shld    vcursr          ; Save updated cursor position
        ret
;;; 
;;; ESC ~ ?
esctld: xra     a               ; Clear ESC state
        sta     escst1          ; sequence is complete
        mov     a, b
        lxi     h, B013
        cpi     'R'
        JRZ     L084
        cpi     'r'
        JRZ     L085
        cpi     'H'
        JRZ     L086
        cpi     'h'
        JRZ     L087
        cpi     'B'
        JRZ     L088
        cpi     'b'
        JRZ     L089
        cpi     'N'
        JRZ     L092
        cpi     'U'
        JRZ     L090
        cpi     'u'
        JRZ     L091
        lxi     h, B012
        cpi     's'
        JRZ     L093
        cpi     'S'
        JRZ     L094
        lxi     h, prta
        cpi     'g'
        JRZ     L095
        cpi     'G'
        JRZ     L096
        cpi     'A'
        JRZ     L097
        cpi     'a'
        JRZ     L098
        lxi     h, B003
        cpi     'E'
        JRZ     L099
        cpi     'D'
        JRZ     L100
        cpi     'K'
        JRZ     L101
        cpi     'k'
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
L101:   call    vraddr            ;ea47
        lda     rowcol
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
        lda     vidrow
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
disk1:  shld    dskptr          ; Save data pointer (but this never used)
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
