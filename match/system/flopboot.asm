;
; Floppy disk bootstrap loader
;
PHYSEC  EQU     512
BTADDR  EQU     0C780H          ; Bootstrap loader address
BTPLS1  EQU     BTADDR + PHYSEC ; One sector further on
BTPLS2  EQU     BTPLS1 + PHYSEC ; One sector further still
TWOSEC  EQU     2 * PHYSEC      ; Address increment
DREAD   EQU     0C003H          ; ROM BIOS routine to read a sector on floppy
COLDBT  EQU     0DE00H          ; CBIOS cold boot entry location
STACK   EQU     0F3FFH          ; Stack location while in bootstrap routine
;
        ORG     BTADDR
;
FLBOOT: NOP
        LXI     SP,STACK
        LXI     H,BTPLS1        ; Buffer that can be written safely
        LXI     B,0             ; Restore command, disk 0
        CALL    DREAD           ; Action the command (ignore returned data)
;
; The first two tracks of the disk are written linearly - without
; any sector skew. To avoid a complete rotation of the disk between
; each sector that is read, read every other sector.
;
; Track 0, sectors 2, 4, 6, 8, 10 ...
        LXI     H,BTPLS1        ; Immediately after sector read by ROM
        LXI     D,2             ; Track 0, sector 2
        MVI     B,1             ; Read command
        MVI     C,0             ; Disk 0
EVEN0:  CALL    RDNEXT
        INR     E               ; Step sector number
        INR     E               ; by two
        MOV     A,E
        CPI     12             ; Beyond the required number?
        JNZ     EVEN0           ; Loop over sectors
        SHLD    TMPADR          ; Store address temporarily
;
; Track 0, sectors 3, 5, 7, 9 (1 was already read)
        LXI     H,BTPLS2        ; Two sectors after that read by ROM
        MVI     E,3             ; Start at sector 3
ODD0:   CALL    RDNEXT
        INR     E               ; Step sector number
        INR     E               ; by two
        MOV     A,E
        CPI     11             ; Beyond the required number?
        JNZ     ODD0            ; Loop over sectors
; 
; Track 1, sectors  1, 3, 5, 7, 9
        INR     D               ; Step track number to 1
        MVI     E,1             ; Start at sector 1
ODD1:   CALL    RDNEXT
        INR     E               ; Step sector number
        INR     E               ; by two
        MOV     A,E
        CPI     11              ; Beyond the required number?
        JNZ     ODD1            ; Loop over sectors
;
; Track 1, sectors 2, 4, 6, 8, 10
        MVI     E,2
        LHLD    TMPADR          ; Recover address (after track 0, sector 10)
EVEN1:  CALL    RDNEXT
        INR     E               ; Step sector number
        INR     E               ; by two
        MOV     A,E
        CPI     12              ; Beyond the required number?
        JNZ     EVEN1           ; Loop over sectors
;
        JMP     COLDBT          ; Start CP/M
;
RDNEXT: PUSH    D
        PUSH    B
        PUSH    H
        CALL    DREAD           ; Read a sector into memory at HL
        POP     H
        LXI     D,TWOSEC        ; Add two sectors to the address pointer
        DAD     D               ; thus skipping over one sector
        POP     B
        POP     D
        RET
;
TMPADR: DS      2               ; Space for holding address
;
        END

