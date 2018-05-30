.setcpu     "65816"
.autoimport on
.include "common-macros.inc"
.include "GlobalVars.inc"
.include "ports.inc"

.segment "STARTUP"
; Reset int. (Entry Point) -------------------
.proc Reset ; int handler
	; *unsafe* X
	; vvv Bootstrap -----------------
	sei ; Disable int.
	clc ; C=0
	xce ; C<->E Native Mode On

	phk
	plb ; PB -stack-> DB (=0)

	rep #$30 ; A,I 16bit
	.a16
	.i16

	; Initialize stack
	ldx #$1fff
	txs
	
	jsr initRegs
	; ^^^ Bootstrap -----------------

	stz gRenderFinished
	jsr sceneInit
	jsr doMainLoop

	rti
.endproc

; A16, I16
.proc doMainLoop
.a16
.i16
	save_paxy

	mloop:
		jsr updateScene
		stz gRenderFinished
		
		r_wait:
			lda gRenderFinished
			beq r_wait

	bra mloop
	
	restore_paxy
	rts
.endproc

.proc VBlank ; int handler
	php ; 割り込み前のP保存
set_a16 ; 保存PHAと復帰PLAはA16で統一
.a16
.i16
	pha ; Aを16bitで保存

	jsr renderScene
	jsr updatePadState

	inc gRenderFinished

	pla ; Aを16bitで復帰
	plp ; 割り込み前のPを復帰
	rti
.endproc


.proc updatePadState
	set_a8
	.a8 

	; Wait until auto-read is finished
:	lda $4212
	and #$01
	bne :-

	set_a16
	.a16

	; Store Pad Status
	lda $4218
	sta gPadState

	rts
.endproc


; ===================================================
; Metadata and Assets
; ===================================================

; Cartridge metadata - - -
.segment "CARTINFO"
	;        123456789012345678901
	.byte	"MODE7TEST            "	; Game Title(21Bytes)
	.byte	$00				; 0x01:HiRom, 0x30:FastRom(3.57MHz)
	.byte	$00				; ROM only
	.byte	$09				; 512KB ROM
	.byte	$00				; RAM Size (8KByte * N)
	.byte	$00				; NTSC
	.byte	$01				; Licensee
	.byte	$00				; Version

	; Embed information (must be replaced with checksum)
	.word   $CDCD
	.word   $3232

	.byte	$ff, $ff, $ff, $ff		; unknown

	.word	$0000       ; Native:COP
	.word	$0000       ; Native:BRK
	.word	$0000       ; Native:ABORT
	.word	VBlank		; Native:NMI
	.word	$0000		; 
	.word	$0000       ; Native:IRQ

	.word	$0000       ; 
	.word	$0000       ; 

	.word	$0000       ; Emulation:COP
	.word	$0000       ; 
	.word	$0000       ; Emulation:ABORT
	.word	$0000       ; Emulation:NMI
	.word	Reset       ; Emulation:RESET
	.word	$0000       ; Emulation:IRQ/BRK



; DATA SEGMENTS --------------------------------------------------------
.export M7BGData:far
.export SkyBGData:far
.export SkyMapData:far
.export SpriteData:far
.export PaletteBase:far
.export SinTable:far

; - - - - - - - - - - - -
; ROMデータ 画像系_1
.segment "VISASSET1":far
M7BGData:
.incbin "assets/m7map.bin"

.segment "VISASSET2": far
PaletteBase:
.word $0c84, $0000, $7fff, $7bde, $5f38, $4252, $35ef, $216b, $14a5, $10c8, $216f, $0c87, $000c, $0094, $017d, $0e3f
.word $2ca1, $4581, $6f02, $67c7, $67d1, $0614, $0a9a, $033f, $2b7f, $7d18, $2588, $4605, $3e66, $46c8, $430d, $5773
.word $7a3c, $7a3c, $7a3c, $7a3c, $7a3c, $7a3c, $7a3c, $7a3c, $0426, $7a3c, $7a3c, $7a3c, $7a3c, $7a3c, $7a3c, $7a3c
.word $7a3c, $1461, $2d24, $4584, $63bb, $4f50, $7687, $7350, $735f, $71ee, $3544, $03f9, $03f9, $03f9, $03f9, $03f9

.incbin "assets/sp-palette.bin"

.segment "VISASSET3": far
SkyBGData:
.incbin "assets/sky-bg.bin"

SkyMapData:
.incbin "assets/sky-map.bin"

SpriteData:
.incbin "assets/sp-pattern.bin"

.segment "VISASSET4": far

.segment "VISASSET5": far

.segment "MISCASSET": far
SinTable:
.include "sin-table.inc"

.segment "HIRODATA4": far

.segment "HIRODATA5": far

.segment "HIRODATA6": far

.segment "ALTSNDS1": far

.segment "DONTUSE"
	.byte "NO-DATA"

