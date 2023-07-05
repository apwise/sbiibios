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
;TIME    EQU     0042H           ;TIME ( IN ASCII )
;DATE    EQU     004BH           ;DATE ( BCD )
;
FPYPRM  EQU     8802h           ; 4-byte parameter block
FPYCMD  EQU     8807h           ; Command byte (FF = "go")
FPYBUF  EQU     8808h           ; 512-byte sector buffer
FPYSTS  EQU     8a0bh           ; Returned status byte
PHYSEC  EQU     0200h           ; Physical sector size (512 bytes)
;
;TABLE OF EQUATES--I/O DEVICES
;
AUXDAT  EQU     40H             ; AUX PORT DATA
AUXST   EQU     41H             ; AUX PORT STATUS
INTRST  EQU     48H             ; RESET INTERRUPT LATCH
KBCHAR  EQU     50H             ; KEYBOARD CHARACTER
MNDAT   EQU     58H             ; MAIN PORT DATA
MNSTAT  EQU     59H             ; MAIN PORT STATUS
BDGEN   EQU     60H             ; BAUD RATE GENERATOR
PPIA    EQU     68H             ; 8255 PORT A
PPIB    EQU     69H             ; 8255 PORT B
PPIC    EQU     6AH             ; 8255 PORT C
PPICW   EQU     6BH             ; 8255 CONTROL PORT
TOPSEL  EQU     02H             ; CRTC TOP OF PAGE REGISTER
ROWSTR  EQU     01H             ; CRTC ROW START REGISTER
CURSOR  EQU     03H             ; CRTC CURSOR REGISTER
BELTIM  EQU     15              ; BELL TIME LOOP
KEYDLY  EQU     40              ; KEY DELAY BEFORE REPEAT
RPTTIM  EQU      1              ; KEY REPEAT TIME LOOP
BRKTIM  EQU     15              ; 250 MILLISEC BREAK TIME FOR COMM PORT
LPF     EQU     24              ; NO. OF ROWS ON CRT
CPR     EQU     80              ; No. of chars per row
RTCSEC  EQU     32H             ; Seconds register in RTC
;
        ASEG
        ORG     PVBIOS
;;;
rowcol: dw      3745h           ; Row and column as a 16-bit value
vidcol  EQU     rowcol          ; Low byte is column
vidrow  EQU     rowcol+1        ; High byte is row
CONSTK: dw      3545h           ; Save SP during console routines
DSKSTK: dw      4443h           ; Save SP during disk routines
INIT:   jmp     init1           ; Jump to initialize
CRTIN:  jmp     crtin1          ; Jump to console input
CRTOUT: jmp     crtou1          ; Jump to console output
DISK:   jmp     disk1           ; Jump to disk routine
vcursr: dw      0000h           ; Video cursor address
vtopsc: dw      0000h           ; Copy of vtopsl for this frame
vtopsl: dw      0000h           ; Video top select
vidchr: db      00h             ; Character being sent to screen
vrwenp: dw      0000h           ; Pointer into vrwenc
;;; Copy of vrwen used (in interrupt routine) during video frame
vrwenc: db      39h, 33h, 45h, 30h, 41h, 0dh, 0ah, 3ah
        db      31h, 38h, 45h, 37h, 31h, 35h, 30h, 30h
        db      30h, 44h, 44h, 33h, 36h, 42h, 33h, 45h
        db      30h
;;; Video row enables - 1 byte per row of video
vrwen:  db      46h, 33h, 32h, 34h, 44h, 45h, 34h, 43h
        db      39h, 43h, 44h, 45h, 45h, 45h, 36h, 37h
        db      44h, 45h, 36h, 30h, 37h, 43h, 32h, 31h
        db      45h
belctr: db      45h             ; Bell counter
krptct: db      37h             ; Keyboard repeat counter
vchset: db      00h             ; Select alternate character set
escst1: db      0               ; Escape state-machine state 1
escst2: db      32h             ; Escape state-machine state 2
vtrans: DB      41h             ; Transparanet mode - display control characters
scncol: db      31h             ; Screen column
scnrow: db      32h             ; Screen row
vlinum: db      43h             ; Video line number in interrupt routine
INTSTK: dw      3134h           ; Save SP during interrupts
dskptr: dw      0               ; Save disk data pointer (but unused)
vidatr: db      0               ; Video attribute byte
KBBUFF: db      0               ;... replaces kbchar in os3bdos
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
        call    iniser
        call    vinipt
;;;
;;; Clear video row-enable buffers
        lxi     h, vrwenc
        lxi     d, vrwen
        mvi     b, LPF          ; LPF bytes - 1 per line
        xra     a
init2:  mov     m, a            ; Clear byte in vrwenc
        stax    d               ; Clear byte in vrwen
        inx     h               ; increment pointers
        inx     d
        dcr     b
        JRNZ    init2
;;;
        sta     escst1
        sta     vtrans
        sta     BUFCNT
        lxi     h, KBDBUF
        shld    kbwptr
        shld    kbrptr
                                ; N.B D = 0 - so start of screen
        lxi     h, 0000h        ; Start of video
        mvi     b, CPR          ; 80 characters - screen line length
        call    vidclr          ; Clear the video and attribute RAM
        call    ivsync
        out     INTRST
        IM1
        ei
        ret
;;;
;;; Initialize serial ports
iniser: lxi     h, CONFIG       ; Point at CONFIG structure
        mov     a, m            ; BAUD
        out     BDGEN           ; and program baud generator
        mvi     a, 42h          ; Force reset (and ~DTR low)
        out     AUXST           ; Might be considered a mode byte
        out     AUXST           ; Second one forces the reset
        out     MNSTAT          ; Same for main port
        out     MNSTAT          ; ...
        BIT     1,A             ; Sync mode?
        cz      inisyn          ; Initialise sync character
        inx     h               ; MNMODE
        mov     a, m
        out     MNSTAT          ; Mode Byte
        inx     h               ; MNCMD
        mov     a, m
        out     MNSTAT          ; Command byte
        inx     h               ; AUXMOD
        mov     a, m
        out     AUXST           ; Mode Byte
        inx     h               ; AUXCMD
        mov     a, m
        out     AUXST           ; Command byte
        in      AUXDAT          ; Discard spurious character
        in      AUXDAT
        in      MNDAT           ; Discard spurious character
        in      MNDAT
        ret
;
inisyn: BIT     7,A             ; Single character SYNC?
        lda     SYNC
        JRZ     inisy1          ; ? No, double character SYNC ?
        out     MNSTAT          ; Program sync char1
inisy1: out     MNSTAT          ; Program sync char1 or char2
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
ihsync: call    vseten          ; Set blanking for the next row
        lxi     h, vlinum
        inr     m               ; Step line number
        JR      intrpx
;;;
ivsync: call    vidpts          ; Send video pointers to controller
;;;
        lxi     h, vrwen        ; Copy array from vrwen to vrwenc
        lxi     d, vrwenc
        lxi     b, LPF          ; 24 bytes (but there are 25 allocated?)
        LDIR
;;;
        lxi     h, vrwenc       ; Start of (copy of) blanking array
        shld    vrwenp          ; Initialize pointer for the frame
        call    vseten          ; Set blanking for the first row
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
        JRNZ    kbstb1          ; Pointers don't match
        mov     a, h
        cmp     d
        JRNZ    kbstb1          ; Pointers don't match
        lxi     h, KBDBUF       ; Beyond end of buffer, go to start
kbstb1: mov     m, b            ; Store character in buffer
        inx     h               ; Increment write pointer
        shld    kbwptr          ; and save
        ret
;
kbfull: jmp     rngbel          ; Ring bell - keyboard buffer full
;;;
vseten: lhld    vrwenp          ; Point into vrwenc array
        mov     a, m            ; Pick up flag for current line
        inx     h               ; Step pointer
        shld    vrwenp          ; Save for next line
        ora     a               ; Test flag
        JRZ     vrwbln
        mvi     a, 02h          ; PPIC[1] = 0 Display video row
        out     PPICW
        ret
;
vrwbln: mvi     a, 03h          ; PPIC[1] = 1 Blank video row
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
        cpi     1bh             ; ESC
        jz      crtesc          ; Process escape code
        lda     escst1          ; ESC state-machine active?
        ora     a
        jnz     escprc          ; Yes, process escape code
        lda     vtrans          ; Transparent mode?
        ora     a
        JRNZ    crtou2          ; Yes - display even if a control code
        mov     a, b            ; Recover character
        sui     20h             ; Less than 20h?
        jm      vidctl            ; Yes, process as a control code
crtou2: mov     a, b            ; Recover character
        call    vdsply          ; Display character
        ret
;
vdsply: ani     7fh             ; Lose top bit
        sta     vidchr          ; Save
        call    varwen          ; Address vrwen array
        mov     a, m            ; Is it enabled?
        ora     a
        cz      vclrow          ; No, clear row then enable it
        lhld    vcursr
        mov     a, h            ; Get cursor address
        ori     0f8h            ; Force pointer into video RAM
        mov     h, a
        lda     vchset          ; Alternate character set?
        ora     a
        lda     vidchr          ; Recover character to display
        JRZ     vdspl1          ; Not alternate set
        ori     80h             ; Alternate set - set top bit
vdspl1: mov     m, a            ; Put character in video RAM
        di                      ; Can't be interrupted
        lda     prta            ;   while addressing attribute RAM
        ani     0dfh            ; PRTA[5] = 0 - Address attribute
        out     PPIA
        EXAF                    ; Save port-a value
        mov     a, h            ; Force address to be
        ani     4fh             ;   4800h to 4fffh
        mov     h, a
        lda     vidatr          ; Get video attribute value
        mov     m, a            ; store into attribute RAM
        EXAF                    ; Recover port-a value
        ori     20h             ; PRTA[5] = 1 - Address DRAM
        out     PPIA
        ei                      ; Enable interrupts
        call    stpcrs
        ret
;;;
;;;  Address vrwen (row enables) array
varwen: lxi     h, vrwen        ; Start of vrwen
        mvi     d, 00h
        lda     vidrow
        mov     e, a            ; DE = which row
        dad     d               ; HL now points at correct row blank flag
        ret
;
scroll: lda     scrlck          ; Scroll-lock ?
        ora     a
        rnz                     ; Yes, return
        lda     TIMENB          ; Time displayed?
        ora     a
        JRZ     scrol2
;;;
scrol1: lda     vlinum          ; Is this dead code?
        sui     15h
        jp      scrol1          ; Result is unused
;;; 
scrol2: di                      ; No interrupts while updating
        lhld    vtopsl          ; Get pointer top of sceen
        lxi     d, CPR          ; Add row length
        dad     d
        shld    vtopsl          ; Update top of screen
        lhld    timpos
        dad     d               ; Add row length
        shld    timpos          ; Update time display position
        lxi     h, vrwen+1      ; Copy from vwren[1..23]
        lxi     d, vrwen        ;        to vwren[0..22]
        lxi     b, LPF-1        ; 23 to move
        LDIR                    ; Do the copy
        xra     a               ; Clear...
        stax    d               ;              vwren[23]
        ei
        lxi     h, vrwen        ; Point at vwren[0]
        mov     a, m
        ora     a               ; Is top row enabled
        rnz                     ; Yes - all done
        mvi     b, CPR          ; Line length
        lhld    vtopsl          ; Point at top of screen
        call    vidclr            ; Clear the top row
        lxi     h, vrwen
        mvi     m, 0ffh         ; and enable its display
        ret
;;;
;;; Address video RAM by multiplying row number
;;; by 80 (number of characters in row)
vraddr: lda     vidrow          ; Pick up row number
        lxi     h, 0000h
        lxi     d, CPR          ; Length of row 
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
        ret                             ;
;;;
;;; Actually clear the row in video RAM and clear
;;; the vrwen flag for the row so the row is displayed
vclrow: call    vraddr          ; Address the RAM for this row
        mvi     b, CPR          ; Number to clear
        call    vidclr            ; Clear the row
        call    varwen          ; Address the vrwen array
        mvi     m, 0ffh         ; and set to display the row
        ret
;;; init1
;;; Clear B bytes of video RAM to ASCII space
;;; D is MS byte of address in video RAM
;;; HL points within video RAM
vidclr: mov     c, b            ; Save B
        mvi     d, 0f8h
        push    h
;;; Clear video RAM
vidcl1  mov     a, d
        ora     h               ; Address in video RAM
        mov     h, a
        mvi     m, ' '          ; Save space character
        inx     h
        DJNZ    vidcl1
;;; 
        pop     h
        di                      ; No interrupts while
        lda     prta            ; updating attribute RAM
        ani     0dfh            ; PRTA[5] = 0 - Address attribute
        sta     prta
        out     PPIA
        ei
        mov     b, c            ; Recover B
;;; Clear attribute RAM
vidcl2: mov     a, h
        ani     4fh             ; Force address to be
        ori     48h             ;  4800h to 4fffh
        mov     h, a
        mvi     m, 00h          ; Clear attribute
        inx     h
        DJNZ    vidcl2
;;;
        di
        lda     prta
        ori     20h             ; PRTA[5] = 1 - Address DRAM
        sta     prta
        out     PPIA
        ei
        ret
;
vidctl: mov     a, b
        cpi     01h             ; CTRL-A - Home cursor
        JRZ     vhmcrs
        cpi     02h             ; CTRL-B - Toggle Key-clock
        JRZ     tglclk
        cpi     07h             ; CTRL-G - Ring Bell
        JRZ     rngbel
        cpi     09h             ; CTRL-I - Tab
        JRZ     vhtab
        cpi     0dh             ; CR
        JRZ     vcret
        cpi     14h             ; CTRL-T - Toggle time display
        JRZ     vtgltm
        cpi     0bh             ; CTRL-K - Cursor up
        JRZ     vcrsup
        cpi     06h             ; CTRL-F - Cursor forwards
        JRZ     stpcrs
        cpi     0ah             ; LF/CTRL-J - (Cursor down)
        jz      vlfeed
        cpi     0ch             ; CTRL-L - Clear screen
        jz      vclear
        cpi     15h             ; CTRL-U - Cursor left
        jz      vcrslf
        cpi     08h             ; BS/CTRL-H - Cursor left
        jz      vcrslf
        ret
;
vhmcrs: lxi     h, 0000h        ; Home cursor
        shld    rowcol          ; Set row/col to zeros
        lhld    vtopsl          ; Get current top row
        shld    vcursr          ; Write to cursor position
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
vhtab:  call    stpcrs          ; Step cursor
        mov     a, l            ; Is horizontal position
        ani     07h             ; divisible by 8?
        JRNZ    vhtab           ; No, step again
        ret
;;; 
vcret:  call    vraddr          ; Carriage return
        shld    vcursr          ; Cursor to the left of current row
        mvi     a, 00h          ; Set column to zero
        sta     vidcol
        ret
;;;
vtgltm: lxi     h, TIMENB       ; Toggle time enable
        mov     a, m
        inr     a               ; Flip bottom bit
        ani     01h             ; Lose higher bits
        mov     m, a
        rnz                     ; Return if now enabled
        lhld    timpos          ; If now disabled, clear the time
        mvi     b, 11           ; display (11 characters to end of line)
        call    vidclr
        ret
;;; 
vcrsup: lda     vidrow          ; Cursor up
        ora     a               ; Already on top row?
        rz                      ; Yes, return
        dcr     a               ; No, decrement
        sta     vidrow          ; and update row
        lhld    vcursr          ; Cursor address
        lxi     d, 0ffb0h       ; -80
        dad     d               ; Subtract 80
        shld    vcursr          ; and update
        ret
;;; 
;;; Step cursor?
stpcrs: lhld    vcursr          ; Step cursor
        inx     h               ; Increment cursor address
        shld    vcursr
        lhld    rowcol          ; Get row-col
        inr     l               ; Increment column
        mov     a, l
        cpi     CPR             ; Past end of line?
        JRNZ    stpcr2          ; No, still in the same line
        mvi     l, 00h          ; Clear column
        mov     a, h            ; Get row
        cpi     23              ;   last row?
        JRNZ    stpcr1          ; No, go increment row
        push    h
        call    scroll
        pop     h
        JR      stpcr2
;
stpcr1: inr     h               ; Increment row
stpcr2: shld    rowcol          ; Update row-col
        ret
;;; 
vlfeed: lhld    vcursr          ; Cursor address
        lxi     d, CPR          ; Characters per row
        dad     d               ; Add
        shld    vcursr          ; Update cursor
        lda     vidrow          ; Current row
        cpi     LPF-1           ; On bottom row?
        JRNZ    vlfd1           ; No
        call    scroll          ; Yes, scroll screen
        ret
;;; 
vlfd1:  inr     a               ; Step row
        sta     vidrow          ; and update
        ret
;;; 
vclear: lxi     h, vrwen        ; Clear the video row-enable array
        mvi     b, LPF          ; Number of entries
        xra     a
vclr1:  mov     m, a
        inx     h
        DJNZ    vclr1           ; Loop over array
;;;
        call    vinipt          ; Initialise video pointers
        lxi     h, 0000h        ; Clear the first line
        mvi     b, CPR          ; All 80 characters
        call    vidclr          ; Go clear it
        lxi     h, vrwen        ; Enable
        mvi     m, 0ffh         ;  the first row
        ret
;;; 
vcrslf: lhld    rowcol          ; Get row/col
        mov     a, l            ; are they both zero?
        ora     h
        rz                      ; Yes - return
        mov     a, l            ; Get column
        ora     a               ; Zero (already at left?)
        JRNZ    vcrsl1          ; No
        mvi     l, CPR-1        ; Yes, move to right screen edge column
        dcr     h               ; and up one line
        JR      vcrsl2
;
vcrsl1: dcr     l               ; Not in left column, decrment
vcrsl2: shld    rowcol          ; Store update row/col
        lhld    vcursr          ; Cursor address
        dcx     h               ; Decrement
        shld    vcursr          ; and update
        ret
;;;
;;; Initialize video pointers
vinipt: lxi     h,0000h
        shld    rowcol
        shld    vtopsc
        shld    vtopsl
        shld    vcursr
        lxi     d, 69           ; 69 + 9 = 78 (_00:00:00..)
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
esctwo: lda     escst2          ; Get state variable
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
        lxi     h, vidatr       ; Point at video attribute byte
        cpi     'R'
        JRZ     vrevon
        cpi     'r'
        JRZ     vrevof
        cpi     'H'
        JRZ     vhlfon
        cpi     'h'
        JRZ     vhlfof
        cpi     'B'
        JRZ     vblkon
        cpi     'b'
        JRZ     vblkof
        cpi     'N'
        JRZ     vatrnm
        cpi     'U'
        JRZ     vundon
        cpi     'u'
        JRZ     vundof
        lxi     h, vchset
        cpi     's'
        JRZ     vchrev
        cpi     'S'
        JRZ     vchnrm
        lxi     h, prta
        cpi     'g'
        JRZ     vwaltc
        cpi     'G'
        JRZ     vwnrmc
        cpi     'A'
        JRZ     vwnonr
        cpi     'a'
        JRZ     vwrevv
        lxi     h, vtrans
        cpi     'E'
        JRZ     vtrnon
        cpi     'D'
        JRZ     vtrnof
        cpi     'K'
        JRZ     vclrer
        cpi     'k'
        JRZ     vclres
        ret
vrevon: SETB    0, M            ; Reverse video on
        ret
vrevof: RES     0, M            ; Reverse video off
        ret
vhlfon: SETB    1, M            ; Half intensity on
        ret
vhlfof: RES     1, M            ; Half intensity off
        ret
vblkon: SETB    2, M            ; Blinking on
        ret
vblkof: RES     2, M            ; Blinking off
        ret
vundon: SETB    3, M            ; Underline on
        ret
vundof: RES     3, M            ; Underline off
        ret
vatrnm: xra     a               ; Normalize - all attributes off
        sta     vidatr
        ret
vchrev: mvi     m, 00h          ; Primary and secondary sets as normal
        ret
vchnrm: mvi     m, 0ffh         ; Reverse primary and secondar char. sets
        ret
vwaltc: SETB    0, M            ; Whole screen alternate character set
        mov     a, m
        out     PPIA
        ret
vwnrmc: RES     0, M            ; Whole screen normal character set
        mov     a, m
        out     PPIA
        ret
vwnonr: RES     7, M            ; Whole screen non-reverse video
        mov     a, m
        out     PPIA
        ret
vwrevv: SETB    7, M            ; Whole screen reverse video
        mov     a, m
        out     PPIA
        ret
vtrnon: mvi     m, 0ffh         ; Transparent mode on (display control characters)
        ret
vtrnof: mvi     m, 00h          ; Disable transparent mode
        ret
;;;
;;; Clear to end of row
vclrer: call    vraddr          ; Address of start of current row
        lda     vidcol
        lxi     b, 0
        mov     c, a
        dad     b               ; Compute address of current character
        mvi     a, CPR
        sub     c
        mov     b, a            ; Number of characters to clear
        call    vidclr
        ret
;
vclres: call    vclrer          ; Clear to end of screen
        call    varwen          ; Address row enable array
        lda     vidrow          ; Current row
        cpi     LPF-1           ; Last row?
        rz                      ; Yes, return
        mov     b, a            ; Save current row
        mvi     a, LPF-1        ; Number of rows minus 1
        sub     b               ; Number that need clearing
        mov     c, a            ; Loop counter
        xra     a
vclre1: inx     h               ; Step vrwen pointer
        mov     m, a            ; Blank that row
        dcr     c               ; Step counter
        JRNZ    vclre1          ; Loop until done
        ret
;;;
;;; Disk routine
;;; 
;;; Command in b:
;;;   0,4 - Restore
;;;   1   - Read
;;;   2   - Write with    RAW verification
;;;   5   - format
;;;   6   - Write without RAW verification
;;;
;;; c  = disk   number
;;; d  = track  number
;;; e  = sector number
;;; hl = data pointer (but never used)
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
hst2fp: lxi     h, HSTBUF       ; Copy host buffer to CPU2
        call    busopn
        lxi     d, FPYBUF
        lxi     b, PHYSEC
        LDIR
        call    buscls
        ret
;
fp2hst: call    busopn          ; Copy CPU2 to host buffer
        lxi     d, HSTBUF
        lxi     h, FPYBUF
        lxi     b, PHYSEC
        LDIR
        call    buscls
        ret
;
fpstat: call    busopn          ; Get CPU2 status
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
