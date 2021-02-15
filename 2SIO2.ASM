;	2SIO2.ASM
;
;	Driver Overlay for MODEM8
;
;	This module provides the device-dependent information to be used
;	by MODEM8.  It should be modified for your modem port, assembled
;	with ASM, and the resulting .HEX file renamed to .MDM
;
; 	THIS file should  always  be used to configure  MODEM8  for your 
;	system, rather than modifying MODEM8.ASM.

CR	equ	0dH
LF	equ	0aH
BELL	equ	07H
BS	equ	08H
TAB	equ	09H

TRUE	equ	0ffH
FALSE	equ	0

;	Baud Rate Codes

b100	equ	1
b300	equ	2
b600	equ	3
b1200	equ	4
b2400	equ	5
b4800	equ	6
b9600	equ	7
b19200	equ	8


;	This driver is for a M. I. T. S. 2-SIO

;	2K is reserved for drivers - from 103H to 902H

	org	103h

;
;	DO NOT modify the locations of the jump table or the variables!
;

ModVer:	db	4		; expected MODEM8 major version number

ModIni:	jmp	MdmIni		; modem initialization
ModStI:	jmp	MdmStI		; modem input status
ModStO:	jmp	MdmStO		; modem output status
ModInp:	jmp	MdmInp		; modem character input
ModOut:	jmp	MdmOut		; modem character output
ModFin:	jmp	MdmFin		; modem de-initialization
ModBrk:	jmp	MdmBrk		; modem send break
ModChg:	jmp	MdmChg		; modem parameters have changed
ModDial:jmp	MdmDial		; dial phone number
ModHup:	jmp	MdmHup		; hang up phone
ModCD:	jmp	MdmCD		; modem carrier detect

;
;	Initial variable values
;

FulDpx:	db	TRUE		; Full Duplex Mode
HostMd:	db	FALSE		; Host Mode (Echo characters received)
WtChar:	db	TRUE		; Wait for echo during ascii send
DlyVal:	dw	200		; Delay constant -- 100 * CPU speed in MHz
TrigFlg:db	TRUE		; Wait for Trigger during ASCII send
XltCtrl:db	TRUE		; Translate control characters
QFlg:	db	FALSE		; Don't print messages in send/receive
PLen:	db	24		; Length of console 'page'
TryCRC:	db	TRUE		; Attempt CRC mode (instead of checksum)
SendLF:	db	FALSE		; Transmit LF's during ASCII send
Prefix:	db	'\'-40H		; Command Prefix during terminal mode
;
;	The following variables are considered 'modem parameters'.
;	This means that they have something to do with the state or
;	behaviour of the modem.  Whenever any of these parameters
;	are changed during the course of execution, the driver is
;	notified by a call to ModChg in case commands must be sent
;	to the modem or its interface.
;
;	Inappropriate parameters may be ignored.  Applicable parameters
;	set to unavailable values should be changed to some default
;	value.
;
Pulse:	db	TRUE		; Use pulse dialing instead of touch-tone
Speed:	db	b300		; Baud rate for transmissions (see codes above)
Parity:	db	0		; Type of parity generation/checking:
				;	0 = none
				;	1 = odd
				;	2 = even
DatBit:	db	8		; Number of data bits
StpBit:	db	1		; Number of stop bits

;
;	Character Strings are terminated by a 0 byte.
;	At most 40 characters are allowed per string, including
;	     the terminator byte.
;	To put a NUL in a string use 80h
;
DevNam: db	'MITS 2-SIO '	; Device Name
	db	'V2.0, port ','0'+Mdm/10,'0'+Mdm mod 10,0
	ds	40-($-DevNam)	;	pad out to 40 characters

Trigger:db	CR,LF,0		; Trigger string
	ds	40-($-Trigger)	;	pad out to 40 characters

Pause:	db	('S'-40H),0	; Pause String
	ds	40-($-Pause)	;	pad out to 40 characters

Release:db	('Q'-40H),0	; Release String
	ds	40-($-Release)	;	pad out to 40 characters

NotXlt:			; Control characters that are not translated to
				; '^char' in 'Translate Ctrl-Chr' terminal mode
	db	CR,LF,BS,0
	ds	40-($-NotXlt)	;	pad out to 40 characters

FilPass:		; Control characters that are saved in File Save mode
	db	CR,LF,TAB,0
	ds	40-($-FilPass)	;	pad out to 40 characters

;	Number Table
;
;	Entries in the number table are strings with the same
;	format and restrictions as other strings described above.
;
;	Entries contain two parts separated by a colon (':').
;	The first part is the name of the person or system associated
;	with the phone number.  The second part is a phone number
;	string as described below.
;
;	Characters in a phone number string may be:
;		0-9,*,#		dial the corresponding number
;				note that the * and # may be dialed in
;				touch-tone mode only, if at all
;				they should be ignored if they cannot
;				be dialed
;		P		pause and check for a dial tone
;				if this cannot be implemented directly,
;				make it the same as W
;		W		wait for a short period of time
;				normally used before P
;
;	Any other characters in a phone number string should be ignored.

MaxNum:	db	9		; Maximum number of phone numbers allowed
				; This may be set to any value as long as
				; enough space is reserved in Numbers below
Numbers:
Num1:	db	0
	ds	40-($-Num1)
Num2:	db	0
	ds	40-($-Num2)
Num3:	db	0
	ds	40-($-Num3)
Num4:	db	0
	ds	40-($-Num4)
Num5:	db	0
	ds	40-($-Num5)
Num6:	db	0
	ds	40-($-Num6)
Num7:	db	0
	ds	40-($-Num7)
Num8:	db	0
	ds	40-($-Num8)
Num9:	db	0
	ds	40-($-Num9)


;
;	This area contains the actual device drivers.
;

Mdm	equ	22	;2-SIO status port

;	Equates for the Motorola 6850 ACIA

;	Command Words

Clck01	equ	0		;Clock / 1
Clck16	equ	1		;Clock / 16
Clck64	equ	2		;Clock / 64
MReset	equ	3		;Master Reset

D7S2EP	equ	0		;Data bits, Stop bits,
D7S2OP	equ	4		;Parity (Even, Odd, None)
D7S1EP	equ	8
D7S1OP	equ	0ch
D8S2NP	equ	10h
D8S1NP	equ	14h
D8S1EP	equ	18h
D8S1Op	equ	1ch

NRLTD	equ	0		;Not RTS Level (Low, High),
NRLTE	equ	20h		;Transmit Interrupt (Enable, Disable)
NRHTD	equ	40h
NRHTDB	equ	60h		;Send Break Condition

RD	equ	0		;Receive Interrupt (Enable, Disable)
RE	equ	80h

;	Status Words

RDRF	equ	1		;Receiver Data Ready Flag
TDRF	equ	2		;Transmit Data Ready Flag
DCD	equ	4		;Not Data Carrier Detect
CTS	equ	8		;Not Clear To Send
FE	equ	10h		;Framing Error
OvRn	equ	20h		;Overrun Error
PE	equ	40h		;Parity Error
Irq	equ	80h		;Interrupt Request

;	Default Mode Word
DfltM	equ	RD+NRLTD+D8S1NP

MdmIni:	mvi	a,MReset	;clear acia
	out	Mdm
	jmp	MdmChg		;initialize to 'modem parameters'

MdmStI:	in	Mdm		;return z for not ready, nz for ready
	ani	RDRF		;receiver ready?
	ret

MdmStO:	in	Mdm		;return z for not ready, nz for ready
	ani	TDRF		;transmitter ready?
	ret

MdmInp:	in	Mdm+1		;get character
	ret

MdmOut:	out	Mdm+1		;send character
	ret

MdmFin:	jmp	MdmIni		;same as initialization

MdmBrk:	ret			;not implemented

	; Change modem parameters (if applicable)
MdmChg:	lda	Speed		;check for valid baud rate
	mvi	b,Clck16	;clock/ rate for 1200 baud
	cpi	b1200		;1200 baud?
	jz	DoDatB		;yes - continue
	mvi	a,b300		;no - default to 300 baud
	sta	Speed		;let user know
	mvi	b,Clck64	;clock/ rate for 300 baud

DoDatB:	lda	DatBit		;check for valid data bits
	cpi	7		;not if < 7
	jc	SDfltM		;invalid - use default settings
	cpi	9		;not if >= 9
	jnc	SDfltM
	mvi	e,0		;setup for 7 data bits
	sui	7		;7 data bits?
	jz	DoStpB		;yes - continue
	mvi	e,6		;no - setup for 8 data bits

DoStpB:	lda	StpBit		;check for valid stop bits
	cpi	1		;not if < 1
	jc	SDfltM
	cpi	3		;not if >= 3
	jnc	SDfltM
	dcr	a		;setup for 1 stop bit
	jz	DoPar		;1 stop bit?  yes - continue
	mov	a,e		;no - setup for 2 stop bits
	adi	3
	mov	e,a

DoPar:	lda	Parity		;check for valid parity
	cpi	3		;not if >= 3
	jnc	SDfltM
	add	e		;add parity code to offset for data & stop bits
	mov	e,a		;de = offset into mode table
	mvi	d,0
	lxi	h,MTbl		;hl => base of mode table
	dad	d		;hl => mode table (data, stop & parity)
	mov	a,m		;get mode word

SetMod:	ora	b		;set clock/ rate for desired baud rate
	sta	CurM		;setup current mode
	out	Mdm		;send to acia
	ret

SDfltM:	mvi	a,DFltM		;use default mode word
	jmp	SetMod

;	Mode table for the Motorola 6850 ACIA
;					;Data Bits	Stop Bits	Parity
MTbl:	db	DfltM			;7		1		None *
	db	RD+NRLTD+D7S1OP		;7		1		Odd
	db	RD+NRLTD+D7S1EP		;7		1		Even
	db	DfltM			;7		2		None *
	db	RD+NRLTD+D7S2OP		;7		2		Odd
	db	RD+NRLTD+D7S2EP		;7		2		Even
	db	RD+NRLTD+D8S1NP		;8		1		None
	db	RD+NRLTD+D8S1OP		;8		1		Odd
	db	RD+NRLTD+D8S1EP		;8		1		Even
	db	RD+NRLTD+D8S2NP		;8		2		None
	db	DfltM			;8		2		Odd  *
	db	DfltM			;8		2		Even *

;	* not supported - use default mode

	; Dial a phone number (if possible)
	; See the description of the Numbers table above
	; for the form of a phone number string
	; A pointer to the phone number to be dialed is passed in [HL]
	; [A] will be set to TRUE if the connection should be voice-only
	; This allows MODEM8 to be used as an auto-dialer for voice calls
	; Ignore this flag if your modem does not make the distinction
MdmDial:
	ret			;not implemented

	; Hang up phone line (if possible)
MdmHup:
	ret			;not implemented

	; Check state of Carrier Detect from modem
	; If this signal is not available, return TRUE always
	; The value TRUE or FALSE should be returned in [A]
MdmCD:	mvi	a,TRUE
	ret

CurM:	db	DfltM		;current mode

	end

