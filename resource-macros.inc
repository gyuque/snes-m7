; Asset pointer
.macro ldstx_long label
	ldx #.HIWORD(label)
	stx gAssetBankTemp
	ldx #.LOWORD(label)
	stx gAssetOffsetTemp
.endmacro

; ◆ラベルで指示されたアセットをVRAMに転送
;                      アセットのラベル, VRAMアドレス(WORD), 転送サイズ
.macro loadWithAssetAddress asset_label, dest_addr_w, size_b
	phx
	phy
		ldstx_long asset_label
		
		ldx dest_addr_w
		ldy size_b
		jsr transferBitmapDataDMA
	ply
	plx
.endmacro

.define kTitlePalBase   #1
.define kWMapPalBase    #3
.define kWMapSpPalBase  #11
.define kBGPalBase      #14
