        MACLIB  Z80
;
OFFSET  EQU     9400h           ; OFFSET for 64K = 9400h
                                ; OFFSET for 32K = 1400h
HSTBUF  EQU     6200h + OFFSET  ; DMA disk buffer
STACK   EQU     5fffh + OFFSET  ; Stack when loading
STACK1  EQU     5fdfh + OFFSET  ; Stack during interrupt
STACK2  EQU     5fbfh + OFFSET  ; Stack during conout
STACK3  EQU     5f9fh + OFFSET  ; Stack during disk routines
KBDBFE  EQU     5f80h + OFFSET  ; End of keyboard buffer (bottom of STACK3)
KBDBUF  EQU     5f00h + OFFSET  ; 128 byte keyboard buffer
DIRBUF  EQU     5e80h + OFFSET  ; 128 bytes for disk directory
;
CONFIG  EQU     5b00h + OFFSET  ; Configuration table read from disk
BAUD    EQU     CONFIG          ; For main and aux ports
MNMODE  EQU     CONFIG+1        ; Main port mode        
MNCMD   EQU     CONFIG+2        ; Main port command byte
AUXMOD  EQU     CONFIG+3        ; Aux port mode
AUXCMD  EQU     CONFIG+4        ; Aux port command byte
FREQ    EQU     CONFIG+5        ; 4bh=60Hz, 0bh=50Hz
prta    EQU     FREQ            ;   also maintains current PPIA value
HDSHAK  EQU     CONFIG+6        ; 00 = DSR disabled; 01 = DSR enabled
RAW     EQU     CONFIG+7        ; 00 = No disk read verify; ff = Read verify
TIMENB  EQU     CONFIG+8        ; 00 = Time function disabled; ff = Time enabled
SYNC    EQU     CONFIG+9        ; Sync byte
KEYCLK  EQU     CONFIG+10       ; Handshake byte
KEYPAD  EQU     CONFIG+14       ; Keypad mapping table (18 bytes)
;
PVBIOS: EQU     5000H+OFFSET    ; Start of this private BIOS module
;
; Locations in CPU-2 RAM concerned with floppy disks
; 
FPYPRM  EQU     8802h           ; 4-byte parameter block
FPYGO   EQU     8807h           ; Command byte (FF = "go")
FPYBUF  EQU     8808h           ; 512-byte sector buffer
FPYSTS  EQU     8a0bh           ; Returned status byte
PHYSEC  EQU     0200h           ; Physical sector size (512 bytes)
;
; Table of equates--I/O devices
;
TENTHS  EQU     31h             ; RTC tenths digit (r/o)
USECS   EQU     32h             ; RTC units of seconds (r/o)
TSECS   EQU     33h             ; RTC tens of seconds (r/o)
UMINS   EQU     34h             ; RTC units of minutes (r/w)
TMINS   EQU     35h             ; RTC tens of minutes (r/w)
UHRS    EQU     36h             ; RTC units of hours (r/w)
THRS    EQU     37h             ; RTC tens of hours (r/w)
UDAYS   EQU     38h             ; RTC units of days (r/w)
TDAYS   EQU     39h             ; RTC tens of days (r/w)
DAYOW   EQU     3ah             ; RTC day of the week (r/w)
UMONTH  EQU     3bh             ; RTC units of months (r/w)
TMONTH  EQU     3ch             ; RTC tens of months (r/w)
YEARS   EQU     3dh             ; RTC leap year setting (w/o)
START   EQU     3eh             ; RTC start/stop port (w/o)
AUXDAT  EQU     40h             ; Aux port data
AUXST   EQU     41h             ; Aux port status
INTRST  EQU     48h             ; Reset interrupt latch
KBCHAR  EQU     50h             ; Keyboard character
MNDAT   EQU     58h             ; Main port data
MNSTAT  EQU     59h             ; Main port status
BDGEN   EQU     60h             ; Baud rate generator
PPIA    EQU     68h             ; 8255 port a
PPIB    EQU     69h             ; 8255 port b
PPIC    EQU     6ah             ; 8255 port c
PPICW   EQU     6bh             ; 8255 control port
TOPSEL  EQU     02h             ; CRTC top of page register
ROWSTR  EQU     01h             ; CRTC row start register
CURSOR  EQU     03h             ; CRTC cursor register
BELTIM  EQU     15              ; Bell time loop
KEYDLY  EQU     40              ; Key delay before repeat
RPTTIM  EQU      1              ; Key repeat time loop
BRKTIM  EQU     15              ; 250 millisec break time for comm port
LPF     EQU     24              ; No. of rows on crt
CPR     EQU     80              ; No. of chars per row
;
;
        ASEG
        ORG     PVBIOS
;
rowcol: ds      2               ; Row and column as a 16-bit value
vidcol  EQU     rowcol          ; Low byte is column
vidrow  EQU     rowcol+1        ; High byte is row
CONSTK: ds      2               ; Save SP during console routines
DSKSTK: ds      2               ; Save SP during disk routines
INIT:   jmp     init1           ; Jump to initialize
CRTIN:  jmp     crtin1          ; Jump to console input
CRTOUT: jmp     crtou1          ; Jump to console output
DISK:   jmp     disk1           ; Jump to disk routine
vcursr: ds      2               ; Video cursor address
vtopsc: ds      2               ; Copy of vtopsl for this frame
vtopsl: ds      2               ; Video top select
vidchr: ds      1               ; Character being sent to screen
vrwenp: ds      2               ; Pointer into vrwenc
; Copy of vrwen used (in interrupt routine) during video frame
vrwenc: ds      LPF + 1
; Video row enables - 1 byte per row of video
vrwen:  ds      LPF + 1
belctr: db      0               ; Bell counter
krptct: db      0               ; Keyboard repeat counter
vchset: ds      1               ; Select alternate character set
escst1: ds      1               ; Escape state-machine state 1
escst2: ds      1               ; Escape state-machine state 2
vtrans: ds      1               ; Transparent mode - display control characters
scncol: ds      1               ; Screen column
scnrow: ds      1               ; Screen row
vlinum: ds      1               ; Video line number in interrupt routine
INTSTK: ds      2               ; Save SP during interrupts
dskptr: ds      2               ; Save disk data pointer (but unused)
vidatr: ds      1               ; Video attribute byte
KBBUFF: db      0               ; CCP's keyboard buffer
brkctr: db      0               ; Main port break time counter
BUFCNT: ds      1               ; Type-ahead buffer count
scrlck: db      0               ; Scroll lock
kbwptr: ds      2               ; Type-ahead buffer write pointer
kbrptr: ds      2               ; Type-ahead buffer read pointer
timpsc: ds      2               ; Copy of timpos for current frame
timpos: ds      2               ; Position tor time display on top line
;
; Initialization
init1:  di
        lda     prta            ; Initialize 50Hz/60Hz
        out     PPIA
;
; Set up interrupt vector
        mvi     a, 0c3h
        sta     0038h           ; JMP opcode
        lxi     h, INTRP
        shld    0039h           ; Address of interrupt routine
;
        mvi     a, 0eh          ; PPIC[7] = 0
        out     PPICW           ; New keyboard char ack.
;
        call    iniser          ; Initialise serial ports
        call    vinipt          ; Initialise video pointers
;
; Clear video row-enable buffers
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
;
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
;
; Initialize serial ports
;
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
INTRP:  SSPD    INTSTK          ; Save stack pointer
        lxi     sp, STACK1      ; Switch to interrupt stack
        push    h               ; Save registers
        push    d
        push    b
        push    psw
        in      PPIB
        ani     04h             ; Vertical sync?
        JRZ     ihsync          ; No, deal with horizontal sync
; Vertical sync
        call    ivsync
        lxi     h, vlinum
        mvi     m, 00h          ; Clear line number
intrpx: in      INTRST          ; Acknowledge interrupt
        pop     psw             ; Restore registers
        pop     b
        pop     d
        pop     h
        LSPD    INTSTK          ; Restore stack pointer
        ei
        RETI
;
; Horizontal sync
ihsync: call    vseten          ; Set blanking for the next row
        lxi     h, vlinum
        inr     m               ; Step line number
        JR      intrpx          ; Exit interrupt routine
;
ivsync: call    vidpts          ; Send video pointers to controller
;
        lxi     h, vrwen        ; Copy array from vrwen to vrwenc
        lxi     d, vrwenc
        lxi     b, LPF          ; 24 bytes (but there are 25 allocated?)
        LDIR
;
        lxi     h, vrwenc       ; Start of (copy of) enable array
        shld    vrwenp          ; Initialize pointer for the frame
        call    vseten          ; Set blanking for the first row
        call    rtcdpy          ; Display time on screen
;
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
;
        mov     a, h
        ani     0fh             ; Limit to 12-bit address (but why not 11-bit since it's 2K?)
        mov     h, a
        mov     a, d
        ani     0fh
        mov     d, a
;
        mvi     a, 01h          ; PPIC[0] = 1 swap addr and data buses
        out     PPICW
        mvi     a, CURSOR
        mov     m, a            ; Set cursor address
        mvi     a, ROWSTR
        xchg
        mov     m, a            ; Set row start (for first row)
        mvi     a, TOPSEL
        mov     m, a            ; which is also the top of screen
        mvi     a, 00h          ; PPIC[0] = 0 - addr/data bus back to normal
        out     PPICW
        ret
;
; Service the keyboard (called from vertical sync interrupt)
;
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
;
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
        mvi     c, USECS        ; RTC units of seconds
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
; Timeout
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
;
tglslk: lxi     h, scrlck       ; Address scroll lock
        mov     a, m            ; Read it
        inr     a               ; Step
        ani     01h             ; Limit to 0/1 
        mov     m, a            ; Update it
        JR      crtinx
; 
kmap81: mvi     b, 08h          ; BS - backspace      - left ?
        JR      crtinx
kmap83: mvi     b, 0bh          ; VT - vertical tab   - down ?
        JR      crtinx
kmap82: mvi     b, 06h          ; ^F - cursor fowards - right ?
        JR      crtinx
kmap85: mvi     b, 0ah          ; LF - line feed      - down?
        JR      crtinx
;
break:  mvi     a, BRKTIM       ; Time for break (in video frames)
        sta     brkctr
        lda     MNCMD
        ori     08h             ; Set break bit
        out     MNSTAT
; Fall through to exit
crtinx: mov     a, b            ; Recover saved character
        ret
;
; Get character from type-ahead buffer
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
; 
; Table of keypad key-codes
        db      081h, 082h, 083h, 085h
        db      08Dh, 0ACh, 0ADh, 0AEh
        db      0B0h, 0B1h, 0B2h, 0B3h
        db      0B4h, 0B5h, 0B6h, 0B7h
        db      0B8h
kpdcds: db      0B9h
;
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
        call    stpcrs          ; Step cursor
        ret
;
;  Address vrwen (row enables) array
varwen: lxi     h, vrwen        ; Start of vrwen
        mvi     d, 00h
        lda     vidrow
        mov     e, a            ; DE = which row
        dad     d               ; HL now points at correct row enable flag
        ret
;
scroll: lda     scrlck          ; Scroll-lock ?
        ora     a
        rnz                     ; Yes, return
        lda     TIMENB          ; Time displayed?
        ora     a
        JRZ     scrol2
;
scrol1: lda     vlinum          ; Is this dead code?
        sui     15h
        jp      scrol1          ; Result is unused
; 
scrol2: di                      ; No interrupts while updating
        lhld    vtopsl          ; Get pointer to top of sceen
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
        call    vidclr          ; Clear the top row
        lxi     h, vrwen
        mvi     m, 0ffh         ; and enable its display
        ret
;
; Address video RAM by multiplying row number
; by 80 (number of characters in row) and add the
; current vtopsl (top of screen) pointer
;
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
        ret
;
; Actually clear the row in video RAM and clear
; the vrwen flag for the row so the row is displayed
;
vclrow: call    vraddr          ; Address the RAM for this row
        mvi     b, CPR          ; Number to clear
        call    vidclr          ; Clear the row
        call    varwen          ; Address the vrwen array
        mvi     m, 0ffh         ; and set to display the row
        ret
;
; Clear B bytes of video RAM to ASCII space
; D is MS byte of address in video RAM
; HL points at start character in video RAM
;
vidclr: mov     c, b            ; Save B
        mvi     d, 0f8h
        push    h
; Clear video RAM
vidcl1  mov     a, d
        ora     h               ; Address in video RAM
        mov     h, a
        mvi     m, ' '          ; Save space character
        inx     h
        DJNZ    vidcl1
; 
        pop     h
        di                      ; No interrupts while
        lda     prta            ; updating attribute RAM
        ani     0dfh            ; PRTA[5] = 0 - Address attribute
        sta     prta
        out     PPIA
        ei
        mov     b, c            ; Recover B
; Clear attribute RAM
vidcl2: mov     a, h
        ani     4fh             ; Force address to be
        ori     48h             ;  4800h to 4fffh
        mov     h, a
        mvi     m, 00h          ; Clear attribute
        inx     h
        DJNZ    vidcl2
;
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
;
tglclk: lxi     h, KEYCLK       ; Toggle key click
        mov     a, m
        inr     a
        ani     01h
        mov     m, a
        ret
;
rngbel: mvi     a, 0dh          ; PPIC[6] = 1 (Bell on)
        out     PPICW
        mvi     a, BELTIM       ; Bell duration
        sta     belctr
        ret
;
vhtab:  call    stpcrs          ; Step cursor
        mov     a, l            ; Is horizontal position
        ani     07h             ; divisible by 8?
        JRNZ    vhtab           ; No, step again
        ret
; 
vcret:  call    vraddr          ; Carriage return
        shld    vcursr          ; Cursor to the left of current row
        mvi     a, 00h          ; Set column to zero
        sta     vidcol
        ret
;
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
; 
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
; 
; Step cursor
;
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
        cpi     LPF-1           ;   last row?
        JRNZ    stpcr1          ; No, go increment row
        push    h
        call    scroll
        pop     h
        JR      stpcr2
;
stpcr1: inr     h               ; Increment row
stpcr2: shld    rowcol          ; Update row-col
        ret
; 
vlfeed: lhld    vcursr          ; Cursor address
        lxi     d, CPR          ; Characters per row
        dad     d               ; Add
        shld    vcursr          ; Update cursor
        lda     vidrow          ; Current row
        cpi     LPF-1           ; On bottom row?
        JRNZ    vlfd1           ; No
        call    scroll          ; Yes, scroll screen
        ret
; 
vlfd1:  inr     a               ; Step row
        sta     vidrow          ; and update
        ret
; 
vclear: lxi     h, vrwen        ; Clear the video row-enable array
        mvi     b, LPF          ; Number of entries
        xra     a
vclr1:  mov     m, a
        inx     h
        DJNZ    vclr1           ; Loop over array
;
        call    vinipt          ; Initialise video pointers
        lxi     h, 0000h        ; Clear the first line
        mvi     b, CPR          ; All 80 characters
        call    vidclr          ; Go clear it
        lxi     h, vrwen        ; Enable
        mvi     m, 0ffh         ;  the first row
        ret
; 
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
;
; Initialize video pointers
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
;
; First character after ESC
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
;
; ESC Y or ESC = received
escsy: xra     a
        sta     escst2          ; Clear escst2
esc1x:  mvi     a, 02h
        sta     escst1
        ret
escstl: mvi     a, 0ffh         ; Set escst2
        sta     escst2
        JR      esc1x
;
esctwo: lda     escst2          ; Get state variable
        ora     a
        JRNZ    esctld
; Here for ESC Y ? or ESC = ?
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
;
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
; 
; ESC ~ ?
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
;
; Clear to end of row
; 
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
;
; Disk routine
; 
; Command in b:
;   0 - Restore
;   1 - Read
;   2 - Write with RAW verification
;   3 - (also write with RAW)
;   4 - Format
;   5 - Select drive 
;   6 - Write without RAW verification
;
; c  = disk   number
; d  = track  number
; e  = sector number
; hl = data pointer (but never used)
;
disk1:  shld    dskptr          ; Save data pointer (but this never used)
        SSPD    DSKSTK
        lxi     sp, STACK3
        mov     a, b
        cpi     00h             ; Restore
        JRZ     dnodat
        cpi     04h             ; Format
        JRZ     dnodat
        cpi     05h             ; Select
        JRZ     dselct
        cpi     01h             ; Read
        JRZ     dread
; Here for write
        push    d
        push    b
        call    hst2fp          ; Copy data to CPU2
        pop     b
        pop     d
dnodat: call    fparam          ; Send parameters
        call    fpwres          ; Wait for result
        call    fpstat          ; Get status to return
dexit:  LSPD    DSKSTK
        ret
;
dread:  push    h               ; Save data pointer (why is dskptr not used?)
        call    fparam          ; Send parameters
        call    fpwres          ; Wait for result
        pop     h               ; Recover data pointer
        call    fp2hst          ; Copy data from CPU2
        call    fpstat          ; Get status to return
        JR      dexit
;
dselct: call    fparam          ; Send parameters
        mvi     b, 80h
dslct1: push    h               ; Waste time for command to start
        pop     h
        dcr     b
        JRNZ    dslct1
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
        sta     FPYGO
        call    buscls
        ret
;
hst2fp: lxi     h, HSTBUF       ; Copy host buffer to CPU-2
        call    busopn
        lxi     d, FPYBUF
        lxi     b, PHYSEC
        LDIR
        call    buscls
        ret
;
fp2hst: call    busopn          ; Copy CPU-2 to host buffer
        lxi     d, HSTBUF
        lxi     h, FPYBUF
        lxi     b, PHYSEC
        LDIR
        call    buscls
        ret
;
fpstat: call    busopn          ; Get CPU-2 status
        lda     FPYSTS
        push    psw
        call    buscls
        pop     psw
        ret
;
busopn: mvi     a, 0ah          ; PPIC[5] Low
        out     PPICW
busbsy: in      PPIB            ; Wait for CPU2
        ral                     ; not busy
        JRC     busbsy
        mvi     a, 08h          ; PPIC[4] Low
        out     PPICW
        ret
;
buscls: mvi     a, 09h          ; PPIC[4] High
        out     PPICW
        mvi     a, 0bh
        out     PPICW           ; PPIC[5] High
        ret
;
        end
