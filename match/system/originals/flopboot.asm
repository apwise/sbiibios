	ORG	0C780H
;
; Floppy disk boot sector
;
L0002	EQU	02H
RDLEN	EQU	0400H		; Number of bytes read at one time
RDSEC	EQU	0C003H		; ROM BIOS routine to read a sector on floppy
LC980	EQU	0C980H
LCB80	EQU	0CB80H
COLDBT	EQU	0DE00H		; CBIOS cold boot entry location
STACK	EQU	0F3FFH		; Stack location while in bootstrap routine
;
FLBOOT: NOP
	LXI	SP,STACK
	LXI	H,LC980 ;0C980H
	LXI	B,0		; track 0, sector 0
	CALL	RDSEC
	LXI	H,LC980 ;0C980H
	LXI	D,2		; D=0, E=2
	MVI	B,1		; sector 1
	MVI	C,0		; track 0
LC797:		;C797 
	CALL	RDNEXT
	INR	E
	INR	E
	MOV	A,E
	CPI	0CH
	JNZ	LC797	;0C797H
;
	SHLD	TMPADR		; Store address temporarily
	LXI	H,LCB80 ;0CB80H
	MVI	E,3
LC7AA:		;C7AA 
	CALL	RDNEXT
	INR	E
	INR	E
	MOV	A,E
	CPI	0BH
	JNZ	LC7AA	;0C7AAH
	INR	D
	MVI	E,1
LC7B8:		;C7B8 
	CALL	RDNEXT
	INR	E
	INR	E
	MOV	A,E
	CPI	0BH
	JNZ	LC7B8	;0C7B8H
;
	MVI	E,2
	LHLD	TMPADR		; Get address
LC7C8:		;C7C8 
	CALL	RDNEXT
	INR	E
	INR	E
	MOV	A,E
	CPI	0CH
	JNZ	LC7C8	;0C7C8H
;
	JMP	COLDBT		
;
RDNEXT: PUSH	D
	PUSH	B
	PUSH	H
	CALL	RDSEC		; Read a sector into memory at HL (?)
	POP	H
	LXI	D,RDLEN 	; Add in number of bytes read to address
	DAD	D
	POP	B
	POP	D
	RET
;
TMPADR: DS	2		; Space for holding address
;
	END
; Add in number of bytes r