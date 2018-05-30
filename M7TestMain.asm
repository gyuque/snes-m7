.setcpu "65816"
.autoimport on
.include "common-macros.inc"
.include "GlobalVars.inc"
.include "resource-macros.inc"
.include "ports.inc"

.include "pad-bits.inc"

.import M7BGData:far
.import SinTable:far
.import SkyBGData:far
.import SkyMapData:far
.import SpriteData:far

.export sceneInit

.export updateScene
.export renderScene
.export processInput

; A16, I16
.proc sceneInit
.a16
.i16
	save_paxy

	jsr resetScroll
	jsr disableScreen
	jsr disableNMI
	jsr forceStopHDMA
	jsr initScrollHDMATable
	
	stz gPadState
	stz gRotAngle
	
	stz gPositionX
	stz gPositionY
	stz gScrollX
	stz gScrollY
	stz gPlayerVX
	stz gPlayerVY
	stz gGlobalCount
	stz gPlayerFrameCount
	stz gPlayerTileBase

	stz gTransCX
	stz gTransCY
		
	stz gTransSin
	stz gTransNSin
	ldsta gTransCos, #$0100
	
	ldsta gTransTestA, #$0100
	ldsta gTransTestD, #$0100
	stz gTransTestB
	stz gTransTestC

	; LOAD
	ldx #0
	ldy #0
	jsr transferPaletteDataBulk8
	
	ldx #4
	ldy #$80 ; sprite#0
	jsr transferPaletteDataBulk8

	; CLEAR
	lda #$4000
	ldy #$4000
	jsr clearVRAMDirect

	loadWithAssetAddress SpriteData, #$4000, #2048
	loadWithAssetAddress SkyBGData, #$6000, #3072
	
	jsr initVideoForMode7
	jsr transferBGData
	jsr transferSkyMapData

	ldx #2 ; select pattern area
	jsr spConfigureForGame
	jsr spClearDirect
	jsr spInitShip
	jsr spInitTitle

	jsr writeBGTransform
	jsr updateScroll

	; RESUME SCREEN
	jsr enableNMI
	ldx #$0F
	jsr enableScreensWithBrightness

	restore_paxy
	rts
.endproc

; A16, I16
.proc initScrollHDMATable
.a16
.i16
	save_paxy

	; 96,0,0
	lda #96
	sta gVScrollHDMATable
	stz gVScrollHDMATable+1

	sta gHScrollHDMATable
	stz gHScrollHDMATable+1

	; 1,0,0
	lda #1
	sta gVScrollHDMATable+3
	stz gVScrollHDMATable+4

	sta gHScrollHDMATable+3
	stz gHScrollHDMATable+4

	; 0(term)
	stz gVScrollHDMATable+6
	stz gHScrollHDMATable+6

	restore_paxy
	rts
.endproc


; A16, I16
.proc updateScene
.a16
.i16
	save_paxy
	mEnableHighClockMode

	jsr setupTransformHDMATable

	jsr updateVelocity
	jsr applyVelocity

	inc gGlobalCount

	; gPlayerFrameCount += gGlobalCount & 0x1
	lda gGlobalCount
	and #$01
	add gPlayerFrameCount
	sta gPlayerFrameCount
	
	restore_paxy
	rts
.endproc

; ◆速度ベクトル関係

; 速度ベクトル減衰処理 = =
.macro ldy_negflag_abs
	bpl :+
		eor #$FFFF
		inc ; 符号反転
		ldy #1
		bra :++
	:
		ldy #0
	:
.endmacro
; A16, I16
.proc updateVelocity
.a16
.i16
	save_paxy
	; v = v*16/17 で減衰させる
	; a=16 max のとき v=240で均衡

	lda gPlayerVY
	ldy_negflag_abs
	; Y <- original is neg?
	; A <- abs(VY)
	
	left_shift_4
	sta pDivc_dividend

set_a8
.a8
	lda #17
	sta pDivc_divisor
set_a16
.a16	

	
	; 結果待ちの間に次の計算をしておく ----
	lda gPlayerVX  ; 4c
	eor #$FFFF     ; 3c
	inc            ; 2c
	tax            ; 2c
	; ここまで11サイクル
	
	xba ; 3c wait
	xba ; 3c wait
	; --------------------------------------
	
	lda pDivc_outQ
	
	cpy #0
	beq no_yinv ; 再度反転
		eor #$FFFF
		inc
	no_yinv:

	sta gPlayerVY

	; X処理 = = =
	ldy #0
	
	lda gPlayerVX
	bpl X_positive
		iny
		txa
	X_positive:

	left_shift_4
	sta pDivc_dividend
	
set_a8
.a8
	lda #17
	sta pDivc_divisor
set_a16
.a16

	wait_divcycles
	
	lda pDivc_outQ

	cpy #0
	beq no_Xinv ; 再度反転
		eor #$FFFF
		inc
	no_Xinv:
	
	sta gPlayerVX

	restore_paxy
	rts
.endproc

.define kPosWrap #$3FFF

; A16, I16
.proc applyVelocity
.a16
.i16
	save_paxy

	lda gPositionX
	add gPlayerVX
	and kPosWrap
	sta gPositionX

	lda gPositionY
	add gPlayerVY
	and kPosWrap
	sta gPositionY

	restore_paxy
	rts
.endproc

; ◆HDMAセットアップ

.proc setupTransformHDMATable
.a16
.i16
	save_paxy
	
	; Init table lookup offset
	lda #$3F00
	sta gSinTableOfs

	lda #96
	sta gHDMATable_TrA
	sta gHDMATable_TrB
	sta gHDMATable_TrC
	sta gHDMATable_TrD

	lda #$0100
	sta gHDMATable_TrA+1
	stz gHDMATable_TrB+1
	stz gHDMATable_TrC+1
	sta gHDMATable_TrD+1


	ldy #64
	ldx #3
	lp:
		lda #2
		sta gHDMATable_TrA,x
		sta gHDMATable_TrB,x
		sta gHDMATable_TrC,x
		sta gHDMATable_TrD,x
		inx
		
		lda gRotAngle
		jsr pickTblCos
		sta gHDMATable_TrA,x
		sta gHDMATable_TrD,x

		lda gRotAngle
		jsr pickTblSin
		sta gHDMATable_TrB,x

		eor #$FFFF ; -sin
		inc
		sta gHDMATable_TrC,x

		inxinx

		lda gSinTableOfs
		sub #256
		sta gSinTableOfs
		
		; - - - -
		dey
		bne lp
		
	stz gHDMATable_TrA,x ; Terminator
	stz gHDMATable_TrB,x ; Terminator
	stz gHDMATable_TrC,x ; Terminator
	stz gHDMATable_TrD,x ; Terminator

	restore_paxy
	rts
.endproc


; A16, I16
.proc renderScene
.a16
.i16
	save_paxy
	mEnableHighClockMode

	jsr processInput
	jsr calcScrollAmount

	jsr spUpdateShip
	jsr sendPaletteAnimation

	jsr writeBGTransform
	; jsr updateScroll
	jsr prepareTransformHDMA
	jsr prepareScrollHDMA
	jsr prepareFadeHDMA
	jsr executeAllHDMA
	

	out_scanpos gBenchmarkOut
	restore_paxy
	rts
.endproc

; A16, I16
.proc sendPaletteAnimation
.a16
.i16
	save_paxy

set_a8
.a8

	; entry index
	lda #40
	sta pCGRAMAddr

	lda gGlobalCount
	lsr
	and #$1E
	tax

	lda AnimColorTable,x
	sta pCGRAMWrite
	lda AnimColorTable+1,x
	sta pCGRAMWrite
set_a16
.a16

	restore_paxy
	rts
.endproc

; A16, I16
.proc processInput
.a16
.i16
	save_paxy

	stz gPlayerTileBase

	; ROTATE

	lda gPadState
	bit kPad16_Right
	beq no_R
		ldsta gPlayerTileBase,#$4006 ; flip

		lda gRotAngle
		dec
		dec
		and #$00FF
		sta gRotAngle
	no_R:

	lda gPadState
	bit kPad16_Left
	beq no_L
		ldsta gPlayerTileBase,#$0004
		
		lda gRotAngle
		inc
		inc
		and #$00FF
		sta gRotAngle
	no_L:

	; fwd - - - - - - -
	lda gPadState
	bit kPad16_TrgA
	beq no_A
		lda gPlayerFrameCount
		bit #$01
		beq :+
			lda #$08
			tsb gPlayerTileBase
		:
		
		jsr goForward
	no_A:


	restore_paxy
	rts
.endproc


; A16, I16
.proc goForward
.a16
.i16
	save_paxy
	stz gSinTableOfs ; select table #0
	
	; Y
	lda gRotAngle
	add #128
	and #$00FF
	jsr pickTblCos
	alshift_4
	
	add gPlayerVY
	sta gPlayerVY

	; X
	lda gRotAngle
	add #128
	and #$00FF
	jsr pickTblSin
	alshift_4

	add gPlayerVX
	sta gPlayerVX
	
	restore_paxy
	rts
.endproc



; A16, I16
; in A: angle(0-255)
; out A: value (8bit-8bit fixed)
.proc pickTblSin
.a16
.i16
	save_pxy

	asl
	bit #$0100
	bne neg_part

		ora gSinTableOfs
		tax
		lda f:SinTable,x

	bra fend
	neg_part:

		and #$00FF
		ora gSinTableOfs
		tax
		lda f:SinTable,x
		eor #$FFFF
		inc
		
fend:
	restore_pxy
	rts
.endproc

; A16, I16
; in A: angle(0-255)
; out A: value (8bit-8bit fixed)
.proc pickTblCos
.a16
.i16
	save_pxy

	add #64
	and #$00FF
	jsr pickTblSin
	
	restore_pxy
	rts
.endproc



; A16, I16
.proc transferBGData
.a16
.i16
	save_paxy

	stz pVWriteAddrW
	
	ldx #0
	ldy #16384
	lp:
		lda f:M7BGData,x
		sta pVWriteValW

		inxinx
		; - - -
		dey
		bne lp
	

	restore_paxy
	rts
.endproc

; A16, I16
.proc transferSkyMapData
.a16
.i16
	save_paxy

	lda #$7000
	sta pVWriteAddrW
	
	ldx #0
	ldy #(32*38)
	lp:
		lda f:SkyMapData,x
		sta pVWriteValW

		inxinx
		; - - -
		dey
		bne lp
	

	restore_paxy
	rts
.endproc



; A16, I16

.macro send_transform port,var
	lda var
	sta port

	lda var+1
	sta port
.endmacro

.proc writeBGTransform
.a16
.i16
	save_paxy


	; BG configuration
set_a8
.a8

	; init transform
;	send_transform $211B,gTransTestA
;	send_transform $211C,gTransTestB
;	send_transform $211D,gTransTestC
;	send_transform $211E,gTransTestD

	lda gTransCX
	sta $211F
	lda gTransCX+1
	sta $211F

	lda gTransCY
	sta $2120
	lda gTransCY+1
	sta $2120

set_a16
.a16

	restore_paxy
	rts
.endproc

.proc updateScroll
.a16
.i16
	save_paxy

set_a8
.a8

;	lda gScrollX
;	sta pScrollX0
;	lda gScrollX+1
;	sta pScrollX0

;	lda gScrollY
;	sta pScrollY0
;	lda gScrollY+1
;	sta pScrollY0

set_a16
.a16

	restore_paxy
	rts
.endproc

.proc calcScrollAmount
.a16
.i16
	save_paxy

	; scrolling sky BG
	lda gRotAngle
	left_shift_2
	eor #$FFFF
	sta gHScrollHDMATable+1

	lda gPositionX
	right_shift_4 ; fixed -> int
	sta gScrollX
	sta gHScrollHDMATable+4

	lda gPositionY
	right_shift_4 ; fixed -> int
	sta gScrollY
	sta gVScrollHDMATable+4

	
	lda gScrollX
	add #128
	sta gTransCX

	lda gScrollY
	add kRotateCenterY
	sta gTransCY

	restore_paxy
	rts
.endproc

; ◆変形用HDMA実行

; A16, I16
.proc prepareTransformHDMA
.a16
.i16
	save_paxy
	

	set_a8
	.a8
		; A and B
		; X <- Table for A
		; Y <- Table for B
		ldx #.LOWORD(gHDMATable_TrA)
		ldy #.LOWORD(gHDMATable_TrB)

		; == X ==
		; Set VRAM Target address
		; $211B(Transform A)
		lda #$1B
		sta pDMA1Dest

		; Table bank
		lda #.LOBYTE(.HIWORD(gHDMATable_TrA))
		sta pDMA1SourceBank
		
		; Table address
		stx pDMA1SourceOffsetW

		; byte-twice mode, normal HDMA
		lda #$02
		sta pDMA1Config

		; == Y ==
		; Set VRAM Target address
		; $211C(transform B)
		lda #$1C
		sta pDMA2Dest

		; Table bank
		lda #.LOBYTE(.HIWORD(gHDMATable_TrB))
		sta pDMA2SourceBank
		
		; Table address
		sty pDMA2SourceOffsetW

		; byte-twice mode, normal HDMA
		lda #$02
		sta pDMA2Config

		; C and D
		; X <- Table for C
		; Y <- Table for D
		ldx #.LOWORD(gHDMATable_TrC)
		ldy #.LOWORD(gHDMATable_TrD)

		; == X == ; Set VRAM Target address
		; $211D(Transform C)
		lda #$1D
		sta pDMA3Dest

		; Table bank
		lda #.LOBYTE(.HIWORD(gHDMATable_TrC))
		sta pDMA3SourceBank
		
		; Table address
		stx pDMA3SourceOffsetW

		; byte-twice mode, normal HDMA
		lda #$02
		sta pDMA3Config

		; == Y ==
		; Set VRAM Target address
		; $211E(transform B)
		lda #$1E
		sta pDMA4Dest

		; Table bank
		lda #.LOBYTE(.HIWORD(gHDMATable_TrD))
		sta pDMA4SourceBank
		
		; Table address
		sty pDMA4SourceOffsetW

		; byte-twice mode, normal HDMA
		lda #$02
		sta pDMA4Config
		
	set_a16
	.a16
	

	restore_paxy
	rts
.endproc

; ◆地平線HDMA

; A16, I16
.proc prepareScrollHDMA
.a16
.i16
	save_paxy
	

	set_a8
	.a8
		; A and B
		; X <- Table for A
		; Y <- Table for B
		ldx #.LOWORD(gVScrollHDMATable)
		ldy #.LOWORD(gHScrollHDMATable)

		; == X ==
		; Set VRAM Target address
		; $210E(BG1 v-scroll)
		lda #$0E
		sta pDMA5Dest

		; Table bank
		lda #.LOBYTE(.HIWORD(gVScrollHDMATable))
		sta pDMA5SourceBank
		
		; Table address
		stx pDMA5SourceOffsetW

		; byte-twice mode, normal HDMA
		lda #$02
		sta pDMA5Config

		; == Y ==
		; Set VRAM Target address
		; $210D(BG1 h-scroll)
		lda #$0D
		sta pDMA6Dest

		; Table bank
		lda #.LOBYTE(.HIWORD(gHScrollHDMATable))
		sta pDMA6SourceBank
		
		; Table address
		sty pDMA6SourceOffsetW

		; byte-twice mode, normal HDMA
		lda #$02
		sta pDMA6Config
	set_a16
	.a16
	

	restore_paxy
	rts
.endproc


; ◆遠方フェードHDMA

; A16, I16
.proc prepareFadeHDMA
.a16
.i16
	save_paxy
	

	set_a8
	.a8
		; A and B
		; X <- Table for A
		ldx #.LOWORD(FadeHDMATable)

		; == X ==
		; Set VRAM Target address
		; $2100(screen brightness)
		lda #$00
		sta pDMA7Dest

		; Table bank
		lda #.LOBYTE(.HIWORD(FadeHDMATable))
		sta pDMA7SourceBank
		
		; Table address
		stx pDMA7SourceOffsetW

		; byte-single mode, normal HDMA
		lda #$00
		sta pDMA7Config
		
	set_a16
	.a16
	

	restore_paxy
	rts
.endproc


; ◆地平線HDMA

; A16, I16
.proc executeAllHDMA
.a16
.i16
	save_paxy
	

	set_a8
	.a8
		; A and B
		; X <- Table for A
		ldx #.LOWORD(HorizonHDMATable)

		; == X ==
		; Set VRAM Target address
		; $2105(screen mode)
		lda #$05
		sta pDMA0Dest

		; Table bank
		lda #.LOBYTE(.HIWORD(HorizonHDMATable))
		sta pDMA0SourceBank
		
		; Table address
		stx pDMA0SourceOffsetW

		; byte-single mode, normal HDMA
		lda #$00
		sta pDMA0Config
		
		; ---------------------------------------------
		; Enable HDMA Ch0-7 all
		lda #$FF
		sta pHDMATrigger

	set_a16
	.a16
	

	restore_paxy
	rts
.endproc

AnimColorTable:
.word $221f, $21ff, $1dde, $1dbc, $199a, $1978, $1556, $1535
.word $1113, $10f1, $0ccf, $0cad, $088b, $0869, $0447, $0426

; Mode1/LargeChip -> Mode7
HorizonHDMATable:
.byte 96
.byte $11
.byte 2
.byte $07
.byte 0
.byte 0


FadeHDMATable:
.byte 96
.byte $0F,2
.byte $05,2
.byte $07,3
.byte $09,4
.byte $0A,5
.byte $0B,6
.byte $0C,7
.byte $0D,8
.byte $0E,9
.byte $0F
.byte 0
.byte 0
