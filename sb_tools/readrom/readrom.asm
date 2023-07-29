        MACLIB  Z80
;;;
PPIB    EQU     69h             ; 8255 port b
PPICW   EQU     6bh             ; 8255 control port
;;;
BOOT    EQU     0000h
BDOS    EQU     0005h
PRINTF  EQU     9
CLOSEF  EQU     16
DELETEF EQU     19
WRITEF  EQU     21
MAKEF   EQU     22
SETDMF  EQU     26
FCB     EQU     005ch
SECBUF  EQU     8000h
RDSUB   EQU     8100h
;;;
        ASEG
        org     100h
;;; Relocate readsc
        lxi     h, readsc
        lxi     d, RDSUB
        lxi     b, endrd-readsc
        LDIR
;;;
        lxi     d, SECBUF
        mvi     c, SETDMF
        call    BDOS
;;; 
        lxi     d, FCB
        mvi     c, DELETEF
        call    BDOS
        lxi     d, FCB
        mvi     c, MAKEF
        call    BDOS
        inr     a               ; 255 -> 0
        jz      error
;;;
        lxi     h,0000h
        mvi     a, 16
loop:   shld    addr
        sta     lpcnt
;;; HL already has source address
        lxi     d, SECBUF
        lxi     b, 128
;;; 
        call    RDSUB
        lxi     d, FCB
        mvi     c, WRITEF
        call    BDOS
        ora     a
        jnz     error
;;; 
        lhld    addr            ; Step source address
        lxi     b,128           ; by one sector's worth
        dad     b
        lda     lpcnt           ; Decrement loop counter
        dcr     a
        jnz     loop            ; Loop if more
;;;
        lxi     d, FCB
        mvi     c, CLOSEF
        call    BDOS
        inr     a
        jz      error
;;;
        jmp     BOOT            ; All done
;;;
error:  lxi     d,msg
        mvi     c, PRINTF
        call    BDOS
        jmp     BOOT
;;;
msg:    db      'error$'
lpcnt:  db      0
addr:   dw      0
;;;
;;; Read from the boot rom
;;; Note this is all relocatable code
readsc: mvi     a, 0ah          ; PPIC[5] Low
        out     PPICW
busbsy: in      PPIB            ; Wait for CPU2
        ral                     ; not busy
        JRC     busbsy
        mvi     a, 05h          ; PPIC[2] High - map ROM
        di
        out     PPICW
;;; Do the transfer
        LDIR
;;; Close the bus
        mvi     a, 04h          ; PPIC[2] Low - unmap ROM
        out     PPICW
        ei
        mvi     a, 0bh
        out     PPICW           ; PPIC[5] High
        ret
endrd:
        end

