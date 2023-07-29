;
        MACLIB  Z80
;
PHYSEC  EQU     0200h           ; Physical sector size (512 bytes)
BTROMA  EQU     00400h          ; Address of boot code in ROM
BTSIZE  EQU     00400h          ; Size of boot code in ROM
BTRAMA  EQU     0c000h          ; Address of boot code in RAM
;
VERS    EQU     41
;
FCMND   EQU     08h             ; FDC1791 command
FSTAT   EQU     FCMND           ;   and status register
FTRACK  EQU     FCMND + 1       ; Track register
FSECTR  EQU     FCMND + 2       ; Sector register
FDATA   EQU     FCMND + 3       ; Data register
FCTRL   EQU     10h             ; 6-bit control register
; 
        ORG     0000h
        lda     btchk1          ; Has CPU-1 set this
        cpi     55h             ;   to the expected value?
        jnz     btcpu1          ; No, so this must be CPU-1
        lda     btchk2          ; Check another byte
        cpi     0aah            ;   and a different value
        jnz     btcpu1          ; No, it hasn't booted
        jmp     btcpu2          ; Yes, this must be CPU-2
;
btcpu1: lxi     h, BTROMA       ; CPU-1 boot code in ROM
        lxi     d, boot         ; Where to put it in RAM
        lxi     b, BTSIZE       ; Size of boot code
        LDIR                    ; Copy to RAM
        jmp     bootgo          ; And jump to boot in RAM
;
btcpu2: lxi     sp, fstack      ; Initialise stack pointer
        mvi     a, 00h          ; Clear:
        sta     btchk1          ;   boot-check flags
        sta     btchk2          ;     both of them
        sta     FPYGO           ;   floppy "go" bit
        sta     drvsel          ;   currently selected drive
        out     FCTRL           ;   the control register
;
; Surely this next instruction is a bug?
; It should be `mvi a, 2fh` - a "Force interrupt" command
; which aborts any ongoing command. It probably doesn't matter
; greatly because that's sent again immediately after the
; cmndlp, below, (which waits for a command from CPU-1).
; 
        lda     2fh             ; Should be a Force interrupt
        out     FCMND
nxtcmd: mvi     a, 00h          ; Clear format flag
        sta     fmtflg
        lxi     sp, fstack      ; Initialize stack
;
cmndlp: lda     FPYGO           ; Get "go" flag
        ora     a               ; Non-zero?
        jz      cmndlp          ; No, wait for command
;
        mvi     a, 2fh          ; ~2f = d0h = Terminate command
        out     FCMND           ; Stop any running command
        xra     a               ; A = 0
        sta     FPYGO           ; Clear the go byte
        sta     FPYSTS          ; Clear return status
        lda     fpydsk          ; Get disk number
        ani     03h             ; 0 to 3
        mov     b, a            ; Save
        inr     b               ; 1 to 4
        mvi     a, 02h          ; Bit indicating drive 0
cmnd1:  dcr     b               ; Decrement disk number
        jz      cmnd2           ; Done. 1-hot in A
        rlc                     ; Shift left
        jmp     cmnd1           ; Loop over drive numbers
cmnd2:  ani     1eh             ; Force bits other than disk sel. to zero
        sta     fpydsk          ; Save
        lda     fpytrk          ; Get complemented track number
        cma                     ; Get true track number
        sbi     35              ; Subtract # tracks
        jm      cmnd3           ; -ve, then must be on side 0
        cma                     ; Convert back to complement form
        sta     fpytrk          ; Save the track
        lda     fpydsk          ; Recover the disk select value
        ori     20h             ; Select side 1
        sta     fpydsk          ; and store again
cmnd3:  lda     fpydsk          ; Recover disk select and side
        ori     01h             ; OR-in the busy bit that CPU-1 can see
        out     FCTRL           ; and set on the port.
        lda     fpycmd          ; Get the selected command
        cpi     05h             ; Select ?
        jz      select          ;   yes...
        cpi     04h             ; Format ?
        jz      format          ;   yes...
        cpi     01h             ; Read ?
        jz      read            ;   yes...
        jp      write           ; >1, is a write
;
; Command byte < 1 - Restore
        lxi     h, 0005h        ; Retry set to 5 (6 tries)
        shld    retryc
restr1: lda     fpydsk          ; Recover disk selection
        ani     1eh             ; Mask bits
        sta     drvsel          ; Save
        call    restor          ; Try to restore
        ora     a               ; Set flags (why?)
        ani     1ch             ; Mask bits
        xri     04h             ; Flip the track 0 bit
        sta     FPYSTS          ; Save as status
        jz      gdexit          ; If zero, good exit
        lxi     h, retryc       ; Point at retry counter
        mov     a, m            ; Load
        ora     a               ; Test
        jz      bdexit          ; If it's already zero - bad exit
        dcr     m               ; Decrement
        call    stepin          ; Move the heads in
        call    stepin          ;   ...
        jmp     restr1          ; Retry
;
restor: lda     fpycmd          ; Recover the command
        ora     a               ; Set flags
        jp      restr2          ; All +ve values - don't verify 
        mvi     a, 0f3h         ; ~f3 = 0c = Restore and verify
        jmp     restr3          ; -ve: with verify
; 
restr2: mvi     a, 0f7h         ; ~f7 = 08 = Restore
restr3: out     FCMND
        call    ldelay          ; Long delay
        call    ldelay          ;   ...
        call    ldelay          ;   ...
        call    ldelay          ;   ...
        nop                     ; Space to patch delay
        nop
        nop
        call    wtdone          ; Wait for command done
        ret
;
; Read
read:   sub     a               ; A = 0 - a read
        lxi     h, 0019h        ; Retries 0w, 25r
        jmp     rdwrt
;
; Write
write:  mvi     a, 01h          ; Flag it's a write
        lxi     h, 0500h        ; Retries 5w, 0r
; Read/write common code
rdwrt:  shld    rwrtry          ; Save retries
        sta     wrtflg          ; Save R/W flag 0 = read, 1 = write
rdwrt1: lda     drvsel          ; Get currently selected drive
        mov     d, a            ; Save
        lda     fpydsk          ; Get required drive
        ani     1eh             ; Lose busy and side bits
        cmp     d               ; Compare with current
        jz      seek            ; Disk already selected
; 
        lda     fpydsk          ; Get required disk
        ani     1eh             ; Lose busy and side bits
        sta     drvsel          ; Save as currently selected drive
chktrk: call    readad          ; Read address
        jz      chktr1          ; All good, go select track
        call    stpout          ; Try moving the heads out
        call    readad          ;   and reading address again
        jz      chktr1          ; All good, go select track
        call    restor          ; Try a restore
        call    readad          ;   and read the address once more
        jz      chktr1          ; All good, go select track
        jmp     bdexit          ; Can't access this drive - exit
; 
chktr1: in      FSECTR          ; Read address put track # in FSECTR
        out     FTRACK          ; Put it into track
        call    sdelay          ; Short delay
seek:   lhld    fpysec          ; L = sec, H = trk
        mov     c, l            ; Save sector
        in      FTRACK          ; Get actual track
        cmp     h               ; Compare desired
        jz      seek1           ; If they match, go deal with sector
; On wrong track
        mov     a, h            ; Get desired track
        out     FDATA           ; Output to FDC 
        call    sdelay          ; Short delay
        mvi     a, 0e7h         ; ~e7 = 18 = Seek
        out     FCMND
        call    ldelay          ; Long delay
        call    ldelay          ;   ...
        call    ldelay          ;   ...
        call    ldelay          ;   ...
        nop                     ; Space to patch delay...
        nop
        nop
        nop
        nop
        nop
        call    wtdone          ; Wait for command done
        jmp     chktrk          ; Check the track is correct
; 
seek1:  mov     a, c            ; Recover desired sector
seek2:  out     FSECTR          ; To FDC
        call    sdelay          ; Short delay
        lxi     h, FPYBUF       ; Point at data buffer
        lda     wrtflg          ; Reading or writing?
        ora     a
        jnz     wrtsec          ; Go write the sector
;
        mvi     a, 77h          ; ~77 = 88h = Read Sector
        out     FCMND
        call    sdelay          ; Short delay
        lda     fpycmd          ; Get overall command
        sui     02h             ; Is it a write (hence verify)
        jm      rddata          ; No, go actually read the data
rdvrf   call    wtdrq           ; Yes, wait for data
        in      FDATA           ;   read it, but ignore
        jmp     rdvrf           ;   loop over sector
rddata: call    wtdrq           ; Wait for data
        in      FDATA           ;   read it
        mov     m, a            ;   save in buffer
        inx     h               ;   step pointer
        jmp     rddata          ;   loop over sector
;
; Wait for DRQ, checking still busy
; If status goes not busy then don't return to caller,
; but to caller's caller.
wtdrq:  in      FSTAT           ; Get (inverted) status
        rar                     ; Move bit 1 (DRQ)
        rar                     ; into the carry
        rnc                     ; Return if DRQ = 1
        ral                     ; Busy to carry bit
        jnc     wtdrq           ; Loop if still busy
; Gone not busy
        lda     fmtflg          ; Called from format?
        ora     a
        jnz     retcsc          ; Yes, return to format
        pop     h               ; No, discard return address
        jmp     rdwrst          ; Deal with status
; 
wrtsec: cpi     03h             ; Compare wrtflg to 3 (but it can never be 3)
        mvi     a, 57h          ; ~57 = a8 = Write sector, side 1
        jnz     wrtsc1          ; Command diff irrelevant since compare flag = 0 
        mvi     a, 50h          ; ~50 = a0 = Write sector, side 0
wrtsc1: out     FCMND           ; Send command
        call    sdelay          ; Short delay
wrtsc2: call    wtdrq           ; Wait for data ready
        mov     a, m            ; Pick up data from buffer
        out     FDATA           ; Write to FDC
        inx     h               ; Step pointer
        jmp     wrtsc2          ; Loop over data
;
; Read/write status
rdwrst: mvi     c, 7ch          ; Mask status error bits (write)
        lda     wrtflg          ; Read/write flag
        ora     a               ; Set flags
        jnz     rdwrs1
        mvi     c, 1ch          ; Mask status error bits (read)
rdwrs1: call    wtdone          ; Wait for done
        ana     c               ; Mask returned status
        sta     FPYSTS          ; Save for return
        jz      rdwrdn          ; Read or write done
        lxi     h, rwrtry       ; Point at retry count
        lda     wrtflg          ; Write?
        ora     a
        jz      rdagn                   ;01d9 ca e4 01         jz 01e4h
        inx     h               ; Point at write retry count
        dcr     m               ; Decrement
        jz      bdexit          ; No more retries, bad exit
        jmp     rdwrt1          ; Try write again
; 
rdagn:  dcr     m               ; Decrement read retry count
        jnz     rdwrt1          ; Try read again
        lda     fpycmd          ; Get overall command
        cpi     01h             ; Is it a read?
        jnz     wragn           ; No, verify failed, write again?
        jmp     bdexit          ; Yes, bad exit
; 
wragn:  inx     h               ; Point at write retry counter
        dcr     m               ; Decrement
        jz      bdexit          ; No more retries, bad exit
        mvi     a, 01h          ; Set the write flag
        sta     wrtflg          ;   again
        jmp     rdwrt1          ; Try the write another time
; 
rdwrdn: lda     fpycmd          ; Get overall command
        cpi     06h             ; Write without verify?
        jz      gdexit          ; Yes, good exit
        ora     a               ; Set flags (why?)
        sbi     02h             ; < 2 ?
        jm      gdexit          ; Yes, was a read - good exit
        lxi     h, wrtflg       ; Point at write flag
        sub     a               ; A = 0
        cmp     m               ; Write flag already clear?
        jz      gdexit          ; Yes, good exit
        mov     m, a            ; Clear flag
        mvi     a, 0ah          ; Reset retry count to 10
        sta     rwrtry
        lda     fpysec          ; Pick up required sector
        jmp     seek2           ; Go do the verify read
;
; Error return from command
bdexit: lda     FPYSTS          ; Set status
        ori     01h             ;   non-zero
        sta     FPYSTS          ; Fall-though to exit
; Good return from command
gdexit: mvi     a, 2fh          ; Force interrupt
        out     FCMND           ; Terminate any ongoing command
        call    sdelay          ; Wait a moment
        lda     fpydsk          ; Get current FCTRL value
        ani     3eh             ; Remove busy bit (to CPU-1)
        out     FCTRL           ; Output to signal done
        jmp     nxtcmd          ; Go and wait for next command
;
; Read address
readad: lxi     h, 000ah        ; Set retry counter to 10
        shld    retryc
reada1: lxi     d, 0a000h       ; Timeout value
        lxi     h, rdabuf       ; Buffer for read address
        mvi     a, 3bh          ; ~3b = c4 = Read address, with 15ms delay
        out     FCMND
reada2: dcx     d               ; Decrement timeout
        mov     a, e
        ora     d
        jz      toxprd          ; Zero - Timeout expired
        in      FSTAT           ; Get status
        rar                     ; DRQ
        rar                     ;   to the carry bit
        jc      reada2          ; Loop to wait for data
reada3: in      FDATA           ; Get data 
        mov     m, a            ; Store in buffer
        inx     h               ; Step pointer
reada4: in      FSTAT           ; Get status
        rar                     ; DRQ
        rar                     ;   to the carry bit
        jnc     reada3          ; Go read the data
        ral                     ; Busy to the carry bit
        jnc     reada4          ; Still busy - loop for DRQ
; 
        call    wtdone          ; Wait for command done
        ani     0ch             ; Mask status bits
        sta     FPYSTS          ; Save return status
        rz                      ; All good, return
        lxi     h, retryc       ; Point at retry counter
        dcr     m               ; Decrement
        jnz     reada1          ; Loop for retries
        lda     FPYSTS          ; Recover the (errored) status
        ora     a               ; Set flags
        ret
;
; Wait for busy to go low, with long timeout
; (don't understand action on timeout)
wtdone: mvi     l, 05h          ; Short delay
wtdon1: dcr     l               ;   around 25us
        jnz     wtdon1          ;   ...
;
        lxi     h, 0000h        ; Long timeout
wtdon2: dcx     h               ; Decrement timeout counter
        mov     a, h            ; Are both
        ora     l               ;   bytes zero?
        jnz     wtdon4          ; No, continue waiting
; 
toxprd: inr     a               ; A = 1
        rrc                     ; A = 80h
        sta     FPYSTS          ; To status
        jmp     bdexit          ; Exit command
; 
wtdon4: in      FSTAT           ; Get complemented status
        cma                     ; True status
        rar                     ; Busy to carry bit
        jc      wtdon2          ; Still busy, loop
        ral                     ; Recover status
        push    psw             ; Save
        mvi     a, 2fh          ; Terminate command
        out     FCMND
        pop     psw             ; Recover status
        ret
;
; Select, write fpydsk[4:1] to FCTRL, return success
select: lda     fpydsk          ; Get argument
        ani     3eh             ; Isolate bits
        out     FCTRL           ; Write to control register
        xra     a               ; Clear
        sta     FPYSTS          ;   the return status
        jmp     nxtcmd          ; Go and wait for the next command
;
; Long delay
; Each iteration is 45 T states
; totalling 276480 T states, or not quite 70 ms
ldelay: lxi     h, 1800h        ; # Loop iterations
ldel1:  push    h               ; 11 T states
        pop     h               ; 10 T states
        dcx     h               ;  6 T states
        mov     a, h            ;  4 T states
        ora     l               ;  4 T states
        jnz     ldel1           ; 10 T states
        ret
;
; Format
format: mvi     a, 0ffh
        sta     fmtflg          ; Flag this is a format
        lda     fpydsk          ; Get disk select value
        ani     1eh             ; Lose busy and side select bits 
        sta     drvsel          ; Save
        lxi     b,0ff01h        ;  1 * 00h - Side 0
        SBCD    sidebt          ; For use in ID field
        lda     fpydsk          ; Get disk select value
        ani     20h             ; Isolate side select
        jz      frmt1
        lxi     b, 0fe01h       ;  1 * 01h - Side1
        SBCD    sidebt
frmt1:  lda     fpytrk          ; Get track
        mov     d, a            ; Save for use in ID field
        in      FTRACK          ; Get current track
        cmp     d               ; Same 
        jz      frmt2           ; Yes, start format track
        mov     a, d            ; Recover desired track
        out     FDATA           ; Write to Data Register
        mvi     a, 0e7h         ; ~e7 = 18h = Seek
        out     FCMND
        call    wtdone          ; Wait for seek done
        call    ldelay          ; And a little longer
frmt2:  mvi     e, 0feh         ; ~fe = 01h = first sector number
        mvi     h, 0ah          ; 10 sectors
        mvi     a, 0bh          ; ~0b = f4 = Write track
        out     FCMND
        lxi     b, 0b128h       ; 40 * 4eh (Gap 5)
        call    wrtbyt
fmtsec: lxi     b, 0b110h       ; 16 * 4eh \
        call    wrtbyt          ;           } Gap1 / 3
        lxi     b, 0ff0ah       ; 10 * 00h /
        call    wrtbyt
        lxi     b, 0a03h        ;  3 * f5h (Write A1)
        call    wrtbyt
        lxi     b, 0101h        ;  1 * feh (ID AM)
        call    wrtbyt
        mov     b, d            ; Recover track number
        mvi     c, 01h          ;  1 * track
        call    wrtbyt
        LBCD    sidebt          ;  Side number
        call    wrtbyt
        mov     b, e            ; Recover sector number
        mvi     c, 01h          ;  1 * sector
        call    wrtbyt
        lxi     b, 0fd01h       ;  1 * 02h = 512 byte sector
        call    wrtbyt
        lxi     b, 0801h        ;  1 * f7h (CRC)
        call    wrtbyt
        lxi     b, 0b116h       ; 22 * 4eh \
        call    wrtbyt          ;           } Gap 2
        lxi     b, 0ff0ch       ; 12 * 00h /
        call    wrtbyt
        lxi     b, 0a03h        ;  3 * f5h (Write A1)
        call    wrtbyt
        lxi     b, 0501h        ;  1 * fah (Data AM) [** Not fb **]
        call    wrtbyt
        lxi     b, 0e5ffh       ;255 * 1ah (Data field)
        call    wrtbyt
        mvi     c, 0ffh         ;255 more
        call    wrtbyt
        mvi     c, 02h          ;  2 more to total 512
        call    wrtbyt
        lxi     b, 0801h        ;  1 * f7h (CRC)
        call    wrtbyt
        dcr     e               ; Step the (inverted) sector number
        dcr     h               ; Step the sector counter
        jnz     fmtsec          ; Loop over sectors
        lxi     b, 0b1ffh       ;255 * 4eh
        call    wrt2ix          ; Send until index mark
        mvi     c, 0ffh         ;255 more
        call    wrt2ix          ; Send until index mark
        in      FSTAT           ; Get complemented status
        cma                     ; True status
        ani     22h             ; Write fault or DRQ
        sta     FPYSTS          ; Returned status
        jnz     bdexit          ; Nonzero - bad exit
        mvi     a, 2fh          ; Terminate command
        out     FCMND
        call    sdelay          ; Short delay
        jmp     gdexit          ; Good exit
;
; Write c copies of byte b
; 
wrtbyt: in      FSTAT           ; Get (inverted) status
        rar                     ; Move bit 1 (DRQ)
        rar                     ; into the carry
        jc      wrtbyt          ; Loop if DRQ == 0
        mov     a, b            ; Get data byte
        out     FDATA           ; Output
        dcr     c               ; Decrment repeat counter
        jnz     wrtbyt          ; Loop over repeats
        ret
;
; Write at most c copies of byte b, stop at index mark
;
wrt2ix: call    wtdrq           ; Wait for data ready
        mov     a, b            ; Get data byte
        out     FDATA           ; Output
        dcr     c               ; Decrement repeat counter
        jnz     wrt2ix          ; Loop over repeats
        ret
; 
retcsc: pop     b               ; Discard return address
        ret                     ; Return to caller's caller
; 
stepin: EXX
        mvi     a, 0a7h         ; ~a7 = 58 = Step In
        out     FCMND
        call    wtdone          ; Wait for done
        ani     00h             ; Ignore errors 
        EXX
        jnz     bdexit          ; Will never jump
        ret
; 
stpout: EXX
        mvi     a, 87h          ; ~87 = 78 = Step out
        out     FCMND
        call    wtdone          ; Wait for done
        ani     00h             ; Ignore errors
        EXX
        jnz     bdexit          ; Will never jump
        ret
;
; Short delay
;
; With a call (17 Tstates) this is
; 34 + 5 * 14 = 104 T states, or about 26us
sdelay: mvi     a, 05h          ;  7 T states
sdel1:  dcr     a               ;  4 T states
        jnz     sdel1           ; 10 T states
        ret                     ; 10 T states
;
        ORG     8800h
        RAMSZ   EQU     00400h
btchk1: ds      1               ; Boot check byte
btchk2: ds      1               ; Boot check byte
fpycmd: ds      1               ; Command for CPU-2 floppy driver
FPYPRM  EQU     fpycmd          ; 4-byte parameter block
fpydsk: ds      1               ; Disk
fpysec: ds      1               ; Complemented sector number
fpytrk: ds      1               ; Complemented track number
drvsel: ds      1               ; Drive select (persists over commands)
FPYGO:  ds      1               ; Go byte (FF = "go")
FPYBUF: ds      PHYSEC          ; 512-byte sector buffer
rwrtry: ds      2               ; Read/write sector retry counts
wrtflg: ds      1               ; Whether writing
FPYSTS: ds      1               ; Returned status byte
fmtflg: ds      1               ; Whether formatting
retryc: ds      2               ; Restore/read address retry count
rdabuf: ds      10              ; Buffer for read address command
sidebt: ds      2               ; Side select byte pair (format)
fstack  EQU     btchk1+RAMSZ-1  ; Stack for CPU-2 running from ROM
; 
STACK   EQU     0f3ffh
LPF     EQU     24              ; No. of rows on crt
CPR     EQU     80              ; No. of chars per row
;
INTRST  EQU     48h             ; Reset interrupt latch
PPIA    EQU     68h             ; 8255 port a
PPIB    EQU     69h             ; 8255 port b
PPIC    EQU     6ah             ; 8255 port c
PPICW   EQU     6bh             ; 8255 control port
TOPSEL  EQU     02h             ; CRTC top of page register
ROWSTR  EQU     01h             ; CRTC row start register
CURSOR  EQU     03h             ; CRTC cursor register
;
; Locations in CPU-2 RAM concerned with floppy disks
;
;
BTSTRP  EQU     0c780h          ; Bootstrap loader address
;
        ORG     BTRAMA
boot:   jmp     bootgo          ; Main entry point
DREAD:  jmp     dread1          ; Disk read entry point
bootgo: di                      ; Disable interrupts during boot
        lxi     sp, STACK       ; Initial stack pointer
; 
        mvi     a, 82h          ; A & C upper: Basic I/O, both output
        out     PPICW           ; B & C lower: Basic I/O, C output, B input
; 
        mvi     a, 2ah          ; Bell off, Req Bus, Map CPU-2 RAM
        out     PPIC            ; CPU-2 reset, ROM not mapped, blank video
; 
        mvi     a, 60h          ; Nrm video, 60Hz, Not addr attribute RAM
        sta     prta            ; Normal screen character set
        out     PPIA            ; Save value for later use
; 
        mvi     a, 08h          ; PPIC[4] = 0
        out     PPICW           ; Map CPU-2 RAM (it already is)
; 
        mvi     a, 55h          ; Mark that CPU-1 has booted
        sta     btchk1
        mvi     a, 0aah         ; And again in this byte
        sta     btchk2          ; (Allows CPU-2 to determine which code to run)
; 
        mvi     a, 0b2h         ; ACK keyboard, Bell off, Release CPU-2 bus
        out     PPIC            ; Unmap CPU-2 RAM, allow CPU-2 to boot
;
; Clear the video attribute RAM
; 
        mvi     a, 40h          ; Map attribute RAM
        out     PPIA
;
        lxi     h, 4800h        ; Address of RAM
        lxi     d, 0800h        ; Its size
clatr1: xra     a               ; Clear A
        mov     m, a            ;   and attribute RAM location
        inx     h               ; Step pointer
        dcx     d               ; Decrement cpunter
        mov     a, d            ; Check both 
        ora     e               ;   bytes
        jnz     clatr1          ; Loop over attrinute RAM
;
        mvi     a, 60h          ; Unmap attribute RAM
        out     PPIA
;
; Clear the video RAM
; 
        lxi     h, 0f800h       ; Base of video DRAM
        lxi     d, 0800h        ; Its size
clvid1: mvi     a, 20h          ; ASCII space
        mov     m, a            ;   write to video DRAM
        inx     h               ; Step pointer
        dcx     d               ; Decrement counter
        mov     a, d            ; Check both
        ora     e               ;   bytes
        jnz     clvid1          ; Loop over video DRAM
; 
; Set up an interrupt vector
; 
        mvi     a, 0c3h         ; JMP instruction
        sta     0038h           ; Save at interrupt vector
        lxi     h, intrp        ; Address of ISR
        shld    0039h           ; Complete JMP instruction
;
        lxi     h, 0000h        ; Set all video RAM pointers
        shld    rowcol          ; To start of video RAM
        shld    vcursr          ;   ...
        shld    vtopsc          ;   ...
        shld    vtopsl          ;   ...
;
; Clear array that holds copy of video row enable flags
        lxi     h, vrwenc       ; Address of array
        mvi     b, LPF+1        ; Size
        mvi     a, 00h          ; Value to write
clenc1: mov     m, a            ; Write an element
        inx     h               ; Step pointer
        dcr     b               ; Decrement Counter
        jnz     clenc1          ; Loop over array
;
; Clear array of video row enable flags
        lxi     h, vrwen        ; Address of array
        mvi     b, LPF+1        ; Size
        mvi     a, 00h          ; Value to write
clen1:  mov     m, a            ; Write an element
        inx     h               ; Step pointer
        dcr     b               ; Decrement Counter
        jnz     clen1           ; Loop over array
;
        sta     escst1          ; Clear flags (this one unused)
        sta     vtrans          ; (this one unused)
; 
        call    ivsync          ; Set up CRTC address pointers
        out     INTRST          ; Clear any pending video interrupt
        IM1                     ; Select interrupt mode
        ei                      ; Enable interrupts
        jmp     load            ; Go to the boot loader
;
prnmsg: lxi     h, signon       ; Print the sign-on message
        call    print
        ret
;
print:  mov     a, m            ; Get character
        push    h               ; Save pointer
        call    crtout          ; Print character
        pop     h               ; Restore pointer
        mov     a, m            ; Recover character
        ora     a               ; Set flags
        rm                      ; Top bit set, return
        inx     h               ; Step pointer
        jmp     print           ; Loop over message
;
signon: db      VERS/10+'0','.',VERS MOD 10+'0'
        db      '   '
        db      'INSERT DISKETTE INTO DRIVE '
        db      'A'+80h
;
load:   lxi     b, 0ff00h       ; Restore & verify command, Disk 0
        call    fparam          ; Send parameters
        call    fpwres          ; Wait for result
        call    fpstat          ; Get status
        ani     80h             ; Failed?
        jz      ldbtst          ; No, go read bootstrap
        call    prnmsg          ; Yes, print "Insert disk" message
;
waitfp: lxi     b, 0000h        ; Restore command, Disk 0
        call    fparam          ; Send parameters
        call    fpwres          ; Wait for result
        call    fpstat          ; Get status
        ani     80h             ; Failed...
        jnz     waitfp          ; Wait until floppy in drive
;
ldbtst: lxi     h, BTSTRP       ; Bootstrap loader address
        lxi     d, 0001h        ; Track 0, Sector 1
        lxi     b, 0100h        ; Read command, Disk 0
        call    dread1          ; Read the sector
        jmp     BTSTRP          ; Jump to the bootstrap loader
;
; Interrupt Service Routine
intrp:  push    h               ; Save registers
        push    d
        push    b
        push    psw
        in      PPIB
        ani     04h             ; Vertical sync?
        jz      ihsync          ; No, deal with horizontal sync
        call    ivsync          ; Yes, deal with vertical sync
intrpx: in      INTRST          ; Acknowledge interrupt
        pop     psw             ; Restore registers
        pop     b
        pop     d
        pop     h
        ei
        RETI
;
ihsync: call    vseten          ; Set blanking for the next row
        jmp     intrpx          ; Exit interrupt routine
; 
crtout: ani     7fh             ; Lose top bit
        mov     b, a            ; Save character
        sui     20h             ; Test that it's printable
        jm      vidctl          ; No, test for control chars
        mov     a, b            ; Recover character
        call    vdsply          ; Display it
        ret
;
vidctl: cpi     0ah             ; LF/CTRL-J - (Cursor down)
        jz      vlfeed
        cpi     0dh             ; CR
        jz      vcret
        ret
;
vseten: lhld    vrwenp          ; Point into vrwenc array
        mov     a, m            ; Pick up flag for current line
        inx     h               ; Step pointer
        shld    vrwenp          ; Save for next line
        ora     a               ; Test flag
        jz      vrwbln
        mvi     a, 02h          ; PPIC[1] = 0 Display video row
        out     PPICW
        ret
;
vrwbln: mvi     a, 03h          ; PPIC[1] = 1 Blank video row
        out     PPICW
        ret
;
ivsync: call    vidpts          ; Send video pointers to controller
;
        lxi     h, vrwen        ; Copy array from vrwen to vrwenc
        lxi     d, vrwenc
        lxi     b, LPF+1        ; 25 bytes
        LDIR
        lxi     h, vrwenc       ; Start of (copy of) enable array
        shld    vrwenp          ; Initialize pointer for the frame
        call    vseten          ; Set blanking for the first row
; 
        lda     krptct          ; Decrement
        dcr     a               ; the keyboard repeat counter 
        sta     krptct          ; (does nothing in this code)
        lda     belctr          ; Decrement bell counter
        dcr     a
        sta     belctr
        rnz                     ; Return, leaving the bell on for now
        mvi     a, 0ch          ; PPIC[6] = 0 (Bell off)
        out     PPICW
        ret
;
vdsply: sta     vidchr          ; Save character
        call    varwen          ; Address vrwen array
        mov     a, m            ; Is it enabled?
        ora     a
        cz      vclrow          ; No, clear row then enable it
        lhld    vcursr
        mov     a, h            ; Get cursor address
        ori     0f8h            ; Force pointer into video RAM
        mov     h, a
        lda     vidchr          ; Recover character to display
        mov     m, a            ; Put character in video RAM
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
scroll: di                      ; No interrupts while updating
        lhld    vtopsl          ; Get pointer to top of screen
        lxi     d, CPR          ; Add row length
        dad     d
        shld    vtopsl          ; Update top of screen
        lxi     h, vrwen+1      ; Copy from vwren[1..23]
        lxi     d, vrwen        ;        to vwren[0..22]
        lxi     b, LPF          ; 23 to move [24 is off-by-one bug]
        LDIR                    ; Do the copy
        mvi     a, 0            ; Clear...
        stax    d               ;              vwren[23] [actually 24]
        ei
        ret
;
; Address video RAM by multiplying row number by 80 (number of
; characters in row) and add the current vtopsl (top of screen) pointer
;
vraddr: lxi     h, tmul80       ; Point at multiply by 80 table
        lda     vidrow          ; Pick up row number
        rlc                     ; Multiply by two (to address words)
        mov     e, a            ; Move to DE
        mvi     d, 00h
        dad     d               ; Add table base
        mov     e, m            ; Pick up multiply result LSB
        inx     h
        mov     d, m            ; and MSB
        lhld    vtopsl          ; Start of top row
        dad     d               ; Add in (row * 80)
        ret
;
tmul80: dw      0000h           ; Table of # * 80
        dw      0050h
        dw      00a0h
        dw      00f0h
        dw      0140h
        dw      0190h
        dw      01e0h
        dw      0230h
        dw      0280h
        dw      02d0h
        dw      0320h
        dw      0370h
        dw      03c0h
        dw      0410h
        dw      0460h
        dw      04b0h
        dw      0500h
        dw      0550h
        dw      05a0h
        dw      05f0h
        dw      0640h
        dw      0690h
        dw      06e0h
        dw      0730h
        dw      0780h      
;
vclrow: call    vraddr          ; Address the RAM for this row
        mvi     d, CPR          ; Number to clear
vclrw1: mvi     a, 0f8h
        ora     h               ; Force address into video RAM
        mov     h, a
        mvi     m, 20h          ; ASCII space
        inx     h               ; Write video RAM character
        dcr     d               ; Decrement counter
        jnz     vclrw1          ; Loop over row
;
        call    varwen          ; Address the vrwen array
        mvi     m, 0ffh         ; and set to display the row
        ret
;
vidpts: lhld    vtopsl          ; Take copy of video top select
        shld    vtopsc
        xchg
        lhld    vcursr          ; Cursor position
        mov     a, h
        ani     0fh             ; Limit to 12-bit address (but why not 11-bit since it's 2K?)
        mov     h, a
        mov     a, d
        ani     0fh
        mov     d, a
        mvi     a, 01h          ; PPIC[0] = 1 swap addr and data buses
        out     PPICW
        mvi     a, CURSOR
        mov     m, a            ; Set cursor address
        mvi     a, ROWSTR
        xchg
        mov     m, a            ; Set row start (for first row)
        mvi     a, TOPSEL
        mov     m, a            ; which is also the top of screen
        mvi     a, 00h          ; PPIC[0] = 0 - addr/data bus back to norma
        out     PPICW
        ret
;
stpcrs: lhld    vcursr          ; Step cursor
        inx     h               ; Increment cursor address
        shld    vcursr
        lhld    rowcol          ; Get row-col
        inr     l               ; Increment column
        mov     a, l
        cpi     CPR             ; Past end of line?
        jnz     stpcr2          ; No, still in the same line
        mvi     l, 00h          ; Clear column
        mov     a, h            ; Get row
        cpi     LPF             ;   last row? [off-by-one bug]
        jnz     stpcr1          ; No, go increment row
        push    h
        call    scroll
        pop     h
        jmp     stpcr2
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
        cpi     LPF             ; On bottom row? [off-by-one bug]
        jnz     vlfd1           ; No
        sta     vidrow
        call    scroll          ; Yes, scroll screen
        ret
;
vlfd1:  inr     a               ; Step row
        sta     vidrow          ; and update
        ret
;
vcret:  call    vraddr          ; Carriage return
        shld    vcursr          ; Cursor to the left of current row
        mvi     a, 00h          ; Set column to zero
        sta     vidcol
        ret
;
dread1: push    h               ; Save data pointer
        call    fparam          ; Send parameters
        call    fpwres          ; Wait for result
        pop     h               ; Recover data pointer
        call    fp2hst          ; Copy data from CPU-2
        call    fpstat          ; Get status to return
        ani     01h             ; Reduce to error flag
        ret
;
fparam: call    busopn          ; Send params
        lxi     h, FPYPRM
        mov     m, b            ; Command byte
        inx     h
        mov     m, c            ; Disk number
        inx     h
        mov     a, e
        cma                     ; ~sector number
        mov     m, a
        inx     h
        mov     a, d
        cma
        mov     m, a            ; ~track number
        mvi     a, 0ffh
        sta     FPYGO
        call    buscls
        ret
;
hst2fp: call    busopn          ; Copy host buffer to CPU-2
        lxi     d, FPYBUF       ; (This function is unused)
        lxi     b, PHYSEC
        LDIR
        call    buscls
        ret
;
fp2hst: call    busopn          ; Copy CPU-2 to host buffer
        xchg
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
fpwres: in      PPIB            ; Wait for FPY command to complete
        ani     20h
        jz      fpwres          ; Wait for PPIB[5] to go high
fpwr2:  in      PPIB
        ani     20h
        jnz     fpwr2           ; Wait for PPIB[5] to go low
        ret
;
busopn: mvi     a, 0ah          ; PPIC[5] Low
        out     PPICW
busbsy: in      PPIB            ; Wait for CPU-2
        ral                     ; not busy
        jc      busbsy
        mvi     a, 08h          ; PPIC[4] Low
        out     PPICW
        ret
;
buscls: mvi     a, 09h          ; PPIC[4] High
        out     PPICW
        mvi     a, 0bh          ; PPIC[5] High
        out     PPICW
        ret
;
        ds      1               ; (unused)
rowcol: ds      2
vidcol  EQU     rowcol          ; Low byte is column
vidrow  EQU     rowcol+1        ; High byte is row
vcursr: ds      2
vtopsc: ds      2
vtopsl: ds      2
vidchr: ds      1
vrwenp: ds      2
vrwenc: ds      LPF+1
vrwen:  ds      LPF+1
belctr: ds      1
krptct: ds      1
        ds      1               ; (unused)
escst1: ds      1
vtrans: ds      1
        ds      2               ; (unused)
prta:   ds      1
        END

