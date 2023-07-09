;        .TITLE  'SUPERBRAIN BIOS FOR QUAD DENSITY VER 3.1 64K DOS; CPM VER 2.2 (QD31BIOS.ASM) 05/08/81'
;
;
;*******  DISKS 'A' AND 'B' MUST BE 512 BYTES/SECTOR  ************
;
;
OFFSET  EQU     9400H           ;OFFSET FOR 64K = 9400H
                                ;OFFSET FOR 32K = 1400H
HSTBUF  EQU     6200H+OFFSET    ;DMA DISK BUFFER
STACK   EQU     5FFFH+OFFSET    ;STACK WHEN LOADING
STACK1  EQU     5FDFH+OFFSET    ;STACK DURING INTERRUPT
STACK2  EQU     5FBFH+OFFSET    ;STACK DURING CONOUT; DISK ROUTINES
STACK3  EQU     5F9FH+OFFSET
DIRBUF  EQU     5E80H+OFFSET    ;128 BYTES FOR DISK DIRECTORY
DISK    EQU     500FH+OFFSET
INIT    EQU     5006H+OFFSET
CRTIN   EQU     5009H+OFFSET
CRTOUT  EQU     500CH+OFFSET
CONSTK  EQU     5002H+OFFSET
KBBUFF  EQU     505BH+OFFSET    ;CCP'S KEYBOARD BUFFER
BUFCNT  EQU     505DH+OFFSET    ;TYPE-AHEAD BUFFER COUNT
TIME    EQU     0042H           ;TIME ( IN ASCII )
DATE    EQU     004BH           ;DATE ( BCD )
;
;
;
;
;
;
        ORG     5B00H+OFFSET
;
BAUD:   DB      77H             ;BAUD RATE (1200) LOCATED ON TRACK 1, SECT 30
                                ;FOR MAIN AND AUX PORTS
MNMODE: DB      4EH             ;MAIN PORT MODE (8 BITS, 1SB, NO PAR)
MNCMD:  DB      17H             ;MAIN PORT COMMAND BYTE
AUXMOD: DB      4EH             ;AUX PORT MODE (8BITS, 1SB, NO PAR)
AUXCMD: DB      17H             ;AUX PORT COMMAND BYTE
FREQ:   DB      4BH             ;4BH=60HZ, 0BH=50HZ
HDSHAK: DB      00H             ;00 = DSR DISABLED; 01 = DSR ENABLED
RAW:    DB      00H             ;00 = NO DISK READ VERIFY; FF = READ VERIFY
TIMENB: DB      0FFH            ;00 = TIME FUNCTION DISABLED; FF = TIME ENABLED
SYNC:   DS      1               ;SYNC CHARACTER VALUE STORED HERE
        DS      4
KEYPAD: DB      81H,82H,83H,85H,0DH,2CH,2DH,2EH,30H
        DB      31H,32H,33H,34H,35H,36H,37H,38H,39H
;
;
WMSTRT  EQU     5A80H+OFFSET    ;WARM START ROUTINE
;
        ORG     4A00H+OFFSET
;
;
;**************************************************************************
;
;
;          SUPERBRAIN BIOS INTERFACE MODULE
;
;
;**************************************************************************
;
;
;
;
;***********************************************************************
;
;
;               TABLE OF EQUATES
;
;
;***********************************************************************
;
;
        JMP     BOOT
WBOOTE:
        JMP     WBOOT
        JMP     CONST
        JMP     CONIN
        JMP     CONOUT
        JMP     LIST
        JMP     PUNCH
        JMP     READER
        JMP     HOME
        JMP     SELDSK
        JMP     SETTRK
        JMP     SETSEC
        JMP     SETDMA
        JMP     READ
        JMP     WRITE
        JMP     LISTST
        JMP     SECTRAN
        JMP     DISK
        JMP     MNOUT           ;MAIN PORT SERIAL DATA OUT
        JMP     AUXIN           ;AUX PORT SERIAL DATA IN
;
;
;
BOOT:   JMP     GOCPM
WBOOT:  LXI     SP,STACK
        LDA     04H             ;GET CURRENTLY LOGGED DISK
        STA     DFLDRV
        CALL    WMSTRT          ;WARM BOOT ROUTINE
        JMP     WMRET
TRANS:
        PUSH    H
TRANS1:
        MOV     A,M
        ANA     A
        PUSH    PSW
        MOV     C,A
        CALL    CONOUT
        POP     PSW
        POP     H
        INX     H
        JP      TRANS
        RET
GOCPM:
        CALL    INIT
        LXI     H,SGNON
        CALL    TRANS
WMRET:  XRA     A
        STA     HSTACT          ;RESET ACTIVE FLAG
        STA     UNACNT
        STA     HSTWRT
        MVI     A,0C3H
        STA     0
        LXI     H,WBOOTE
        SHLD    1
        STA     5
        LXI     H,3C06H+OFFSET
        SHLD    6
        LDA     DFLDRV          ;GET LATEST LOGGED-IN DISK
        MOV     C,A
        JMP     3400H+OFFSET    ;CCP
;
CONST:  MVI     A,0FH           ;RESET KEYBOARD
        OUT     PPICW
        LDA     BUFCNT          ;ANYTHING IN THE BUFFER?
        ORA     A
        RZ                      ;RETURN IF EMPTY
CONST1: MVI     A,0FFH          ;CHARACTER READY STATUS
        RET
;
CONIN:  LXI     H,KBBUFF        ;BDOS'S KEYBOARD CHARACTER
        MOV     A,M             ;GET CHARACTER
        ORA     A               ;ANYTHING THERE?
        JZ      CONIN1          ;NO, TRY TYPE-AHEAD BUFFER
        MVI     M,0             ;INDICATES NO CHARACTER
        RET
;
CONIN1: LDA     BUFCNT          ;TYPE-AHEAD BUFFER COUNT
        ORA     A               ;ANYTHING THERE
        JZ      CONIN1          ;NO, WAIT UNTIL THERE IS
        JMP     CRTIN           ;KB CHARACTER RETURNED IN REG A
;
;
;CONOUT: SSPD    CONSTK         ;SAVE STACK POINTER
;
;
CONOUT: DW      73EDH
        DW      CONSTK
;
;
        LXI     SP,STACK2
        PUSH    H               ;SAVE HL
        CALL    CRTOUT          ;CHARACTER IN REG C
        POP     H
;
;        LSPD    CONSTK         ;RETRIEVE STACK POINTER
        DW      7BEDH
        DW      CONSTK
        RET
;
;
LIST:
        JMP     AUXOUT          ;CHARACTER OUTPUT IN REG C
PUNCH:
        JMP     MNOUT
READER:
        JMP     MAININ          ;CHARACTER RETURNRED IN REG A; CARRY=1 IF ERROR
;
;AUX PORT SERIAL DATA IN
;
AUXIN:  IN      AUXST           ;GET STATUS
        ANI     02H             ;CHARACTER READY?
        JZ      AUXIN           ;NO
        IN      AUXDAT          ;INPUT CHARACTER
        RET
;
;AUX PORT SERIAL DATA OUT
;
AUXOUT: LDA     HDSHAK          ;IS HANDSHAKING ENABLED?
        ANI     01H
        JZ      AUXOT1          ;NO
AUXOT:  IN      AUXST           ;GET AUX PORT STATUS
        ANI     80H             ;DATA SET READY (DSR) = 1?
        JZ      AUXOT           ;NO
AUXOT1: IN      AUXST           ;GET AUX PORT STATUS
        ANI     01H             ;TRANSMITTER EMPTY?
        JZ      AUXOT1          ;NO
        MOV     A,C             ;GET CHARACTER
        OUT     AUXDAT
        RET
;
;MAIN PORT SERIAL DATA IN
;
MAININ: IN      MNSTAT          ;GET MAIN PORT STATUS
        ANI     02H             ;CHARACTER READY?
        JZ      MAININ          ;NO
        IN      MNDAT           ;GET CHARACTER
        RET
;
;MAIN PORT SERIAL OUT--CTS MUST BE TRUE TO TRANSMIT
;
MNOUT:  LDA     HDSHAK          ;IS HANDSHAKING ENABLED?
        ANI     10H
        JZ      MNOT1           ;NO
MNOT:   IN      MNSTAT          ;GET MAIN PORT STATUS
        ANI     80H             ;DATA SET READY (DSR) = 1?
        JZ      MNOT            ;NO
MNOT1:  IN      MNSTAT          ;GET MAIN PORT STATUS
        ANI     01H             ;TRANSMITTER EMPTY?
        JZ      MNOUT           ;NO
        MOV     A,C
        OUT     MNDAT
        RET
;
;
;
DPBASE  EQU     $
DPE0    DW      XLT0,0000H
        DW      0000H,0000H
        DW      DIRBUF,DPB0
        DW      CSV0,ALV0
;
;DEFINITION FOR DISK B (512 BYTES/SECTOR)
;
DPE1    DW      XLT0,0000H
        DW      0000H,0000H
        DW      DIRBUF,DPB0
        DW      CSV1,ALV1
;
;
DPB0    EQU     $
        DW      40
        DB      4
        DB      15
        DB      1
        DW      169
        DW      63
        DB      128
        DB      0
        DW      16
        DW      2
;
;
XLT0    EQU     $
        DB      0,1,2,3
        DB      8,9,10,11
        DB      16,17,18,19
        DB      24,25,26,27
        DB      32,33,34,35
        DB      4,5,6,7
        DB      12,13,14,15
        DB      20,21,22,23
        DB      28,29,30,31
        DB      36,37,38,39
;
;
;PHYSICAL SECTOR TRANSLATION
;
;
PHYSEC:
        DB      1,2,3,4,5
        DB      6,7,8,9,10
;
;
;
BEGDAT  EQU     $
ALV0:   DS      31
CSV0:   DS      16
ALV1:   DS      31
CSV1:   DS      16
;
ENDAT   EQU     $
DATSIZ: EQU     $-BEGDAT
;
;
;
;
;
;
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
;

;*****************************************************
;*                                                   *
;*      Sector Deblocking Algorithms for CP/M 2.0    *
;*                                                   *
;*****************************************************
;
;
;*****************************************************
;*                                                   *
;*         CP/M to host disk constants               *
;*                                                   *
;*****************************************************
blksiz  equ     2048            ;CP/M allocation size
hstsiz  equ     512             ;host disk sector size
hstspt  equ     10              ;host disk sectors/trk
hstblk  equ     hstsiz/128      ;CP/M sects/host buff
cpmspt  equ     hstblk * hstspt ;CP/M sectors/track
secmsk  equ     hstblk-1        ;sector mask
secshf  equ     2              ;log2(hstblk)
;
;*****************************************************
;*                                                   *
;*        BDOS constants on entry to write           *
;*                                                   *
;*****************************************************
wrall   equ     0               ;write to allocated
wrdir   equ     1               ;write to directory
wrual   equ     2               ;write to unallocated
;
;
;
;
home:
        ;home the selected disk
home:
        lda     hstwrt  ;check for pending write
        ora     a
        cnz     writehst        ;clear buffer
        xra     a
        sta     hstact  ;clear host active flag
        lda     sekdsk  ;get disk no.
        sta     hstdsk
        mov     c,a     ;get disk no.
        xra     a       ;restore command
        mov     b,a
        call    disk
        ora     a
        sta     erflag  ;error status
        rz
        jmp     errout  ;go to error routine
;
seldsk:
        ;select disk
        lxi     h,0000          ;error return code
        mov     a,c             ;selected disk number
        sta     sekdsk          ;seek disk number
        cpi     2               ;max no. of disks
        rnc
        mov     l,a             ;disk number to HL
        mvi     h,0
        dad     h               ;multiply by 16
        dad     h
        dad     h
        dad     h
        lxi     d,dpbase        ;base of parm block
        dad     d               ;hl=.dpb(curdsk)
        ret
;
settrk:
        ;set track given by registers BC
        mov     h,b
        mov     l,c
        shld    sektrk          ;track to seek
        ret
;
setsec:
        ;set sector given by register c
        mov     a,c
        sta     seksec          ;sector to seek
        ret
;
setdma:
        ;set dma address given by BC
        mov     h,b
        mov     l,c
        shld    dmaadr
        ret
;
listst:
        xra     a
        ret
;
;
sectran:
        ;translate sector number BC
        xchg                    ;hl=.trans
        dad     b               ;hl=.trans(sector)
        mov     l,m
        mvi     h,0
        ret
;
;*****************************************************
;*                                                   *
;*      The READ entry point takes the place of      *
;*      the previous BIOS defintion for READ.        *
;*                                                   *
;*****************************************************
read:
        ;read the selected CP/M sector
        xra     a
        sta     unacnt
        mvi     a,1
        sta     readop          ;read operation
        sta     rsflag          ;must read data
        mvi     a,wrual
        sta     wrtype          ;treat as unalloc
        jmp     rwoper          ;to perform the read
;
;*****************************************************
;*                                                   *
;*      The WRITE entry point takes the place of     *
;*      the previous BIOS defintion for WRITE.       *
;*                                                   *
;*****************************************************
write:
        ;write the selected CP/M sector
        xra     a               ;0 to accumulator
        sta     readop          ;not a read operation
        mov     a,c             ;write type in c
        sta     wrtype
        cpi     wrual           ;write unallocated?
        jnz     chkuna          ;check for unalloc
;
;       write to unallocated, set parameters
        mvi     a,blksiz/128    ;next unalloc recs
        sta     unacnt
        lda     sekdsk          ;disk to seek
        sta     unadsk          ;unadsk = sekdsk
        lhld    sektrk
        shld    unatrk          ;unatrk = sectrk
        lda     seksec
        sta     unasec          ;unasec = seksec
;
chkuna:
        ;check for write to unallocated sector
        lda     unacnt          ;any unalloc remain?
        ora     a
        jz      alloc           ;skip if not
;
;       more unallocated records remain
        dcr     a               ;unacnt = unacnt-1
        sta     unacnt
        lda     sekdsk          ;same disk?
        lxi     h,unadsk
        cmp     m               ;sekdsk = unadsk?
        jnz     alloc           ;skip if not
;
;       disks are the same
        lxi     h,unatrk
        call    sektrkcmp       ;sektrk = unatrk?
        jnz     alloc           ;skip if not
;
;       tracks are the same
        lda     seksec          ;same sector?
        lxi     h,unasec
        cmp     m               ;seksec = unasec?
        jnz     alloc           ;skip if not
;
;       match, move to next sector for future ref
        inr     m               ;unasec = unasec+1
        mov     a,m             ;end of track?
        ani     03h
        jnz     chk1
        mov     a,m
        adi     4
        mov     m,a
chk1:
        mov     a,m
        cpi     cpmspt          ;count CP/M sectors
        jnz     chk2
        mvi     m,4
        jmp     noovf
;
chk2:   jc      noovf           ;skip if no overflow
;
;       overflow to next track
        mvi     m,0             ;unasec = 0
        lhld    unatrk
        inx     h
        shld    unatrk          ;unatrk = unatrk+1
;
noovf:
        ;match found, mark as unnecessary read
        xra     a               ;0 to accumulator
        sta     rsflag          ;rsflag = 0
        jmp     rwoper          ;to perform the write
;
alloc:
        ;not an unallocated record, requires pre-read
        xra     a               ;0 to accum
        sta     unacnt          ;unacnt = 0
        inr     a               ;1 to accum
        sta     rsflag          ;rsflag = 1
;
;*****************************************************
;*                                                   *
;*      Common code for READ and WRITE follows       *
;*                                                   *
;*****************************************************
rwoper:
        ;enter here to perform the read/write
        xra     a               ;zero to accum
        sta     erflag          ;no errors (yet)
        lda     seksec          ;compute host sector
        ora     a               ;carry = 0
        rar                     ;shift right
        rar
        ani     0fh
        lxi     h,physec        ;get table address
        mvi     b,0
        mov     c,a             ;get logical sector
        dad     b               ;hl has physical sector no.
        mov     a,m
        sta     sekhst          ;host physical sector to seek
;
;       active host sector?
rw1:
        lxi     h,hstact        ;host active flag
        mov     a,m
        mvi     m,1             ;always becomes 1
        ora     a               ;was it already?
        jz      filhst          ;fill host if not
;
;       host buffer active, same as seek buffer?
        lda     sekdsk
        lxi     h,hstdsk        ;same disk?
        cmp     m               ;sekdsk = hstdsk?
        jnz     nomatch
;
;       same disk, same track?
        lxi     h,hsttrk
        call    sektrkcmp       ;sektrk = hsttrk?
        jnz     nomatch
;
;       same disk, same track, same buffer?
        lda     sekhst
        lxi     h,hstsec        ;sekhst = hstsec?
        cmp     m
        jz      match           ;skip if match
;
nomatch:
        ;proper disk, but not correct sector
        lda     hstwrt          ;host written?
        ora     a
        cnz     writehst        ;clear host buff
;
filhst:
        ;may have to fill the host buffer
        lda     sekdsk
        sta     hstdsk
        lhld    sektrk
        shld    hsttrk
        lda     sekhst
        sta     hstsec
        lda     rsflag          ;need to read?
        ora     a
        cnz     readhst         ;yes, if 1
        xra     a               ;0 to accum
        sta     hstwrt          ;no pending write
;
match:
        ;copy data to or from buffer
        lda     seksec          ;mask buffer number
        ani     secmsk          ;least signif bits
        mov     l,a             ;ready to shift
        mvi     h,0             ;double count
        dad     h               ;shift left 7
        dad     h
        dad     h
        dad     h
        dad     h
        dad     h
        dad     h
;       hl has relative host buffer address
match1:
        lxi     d,hstbuf
        dad     d               ;hl = host address
        xchg                    ;now in DE
        lhld    dmaadr          ;get/put CP/M data
        mvi     c,128           ;length of move
        lda     readop          ;which way?
        ora     a
        jnz     rwmove          ;skip if read
;
;       write operation, mark and switch direction
        mvi     a,1
        sta     hstwrt          ;hstwrt = 1
        xchg                    ;source/dest swap
;
rwmove:
        ;C initially 128, DE is source, HL is dest
        ldax    d               ;source character
        inx     d
        mov     m,a             ;to dest
        inx     h
        dcr     c               ;loop 128 times
        jnz     rwmove
;
;       data has been moved to/from host buffer
rwmv1:
        lda     wrtype          ;write type
        cpi     wrdir           ;to directory?
        lda     erflag          ;in case of errors
        rnz                     ;no further processing
;
;       clear host buffer for directory write
match2:
        lda     erflag
        ora     a               ;errors?
        rnz                     ;skip if so
        xra     a               ;0 to accum
        sta     hstwrt          ;buffer written
        call    writehst
        lda     erflag
        ret
;
;*****************************************************
;*                                                   *
;*      Utility subroutine for 16-bit compare        *
;*                                                   *
;*****************************************************
sektrkcmp:
        ;HL = .unatrk or .hsttrk, compare with sektrk
        xchg
        lxi     h,sektrk
        ldax    d               ;low byte compare
        cmp     m               ;same?
        rnz                     ;return if not
;       low bytes equal, test high 1s
        inx     d
        inx     h
        ldax    d
        cmp     m       ;sets flags
        ret
;
;*****************************************************
;*                                                   *
;*      WRITEHST performs the physical write to      *
;*      the host disk, READHST reads the physical    *
;*      disk.                                        *
;*                                                   *
;*****************************************************
writehst:
        ;hstdsk = host disk #, hsttrk = host track #,
        ;hstsec = host sect #. write "hstsiz" bytes
        ;from hstbuf and return error flag in erflag.
        ;return erflag non-zero if error
;
;
        call    parm    ;get disk parameters
        mvi     b,2     ;write command
        lda     raw     ;get read-after-write indicator
        ora     a       ;raw?
        jnz     writ1   ;yes
        mvi     b,6     ;no
writ1:
        call    disk
        ora     a       ;error status returned in a
        sta     erflag
        rz
        jmp     errout  ;go to error handler
;
readhst:
        ;hstdsk = host disk #, hsttrk = host track #,
        ;hstsec = host sect #. read "hstsiz" bytes
        ;into hstbuf and return error flag in erflag.
;
;
        call    parm    ;get disk parameters
        mvi     b,1     ;disk read command
        call    disk
        ora     a
        sta     erflag
        rz
        jmp     errout
;
;
;routine to get disk parameters
;
parm:
        lxi     h,hstdsk
        mov     c,m
        inx     h
        mov     d,m             ;get track no.
        inx     h
        inx     h
        mov     e,m             ;get sector no.
        lxi     h,hstbuf
        ret
;
;
;error handler
;
;
errout:
        lxi     h,msg1
        ral                     ;disk not ready?
        cc      msgout
        lxi     h,msg2
        ral                     ;disk write protected?
        cc      msgout
        lxi     h,msg3
        ral
        ral                     ;can't find record?
        cc      msgout
        lxi     h,msg4
        ral                     ;crc error?
        cc      msgout
        lxi     h,msg5
        ral                     ;lost data?
        cc      msgout
        mvi     a,01
        sta     erflag
        ret
;
;
;
msgout:
        push    psw
        call    trans
        pop     psw
        ret
;
;
;
;
msg1:   db      0ah,0dh,'*** disk not ready ***',80h
msg2    db      0ah,0dh,'*** disk write protected ***',80h
msg3:   db      0ah,0dh,'*** record not found ***',80h
msg4:   db      0ah,0dh,'*** crc error ***',80h
msg5:   db      0ah,0dh,'*** lost data ***',80h
;
;
;*****************************************************
;*                                                   *
;*      Unitialized RAM data areas                   *
;*                                                   *
;*****************************************************
;
sekdsk: ds      1               ;seek disk number
sektrk: ds      2               ;seek track number
seksec: ds      1               ;seek sector number
;
hstdsk: ds      1               ;host disk number
hsttrk: ds      2               ;host track number
hstsec: ds      1               ;host sector number
;
sekhst: ds      1               ;seek shr secshf
hstact: ds      1               ;host active flag
hstwrt: ds      1               ;host written flag
;
unacnt: ds      1               ;unalloc rec cnt
unadsk: ds      1               ;last unalloc disk
unatrk: ds      2               ;last unalloc track
unasec: ds      1               ;last unalloc sector
;
erflag: ds      1               ;error reporting
rsflag: ds      1               ;read sector flag
readop: ds      1               ;1 if read operation
wrtype: ds      1               ;write operation type
dmaadr: ds      2               ;last dma address
;
dfldrv: db      0
;
;
;
sgnon:
;
        DB      '64K SUPERBRAIN QUAD DENSITY DOS VER 3.1 FOR CP/M 2.2   ',0AH,0DH,80H
;
;
;
;
;********************************************************
;*                                                      *
;*       insert user routines here                      *
;*                                                      *
;********************************************************
;
;
USRSTRT EQU     $       ;USER START ADDRESS
;
;USRSIZE        EQU     5000H+OFFSET-$  ;NUMBER OF BYTES AVAILABLE (HEX)
;
USREND  EQU     4FFFH+OFFSET    ;USER END ADDRESS
;
;
        end


