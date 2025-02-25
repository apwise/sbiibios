        TITLE   'SYSGEN - SYSTEM GENERATION PROGRAM 8/79'
;       SYSTEM GENERATION PROGRAM, VERSION FOR SUPERBRAIN
VERS    EQU     20     ;X.X
;
;       COPYRIGHT (C) DIGITAL RESEARCH
;                1976, 1977, 1978, 1979
;
NSECTS  EQU     40      ;NO. OF SECTORS PER TRACK
NTRKS   EQU     2       ;NO. OF OPERATING SYSTEM TRACKS
NDISKS  EQU     4       ;NUMBER OF DISK DRIVES
SECSIZ  EQU     128     ;SIZE OF EACH SECTOR
LOG2SEC EQU     7       ;LOG 2 SECSIZ
SKEW    EQU     1       ;SECTOR SKEW FACTOR
;
FCB     EQU     005CH   ;DEFAULT FCB LOCATION
FCBCR   EQU     FCB+32  ;CURRENT RECORD LOCATION
TPA     EQU     0100H   ;TRANSIENT PROGRAM AREA
LOADP   EQU     900H    ;LOAD POINT FOR SYSTEM DURING LOAD/STORE
BDOS    EQU     5H      ;DOS ENTRY POINT
BOOT    EQU     0       ;JMP TO 'BOOT' TO REBOOT SYSTEM
CONI    EQU     1       ;CONSOLE INPUT FUNCTION
CONO    EQU     2       ;CONSOLE OUTPUT FUNCTION
SELF    EQU     14      ;SELECT DISK
OPENF   EQU     15      ;DISK OPEN FUNCTION
DREADF  EQU     20      ;DISK READ FUNCTION
;
MAXTRY  EQU     10      ;MAXIMUM NUMBER OF RETRIES ON EACH READ/WRITE
CR      EQU     0DH     ;CARRIAGE RETURN
LF      EQU     0AH     ;LINE FEED
STACKSIZE       EQU     16      ;SIZE OF LOCAL STACK
;
WBOOT   EQU     1       ;ADDRESS OF WARM BOOT (OTHER PATCH ENTRY
;                       POINTS ARE COMPUTED RELATIVE TO WBOOT)
SELDSK  EQU     24      ;WBOOT+24 FOR DISK SELECT
SETTRK  EQU     27      ;WBOOT+27 FOR SET TRACK FUNCTION
SETSEC  EQU     30      ;WBOOT+30 FOR SET SECTOR FUNCTION
SETDMA  EQU     33      ;WBOOT+33 FOR SET DMA ADDRESS
READF   EQU     36      ;WBOOT+36 FOR READ FUNCTION
WRITF   EQU     39      ;WBOOT+39 FOR WRITE FUNCTION
;
        ORG     TPA     ;TRANSIENT PROGRAM AREA
        JMP     START
        DB      'COPYRIGHT (C) 1978, DIGITAL RESEARCH '
;
;       TRANSLATE TABLE - SECTOR NUMBERS ARE TRANSLATED
;       HERE TO DECREASE THE SYSGEN TIME FOR MISSED SECTORS
;       WHEN SLOW CONTROLLERS ARE INVOLVED.  TRANSLATION TAKES
;       PLACE ACCORDING TO THE "SKEW" FACTOR SET ABOVE.
;
OST:    DB      NTRKS   ;OPERATING SYSTEM TRACKS
SPT:    DB      NSECTS  ;SECTORS PER TRACK (CAN BE PATCHED)
TRAN:                   ;BASE OF TRANSLATE TABLE
;TRELT   SET     1       ;FIRST/NEXT TRAN ELEMENT
;TRBASE  SET     1       ;BASE FOR WRAPAROUND
;        REPT    NSECTS  ;ONCE FOR EACH SECTOR ON A TRACK
;        DB      TRELT   ;GENERATE FIRST/NEXT SECTOR
;TRELT   SET     TRELT+SKEW
;        IF      TRELT GT NSECTS
;TRBASE  SET     TRBASE+1
;TRELT   SET     TRBASE
;        ENDIF
;        ENDM
        db       0,  1,  2,  3,  8,  9, 10, 11
        db      16, 17, 18, 19, 24, 25, 26, 27
        db      32, 33, 34, 35,  4,  5,  6,  7
        db      12, 13, 14, 15, 20, 21, 22, 23
        db      28, 29, 30, 31, 36, 37, 38, 39
;
;       NOW LEAVE SPACE FOR EXTENSIONS TO TRANSLATE TABLE
        IF      NSECTS LT 64
        REPT    64-NSECTS
        DB      0
        ENDM
;
;
;
;
;       UTILITY SUBROUTINES
MULTSEC:
        ;MULTIPLY THE SECTOR NUMBER IN A BY THE SECTOR SIZE
        MOV L,A! MVI H,0 ;SECTOR NUMBER IN HL
        REPT LOG2SEC    ;LOG 2 OF SECTOR SIZE
        DAD     H
        ENDM
        RET ;WITH HL = SECTOR * SECTOR SIZE
;
GETCHAR:
;       READ CONSOLE CHARACTER TO REGISTER A
        MVI C,CONI! CALL BDOS!
;       CONVERT TO UPPER CASE BEFORE RETURN
        CPI 'A' OR 20H ! RC     ;RETURN IF BELOW LOWER CASE A
        CPI ('Z' OR 20H) + 1
        RNC     ;RETURN IF ABOVE LOWER CASE Z
        ANI 5FH! RET
;
PUTCHAR:
;       WRITE CHARACTER FROM A TO CONSOLE
        MOV E,A! MVI C,CONO! CALL BDOS! RET
;
CRLF:   ;SEND CARRIAGE RETURN, LINE FEED
        MVI     A,CR
        CALL    PUTCHAR
        MVI     A,LF
        CALL    PUTCHAR
        RET
;
CRMSG:  ;PRINT MESSAGE ADDRESSED BY H,L TIL ZERO
        ;WITH LEADING CRLF
        PUSH H! CALL CRLF! POP H ;DROP THRU TO OUTMSG0
OUTMSG:
        MOV A,M! ORA A! RZ
;       MESSAGE NOT YET COMPLETED
        PUSH H! CALL PUTCHAR! POP H! INX H
        JMP     OUTMSG
;
SEL:
;       SELECT DISK GIVEN BY REGISTER A
        MOV C,A! LHLD WBOOT! LXI D,SELDSK! DAD D! PCHL
;
TRK:    ;SET UP TRACK
        LHLD    WBOOT   ;ADDRESS OF BOOT ENTRY
        LXI     D,SETTRK        ;OFFSET FOR SETTRK ENTRY
        DAD     D
        PCHL            ;GONE TO SETTRK
;
SEC:    ;SET UP SECTOR NUMBER
        LHLD    WBOOT
        LXI     D,SETSEC
        DAD     D
        PCHL
;
DMA:    ;SET DMA ADDRESS TO VALUE OF B,C
        LHLD    WBOOT
        LXI     D,SETDMA
        DAD     D
        PCHL
;
READ:   ;PERFORM READ OPERATION
        LHLD    WBOOT
        LXI     D,READF
        DAD     D
        PCHL
;
WRITE:  ;PERFORM WRITE OPERATON
        LHLD    WBOOT
        LXI     D,WRITF
        DAD     D
        PCHL
;
DREAD:  ;DISK READ FUNCTION
        MVI     C,DREADF
        JMP     BDOS
;
OPEN:   ;FILE OPEN FUNCTION
        MVI C,OPENF ! JMP BDOS
;
GETPUT:
;       GET OR PUT CP/M (RW=0 FOR READ, 1 FOR WRITE)
;       DISK IS ALREADY SELECTED
;
        LXI     H,LOADP ;LOAD POINT IN RAM FOR CP/M DURING SYSGEN
        SHLD    DMADDR
;
;       CLEAR TRACK TO 00
        MVI     A,-1    ;START WITH TRACK EQUAL -1
        STA     TRACK
;
RWTRK:  ;READ OR WRITE NEXT TRACK
        LXI     H,TRACK
        INR     M       ;TRACK = TRACK + 1
        LDA     OST     ;NUMBER OF OPERATING SYSTEM TRACKS
        CMP     M       ;= TRACK NUMBER ?
        JZ      ENDRW   ;END OF READ OR WRITE
;
;       OTHERWISE NOTDONE, GO TO NEXT TRACK
        MOV     C,M     ;TRACK NUMBER
        CALL    TRK     ;TO SET TRACK
        MVI     A,-1    ;COUNTS 0, 1, 2, . . . 25
        STA     SECTOR  ;SECTOR INCREMENTED BEFORE READ OR WRITE
;
RWSEC:  ;READ OR WRITE SECTOR
        LDA     SPT     ;SECTORS PER TRACK
        LXI     H,SECTOR
        INR     M       ;TO NEXT SECTOR
        CMP     M       ;A=26 AND M=0 1 2...25 (USUALLY)
        JZ      ENDTRK  ;
;
;       READ OR WRITE SECTOR TO OR FROM CURRENT DMA ADDR
        LXI     H,SECTOR
        MOV     E,M     ;SECTOR NUMBER
        MVI     D,0     ;TO DE
        LXI     H,TRAN
        MOV     B,M     ;TRAN(0) IN B
        DAD     D       ;SECTOR TRANSLATED
        MOV     C,M     ;VALUE TO C READY FOR SELECT
        PUSH    B       ;SAVE TRAN(0),TRAN(SECTOR)
        CALL    SEC     ;SET UP SECTOR NUMBER
        POP     B       ;RECALL TRAN(0),TRAN(SECTOR)
        MOV     A,C     ;TRAN(SECTOR)
        SUB     B       ;-TRAN(0)
        CALL    MULTSEC ;*SECTOR SIZE
        XCHG            ;TO DE
        LHLD    DMADDR  ;BASE DMA ADDRESS FOR THIS TRACK
        DAD     D       ;+(TRAN(SECTOR)-TRAN(0))*SECSIZ
        MOV     B,H
        MOV     C,L     ;TO BC FOR SEC CALL
        CALL    DMA     ;DMA ADDRESS SET FROM B,C
;       DMA ADDRESS SET, CLEAR RETRY COUNT
        XRA     A
        STA     RETRY   ;SET TO ZERO RETRIES
;
TRYSEC: ;TRY TO READ OR WRITE CURRENT SECTOR
        LDA     RETRY
        CPI     MAXTRY  ;TOO MANY RETRIES?
        JC      TRYOK
;
;       PAST MAXTRIES, MESSAGE AND IGNORE
        LXI     H,ERRMSG
        CALL    OUTMSG
        CALL    GETCHAR
        CPI     CR
        JNZ     REBOOT
;
;       TYPED A CR, OK TO IGNORE
        CALL    CRLF
        JMP     RWSEC
;
TRYOK:
;       OK TO TRY READ OR WRITE
        INR     A
        STA     RETRY   ;RETRY=RETRY+1
        LDA     RW      ;READ OR WRITE?
        ORA     A
        JZ      TRYREAD
;
;       MUST BE WRITE
        CALL    WRITE
        JMP     CHKRW   ;CHECK FOR ERROR RETURNS
TRYREAD:
        CALL    READ
CHKRW:
        ORA     A
        JZ      RWSEC   ;ZERO FLAG IF R/W OK
;
;       ERROR, RETRY OPERATION
        JMP     TRYSEC
;
;       END OF TRACK
ENDTRK:
        LDA     SPT     ;SECTORS PER TRACK
        CALL    MULTSEC ;*SECSIZ
        XCHG            ;TO DE
        LHLD    DMADDR  ;BASE DMA FOR THIS TRACK
        DAD     D       ;+SPT*SECSIZ
        SHLD    DMADDR  ;READY FOR NEXT TRACK
        JMP     RWTRK   ;FOR ANOTHER TRACK
ENDRW:  lhld    1       ;Pointer to WBOOTE
        lxi     d, 21   ;7 'jmp' instructions later
        dad     d       ;is entry point to HOME
        pchl            ;flushes any pending write
        ds      10
;
;ENDRW:  ;END OF READ OR WRITE, RETURN TO CALLER
;        RET
;
;
;START:
;
;        LXI     SP,STACK        ;SET LOCAL STACK POINTER
;        LXI     H,SIGNON
;        CALL    OUTMSG
;
;       CHECK FOR DEFAULT FILE LOAD INSTEAD OF GET
;
;        LDA     FCB+1   ;BLANK IF NO FILE
;        CPI     ' '
;        JZ      GETSYS  ;SKIP TO GET SYSTEM MESSAGE IF BLANK
STRT:   LXI     D,FCB   ;TRY TO OPEN IT
        CALL    OPEN    ;
        INR     A       ;255 BECOMES 00
        JNZ     RDOK    ;OK TO READ IF NOT 255
;
;       FILE NOT PRESENT, ERROR AND REBOOT
;
        LXI     H,NOFILE
        CALL    CRMSG
        JMP     REBOOT
;
;       FILE PRESENT
;         READ TO LOAD POINT
;
RDOK:
        XRA     A
        STA     FCBCR   ;CURRENT RECORD = 0
;
;       PRE-READ AREA FROM TPA TO LOADP
;
        MVI     C,(LOADP-TPA)/SECSIZ
;       PRE-READ FILE
PRERD:
        PUSH    B       ;SAVE COUNT
        LXI     D,FCB   ;INPUT FILE CONTROL COUNT
        CALL    DREAD   ;ASSUME SET TO DEFAULT BUFFER
        POP     B       ;RESTORE COUNT
        ORA     A
        JNZ     BADRD   ;CANNOT ENCOUNTER END-OF FILE
        DCR     C       ;COUNT DOWN
        JNZ     PRERD   ;FOR ANOTHER SECTOR
;
;       SECTORS SKIPPED AT BEGINNING OF FILE
;
        LXI     H,LOADP
RDINP:
        PUSH    H
        MOV     B,H
        MOV     C,L     ;READY FOR DMA
        CALL    DMA     ;DMA ADDRESS SET
        LXI     D,FCB   ;READY FOR READ
        CALL    DREAD   ;
        POP     H       ;RECALL DMA ADDRESS
        ORA     A       ;00 IF READ OK
        JNZ     PUTSYS  ;ASSUME EOF IF NOT.
;       MORE TO READ, CONTINUE
        LXI     D,SECSIZ
        DAD     D       ;HL IS NEW LOAD ADDRESS
        JMP     RDINP
;
BADRD:  ;EOF ENCOUNTERED IN INPUT FILE

        LXI     H,BADFILE
        CALL    CRMSG
        JMP     REBOOT
;
;
GETSYS:
        LXI     H,ASKGET        ;GET SYSTEM?
        CALL    CRMSG
        CALL    GETCHAR
        CPI     CR
        JZ      PUTSYS  ;SKIP IF CR ONLY
;
        SUI     'A'             ;NORMALIZE DRIVE NUMBER
        CPI     NDISKS          ;VALID DRIVE?
        JC      GETC            ;SKIP TO GETC IF SO
;
;       INVALID DRIVE NUMBER
        CALL    BADDISK
        JMP     GETSYS          ;TO TRY AGAIN
;
GETC:
;       SELECT DISK GIVEN BY REGISTER A
        ADI     'A'
        STA     GDISK           ;TO SET MESSAGE
        SUI     'A'
        CALL    SEL             ;TO SELECT THE DRIVE
;       GETSYS, SET RW TO READ AND GET THE SYSTEM
        CALL    CRLF
        LXI     H,GETMSG
        CALL    OUTMSG
        CALL    GETCHAR
        CPI     CR
        JNZ     REBOOT
        CALL    CRLF
;
        XRA     A
        STA     RW
        CALL    GETPUT
        LXI     H,DONE
        CALL    OUTMSG
;
;       PUT SYSTEM
PUTSYS:
        LXI     H,ASKPUT
        CALL    CRMSG
        CALL    GETCHAR
        CPI     CR
        JZ      REBOOT
        SUI     'A'
        CPI     NDISKS
        JC      PUTC
;
;       INVALID DRIVE NAME
        CALL    BADDISK
        JMP     PUTSYS  ;TO TRY AGAIN
;
PUTC:
;       SET DISK FROM REGISTER C
        ADI     'A'
        STA     PDISK   ;MESSAGE SET
        SUI     'A'
        CALL    SEL     ;SELECT DEST DRIVE
;       PUT SYSTEM, SET RW TO WRITE
        LXI     H,PUTMSG
        CALL    CRMSG
        CALL    GETCHAR
        CPI     CR
        JNZ     REBOOT
        CALL    CRLF
;
        LXI     H,RW
        MVI     M,1
        CALL    GETPUT  ;TO PUT SYSTEM BACK ON DISKETTE
        LXI     H,DONE
        CALL    OUTMSG
        JMP     PUTSYS  ;FOR ANOTHER PUT OPERATION
;
REBOOT:
        MVI     A,0
        CALL    SEL
        CALL    CRLF
        JMP     BOOT
BADDISK:
        ;BAD DISK NAME
        LXI     H,QDISK
        CALL    CRMSG
        RET
;
;
;
;       DATA AREAS
;       MESSAGES
SIGNON: DB      'SYSGEN VER '
        DB      VERS/10+'0','.',VERS MOD 10+'0'
        DB      0
ASKGET: DB      'SOURCE DRIVE NAME (OR RETURN TO SKIP)',0
GETMSG: DB      'SOURCE ON '
GDISK:  DS      1       ;FILLED IN AT GET FUNCTION
        DB      ', THEN TYPE RETURN',0
ASKPUT: DB      'DESTINATION DRIVE NAME (OR RETURN TO REBOOT)',0
PUTMSG: DB      'DESTINATION ON '
PDISK:  DS      1       ;FILLED IN AT PUT FUNCTION
        DB      ', THEN TYPE RETURN',0
ERRMSG: DB      'PERMANENT ERROR, TYPE RETURN TO IGNORE',0
DONE:   DB      'FUNCTION COMPLETE',0
QDISK:  DB      'INVALID DRIVE NAME (USE A, B, C, OR D)',0
NOFILE: DB      'NO SOURCE FILE ON DISK',0
BADFILE:
        DB      'SOURCE FILE INCOMPLETE',0
;
;       VARIABLES
SDISK:  DS      1       ;SELECTED DISK FOR CURRENT OPERATION
TRACK:  DS      1       ;CURRENT TRACK
SECTOR: DS      1       ;CURRENT SECTOR
RW:     DS      1       ;READ IF 0, WRITE IF 1
DMADDR: DS      2       ;CURRENT DMA ADDRESS
RETRY:  DS      1       ;NUMBER OF TRIES ON THIS SECTOR
        DS      STACKSIZE*2
STACK:
;
        org     04d0h
START:
;
        LXI     SP,STACK        ;SET LOCAL STACK POINTER
        LXI     H,SIGNON
        CALL    OUTMSG
;
;       CHECK FOR DEFAULT FILE LOAD INSTEAD OF GET
;
        LDA     FCB+1   ;BLANK IF NO FILE
        CPI     ' '
        JZ      GETSYS  ;SKIP TO GET SYSTEM MESSAGE IF BLANK
        JMP     STRT
;
        END
