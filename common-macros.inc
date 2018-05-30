.macro mEnableHighClockMode
	sep #$20
.a8

	lda #1
	sta $420d
	jml f:$800000+high_mode_start
high_mode_start:
	nop

	rep #$20
.a16

.endmacro

; Wait 16 cycles (for HW div)
.macro wait_divcycles
	pha ; 3
	xba ; 3
	xba ; 3
	xba ; 3
	pla ; 4
.endmacro

; performance tuning utility
.macro out_scanpos dest
set_a8
.a8
	lda $2137
	lda $213D
	lda $213D
;	cmp #$83
;	bcc not_heavy
		sta dest
;	not_heavy:
set_a16
.a16
.endmacro


; 8/16 switch  --------------------------------------------------------------

.macro set_a8
	sep	#$20
.endmacro

.macro set_a16
	rep	#$20
.endmacro

; no-carry add/sub +++++++++++++++++++++++++++++++++++++++++++++++++

.macro add dest
	clc
	adc dest
.endmacro

.macro adx dest
	clc
	adc dest,x
.endmacro

.macro sub dest
	sec
	sbc dest
.endmacro

.macro sbx dest
	sec
	sbc dest,x
.endmacro

; Quick store <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.macro ldsta addr,val
	lda val
	sta addr
.endmacro

.macro debug_ld_sta addr,val
	lda val
	sta addr
.endmacro


; Bulk push/pop =============================================================

.macro save_paxy
	php
	pha
	phx
	phy
.endmacro

.macro restore_paxy
	ply
	plx
	pla
	plp
.endmacro


.macro save_pxy
	php
	phx
	phy
.endmacro

.macro restore_pxy
	ply
	plx
	plp
.endmacro


.macro save_pa
	php
	pha
.endmacro

.macro restore_pa
	pla
	plp
.endmacro


.macro save_pax
	pha
	phx
	php
.endmacro

.macro restore_pax
	plp
	plx
	pla
.endmacro


.macro save_pay
	php
	pha
	phy
.endmacro

.macro restore_pay
	ply
	pla
	plp
.endmacro


.macro save_axy
	pha
	phx
	phy
.endmacro

.macro restore_axy
	ply
	plx
	pla
.endmacro


; Bulk shift =============================================================


.macro left_shift_2
	asl
	asl
.endmacro

.macro A_to_4x
	asl
	asl
.endmacro
; alias

.macro left_shift_3
	asl
	asl
	asl
.endmacro

.macro left_shift_4
	asl
	asl
	asl
	asl
.endmacro

.macro left_shift_5
	asl
	asl
	asl
	asl
	asl
.endmacro

.macro left_shift_6
	left_shift_3
	left_shift_3
.endmacro

.macro left_shift_8
	asl
	asl
	asl
	asl
	asl
	asl
	asl
	asl
.endmacro

.macro right_shift_8
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
.endmacro

.macro right_shift_2
	lsr
	lsr
.endmacro

.macro right_shift_3
	lsr
	lsr
	lsr
.endmacro

.macro right_shift_4
	right_shift_2
	right_shift_2
.endmacro

.macro right_shift_5
	right_shift_3
	right_shift_2
.endmacro

.macro arith_rshift_w
	lsr
	bit #$4000 ; take *former* sign flag
	beq :+
		ora #$8000
	:
.endmacro

.macro alshift_4
	arith_rshift_w
	arith_rshift_w
	arith_rshift_w
	arith_rshift_w
.endmacro


; Bulk inc/dec =============================================================

.macro incinc
	inc
	inc
.endmacro

.macro decdec
	dec
	dec
.endmacro

.macro inxinx
	inx
	inx
.endmacro

.macro dexdex
	dex
	dex
.endmacro

.macro inyiny
	iny
	iny
.endmacro

; local vars ==============================

.macro begin_lvar_1
	pha
.endmacro

.macro end_lvar_1
	pla
.endmacro


.macro begin_lvar_2
	pha
	pha
.endmacro

.macro end_lvar_2
	pla
	pla
.endmacro


.macro begin_lvar_3
	pha
	pha
	pha
.endmacro

.macro end_lvar_3
	pla
	pla
	pla
.endmacro


.macro begin_lvar_4
	pha
	pha
	pha
	pha
.endmacro

.macro end_lvar_4
	pla
	pla
	pla
	pla
.endmacro


.macro ldaw_v1
	lda 1,s
.endmacro

.macro staw_v1
	sta 1,s
.endmacro

.macro add_v1
	clc
	adc 1,s
.endmacro

.macro ora_v1
	ora 1,s
.endmacro

.macro and_v1
	and 1,s
.endmacro

.macro cmp_v1
	cmp 1,s
.endmacro

.macro sub_v1
	sec
	sbc 1,s
.endmacro

.macro ldaw_v2
	lda 3,s
.endmacro

.macro staw_v2
	sta 3,s
.endmacro

.macro addw_v2
	clc
	adc 3,s
.endmacro

.macro subw_v2
	sec
	sbc 3,s
.endmacro

.macro cmpw_v2
	cmp 3,s
.endmacro


.macro ldaw_v3
	lda 5,s
.endmacro

.macro staw_v3
	sta 5,s
.endmacro


.macro ldaw_v4
	lda 7,s
.endmacro

.macro staw_v4
	sta 7,s
.endmacro
