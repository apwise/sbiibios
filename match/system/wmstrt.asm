        MACLIB  Z80
;
OFFSET  EQU     9400H           ; OFFSET FOR 64K = 9400H
                                ; OFFSET FOR 32K = 1400H
PHYSEC  EQU     512
BTADDR  EQU     0C780H          ; Bootstrap loader address
BTPLS1  EQU     BTADDR + PHYSEC ; One sector further on
TWOSEC  EQU     2 * PHYSEC      ; Address increment
;
DISKE   EQU     4A33H + OFFSET  ; Disk routine entry point
HSTBUF  EQU     6200h + OFFSET  ; DMA disk buffer
;
        org     5A80H + OFFSET
WMSTRT  lxi     b, 0000h        ; Restore command, disk 0
        call    DISKE
;
; Read CCP and BDOS back into memory
;
; A total of 12 physical sectors from C780 to DF7F
;
; Track 0, sectors 2, 4, 6, 8, 10 ...
        lxi     h, BTPLS1       ; One sector after boot address
        lxi     d, 0002h        ; Track 0, sector 2
        mvi     b, 01h          ; Read command
        mvi     c, 00h          ; Disk 0
even0:  call    rdnext
        inr     e               ; Step sector number
        inr     e               ; by two
        mov     a, e
        cpi     0ch             ; Beyond the required number?
        jnz     even0           ; Loop over sectors
        shld    tmpadr          ; Store address temporarily
;
; Track 0, sectors 1, 3, 5, 7, 9
        lxi     h, BTADDR       ; Boot address
        mvi     e, 01h          ; Start at sector 1
odd0:   call    rdnext
        inr     e               ; Step sector number
        inr     e               ; by two
        mov     a, e
        cpi     0bh             ; Beyond the required number?
        jnz     odd0            ; Loop over sectors
;
; Track 1, sector 1
        inr     d               ; Step track number to 1
        mvi     e, 01h          ; Start at sector 1
odd1:   call    rdnext
        inr     e               ; Step sector number
        inr     e               ; by two
        mov     a, e
        cpi     03h             ; Beyond the required number?
        jnz     odd1            ; Loop over sectors
;
; Track 1, sector 2
        mvi     e, 02h
        lhld    tmpadr          ; Recover address (after track 0, sector 10)
even1:  call    rdnext
        inr     e               ; Step sector number
        inr     e               ; by two
        mov     a, e
        cpi     04h             ; Beyond the required number?
        jnz     even1           ; Loop over sectors
        ret
;
rdnext: push    d
        push    b
        push    h
        shld    addr            ; Save address for use in hst2ad, below
        call    DISKE           ; Read a sector into the host buffer
        call    hst2ad          ; Copy to required address
        pop     h               ; Recover address
        lxi     d, TWOSEC       ; Add two sectors to the address pointer
        dad     d               ; thus skipping over one sector
        pop     b
        pop     d
        ret
;
hst2ad: lhld    addr            ; Recover address
        lxi     d, HSTBUF       ; Address of host buffer
        xchg                    ; Swap addresses
        lxi     b, PHYSEC       ; Size of copy
        LDIR                    ; Copy from host buffer to addr
        ret
;
tmpadr: ds      2               ; Space for holding address
addr:   ds      2               ; Address of current load
        end
