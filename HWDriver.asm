.setcpu "65816"
.autoimport on
.include "common-macros.inc"
.include "GlobalVars.inc"
.include "ports.inc"
.import PaletteBase:far

; API LIST
; =============== Initialization Utilities ===============
.export initSystemGenericStatuses
.export initVideoForGame
.export initVideoForMode7
.export clearVRAMDirect

; ==================== Screen Control ====================
.export disableScreen
.export enableScreensWithBrightness
.export enableBG2WithBrightness
.export setScreenBrightness
.export disableNMI
.export enableNMI
.export forceStopHDMA

.export resetScroll

; ======================= Transfer =======================
.export transferPaletteData
.export transferPaletteDataBulk8
.export transferBitmapDataDMA


; ◆ ハードウェア初期化
; ビデオ関係は外でするので、今のところパッド入力のオプションのみ
; A16, I16
.proc initSystemGenericStatuses
.a16
.i16
	save_paxy

	set_a8
	.a8
		; Disable old-style pad input
		stz $4016
	set_a16
	.a16

	restore_paxy
	rts
.endproc


; ◆ ビデオ初期化
; ・画面モード、チップサイズ設定
; ・VRAMアドレス設定
; A16, I16
.proc initVideoForGame
.a16
.i16
	save_paxy

	; BG configuration
set_a8
.a8
	; Set BG tile size(Upper 4bits [BG4321])
	; Specify BGMode  MODE1={16/16/4/0} colors
	lda #$39 ; order change bit enabled
	sta $2105 ; <- SSSSPMMM (chip Size, Priority change, screen Mode)


	; BG1 Size = 32x32 tiles
	;     Map start = +6800W
	; * Tile area = 2048(0x800h) bytes
	lda kMap1StartHi
	sta $2107 ; <- AAAAAASS

	; BG2 Size = 32x32 tiles
	;     Map start = +7000W
	; * Tile area = 2048(0x800h) bytes
	lda kMap2StartHi
	sta $2108

	; BG3 Size = 32x32 tiles
	;     Map start = +7800W
	; * Tile area = 2048(0x800h) bytes
	lda kMap3StartHi
	sta $2109


	; sta $2108 ; BG2 map/size

	; BG 1/2 Pattern Source Start(0)
	; $0000W-$3FFFW (32KB)
	stz $210b

	; BG 3 Pattern Source Start(6*0x2000 B)=$6000W + 2048B
	lda #$06
	sta $210c

set_a16
.a16

	restore_paxy
	rts
.endproc


; A16, I16
.proc initVideoForMode7
.a16
.i16
	save_paxy

	; BG configuration
set_a8
.a8

	lda #$00
	sta pM7FillConfig

	lda #$07
	sta $2105 ; <- SSSSPMMM (chip Size, Priority change, screen Mode)

	; init transform
	lda #1
	stz $211B
	sta $211B

	stz $211E
	sta $211E
	; ^^^ note: HIGH BYTE=Int part thus 1.0 = 0100h

	stz $211C
	stz $211C

	stz $211D
	stz $211D

	; BG 1 map area start
	lda #$71  ; map 7000h- , 64x32
	sta $2107 ; <- AAAAAASS

	; BG 1 Pattern Source Start($6000W)
	lda #$06
	sta $210B


set_a16
.a16

	restore_paxy
	rts
.endproc

; ◆ VRAM直接クリア
; in A: Dest address(W)
; in Y: Amount
; A16, I16
.proc clearVRAMDirect
.a16
.i16
	save_paxy
	sta pVWriteAddrW

	lp:
		stz pVWriteValW

		dey
		bne lp

	restore_paxy
	rts
.endproc


; ◆ 全画面表示オフ
; A16, I16
.proc disableScreen
.a16
.i16
	php
	pha

set_a8
.a8
	lda #$80
	sta $2100
set_a16
.a16

	pla
	plp
	rts
.endproc


; ◆ 全画面表示オン＋輝度設定
; A16, I16
; in X: brightness(1-15)
.proc enableScreensWithBrightness
.a16
.i16
	save_paxy

set_a8
.a8
	; vvvvv CONFIGURE HERE
	; flags = [X][X][X][SP] [BG4][BG3][BG2][BG1]
;	lda #%00010111 ; BG1+2+3+SP
	lda #%00010001 ; BG1+SP
	sta pScrsEnabled ; Main screen
	stz $212d ; Sub screen (0=all off)

	; brightness
	txa
	and #$0f
	sta $2100

set_a16
.a16
	
	restore_paxy
	rts
.endproc

; A16, I16
; in X: brightness(1-15)
.proc enableBG2WithBrightness
.a16
.i16
	save_paxy

set_a8
.a8
	; vvvvv CONFIGURE HERE
	; flags = [X][X][X][SP] [BG4][BG3][BG2][BG1]
	lda #%00000010 ; BG2
	sta pScrsEnabled ; Main screen
	stz $212d ; Sub screen (0=all off)

	; brightness
	txa
	and #$0f
	sta $2100

set_a16
.a16
	
	restore_paxy
	rts
.endproc

; in A: brightness(0-15)
.proc setScreenBrightness
.a16
.i16
	save_pa

set_a8
.a8
	and #$0f
	sta $2100
set_a16
.a16

	restore_pa
	rts
.endproc


; ◆ NMI(VBLANK割り込み)有効化
; A16, I16
.proc enableNMI
.a16
.i16
	pha

	set_a8
	.a8
		lda #$81 ; bit 0 is always on (Joy pad auto read)
		sta $4200
	set_a16
	.a16

	pla
	rts
.endproc

; ◆ NMI(VBLANK割り込み)停止
; A16, I16
.proc disableNMI
.a16
.i16
	pha

	set_a8
	.a8
		lda #$01
		sta $4200
	set_a16
	.a16

	pla
	rts
.endproc


; ◆パレット転送
; A16, I16
; in X: Palette select
; in Y: Dest offset (in words)
; Note: each palette entry is 16bit(1W/2B)
.proc transferPaletteData
.a16
.i16
	save_paxy

	; X <- X*32
	txa
	left_shift_5
	tax

	set_a8
	.a8

	; Set write position
	tya
	sta $2121

	ldy #32 ; Loop 32 times (2*16)

:	lda f:PaletteBase, x
	sta $2122

	inx
	dey
	bne :-

	set_a16
	.a16

	restore_paxy
	rts
.endproc

; ◆パレットバルク転送
; A16, I16
; in X: Palette select
; in Y: Dest offset (in words)
; Note: each palette entry is 16bit(1W/2B)
.proc transferPaletteDataBulk8
.a16
.i16
	save_paxy

	; X <- X*32
	txa
	left_shift_5
	tax

	set_a8
	.a8

	; Set write position
	tya
	sta $2121

	ldy #32*8 ; Loop 32 times (2*16)

:	lda f:PaletteBase, x
	sta $2122

	inx
	dey
	bne :-

	set_a16
	.a16

	restore_paxy
	rts
.endproc



; ◆VRAMデータDMA転送
; A16, I16
; in X: Dest word address
; in Y: Size (in BYTES)
.proc transferBitmapDataDMA
.a16
.i16
	save_paxy

	; Set dest VRAM address
	stx $2116

	; Set length(bytes)
	sty pDMA0ByteCountW

	; load address(long)
	lda gAssetBankTemp
	ldy gAssetOffsetTemp

	set_a8
	.a8
		; Set DMA source address
		sta pDMA0SourceBank    ; bank (8bit)
		sty pDMA0SourceOffsetW ; offset(16bit)

		; Set DMA target
		; write to $2118(VRAM channel)
		lda #$18
		sta pDMA0Dest

		; Write a word
		lda #$01
		sta pDMA0Config

		; Start - - - - - - - - - - - - -
		lda #$01
		sta pDMATrigger

	set_a16
	.a16

	restore_paxy
	rts
.endproc


; ◆スクロール位置初期化
; A16, I16
.proc resetScroll
.a16
.i16
	save_pa

	; BGにスクロール適用
set_a8
.a8

	; FRONT
	lda #$00
	sta pScrollX0
	sta pScrollX0

	sta pScrollY0
	sta pScrollY0

	; BACK
	sta pScrollX1
	sta pScrollX1

	sta pScrollY1
	sta pScrollY1

	; TEXT
	
	sta pScrollY2
	sta pScrollY2

set_a16
.a16

	restore_pa
	rts
.endproc

; A16, I16
.proc forceStopHDMA
.a16
.i16
	save_pa

set_a8
.a8
	stz pHDMATrigger
set_a16
.a16

	restore_pa
	rts
.endproc
