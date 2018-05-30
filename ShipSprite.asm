.setcpu "65816"
.autoimport on
.include "common-macros.inc"
.include "GlobalVars.inc"
.include "ports.inc"

.export spConfigureForGame
.export spClearDirect
.export spInitShip
.export spInitTitle
.export spUpdateShip

.define kTitleSpIndex   #0
.define kShipSpIndex    #4
.define kShadowSpIndex  #6

; A16, I16
; in X: Name selection
.proc spConfigureForGame
.a16
.i16
	save_paxy
	txa
	begin_lvar_1 ; var1 <- A <- X

	; name | offset
	; -----+-------
	;    0 |  0000W
	;    1 |  2000W
	;    2 |  4000W

	; size %000 = small: 8x 8  large:16x16
	; size %001 = small: 8x 8  large:32x32
	; size %010 = small: 8x 8  large:64x64
	; size %011 = small:16x16  large:32x32

	;     sssbbnnn (sss=size  bb=base  nnn=name)
	lda #%01100000
	ora 1,s

set_a8
.a8
	sta pSpriteConf
set_a16
.a16

	end_lvar_1
	restore_paxy
	rts
.endproc


; A16, I16
.proc spClearDirect
.a16
.i16
	save_paxy

	stz pOAMWAddress

set_a8
.a8

	ldy #128
	loop1:
		stz pOAMWrite ; set x

		lda #$E0  ; y=above the top
		sta pOAMWrite ; set y
		stz pOAMWrite ; tile
		stz pOAMWrite ; others

		dey
		bne loop1

set_a16
.a16

	; Second Table
	lda #$0100
	sta pOAMWAddress

set_a8
.a8

	ldy #32
	loop2:
		stz pOAMWrite

		dey
		bne loop2
	
set_a16
.a16


	restore_paxy
	rts
.endproc




; A16, I16
.proc spInitShip
.a16
.i16
	save_paxy

	; first
	lda kShipSpIndex
	ldx #$2000 ; priority=2	
	jsr spSetTileDirect

	ldx #(128-16)
	ldy #112
	jsr spMoveDirect
	
	; second
	inc ; next sprite
	ldx #$2002 ; priority=2, tile=2
	jsr spSetTileDirect

	ldx #128
	jsr spMoveDirect

	; shadow first
	lda kShadowSpIndex
	ldx #$2020 ; priority=2, tile=32
	jsr spSetTileDirect

	ldx #(128-16)
	ldy kRotateCenterY-8
	jsr spMoveDirect

	; shadow second
	inc ; next sprite
	ldx #$6020 ; hflip+priority=2, tile=32
	jsr spSetTileDirect

	ldx #128
	jsr spMoveDirect

	restore_paxy
	rts
.endproc


; A16, I16
.proc spInitTitle
.a16
.i16
	save_paxy

	; first
	lda kTitleSpIndex
	ldx #$2022 ; priority=2	, tile=34
	ldy #4
	lp:
		jsr spSetTileDirect

		save_axy
			left_shift_4
			add #10
			tax
			ldy #200
			
			sub #10
			right_shift_4
			
			jsr spMoveDirect
		restore_axy
	
		inc
		inxinx
		; - - -
		dey
		bne lp

	restore_paxy
	rts
.endproc

; A16, I16
.proc spUpdateShip
.a16
.i16
	save_paxy

	lda gPlayerFrameCount
	and #$1E ; (& 0xf) << 1
	tax
	ldy FloatYTable,x

	lda kShipSpIndex
	ldx #(128-16)
	jsr spMoveDirect
	
	; next sprite
	inc
	ldx #128
	jsr spMoveDirect

	lda gPlayerTileBase
	ora #$2000 ; add priority
	tax

	lda kShipSpIndex
	jsr spSetTileDirect
	
	lda gPlayerTileBase
	bit #$4000
	bne flipped
		inxinx ; next chip
		bra endif_flip
	flipped:
		dexdex ; next chip
	endif_flip:
	
	lda kShipSpIndex+1
	jsr spSetTileDirect

	restore_paxy
	rts
.endproc




; A16, I16
; in A: Index
; in X: X coord
; in Y: Y coord
.proc spMoveDirect
.a16
.i16
	save_paxy
	
	asl ; A*=2
	sta pOAMWAddress

set_a8
.a8
	txa
	sta pOAMWrite
	
	tya
	sta pOAMWrite
set_a16
.a16
	
	restore_paxy
	rts
.endproc

; A16, I16
; in A: Index
; in X: Tile and Flags
.proc spSetTileDirect
.a16
.i16
	save_paxy

	asl ; A = A*2+1
	inc
	sta pOAMWAddress

	; Y <- HI(X)
	txa
	xba
	tay

set_a8
.a8
	txa
	sta pOAMWrite
	
	tya
	sta pOAMWrite
set_a16
.a16


	restore_paxy
	rts
.endproc


; A16, I16
; in A: Index/8
; in X: value
.proc spExtFlagsDirect
.a16
.i16
	save_paxy

	add #256
	sta pOAMWAddress

set_a8
.a8
	txa
	sta pOAMWrite
	sta pOAMWrite
set_a16
.a16

	restore_paxy
	rts
.endproc

FloatYTable:
.word 122+0, 122+1, 122+1, 122+2
.word 122+3, 122+3, 122+4, 122+4
.word 122+4, 122+3, 122+3, 122+2
.word 122+1, 122+1, 122+0, 122+0
